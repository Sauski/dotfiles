-- tests/auto_build_spec.lua: E2E tests for auto-build on save functionality

describe("Auto-build on save", function()
  local original_cwd

  before_each(function()
    -- Get repo root by finding .git in parent directories
    local cwd = vim.fn.getcwd()
    original_cwd = cwd
    while original_cwd ~= "/" and original_cwd ~= "" do
      if vim.fn.isdirectory(original_cwd .. "/.git") == 1 then
        break
      end
      original_cwd = vim.fn.fnamemodify(original_cwd, ":h")
    end

    -- Ensure package.path includes our local module paths (absolute paths)
    local root = vim.fn.fnamemodify(original_cwd, ":p"):gsub("\\", "/"):gsub("/$", "")
    if not package.path:find(root .. "/lua/%?%.lua", 1, true) then
      package.path = package.path .. ";" .. root .. "/lua/?.lua"
      package.path = package.path .. ";" .. root .. "/lua/?/init.lua"
    end

    -- Create .git directory in test fixture for git root detection
    local git_dir = original_cwd .. "/tests/fixtures/broken_project/.git"
    if vim.fn.isdirectory(git_dir) == 0 then
      vim.fn.mkdir(git_dir, "p")
    end

    -- Clear autocmds but DON'T reload modules
    -- (reloading builder would reset last_changedtick state)
    pcall(vim.api.nvim_del_augroup_by_name, "quickbuild_auto")
    pcall(vim.api.nvim_del_augroup_by_name, "quickbuild_cleanup")
  end)

  after_each(function()
    vim.cmd("cd " .. original_cwd)

    -- Cleanup build artifacts
    local build_dir = original_cwd .. "/tests/fixtures/broken_project/build"
    if vim.fn.isdirectory(build_dir) == 1 then
      vim.fn.system({"rm", "-rf", build_dir})
    end

    -- Cleanup .git directory
    local git_dir = original_cwd .. "/tests/fixtures/broken_project/.git"
    if vim.fn.isdirectory(git_dir) == 1 then
      vim.fn.system({"rm", "-rf", git_dir})
    end

    -- Close all buffers
    vim.cmd("bufdo! bwipeout!")

    -- Clear autocmds
    pcall(vim.api.nvim_del_augroup_by_name, "quickbuild_auto")
    pcall(vim.api.nvim_del_augroup_by_name, "quickbuild_cleanup")
  end)

  local function check_dependencies()
    if vim.fn.executable("cmake") == 0 then
      pending("cmake not found, skipping E2E test")
      return false
    end

    local has_compiler = vim.fn.executable("cl") == 1 or
                        vim.fn.executable("gcc") == 1 or
                        vim.fn.executable("clang") == 1 or
                        vim.fn.executable("g++") == 1 or
                        vim.fn.executable("clang++") == 1

    if not has_compiler then
      pending("no C++ compiler found, skipping E2E test")
      return false
    end

    return true
  end

  local function get_scanner_path()
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil
    if is_windows then
      return original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      return original_cwd .. "/scanner/build/qb-scanner"
    end
  end

  it("buffer change detection: unchanged buffer should NOT trigger build", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path = get_scanner_path()
    require("quickbuild").setup({
      scanner_path = scanner_path,
    })

    -- Open main.cpp
    local main_cpp_path = test_project .. "/main.cpp"
    vim.cmd("edit " .. main_cpp_path)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Track ACTUAL builds (not just M.build calls)
    local actual_build_count = 0
    local bufnr_values = {}
    local builder = require("quickbuild.builder")

    -- Spy on start_build_now to count actual builds
    local build_module_internals = debug.getregistry()
    local original_execute_sequential

    -- Hook into builder module to intercept actual build starts
    local original_build = builder.build
    builder.build = function(opts)
      table.insert(bufnr_values, opts.bufnr)
      local tick = vim.api.nvim_buf_get_changedtick(bufnr)
      print(string.format("\n==> M.build() called: bufnr_in_opts=%s, actual_bufnr=%d, tick=%d",
        tostring(opts.bufnr), bufnr, tick))

      -- Wrap to detect if build actually starts
      local orig_on_complete = opts.on_complete
      opts.on_complete = function(...)
        actual_build_count = actual_build_count + 1
        print(string.format("==> ACTUAL BUILD #%d completed", actual_build_count))
        if orig_on_complete then
          orig_on_complete(...)
        end
      end

      original_build(opts)
    end

    -- First save (with actual change)
    local tick_before = vim.api.nvim_buf_get_changedtick(bufnr)
    vim.cmd("normal! Gointroduce change")
    local tick_after_change = vim.api.nvim_buf_get_changedtick(bufnr)
    print(string.format("\nFirst save (WITH change)... tick: %d -> %d", tick_before, tick_after_change))
    vim.cmd("write")

    -- Wait for actual build to complete (max 30 seconds)
    local completed = vim.wait(30000, function() return actual_build_count >= 1 end, 100)
    assert.is_true(completed, "First build should complete within 30 seconds")

    local builds_after_change = actual_build_count

    -- Second save (NO change)
    local tick_before_2 = vim.api.nvim_buf_get_changedtick(bufnr)
    print(string.format("\nSecond save (NO change)... tick: %d", tick_before_2))
    vim.cmd("write")
    vim.wait(1000, function() return false end)

    local builds_after_no_change = actual_build_count

    -- Third save (NO change again)
    local tick_before_3 = vim.api.nvim_buf_get_changedtick(bufnr)
    print(string.format("\nThird save (NO change)... tick: %d", tick_before_3))
    vim.cmd("write")
    vim.wait(1000, function() return false end)

    local builds_after_second_no_change = actual_build_count

    -- Restore
    builder.build = original_build

    print(string.format("\nActual build counts: after_change=%d, after_no_change=%d, after_second_no_change=%d",
      builds_after_change, builds_after_no_change, builds_after_second_no_change))
    print(string.format("bufnr values passed: %s", vim.inspect(bufnr_values)))

    -- KEY ASSERTION: bufnr should be passed from autocmd
    for i, val in ipairs(bufnr_values) do
      assert.is_not_nil(val, string.format("M.build call #%d should have bufnr in opts", i))
      assert.equals(bufnr, val, string.format("M.build call #%d should have correct bufnr", i))
    end

    -- Changed buffer SHOULD trigger ACTUAL build
    assert.is_true(builds_after_change >= 1,
      "Actual build should occur when buffer has changes")

    -- Unchanged buffer SHOULD NOT trigger ACTUAL build
    assert.equals(builds_after_change, builds_after_no_change,
      "Actual build should NOT occur when buffer has no changes (first redundant save)")
    assert.equals(builds_after_change, builds_after_second_no_change,
      "Actual build should NOT occur when buffer has no changes (second redundant save)")
  end)
end)

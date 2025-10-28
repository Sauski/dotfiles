-- tests/e2e_spec.lua: End-to-end tests with real compilation

describe("E2E build", function()
  local original_cwd

  before_each(function()
    original_cwd = vim.fn.getcwd()

    -- Create .git directory in test fixture for git root detection
    local git_dir = original_cwd .. "/tests/fixtures/broken_project/.git"
    if vim.fn.isdirectory(git_dir) == 0 then
      vim.fn.mkdir(git_dir, "p")
    end
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
  end)

  -- Skip test if dependencies missing
  local function check_dependencies()
    if vim.fn.executable("cmake") == 0 then
      pending("cmake not found, skipping E2E test")
      return false
    end

    -- Check for any C++ compiler (cross-platform)
    local has_compiler = vim.fn.executable("cl") == 1 or       -- MSVC
                        vim.fn.executable("gcc") == 1 or      -- GCC
                        vim.fn.executable("clang") == 1 or    -- Clang
                        vim.fn.executable("g++") == 1 or      -- G++
                        vim.fn.executable("clang++") == 1     -- Clang++

    if not has_compiler then
      pending("no C++ compiler found, skipping E2E test")
      return false
    end

    return true
  end

  it("compiles broken project and produces diagnostics", function()
    if not check_dependencies() then
      return
    end

    -- Change to test project directory
    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    -- Build scanner binary path (from repo root)
    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    -- Verify scanner binary exists
    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    -- Run build (returns immediately, work happens async)
    local diagnostics, has_error
    local done = false

    require("quickbuild").build({
      scanner_path = scanner_path,
      on_complete = function(diags, err)
        diagnostics = diags
        has_error = err
        done = true
      end
    })

    -- Wait for build to complete (max 30 seconds)
    local completed = vim.wait(30000, function()
      return done
    end, 100)

    -- Assert build completed
    assert.is_true(completed, "Build should have completed within 30 seconds")
    assert.is_true(done, "Build done flag should be set")

    -- Assert build failed (intentional errors)
    assert.is_true(has_error, "Build should have failed with errors")

    -- Assert diagnostics were produced
    assert.is_not_nil(diagnostics, "Diagnostics should not be nil")
    assert.is_true(#diagnostics > 0,
      string.format("Should have at least one diagnostic. Got %d diagnostics", #diagnostics))

    -- Check for specific errors
    local error_count = 0
    local found_main_error = false
    local diagnostic_summary = {}

    for _, diag in ipairs(diagnostics) do
      table.insert(diagnostic_summary, string.format(
        "%s:%d:%d:%s",
        diag.file, diag.lnum + 1, diag.col,
        diag.severity == vim.diagnostic.severity.ERROR and "error" or "warning"
      ))

      if diag.severity == vim.diagnostic.severity.ERROR then
        error_count = error_count + 1

        -- Check if we found the main.cpp errors
        if diag.file:match("main%.cpp") then
          found_main_error = true
        end
      end
    end

    -- Print diagnostic summary for debugging
    if #diagnostic_summary > 0 then
      print("Diagnostics received:\n  " .. table.concat(diagnostic_summary, "\n  "))
    end

    -- Assert we have multiple errors
    assert.is_true(error_count >= 2,
      string.format("Should have at least 2 compile errors, got: %d\nDiagnostics: %s",
        error_count, table.concat(diagnostic_summary, ", ")))

    -- Assert errors from main.cpp
    assert.is_true(found_main_error, "Should have error from main.cpp")
  end)

  it("publishes diagnostics to vim.diagnostic namespace", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    -- Verify scanner binary exists
    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    -- Run build (returns immediately, work happens async)
    local done = false

    require("quickbuild").build({
      scanner_path = scanner_path,
      on_complete = function(diags, err)
        done = true
      end
    })

    -- Wait for build to complete (max 30 seconds)
    local completed = vim.wait(30000, function()
      return done
    end, 100)

    -- Assert build completed
    assert.is_true(completed, "Build should have completed within 30 seconds")
    assert.is_true(done, "Build done flag should be set")

    -- Get diagnostics from namespace
    local ns = require("quickbuild").get_namespace()
    local all_diagnostics = vim.diagnostic.get(nil, { namespace = ns })

    -- Assert diagnostics were published
    assert.is_true(#all_diagnostics > 0,
      string.format("Diagnostics should be published to namespace. Got %d diagnostics",
        #all_diagnostics))
  end)

  it("auto-builds on save when configured", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    -- Verify scanner binary exists
    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    -- Setup plugin (required to enable auto-build)
    require("quickbuild").setup({
      scanner_path = scanner_path,
    })

    -- Open main.cpp
    local main_cpp_path = test_project .. "/main.cpp"
    vim.cmd("edit " .. main_cpp_path)

    -- Track build completion
    local done = false
    local diagnostics, has_error

    -- Override on_complete temporarily to track builds
    local builder = require("quickbuild.builder")
    local original_build = builder.build
    builder.build = function(opts)
      opts = opts or {}
      local original_on_complete = opts.on_complete
      opts.on_complete = function(diags, err)
        diagnostics = diags
        has_error = err
        done = true
        if original_on_complete then
          original_on_complete(diags, err)
        end
      end
      original_build(opts)
    end

    -- Trigger save (should auto-build after debounce)
    vim.cmd("write")

    -- Wait for debounce + build (max 35 seconds: 500ms debounce + 30s build)
    local completed = vim.wait(35000, function()
      return done
    end, 100)

    -- Restore original build function
    builder.build = original_build

    -- Assert build was triggered and completed
    assert.is_true(completed, "Auto-build should have triggered and completed within 35 seconds")
    assert.is_true(done, "Build done flag should be set")

    -- Assert diagnostics were produced
    assert.is_not_nil(diagnostics, "Diagnostics should not be nil")
    assert.is_true(#diagnostics > 0, "Should have at least one diagnostic from auto-build")

    -- Verify diagnostics are published to namespace
    local ns = require("quickbuild").get_namespace()
    local all_diagnostics = vim.diagnostic.get(nil, { namespace = ns })
    assert.is_true(#all_diagnostics > 0, "Diagnostics should be published to namespace")
  end)

  it("handles rapid saves without crashing (regression test)", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    -- Verify scanner binary exists
    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    -- Setup plugin with shorter debounce to trigger the race condition faster
    require("quickbuild").setup({
      scanner_path = scanner_path,
    })

    -- Open main.cpp
    local main_cpp_path = test_project .. "/main.cpp"
    vim.cmd("edit " .. main_cpp_path)

    -- Track all build completions
    local build_count = 0
    local last_diagnostics = nil
    local had_failure = false
    local failure_message = ""

    -- Override builder to track builds
    local builder = require("quickbuild.builder")
    local original_build = builder.build
    builder.build = function(opts)
      opts = opts or {}
      local original_on_complete = opts.on_complete
      opts.on_complete = function(diags, err)
        build_count = build_count + 1
        last_diagnostics = diags

        -- Check if this build failed before producing any diagnostics
        -- This is the symptom of the bug: CMake fails because it's already running
        if err and #diags == 0 then
          had_failure = true
          failure_message = string.format(
            "Build %d failed with no diagnostics (err=%s, diags=%d)",
            build_count, tostring(err), #diags
          )
        end

        if original_on_complete then
          original_on_complete(diags, err)
        end
      end
      original_build(opts)
    end

    -- First, make a change and trigger a build
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    table.insert(lines, "// trigger build")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd("write")

    -- Wait for build to actually start (status becomes is_running)
    local build_started = vim.wait(5000, function()
      return builder.get_status().is_running
    end, 50)

    assert.is_true(build_started, "Initial build should have started")

    -- NOW trigger rapid saves WHILE the build is running
    -- This creates the race condition: we kill the running job and
    -- immediately start a new one, but CMake might still hold locks
    for i = 1, 3 do
      -- Make actual changes so the file change detection doesn't skip
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      table.insert(lines, "// change " .. i)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.cmd("write")
      vim.wait(10, function() return false end)  -- Very short delay
    end

    -- Wait for final build to complete (max 40 seconds)
    local completed = vim.wait(40000, function()
      local status = builder.get_status()
      return not status.is_running and build_count > 0
    end, 100)

    -- Restore original build function
    builder.build = original_build

    -- Assert a build happened and completed
    assert.is_true(completed, "Build should have completed after rapid saves")
    assert.is_true(build_count > 0, "At least one build should have been triggered")

    -- The key assertion: rapid saves should NOT cause builds to fail
    -- without producing diagnostics (the bug symptom)
    assert.is_false(had_failure,
      "Rapid saves should not cause build failures without diagnostics. " ..
      "This indicates CMake is being invoked while already running. " ..
      failure_message)

    -- Assert final build produced diagnostics
    assert.is_not_nil(last_diagnostics, "Final build should have produced diagnostics")
    assert.is_true(#last_diagnostics > 0,
      string.format("Final build should have diagnostics, got %d", #last_diagnostics))
  end)

  it("statusline shows stage names during build", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    require("quickbuild").setup({
      scanner_path = scanner_path,
      statusline = true,
    })

    local stages_seen = {}
    local done = false

    -- Poll statusline during build
    local poll_timer = vim.loop.new_timer()
    poll_timer:start(0, 50, vim.schedule_wrap(function()
      local status_text = require("quickbuild").statusline()
      if status_text and status_text ~= "" then
        table.insert(stages_seen, status_text)
      end
    end))

    require("quickbuild").build({
      scanner_path = scanner_path,
      on_complete = function(diags, err)
        done = true
      end
    })

    local completed = vim.wait(30000, function()
      return done
    end, 100)

    poll_timer:stop()
    poll_timer:close()

    assert.is_true(completed, "Build should have completed")

    -- Check we saw stage names
    local saw_configure = false
    local saw_build = false
    for _, status in ipairs(stages_seen) do
      if status:match("Configure") then
        saw_configure = true
      end
      if status:match("Build") then
        saw_build = true
      end
    end

    assert.is_true(saw_configure, "Should have seen Configure stage in statusline")
    assert.is_true(saw_build, "Should have seen Build stage in statusline")
  end)

  it("statusline shows Build Failed on error", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    require("quickbuild").setup({
      scanner_path = scanner_path,
      statusline = true,
    })

    local done = false

    require("quickbuild").build({
      scanner_path = scanner_path,
      on_complete = function(diags, err)
        done = true
      end
    })

    local completed = vim.wait(30000, function()
      return done
    end, 100)

    assert.is_true(completed, "Build should have completed")

    -- Check statusline shows failure
    local status_text = require("quickbuild").statusline()
    assert.equals("Build Failed", status_text)
  end)

  it("statusline returns to idle after completion duration", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    require("quickbuild").setup({
      scanner_path = scanner_path,
      statusline = true,
      statusline_completion_duration_ms = 500,
    })

    local done = false

    require("quickbuild").build({
      scanner_path = scanner_path,
      on_complete = function(diags, err)
        done = true
      end
    })

    local completed = vim.wait(30000, function()
      return done
    end, 100)

    assert.is_true(completed, "Build should have completed")

    -- Should show status immediately after completion
    local status_text = require("quickbuild").statusline()
    assert.equals("Build Failed", status_text)

    -- Wait for completion duration + margin
    vim.wait(700, function() return false end)

    -- Should be idle now
    status_text = require("quickbuild").statusline()
    assert.equals("", status_text)
  end)

  it("statusline clears immediately on cancel", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    require("quickbuild").setup({
      scanner_path = scanner_path,
      statusline = true,
    })

    local qb = require("quickbuild")

    qb.build({
      scanner_path = scanner_path,
    })

    -- Wait for build to start
    local builder = require("quickbuild.builder")
    local build_started = vim.wait(5000, function()
      return builder.get_status().is_running
    end, 50)

    assert.is_true(build_started, "Build should have started")

    -- Should show building status
    local status_text = qb.statusline()
    assert.is_true(status_text:match("Building") ~= nil, "Should show building status: " .. tostring(status_text))

    -- Cancel build
    qb.cancel()

    -- Statusline should clear immediately
    status_text = qb.statusline()
    assert.equals("", status_text)
  end)

  it("statusline disabled when configured", function()
    if not check_dependencies() then
      return
    end

    local test_project = original_cwd .. "/tests/fixtures/broken_project"
    vim.cmd("cd " .. test_project)

    local scanner_path
    local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

    if is_windows then
      scanner_path = original_cwd .. "/scanner/build/Release/qb-scanner.exe"
    else
      scanner_path = original_cwd .. "/scanner/build/qb-scanner"
    end

    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)

    require("quickbuild").setup({
      scanner_path = scanner_path,
      statusline = false,
    })

    local done = false

    require("quickbuild").build({
      scanner_path = scanner_path,
      on_complete = function(diags, err)
        done = true
      end
    })

    local completed = vim.wait(30000, function()
      return done
    end, 100)

    assert.is_true(completed, "Build should have completed")

    -- Statusline should always be empty when disabled
    local status_text = require("quickbuild").statusline()
    assert.equals("", status_text)
  end)
end)

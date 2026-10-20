-- tests/stale_spec.lua: Stale diagnostics and killed-build handling

describe("stale diagnostics", function()
  local original_cwd = vim.fn.getcwd()
  local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil
  local scanner_path = original_cwd .. (is_windows and "/scanner/build/Release/qb-scanner.exe" or "/scanner/build/qb-scanner")
  local qb = require("quickbuild")
  local builder = require("quickbuild.builder")
  local project

  local fast_cmd = is_windows and 'cmd /c "echo a.cpp:3:1: error: boom"' or "echo a.cpp:3:1: error: boom"
  local slow_cmd = is_windows and 'cmd /c "echo a.cpp:2:1: error: slow & ping -n 30 127.0.0.2"'
    or "sh -c 'echo a.cpp:2:1: error: slow; sleep 30'"

  local function write_config(command)
    vim.fn.writefile({ vim.json.encode({
      patterns = { {
        regex = "^(.+?):(\\d+):(\\d+): (error|warning): (.+)$",
        groups = { file = 1, line = 2, col = 3, severity = 4, message = 5 },
      } },
      commands = { { name = "Build", command = command } },
    }) }, project .. "/.quickbuild.json")
  end

  local function current()
    return vim.diagnostic.get(nil, { namespace = qb.get_namespace() })
  end

  local function stale()
    return vim.diagnostic.get(nil, { namespace = qb.get_stale_namespace() })
  end

  local function build_and_wait(command)
    write_config(command)
    local done = false
    qb.build({ on_complete = function() done = true end })
    assert.is_true(vim.wait(10000, function() return done end, 50), "Build should complete")
  end

  local function start_slow_build(on_complete)
    write_config(slow_cmd)
    qb.build({ on_complete = on_complete })
    assert.is_true(vim.wait(5000, function() return builder.get_status().is_running end, 50), "Build should start")
  end

  before_each(function()
    assert.equals(1, vim.fn.executable(scanner_path), "Scanner binary not found at: " .. scanner_path)
    project = vim.fn.tempname():gsub("\\", "/")
    vim.fn.mkdir(project .. "/.git", "p")
    vim.cmd("cd " .. project)
    qb.setup({ scanner_path = scanner_path, status_messages = false })
  end)

  after_each(function()
    qb.cancel()
    vim.cmd("cd " .. original_cwd)
    vim.fn.delete(project, "rf")
  end)

  it("moves an edited buffer's diagnostics to the stale namespace with stale sign colors", function()
    build_and_wait(fast_cmd)
    local bufnr = current()[1].bufnr
    vim.fn.bufload(bufnr)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "edited" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = bufnr })

    assert.equals(0, #current())
    assert.equals(1, #stale())
    assert.equals("error: boom", stale()[1].message)

    local sign_ns = vim.api.nvim_get_namespaces()["quickbuild_stale_signs"]
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, sign_ns, 0, -1, { details = true })
    assert.equals(1, #marks)
    assert.equals("QuickbuildStaleError", marks[1][4].sign_hl_group)
  end)

  it("finished build replaces current diagnostics and clears stale", function()
    build_and_wait(fast_cmd)
    local bufnr = current()[1].bufnr
    builder.mark_stale(bufnr)
    assert.equals(1, #stale())

    build_and_wait(fast_cmd)

    assert.equals(0, #stale())
    assert.equals(1, #current())
    assert.equals("error: boom", current()[1].message)

    local sign_ns = vim.api.nvim_get_namespaces()["quickbuild_stale_signs"]
    assert.equals(0, #vim.api.nvim_buf_get_extmarks(bufnr, sign_ns, 0, -1, {}))
  end)

  it("cancelled build leaves diagnostics and status untouched", function()
    build_and_wait(fast_cmd)
    local status_before = builder.get_status()

    local killed_completed = false
    start_slow_build(function() killed_completed = true end)
    qb.cancel()
    vim.wait(2000, function() return false end)

    assert.is_false(killed_completed, "Killed build must not complete")
    assert.equals(1, #current())
    assert.equals("error: boom", current()[1].message)
    assert.equals(status_before.last_success, builder.get_status().last_success)
    assert.equals(status_before.errors, builder.get_status().errors)
  end)

  it("restarted build ignores the killed build's completion", function()
    local killed_completed = false
    start_slow_build(function() killed_completed = true end)

    local done = false
    write_config(fast_cmd)
    qb.build({ on_complete = function() done = true end })
    assert.is_true(vim.wait(10000, function() return done end, 50), "Restarted build should complete")
    vim.wait(2000, function() return false end)

    assert.is_false(killed_completed, "Killed build must not complete")
    assert.is_false(builder.get_status().is_running)
    assert.equals(1, #current())
    assert.equals("error: boom", current()[1].message)
  end)

  it("restart and cancel kill the build's child processes", function()
    if not is_windows then
      pending("process tree kill is Windows-only")
      return
    end

    start_slow_build(nil)
    build_and_wait(fast_cmd)
    start_slow_build(nil)
    qb.cancel()
    vim.wait(2000, function() return false end)

    local orphans = vim.fn.system({ "powershell.exe", "-NoProfile", "-Command",
      "@(Get-CimInstance Win32_Process -Filter \"Name='PING.EXE'\" | Where-Object { $_.CommandLine -like '*127.0.0.2*' }).Count" })
    assert.equals("0", vim.trim(orphans))
  end)
end)

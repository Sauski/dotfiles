-- builder.lua: Sequential command execution with scanner integration

local diagnostic = require("quickbuild.diagnostic")

local M = {}

-- State tracking
local active_job = nil  -- nil = IDLE, non-nil = RUNNING
local debounce_timer = nil
local error_count = 0
local warning_count = 0
local cancel_count = 0
local namespace = vim.api.nvim_create_namespace("quickbuild")
local last_changedtick = {}  -- Track b:changedtick per buffer to detect actual changes

-- Find git root from current directory
local function find_git_root()
  local current = vim.fn.getcwd()
  local previous = ""

  -- Keep going up until we reach the root or stop changing
  while current ~= previous and current ~= "" do
    if vim.fn.isdirectory(current .. "/.git") == 1 then
      return current
    end
    previous = current
    current = vim.fn.fnamemodify(current, ":h")
  end

  return nil
end

-- Load .quickbuild.json config
local function load_config(git_root)
  local config_path = git_root .. "/.quickbuild.json"

  if vim.fn.filereadable(config_path) ~= 1 then
    return nil, ".quickbuild.json not found in git root: " .. git_root
  end

  local content = table.concat(vim.fn.readfile(config_path), "\n")
  local ok, config = pcall(vim.json.decode, content)

  if not ok then
    return nil, "Failed to parse .quickbuild.json: " .. tostring(config)
  end

  if not config.commands or #config.commands == 0 then
    return nil, ".quickbuild.json must contain 'commands' array"
  end

  return config, nil
end

-- Process scanner output line-by-line in real-time
local function process_scanner_output(data, diagnostics, git_root, on_diagnostic)
  if not data then
    return false
  end

  local has_error = false
  for line in data:gmatch("[^\r\n]+") do
    local diag = diagnostic.parse_line(line, git_root)
    if diag then
      table.insert(diagnostics, diag)
      if diag.severity == vim.diagnostic.severity.ERROR then
        has_error = true
      end
      if on_diagnostic then
        on_diagnostic(diag)
      end
    end
  end
  return has_error
end

-- Execute single command with scanner (async with real-time streaming)
-- Windows: Uses PowerShell native piping to avoid vim.system() bugs
-- Unix: Uses temporary shell script for consistent behavior
local function execute_command(cmd, scanner_path, git_root, on_diagnostic, on_complete, verbose)
  local diagnostics = {}
  local has_error = false
  local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

  if verbose then
    vim.schedule(function()
      vim.notify("[quickbuild] Running: " .. cmd, vim.log.levels.INFO)
    end)
  end

  -- Stdout callback shared by both platforms
  local function on_stdout(err, data)
    if err then
      vim.schedule(function()
        vim.notify(
          "[quickbuild] Scanner error: " .. tostring(err),
          vim.log.levels.ERROR
        )
      end)
      return
    end

    if data then
      vim.schedule(function()
        if process_scanner_output(data, diagnostics, git_root, on_diagnostic) then
          has_error = true
        end
      end)
    end
  end

  local job
  if is_windows then
    -- Windows: PowerShell with native piping
    local ps_cmd = string.format(
      'Set-Location "%s"; & %s 2>&1 | & "%s"',
      git_root, cmd, scanner_path
    )

    job = vim.system(
      {"powershell.exe", "-NoProfile", "-Command", ps_cmd},
      {text = true, stdout = on_stdout},
      function(result)
        vim.schedule(function()
          if verbose then
            vim.notify(
              string.format("[quickbuild] Command completed with exit code %d: %s", result.code, cmd),
              vim.log.levels.INFO
            )
          end

          -- Only show error if command failed AND no diagnostics were produced
          -- (diagnostics indicate the scanner is working, even if build failed)
          if result.code ~= 0 and #diagnostics == 0 then
            vim.notify(
              string.format(
                "[quickbuild] Command failed with exit code %d: %s\nNo diagnostics were captured. The build may have failed before compilation.",
                result.code, cmd
              ),
              vim.log.levels.WARN
            )
          end

          if on_complete then
            on_complete(diagnostics, has_error, result.code)
          end
        end)
      end
    )
  else
    -- Unix: Temporary shell script
    local script_path = vim.fn.tempname() .. ".sh"
    local script_content = string.format(
      '#!/bin/sh\ncd "%s"\n%s 2>&1 | "%s"',
      git_root, cmd, scanner_path
    )

    vim.fn.writefile(vim.split(script_content, "\n"), script_path)
    vim.fn.system({"chmod", "+x", script_path})

    job = vim.system(
      {script_path},
      {text = true, stdout = on_stdout},
      function(result)
        vim.schedule(function()
          vim.fn.delete(script_path)
          if verbose then
            vim.notify(
              string.format("[quickbuild] Command completed with exit code %d: %s", result.code, cmd),
              vim.log.levels.INFO
            )
          end

          -- Only show error if command failed AND no diagnostics were produced
          -- (diagnostics indicate the scanner is working, even if build failed)
          if result.code ~= 0 and #diagnostics == 0 then
            vim.notify(
              string.format(
                "[quickbuild] Command failed with exit code %d: %s\nNo diagnostics were captured. The build may have failed before compilation.",
                result.code, cmd
              ),
              vim.log.levels.WARN
            )
          end

          if on_complete then
            on_complete(diagnostics, has_error, result.code)
          end
        end)
      end
    )
  end

  return job
end

-- Execute commands sequentially
local function execute_sequential(commands, scanner_path, git_root, on_complete, verbose)
  local all_diagnostics = {}
  local current_index = 1

  local function run_next()
    if current_index > #commands then
      -- All commands completed
      if on_complete then
        on_complete(all_diagnostics, false)
      end
      return
    end

    local cmd = commands[current_index]

    active_job = execute_command(
      cmd,
      scanner_path,
      git_root,
      function(diag)
        table.insert(all_diagnostics, diag)
        -- Publish incrementally
        diagnostic.publish(all_diagnostics, namespace)
      end,
      function(diagnostics, has_error, exit_code)
        -- Add to total diagnostics
        for _, diag in ipairs(diagnostics) do
          table.insert(all_diagnostics, diag)
        end

        -- Stop on first error
        if has_error or exit_code ~= 0 then
          if on_complete then
            on_complete(all_diagnostics, true)
          end
          return
        end

        -- Continue to next command
        current_index = current_index + 1
        run_next()
      end,
      verbose
    )
  end

  run_next()
end

-- Internal: Start build immediately (no debounce)
local function start_build_now(opts)
  opts = opts or {}

  local git_root = find_git_root()
  if not git_root then
    vim.notify("[quickbuild] Not in a git repository. Run 'git init' in your project root.", vim.log.levels.ERROR)
    return
  end

  local config, err = load_config(git_root)
  if not config then
    vim.notify("[quickbuild] " .. (err or "Failed to load .quickbuild.json"), vim.log.levels.ERROR)
    return
  end

  -- Find scanner binary (priority: opts > PATH default)
  local scanner_path = opts.scanner_path or "qb-scanner"

  if vim.fn.executable(scanner_path) ~= 1 then
    vim.notify(
      "[quickbuild] Scanner binary not found: " .. scanner_path .. "\n" ..
      "Either:\n" ..
      "  1. Install to PATH: cmake --install scanner/build\n" ..
      "  2. Specify in setup: require('quickbuild').setup({ scanner_path = '/path/to/qb-scanner' })",
      vim.log.levels.ERROR
    )
    return
  end

  -- Clear previous diagnostics
  diagnostic.clear(namespace)
  error_count = 0
  warning_count = 0

  local verbose = opts.verbose or false

  if verbose then
    vim.notify(
      string.format("[quickbuild] Starting build with %d command(s)", #config.commands),
      vim.log.levels.INFO
    )
  end

  -- Execute commands
  execute_sequential(
    config.commands,
    scanner_path,
    git_root,
    function(diagnostics, has_error)
      active_job = nil

      -- Final publish
      diagnostic.publish(diagnostics, namespace)

      -- Count diagnostics
      error_count = 0
      warning_count = 0
      for _, diag in ipairs(diagnostics) do
        if diag.severity == vim.diagnostic.severity.ERROR then
          error_count = error_count + 1
        elseif diag.severity == vim.diagnostic.severity.WARN then
          warning_count = warning_count + 1
        end
      end

      if verbose then
        vim.notify(
          string.format(
            "[quickbuild] Build completed: %d error(s), %d warning(s)",
            error_count, warning_count
          ),
          has_error and vim.log.levels.ERROR or vim.log.levels.INFO
        )
      end

      if opts.on_complete then
        opts.on_complete(diagnostics, has_error)
      end
    end,
    verbose
  )
end

-- Check if buffer has actually changed (using b:changedtick)
local function buffer_has_changed(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return true  -- Assume changed if buffer is invalid
  end

  -- Get current changedtick (increments on every buffer modification)
  local ok, changedtick = pcall(vim.api.nvim_buf_get_changedtick, bufnr)
  if not ok then
    return true  -- Assume changed if we can't read changedtick
  end

  local prev_tick = last_changedtick[bufnr]
  last_changedtick[bufnr] = changedtick

  -- First time seeing this buffer, consider it changed
  if not prev_tick then
    return true
  end

  return changedtick ~= prev_tick
end

-- Start build process with debounce
function M.build(opts)
  opts = opts or {}

  -- Check if the current buffer actually changed (for auto-saves)
  if opts.debounce_ms and opts.debounce_ms > 0 then
    local current_bufnr = vim.api.nvim_get_current_buf()
    if not buffer_has_changed(current_bufnr) then
      -- Buffer unchanged, skip build
      return
    end
  end

  -- Helper to start build after ensuring previous job is terminated
  local function start_after_cleanup()
    -- Clear existing debounce timer
    if debounce_timer then
      vim.loop.timer_stop(debounce_timer)
      debounce_timer:close()
      debounce_timer = nil
    end

    -- Manual triggers: no debounce
    if not opts.debounce_ms or opts.debounce_ms == 0 then
      start_build_now(opts)
      return
    end

    -- Auto triggers: debounce
    debounce_timer = vim.loop.new_timer()
    debounce_timer:start(opts.debounce_ms, 0, vim.schedule_wrap(function()
      if debounce_timer then
        debounce_timer:close()
        debounce_timer = nil
      end
      start_build_now(opts)
    end))
  end

  -- Cancel existing build and WAIT for it to terminate
  if active_job then
    local job_to_kill = active_job
    active_job = nil  -- Mark as not running immediately
    cancel_count = cancel_count + 1

    -- Check if job is already dead
    local ok, is_alive = pcall(function() return job_to_kill:is_alive() end)
    if not ok or not is_alive then
      start_after_cleanup()
      return
    end

    -- Send SIGTERM first (graceful)
    pcall(function() job_to_kill:kill(15) end)

    -- Wait for process to die, with timeout
    local max_wait = 500  -- 500ms max wait (increased for slower systems)
    local waited = 0
    local check_interval = 20

    local function check_terminated()
      -- Check if job object is still valid and alive
      local ok, is_alive = pcall(function() return job_to_kill:is_alive() end)

      if not ok or not is_alive then
        -- Job is dead or invalid, proceed
        start_after_cleanup()
        return
      end

      waited = waited + check_interval
      if waited >= max_wait then
        -- Timeout, force kill
        pcall(function()
          if job_to_kill:is_alive() then
            job_to_kill:kill(9)  -- SIGKILL
          end
        end)
        -- Wait one more cycle for SIGKILL to take effect
        vim.defer_fn(function()
          start_after_cleanup()
        end, 50)
        return
      end

      -- Check again
      vim.defer_fn(check_terminated, check_interval)
    end

    vim.defer_fn(check_terminated, check_interval)
  else
    -- No active job, proceed immediately
    start_after_cleanup()
  end
end

-- Cancel active build
function M.cancel()
  -- Cancel debounce timer
  if debounce_timer then
    vim.loop.timer_stop(debounce_timer)
    debounce_timer:close()
    debounce_timer = nil
  end

  -- Cancel running build
  if active_job then
    active_job:kill(9)  -- SIGKILL immediately
    active_job = nil
  end
end

-- Get build status (for status line integration)
function M.get_status()
  return {
    is_running = active_job ~= nil,
    errors = error_count,
    warnings = warning_count,
  }
end

-- Get metrics
function M.get_metrics()
  return {
    cancel_count = cancel_count,
  }
end

-- Get diagnostic namespace
function M.get_namespace()
  return namespace
end

-- Get project config (for init.lua to setup autocmds)
function M.get_project_config()
  local git_root = find_git_root()
  if not git_root then
    return nil
  end

  local config, err = load_config(git_root)
  if not config then
    -- Silent failure in get_project_config (used during setup)
    -- Don't notify here, just return nil
    return nil
  end
  return config
end

return M

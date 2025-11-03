-- other.nvim configuration for opening related files
--
-- This configuration uses function-based patterns to treat files as "families"
-- rather than bilateral relationships. Instead of requiring navigation through a hub
-- file (e.g., unittest -> .h -> browsertest), you can jump directly between any files
-- that share the same base name.
--
-- For example, all these files form a family with basename "src/example":
--   src/example.h              (interface/header)
--   src/example.cpp            (primary implementation)
--   src/example_impl.cc        (pimpl implementation)
--   src/example_unittest.cc    (unit test)
--   src/test/example_unittest.cc (unit test in subdirectory)
--
-- From ANY file in the family, pressing <leader>r shows ALL other family members
-- in a single picker. No intermediate hops required.

-- Generic file family extractor
-- Creates a pattern function that can match any file in a family and extract common parts.
--
-- Parameters:
--   file_patterns: List of Lua patterns to match files (e.g., "(.*)%.cpp$")
--                  Order matters - put longest/most specific patterns first
--   dir_patterns_to_strip: Optional list of patterns to remove common subdirs
--                          (e.g., "(.*)/tests?/" to strip /test or /tests)
--
-- Returns a function that takes a filepath and returns:
--   { basename, base_dir } where:
--     basename = full path without extension/suffix (use as %1 in targets)
--     base_dir = directory path with common subdirs removed (use as %2 in targets)
--   or nil if the file doesn't match any pattern
--
-- Usage:
--   pattern = create_family_extractor(
--     { "(.*)_test%.py$", "(.*)%.py$" },
--     { "(.*)/tests/" }
--   )
local function create_family_extractor(file_patterns, dir_patterns_to_strip)
  return function(filepath)
    -- Try each pattern to extract basename (order matters - longest first)
    local basename = nil
    for _, pattern in ipairs(file_patterns) do
      basename = filepath:match(pattern)
      if basename then break end
    end

    if not basename then
      return nil  -- File doesn't match any pattern in this family
    end

    -- Extract base directory by removing common subdirectory patterns
    local base_dir = basename
    for _, strip_pattern in ipairs(dir_patterns_to_strip or {}) do
      local stripped = basename:match(strip_pattern)
      if stripped then
        base_dir = stripped
        break
      end
    end

    -- If no strip pattern matched, just get the parent directory
    if base_dir == basename then
      base_dir = basename:match("(.*)/") or ""
    end

    return { basename, base_dir }
  end
end

-- ========================================
-- C++ File Family Patterns
-- ========================================
local cpp_file_patterns = {
  "(.*)_browsertest%.cc$",   -- Longest suffixes first
  "(.*)_unittest%.cc$",
  "(.*)_impl%.cpp$",
  "(.*)_impl%.cc$",
  "(.*)%.cpp$",
  "(.*)%.cc$",
  "(.*)%.h$",
}

local cpp_dir_strips = {
  "(.*)/tests?/",  -- Remove /test or /tests from path
}

-- ========================================
-- Web File Family Patterns (TS/JS/HTML/CSS)
-- ========================================
local web_file_patterns = {
  "(.*)%.spec%.ts$",      -- Test files first
  "(.*)%.test%.ts$",
  "(.*)%.spec%.js$",
  "(.*)%.test%.js$",
  "(.*)%.component%.ts$", -- Angular/component patterns
  "(.*)%.service%.ts$",
  "(.*)%.ts$",            -- Plain TypeScript
  "(.*)%.js$",            -- Plain JavaScript
  "(.*)%.html$",          -- Templates
  "(.*)%.css$",           -- Styles
  "(.*)%.scss$",
  "(.*)%.sass$",
}

local web_dir_strips = {
  "(.*)/tests?/",
  "(.*)/spec/",
}

local config = {
  mappings = {
    -- ========================================
    -- C++ File Family
    -- ========================================
    {
      pattern = create_family_extractor(cpp_file_patterns, cpp_dir_strips),
      target = {
        { target = "%1.h", context = "header" },
        { target = "%1.cpp", context = "source_cpp" },
        { target = "%1.cc", context = "source_cc" },
        { target = "%1_impl.cpp", context = "impl_cpp" },
        { target = "%1_impl.cc", context = "impl_cc" },
        { target = "%1_unittest.cc", context = "unittest_same" },
        { target = "%1_browsertest.cc", context = "browsertest_same" },
        -- Alternative locations in tests/ subdirectory
        { target = "%2/tests/%1_unittest.cc", context = "unittest_subdir" },
        { target = "%2/tests/%1_browsertest.cc", context = "browsertest_subdir" },
        { target = "%2/test/%1_unittest.cc", context = "unittest_subdir2" },
        { target = "%2/test/%1_browsertest.cc", context = "browsertest_subdir2" },
      },
    },

    -- ========================================
    -- Web File Family (TS/JS/HTML/CSS)
    -- ========================================
    {
      pattern = create_family_extractor(web_file_patterns, web_dir_strips),
      target = {
        { target = "%1.ts", context = "typescript" },
        { target = "%1.js", context = "javascript" },
        { target = "%1.component.ts", context = "component" },
        { target = "%1.service.ts", context = "service" },
        { target = "%1.html", context = "template" },
        { target = "%1.css", context = "styles_css" },
        { target = "%1.scss", context = "styles_scss" },
        { target = "%1.sass", context = "styles_sass" },
        { target = "%1.spec.ts", context = "test_ts_same" },
        { target = "%1.test.ts", context = "test_ts_same2" },
        { target = "%1.spec.js", context = "test_js_same" },
        { target = "%1.test.js", context = "test_js_same2" },
        -- Tests in subdirectories
        { target = "%2/tests/%1.spec.ts", context = "test_ts_subdir" },
        { target = "%2/test/%1.spec.ts", context = "test_ts_subdir2" },
        { target = "%2/spec/%1.spec.ts", context = "test_ts_spec" },
      },
    },
  },
  rememberBuffers = true,
  showMissingFiles = false,
}

local function open_other_in_other_window()
  local current_win = vim.api.nvim_get_current_win()
  local all_wins = vim.api.nvim_tabpage_list_wins(0)
  local other_wins = vim.tbl_filter(function(win)
    return win ~= current_win
  end, all_wins)

  local target_win = #other_wins > 0 and other_wins[1] or nil
  require('other-nvim').open(nil, target_win)
end

local function open_other_picker()
  vim.b.onv_otherFile = nil
  open_other_in_other_window()
end

return {
  config = config,
  open_other_in_other_window = open_other_in_other_window,
  open_other_picker = open_other_picker,
}

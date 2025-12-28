-- tests/coalesce_spec.lua

describe("coalesce", function()
  local coalesce = require("quickbuild.coalesce")

  describe("coalesce", function()
    it("merges diagnostics at same location", function()
      local input = {
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "binary '+' not defined" },
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "note: with template arguments" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(1, #result)
      assert.equals("a.cpp", result[1].file)
      assert.equals(5, result[1].lnum)
      assert.equals(10, result[1].col)
      assert.equals(vim.diagnostic.severity.ERROR, result[1].severity)
      assert.equals("error: binary '+' not defined\nnote: with template arguments", result[1].message)
    end)

    it("removes exact duplicate messages", function()
      local input = {
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "undefined_var" },
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "undefined_var" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(1, #result)
      assert.equals("error: undefined_var", result[1].message)
    end)

    it("keeps highest severity", function()
      local input = {
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.WARN, message = "unused variable" },
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "syntax error" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(1, #result)
      assert.equals(vim.diagnostic.severity.ERROR, result[1].severity)
      assert.equals("error: unused variable\nsyntax error", result[1].message)
    end)

    it("keeps different locations separate", function()
      local input = {
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "at col 10" },
        { file = "a.cpp", lnum = 5, col = 15, severity = vim.diagnostic.severity.ERROR, message = "at col 15" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(2, #result)
    end)

    it("keeps different files separate", function()
      local input = {
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "error in a" },
        { file = "b.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "error in b" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(2, #result)
    end)

    it("keeps different lines separate", function()
      local input = {
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "error at line 5" },
        { file = "a.cpp", lnum = 10, col = 10, severity = vim.diagnostic.severity.ERROR, message = "error at line 10" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(2, #result)
    end)

    it("handles empty input", function()
      local result = coalesce.coalesce({})
      assert.equals(0, #result)
    end)

    it("preserves message order", function()
      local input = {
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "first" },
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "second" },
        { file = "a.cpp", lnum = 5, col = 10, severity = vim.diagnostic.severity.ERROR, message = "third" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(1, #result)
      assert.equals("error: first\nsecond\nthird", result[1].message)
    end)

    it("handles multiline MSVC template error", function()
      local input = {
        { file = "add.cpp", lnum = 2, col = 1, severity = vim.diagnostic.severity.ERROR, message = "binary '+': type does not define operator" },
        { file = "add.cpp", lnum = 2, col = 1, severity = vim.diagnostic.severity.ERROR, message = "note: with template arguments" },
        { file = "add.cpp", lnum = 2, col = 1, severity = vim.diagnostic.severity.ERROR, message = "note: [A=int, B=char]" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(1, #result)
      assert.equals("error: binary '+': type does not define operator\nnote: with template arguments\nnote: [A=int, B=char]", result[1].message)
    end)

    it("handles clang notes at different locations", function()
      local input = {
        { file = "test.hpp", lnum = 2, col = 38, severity = vim.diagnostic.severity.ERROR, message = "no matching function for call to 'bar'" },
        { file = "test.cpp", lnum = 4, col = 13, severity = vim.diagnostic.severity.HINT, message = "in instantiation of function template" },
        { file = "test.hpp", lnum = 0, col = 5, severity = vim.diagnostic.severity.HINT, message = "candidate function not viable" },
      }
      local result = coalesce.coalesce(input)
      assert.equals(3, #result)
    end)
  end)
end)

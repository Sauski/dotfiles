-- tests/builder_spec.lua

describe("builder", function()
  local builder = require("quickbuild.builder")

  describe("cross-platform shell detection", function()
    it("detects Windows correctly", function()
      local is_windows = vim.loop.os_uname().sysname:find("Windows") ~= nil

      if is_windows then
        assert.is_true(vim.fn.executable("cmd.exe") == 1, "cmd.exe should be executable on Windows")
      else
        assert.is_true(vim.fn.executable("sh") == 1, "sh should be executable on Unix")
      end
    end)
  end)

  describe("get_status", function()
    it("returns status table", function()
      local status = builder.get_status()
      assert.is_not_nil(status)
      assert.is_not_nil(status.is_running)
      assert.is_not_nil(status.errors)
      assert.is_not_nil(status.warnings)
    end)

    it("starts in idle state", function()
      local status = builder.get_status()
      assert.is_false(status.is_running)
      assert.equals(0, status.errors)
      assert.equals(0, status.warnings)
    end)
  end)

  describe("get_metrics", function()
    it("returns metrics table", function()
      local metrics = builder.get_metrics()
      assert.is_not_nil(metrics)
      assert.is_not_nil(metrics.cancel_count)
    end)
  end)

  describe("get_namespace", function()
    it("returns namespace", function()
      local ns = builder.get_namespace()
      assert.is_number(ns)
      assert.is_true(ns > 0)
    end)
  end)
end)

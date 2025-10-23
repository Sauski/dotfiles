-- plugin/quickbuild.lua: Neovim plugin entry point

-- Prevent loading plugin twice
if vim.g.loaded_quickbuild then
  return
end
vim.g.loaded_quickbuild = 1

-- Create user commands
vim.api.nvim_create_user_command("QuickBuild", function()
  require("quickbuild").build()
end, {
  desc = "Start quickbuild build process",
})

vim.api.nvim_create_user_command("QuickBuildCancel", function()
  require("quickbuild").cancel()
end, {
  desc = "Cancel active quickbuild build",
})

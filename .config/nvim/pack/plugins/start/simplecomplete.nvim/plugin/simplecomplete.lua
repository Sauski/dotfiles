-- plugin/simplecomplete.lua: Auto-load entry point

-- Prevent loading twice
if vim.g.loaded_simplecomplete then
  return
end
vim.g.loaded_simplecomplete = 1

-- Plugin is loaded but not setup yet
-- User must call require('simplecomplete').setup() in their config

-- init.lua: Main module for simplecomplete.nvim

local indicator = require('simplecomplete.indicator')
local trigger = require('simplecomplete.trigger')
local menu = require('simplecomplete.menu')
local config_module = require('simplecomplete.config')

local M = {}

M.config = {}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', config_module.defaults, opts or {})

  indicator.setup()
  menu.setup(M.config)
  trigger.setup(M.config)

  vim.keymap.set('i', M.config.keymap.accept, function()
    -- If popup menu is visible, select first item and accept
    if vim.fn.pumvisible() == 1 then
      -- Check if anything is selected
      local info = vim.fn.complete_info({'selected'})
      if info.selected == -1 then
        -- Nothing selected, select first item then accept
        return vim.api.nvim_replace_termcodes('<C-n><C-y>', true, false, true)
      else
        -- Something selected, just accept it
        return vim.api.nvim_replace_termcodes('<C-y>', true, false, true)
      end
    end

    -- Otherwise try LCP completion
    local completion_text = trigger.accept_completion()
    if completion_text then
      return completion_text
    end

    -- No completion, normal newline
    return vim.api.nvim_replace_termcodes(M.config.keymap.accept, true, false, true)
  end, {
    expr = true,
    noremap = true,
    silent = true,
    desc = 'Accept completion from menu or LCP, or insert newline',
  })

  vim.keymap.set('i', M.config.keymap.menu, function()
    menu.show()
  end, {
    noremap = true,
    silent = true,
    desc = 'Show completion menu',
  })
end

-- Manual trigger
function M.trigger()
  require('simplecomplete.trigger').do_completion()
end

-- Clear completion
function M.clear()
  local bufnr = vim.api.nvim_get_current_buf()
  indicator.hide(bufnr)
end

return M

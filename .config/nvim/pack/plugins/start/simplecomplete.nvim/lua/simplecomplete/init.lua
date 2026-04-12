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
  trigger.setup(M.config)

  vim.keymap.set('i', M.config.keymap.accept, function()
    -- If popup menu is visible, select first item and accept
    if vim.fn.pumvisible() == 1 then
      -- Check if anything is selected
      local info = vim.fn.complete_info({'selected'})
      if info.selected == -1 then
        -- Nothing selected, select first item then accept
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-n><C-y>', true, false, true), 'n', false)
      else
        -- Something selected, just accept it
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-y>', true, false, true), 'n', false)
      end
      return
    end

    -- Otherwise try LCP completion
    if trigger.accept_completion() then
      return
    end

    -- No completion, normal newline
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(M.config.keymap.accept, true, false, true), 'n', false)
  end, {
    noremap = true,
    silent = true,
    desc = 'Accept completion from menu or LCP, or insert newline',
  })

  vim.keymap.set('i', M.config.keymap.menu, function()
    local matches, keyword = trigger.get_matches_for_menu()
    if matches and #matches > 0 then
      menu.show(matches)
    end
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

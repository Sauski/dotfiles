local function smart_insert(fallback_key)
  return function()
    if vim.api.nvim_get_current_line():match('^%s*$') then
      return '"_cc'
    else
      return fallback_key
    end
  end
end

return {
  smart_insert = smart_insert,
}

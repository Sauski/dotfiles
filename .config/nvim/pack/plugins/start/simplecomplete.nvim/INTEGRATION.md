# Integration with dotfiles

To use simplecomplete.nvim in your Neovim config:

## 1. Update init.lua

Replace blink.cmp setup with simplecomplete:

```lua
-- OLD (around line 40):
-- require('blink.cmp').setup(require('config.blink'))

-- NEW:
require('simplecomplete').setup({
  min_keyword_length = 4,
  debounce_ms = 100,
  sources = {
    buffers = 'all',  -- Scan all buffers, not just visible
  },
  keymap = {
    accept = '<CR>',
  },
})
```

## 2. Add to pack/plugins/start/

Option A - Symlink (recommended):
```bash
cd C:/GitHub/dotfiles/.config/nvim/pack/plugins/start/
ln -s C:/GitHub/simplecomplete.nvim/ simplecomplete.nvim
```

Option B - Copy directory:
```bash
cp -r C:/GitHub/simplecomplete.nvim C:/GitHub/dotfiles/.config/nvim/pack/plugins/start/
```

## 3. Remove blink.cmp (optional)

If you want to fully replace blink.cmp:

```bash
rm -rf C:/GitHub/dotfiles/.config/nvim/pack/plugins/start/blink.cmp
rm C:/GitHub/dotfiles/.config/nvim/lua/config/blink.lua
```

## 4. Test

1. Restart Neovim
2. Open a file with some text
3. Start typing a 4+ character word
4. Ghost text should appear
5. Press Enter to accept

## Troubleshooting

If completions don't appear:

1. Check `:lua =vim.g.loaded_simplecomplete` (should be 1)
2. Check `:lua =require('simplecomplete').config` (should show config)
3. Try manual trigger: `:lua require('simplecomplete').trigger()`
4. Check for errors: `:messages`

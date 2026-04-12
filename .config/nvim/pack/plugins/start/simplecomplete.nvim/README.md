# simplecomplete.nvim

Minimal buffer completion for Neovim with LCP-based indicators and menu selection.

## Features

- **Visual indicator**: Underline shows when completions are available
- **LCP accept**: Press Enter to complete to longest common prefix
- **Menu selection**: Press Shift+Enter to see all matches
- **Buffer-based**: Scans words from all buffers
- **Fast**: 20ms debounce, cached word extraction

## Usage

1. Type at least 2 characters
2. Indicator (underline) appears when matches exist
3. Press **Enter** to complete to longest common prefix
4. Press **Shift+Enter** to see menu of all matches

## Configuration

```lua
require('simplecomplete').setup({
  min_keyword_length = 2,
  debounce_ms = 20,
  sources = {
    buffers = 'all',
  },
  keymap = {
    accept = '<CR>',
    menu = '<S-CR>',
  },
})
```

## How It Works

**Longest Common Prefix (LCP)**:
- Type "te" with buffer containing: testing, tester, tested
- LCP = "test" (common to all matches)
- Press Enter → inserts "st" → cursor at "test"
- Type "i" → cursor at "testi"
- LCP = "testing" (only match)
- Press Enter → inserts "ng" → cursor at "testing"

**Menu**:
- Press Shift+Enter anytime to see all matches
- Navigate with arrows or Ctrl+n/Ctrl+p
- Type to filter
- Enter to accept

## License

MIT

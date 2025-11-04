# quickbuild.nvim

Real-time C++ build error parsing for Neovim.

## What

Runs build commands, parses compiler output via regex, displays diagnostics inline.

## Setup

### 1. Build Scanner

```bash
cd scanner
cmake -B build -S .
cmake --build build --config Release
cmake --install build
```

### 2. Install Plugin

```lua
{
  "yourusername/quickbuild.nvim",
  config = function()
    require("quickbuild").setup()
  end,
}
```

### 3. Configure Project

Create `.quickbuild.json` in git root:

```json
{
  "patterns": [
    {
      "regex": "^(.+?):(\\d+):(\\d+): (error|warning): (.+)$",
      "groups": {"file": 1, "line": 2, "col": 3, "severity": 4, "message": 5}
    }
  ],
  "commands": [
    {"name": "Build", "command": "cmake --build build"}
  ]
}
```

### 4. Run

```vim
:QuickBuild
```

Navigate diagnostics with `]d` / `[d`.

## Patterns

### GCC/Clang

```json
"regex": "^(.+?):(\\d+):(\\d+): (error|warning|note): (.+)$"
```

### MSVC

```json
"regex": "^(.+?)\\((\\d+),(\\d+)\\): (error|warning) C\\d+: (.+)$"
```

### Multi-Compiler

```json
{
  "patterns": [
    {
      "regex": "^(.+?):(\\d+):(\\d+): (error|warning|note): (.+)$",
      "groups": {"file": 1, "line": 2, "col": 3, "severity": 4, "message": 5}
    },
    {
      "regex": "^(.+?)\\((\\d+),(\\d+)\\): (error|warning) C\\d+: (.+)$",
      "groups": {"file": 1, "line": 2, "col": 3, "severity": 4, "message": 5}
    }
  ]
}
```

## Auto-Build

```json
{
  "auto_build_on_save": true,
  "file_patterns": ["*.cpp", "*.hpp"],
  "debounce_ms": 500
}
```

## Options

```lua
require("quickbuild").setup({
  scanner_path = "/custom/path",    -- Override scanner location
  verbose = true,                    -- Show build progress
  status_messages = true,            -- Enable status messages (default: true)
})
```

## API

```lua
local qb = require("quickbuild")

qb.build()                          -- Trigger build
qb.cancel()                         -- Cancel build
qb.get_status()                     -- { is_running, stage, errors, warnings }
qb.get_namespace()                  -- Diagnostic namespace
```

## Commands

- `:QuickBuild` - Start build
- `:QuickBuildCancel` - Cancel build

## Configuration

`.quickbuild.json` fields:

| Field | Type | Required |
|-------|------|----------|
| `patterns` | array | Yes |
| `commands` | array | Yes |
| `auto_build_on_save` | boolean | No |
| `file_patterns` | array | If auto-build |
| `debounce_ms` | number | No |

Command format:
```json
{"name": "Build", "command": "cmake --build build"}
```
- `name`: Display name for statusline
- `command`: Shell command to execute

Pattern groups (ECMAScript regex):
- Required: `file`, `line`, `severity`, `message`
- Optional: `col` (defaults to 0)

Commands execute sequentially, stop on first error.

## Requirements

- Neovim 0.7+
- CMake 3.15+
- C++17 compiler
- Git repository

## Troubleshooting

**Scanner not found**: Run `cmake --install build` or set `scanner_path`

**Not in git repo**: Run `git init`

**No diagnostics**: Test scanner directly:
```bash
echo "test.cpp:1:1: error: test" | qb-scanner
```

**Pattern not matching**: Use `\\d` not `\d` in JSON

## Docs

- [docs/architecture.md](docs/architecture.md)
- [docs/patterns.md](docs/patterns.md)
- [docs/scanner.md](docs/scanner.md)
- [CLAUDE.md](CLAUDE.md)

## License

MIT

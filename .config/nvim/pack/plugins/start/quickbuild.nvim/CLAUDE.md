# CLAUDE.md

Development guidance for Claude Code (claude.ai/code).

## Architecture

Two-part system:
1. **C++ Scanner** (`qb-scanner`): Reads build output (stdin), matches errors via std::regex, outputs diagnostics (stdout)
2. **Lua Plugin**: Spawns builds, pipes through scanner, publishes to `vim.diagnostic`

**Data Flow**:
```
.quickbuild.json → Build Commands → Scanner → Diagnostics → vim.diagnostic
```

## Build

### Scanner

```bash
cd scanner
cmake -B build -S .
cmake --build build --config Release
ctest -C Release
```

Binary: `scanner/build/Release/qb-scanner.exe` (Windows) or `scanner/build/qb-scanner` (Unix)

### Tests

**C++**: `cd scanner/build && ctest -C Release`

**Lua (Windows)**: `powershell -ExecutionPolicy Bypass -File tests/run_isolated_test.ps1`

**Lua (Unix)**: `XDG_DATA_HOME="./tests/.nvim-data" XDG_STATE_HOME="./tests/.nvim-data" XDG_CONFIG_HOME="./tests/.nvim-data" NVIM_APPNAME=qb-test nvim --headless -u tests/minimal_init.lua -c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = './tests/minimal_init.lua' })"`

**Note**: Environment variables isolate test neovim instance from installed plugin copies.

**Required**: All tests must pass before stopping.

## Structure

```
scanner/src/
├── main.cpp       # Stdin loop, git root detection
├── scanner.hpp    # Regex matching, diagnostics
└── config.hpp     # JSON parsing

lua/quickbuild/
├── init.lua       # setup(), build(), cancel()
├── builder.lua    # Job management
└── diagnostic.lua # vim.diagnostic integration

plugin/
└── quickbuild.lua # :QuickBuild, :QuickBuildCancel
```

## Patterns

ECMAScript regex with capture groups:
- Required: `file`, `line`, `severity`, `message`
- Optional: `col` (defaults to 0)

See `docs/patterns.md` for GCC/Clang/MSVC examples.

## Rules

1. **No fallbacks**: Missing scanner/config = error
2. **No exceptions**: Use std::optional, return nullopt on failure
3. **Less is more**: Sharp, no fluff
4. **Local dependencies**: Bundled in `scanner/lib/`, no submodules
5. **Tests pass**: Run complete suite before stopping
6. **Header-only**: Use `.hpp` files

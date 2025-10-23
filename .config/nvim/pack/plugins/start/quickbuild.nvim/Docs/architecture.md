# Architecture

## Overview

Neovim plugin for real-time C++ build error parsing and diagnostic display.

## Components

### 1. Lua Plugin
- Spawns build process via `vim.system()`
- Spawns scanner binary, pipes build output to it
- Receives diagnostics from scanner
- Publishes to `vim.diagnostic` API

### 2. C++ Scanner Binary
- Reads build output from stdin (line-buffered)
- Uses std::regex to match error patterns
- Extracts diagnostic fields (file, line, col, message)
- Outputs diagnostic format to stdout

### 3. Config File
`.quickbuild.json` in git root contains:
- Sequential build commands
- Error pattern regexes

### 4. Data Flow

```
.quickbuild.json → commands[] + patterns[]
    ↓
Build Process (sequential, stop on first error)
    ↓ stdout/stderr
Scanner Binary (std::regex pattern matching)
    ↓ diagnostic format
Neovim Lua
    ↓ vim.diagnostic.set()
Display
```

## Platform Support

- Linux x86-64, ARM64
- macOS Intel, ARM64
- Windows x86-64

Cross-platform via:
- Neovim's libuv-based `vim.system()` (pipe handling)
- C++17 `<filesystem>`, `<iostream>`, `<regex>` (portable I/O)

## Key Design Decisions

1. **std::regex**: C++17 standard library, no dependencies
2. **No fallbacks**: Missing scanner or config = error
3. **Line-buffered**: Diagnostics appear during build
4. **Single config**: Commands + patterns in `.quickbuild.json`
5. **Git root**: Always use git root as project root

# Scanner

## Prerequisites

- CMake 3.15 or later
- C++17 compiler (GCC, Clang, or MSVC)
- Git repository (scanner finds git root at runtime)

## Build

### Linux/macOS

```bash
cd scanner
cmake -B build -S .
cmake --build build
```

### Windows

```bash
cd scanner
cmake -B build -S .
cmake --build build --config Release
```

## Test

```bash
cd scanner/build
ctest
```

Verbose output:
```bash
ctest --verbose
```

Windows:
```bash
ctest -C Release
```

Tests are in `scanner/test/scanner_test.cpp`.

## Install

```bash
cmake --install build
```

Installs `qb-scanner` to system PATH.

## Structure

```
scanner/
├── CMakeLists.txt       # Build configuration
├── lib/
│   └── gtest/           # GTest source (bundled)
├── src/
│   ├── main.cpp         # Stdin loop, signal handling
│   ├── scanner.hpp      # Regex matching, diagnostic output
│   └── config.hpp       # Pattern loading from JSON
└── test/
    └── scanner_test.cpp # GTest unit tests
```

## Artifacts

**Binary**: `build/qb-scanner` (Linux/macOS) or `build/Release/qb-scanner.exe` (Windows)

**Tests**: `build/scanner_test` (Linux/macOS) or `build/Release/scanner_test.exe` (Windows)

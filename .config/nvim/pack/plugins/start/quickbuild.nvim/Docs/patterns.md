# Pattern Configuration

## Format

Patterns defined in `.quickbuild.json`:

```json
{
  "patterns": [
    {
      "regex": "^(.+?):(\\d+):(\\d+): (error|warning): (.+)$",
      "groups": {"file": 1, "line": 2, "col": 3, "severity": 4, "message": 5}
    }
  ]
}
```

## Fields

**regex**: ECMAScript regex pattern with capture groups

**groups**: Map capture group index to diagnostic field

Valid fields:
- `file` (required)
- `line` (required)
- `col` (optional, defaults to 0)
- `severity` (required: "error" or "warning")
- `message` (required)

## Matching

Scanner uses std::regex to match patterns against each line.

On match, extracts groups and outputs diagnostic.

## Common Patterns

### GCC/Clang
```
/path/to/file.cpp:42:10: error: expected ';'
```

Pattern:
```json
{
  "regex": "^(.+?):(\\d+):(\\d+): (error|warning): (.+)$",
  "groups": {"file": 1, "line": 2, "col": 3, "severity": 4, "message": 5}
}
```

### MSVC
```
C:\path\to\file.cpp(42,10): error C2143: syntax error
```

Pattern:
```json
{
  "regex": "^(.+?)\\((\\d+),(\\d+)\\): (error|warning) C\\d+: (.+)$",
  "groups": {"file": 1, "line": 2, "col": 3, "severity": 4, "message": 5}
}
```

## Path Handling

Scanner normalizes paths to absolute with forward slashes:
- `src/main.cpp` → `/abs/project/src/main.cpp`
- `C:\project\src\main.cpp` → `C:/project/src/main.cpp`

Working directory is git root.

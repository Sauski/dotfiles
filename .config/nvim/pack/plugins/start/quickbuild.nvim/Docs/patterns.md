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

## Multiline Patterns

Tools outputting diagnostics across multiple lines require multiline
configuration.

### Block-Based Model

Scanner accumulates lines between `block_start` and `block_end` regex
matches, joins them into a single string, then matches the pattern
against the joined result.

### TLA+ Example

```
***Parse Error***
Was expecting "===="
Encountered "pple" at line 12, column 1 in file .\deadlock.tla
```

Pattern:
```json
{
  "regex": "Encountered .* at line (\\d+), column (\\d+).*file (.+?)$",
  "groups": {"file": 3, "line": 1, "col": 2},
  "multiline": {
    "block_start": "^\\*\\*\\*Parse Error\\*\\*\\*$",
    "block_end": "^Encountered",
    "join": " ",
    "severity": "error",
    "message_parts": [0, 1]
  }
}
```

### TLA+ SANY2 Example (File Before Error)

```
Parsing file C:\GitHub\Celsus\models\deadlock.tla
***Parse Error***
Was expecting "==== or more Module body"
Encountered "problem" at line 10, column 1 and token "0"
```

Pattern:
```json
{
  "regex": "Parsing file (.+?)\\s.*Encountered .* at line (\\d+), column (\\d+)",
  "groups": {"file": 1, "line": 2, "col": 3},
  "multiline": {
    "block_start": "^Parsing file",
    "block_end": "^Encountered",
    "join": " ",
    "severity": "error",
    "message_parts": [1, 2, 3]
  }
}
```

### Multiline Fields

**block_start** (required): Regex triggering line accumulation

**block_end** (required): Regex ending line accumulation

**join** (optional): String joining lines (default: " ")

**severity** (optional): Fixed severity if not in groups

**message_parts** (optional): Array of buffer line indices for
message. Positive indices (0, 1, 2) count from start. Negative
indices (-1, -2) count from end. Empty array uses message from regex.

### Behavior

1. `block_start` matches → enter COLLECTING state
2. Accumulate lines in buffer
3. `block_end` matches → join lines with separator
4. Match `regex` against joined string
5. Extract diagnostic fields from regex groups
6. Emit diagnostic, return to IDLE state
7. EOF during COLLECTING without `block_end` → discard buffer

# transh: Transpiler for universal POSIX-compliant shellscript

## Goal

- Ensure truly portable (= POSIX-compliant) shellscript.
- Complements missing features in POSIX-compliant shellscript.
  - robust `.` command with relative path
  - complete function stack
    - complete local variable
    - complete read-only variable
  - other efficient features
    - absorb the difference subtle command differences
    - ...
  - ... and more!

## Requirements

### For Use

1. Git

### For Development

1. All of the above
2. Docker

## Setup

### For Use

TBD

### For Development

```sh
./setup_shellspec.sh
```

## Test

Planning to use [shellspec](https://github.com/shellspec/shellspec).

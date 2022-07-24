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

## Requirements.

TBD

## Test

### Setup

```sh
./setup_shellspec.sh
```

Planning to use [shellspec](https://github.com/shellspec/shellspec).

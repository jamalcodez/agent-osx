# Agent OS Test Suite

This directory contains automated tests for Agent OS scripts and functions.

## Directory Structure

```
tests/
├── README.md                 # This file
├── run-tests.sh             # Test runner script
├── unit/                    # Unit tests for individual functions
│   ├── test-yaml-parser.bats
│   ├── test-error-handling.bats
│   └── test-validation.bats
├── integration/             # Integration tests for full workflows
│   ├── test-base-install.bats
│   └── test-project-install.bats
└── fixtures/                # Test data and mock files
    ├── mock-profiles/
    └── sample-configs/
```

## Running Tests

### Prerequisites

Install bats-core (Bash Automated Testing System):

```bash
# macOS
brew install bats-core

# Linux (Ubuntu/Debian)
sudo apt-get install bats

# Linux (from source)
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Run All Tests

```bash
./tests/run-tests.sh
```

### Run Specific Test Files

```bash
bats tests/unit/test-yaml-parser.bats
bats tests/unit/test-error-handling.bats
```

### Run with Verbose Output

```bash
bats -t tests/unit/test-yaml-parser.bats
```

## Writing Tests

Tests use bats syntax:

```bash
#!/usr/bin/env bats

# Load the functions to test
load '../test-helper'

@test "function returns expected value" {
    result=$(my_function "input")
    [ "$result" = "expected output" ]
}

@test "function handles errors" {
    run my_function ""
    [ "$status" -eq 1 ]
    [[ "$output" =~ "error message" ]]
}
```

## Test Coverage Goals

- **Unit tests**: Test individual functions in isolation
- **Integration tests**: Test full workflows end-to-end
- **Coverage target**: 80% of critical functions

### Priority Test Areas

1. ✅ YAML parsing (get_yaml_value, get_yaml_array)
2. ✅ Error handling (print_error_with_context)
3. ✅ Configuration validation (validate_config)
4. ⏳ Template compilation (process_conditionals, process_workflows)
5. ⏳ Profile inheritance (get_profile_file)
6. ⏳ Version compatibility checking
7. ⏳ Circular dependency detection

## Continuous Integration

Tests should be run:
- Before committing changes
- In CI/CD pipeline (GitHub Actions)
- Before releasing new versions

## Contributing

When adding new functions:
1. Write tests FIRST (TDD approach)
2. Ensure all tests pass before submitting PR
3. Aim for >80% code coverage for new code

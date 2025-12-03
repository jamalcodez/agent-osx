# Agent OS Script Library

This directory contains modular components extracted from the monolithic `common-functions.sh` file. Each module focuses on a specific domain of functionality.

## Architecture

### Module Structure

```
scripts/
├── common-functions.sh      # Main orchestrator (sources all modules)
├── lib/                     # Modular components
│   ├── README.md            # This file
│   ├── output.sh            # Color printing and user-facing output
│   ├── yaml-parser.sh       # YAML parsing and string normalization
│   └── file-operations.sh   # File manipulation with dry-run support
```

### Design Principles

1. **Single Responsibility**: Each module handles one domain
2. **No Inter-Dependencies**: Modules don't depend on each other
3. **Backward Compatible**: All existing scripts work unchanged
4. **Testable**: Each module can be tested independently
5. **Progressive Migration**: Functions migrate gradually from monolith

## Modules

### output.sh
**Purpose**: User-facing output and error messaging

**Functions**:
- `print_color()` - Print with ANSI color codes
- `print_section()` - Section headers
- `print_status()` - Status messages
- `print_success()` - Success messages (green ✓)
- `print_warning()` - Warning messages (yellow ⚠️)
- `print_error()` - Error messages (red ✗)
- `print_error_with_context()` - Errors with context and fix instructions
- `print_error_with_remedy()` - Errors with fix instructions only
- `print_verbose()` - Verbose mode output

**Dependencies**: None (defines color constants)

**Usage**:
```bash
source "scripts/lib/output.sh"
print_success "Operation completed"
print_error_with_context "File not found" "Path: /tmp/file" "Create the file first"
```

### yaml-parser.sh
**Purpose**: Parse YAML configuration files

**Functions**:
- `normalize_name()` - Convert strings to lowercase-hyphenated format
- `normalize_yaml_line()` - Normalize YAML lines (tabs, spaces)
- `get_indent_level()` - Calculate indentation level
- `get_yaml_value()` - Extract key-value pairs from YAML
- `get_yaml_array()` - Extract array items from YAML

**Dependencies**: None

**Usage**:
```bash
source "scripts/lib/yaml-parser.sh"
version=$(get_yaml_value "config.yml" "version" "1.0.0")
items=$(get_yaml_array "config.yml" "profiles")
```

### file-operations.sh
**Purpose**: File system operations with dry-run support

**Functions**:
- `ensure_dir()` - Create directory if needed (dry-run aware)
- `copy_file()` - Copy file (dry-run aware)
- `write_file()` - Write content to file (dry-run aware)
- `should_skip_file()` - Determine if file should be skipped during update

**Dependencies**:
- Uses `print_verbose()` from output.sh (must be sourced first)
- Requires `$DRY_RUN` global variable

**Usage**:
```bash
source "scripts/lib/output.sh"
source "scripts/lib/file-operations.sh"
DRY_RUN="false"
ensure_dir "/tmp/test"
copy_file "source.txt" "/tmp/test/dest.txt"
```

## Migration Status

### ✅ Completed Modules
- **output.sh**: All output functions extracted and tested
- **yaml-parser.sh**: All YAML functions extracted and tested
- **file-operations.sh**: Core file operations extracted and tested

### ⏳ Planned Modules
- **validator.sh**: Configuration validation logic
- **profile-manager.sh**: Profile resolution and inheritance
- **compiler.sh**: Template compilation (workflows, standards, conditionals)

### 📊 Migration Progress

| Category | Lines | Status | Module |
|----------|-------|--------|--------|
| Output functions | ~90 | ✅ Complete | output.sh |
| YAML parsing | ~140 | ✅ Complete | yaml-parser.sh |
| File operations | ~90 | ✅ Complete | file-operations.sh |
| Profile management | ~200 | ⏳ Pending | profile-manager.sh |
| Validation | ~150 | ⏳ Pending | validator.sh |
| Template compilation | ~600 | ⏳ Pending | compiler.sh |
| Other utilities | ~200 | ⏳ Pending | TBD |

**Total**: ~320 lines migrated out of ~1,468 lines (~22% complete)

## Usage in Scripts

All existing Agent OS scripts automatically use the new modular structure through `common-functions.sh`:

```bash
#!/bin/bash

# Source common functions (automatically loads all modules)
source "$SCRIPT_DIR/common-functions.sh"

# Use functions as before - they now come from modules!
print_success "Using modular architecture"
version=$(get_yaml_value "config.yml" "version" "1.0.0")
ensure_dir "/tmp/output"
```

## Testing

Each module can be tested independently:

```bash
# Test output module
source scripts/lib/output.sh
print_success "Test passed"

# Test YAML parser
source scripts/lib/yaml-parser.sh
value=$(get_yaml_value "test.yml" "key" "default")

# Test file operations (requires output.sh)
source scripts/lib/output.sh
source scripts/lib/file-operations.sh
DRY_RUN="false"
VERBOSE="true"
ensure_dir "/tmp/test"
```

Automated tests are in `tests/unit/`:
- `test-yaml-parser.bats` - YAML parsing functions
- `test-error-handling.bats` - Output functions
- `test-validation.bats` - Configuration validation

Run tests:
```bash
./tests/run-tests.sh
```

## Benefits of Modular Architecture

### Maintainability
- **Easier to understand**: Each module is ~100-200 lines vs 1,468 lines
- **Faster debugging**: Know exactly where to look for issues
- **Clear responsibilities**: Each module has one job

### Testability
- **Unit tests**: Test each module independently
- **Mocking**: Easy to mock dependencies
- **Coverage**: Track coverage per module

### Reusability
- **Selective loading**: Load only what you need
- **External use**: Modules can be used outside Agent OS
- **Composition**: Combine modules in new ways

### Performance
- **Faster sourcing**: Only load necessary modules
- **Reduced memory**: Smaller footprint per script
- **Better caching**: Shells cache smaller files better

## Contributing

When adding new functions:

1. **Determine module**: Which module does it belong to?
2. **Check dependencies**: Does it need other modules?
3. **Add function**: Add to appropriate module
4. **Update tests**: Add unit tests
5. **Document**: Update module comments

When creating new modules:

1. **Single responsibility**: One clear purpose
2. **No inter-dependencies**: Modules shouldn't depend on each other
3. **Document well**: Clear header comments
4. **Add tests**: Create corresponding test file
5. **Update this README**: Add module documentation

## Future Work

### Phase 2: Extract More Modules
- Create `validator.sh` for configuration validation
- Create `profile-manager.sh` for profile operations
- Create `compiler.sh` for template processing

### Phase 3: Cleanup
- Remove legacy functions from `common-functions.sh`
- Make it a pure orchestrator (<100 lines)
- Document completion of migration

### Phase 4: Optimization
- Lazy loading for large modules
- Parallel sourcing where possible
- Precompiled function cache

## Version History

- **v1.0** (2025-12-03): Initial modular architecture
  - Extracted output.sh (90 lines)
  - Extracted yaml-parser.sh (140 lines)
  - Extracted file-operations.sh (90 lines)
  - 22% migration complete

---

**Questions?** See the main [Agent OS documentation](https://buildermethods.com/agent-os) or open an issue on GitHub.

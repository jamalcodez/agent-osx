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
- `show_diff_preview()` - Display colored unified diff (dry-run mode)
- `show_progress()` - Display progress counter with percentage
- `show_compilation_progress()` - Display compilation progress with cache status
- `clear_progress()` - Clear progress line before final output

**Dependencies**: None (defines color constants)

**Usage**:
```bash
source "scripts/lib/output.sh"
print_success "Operation completed"
print_error_with_context "File not found" "Path: /tmp/file" "Create the file first"

# Show diff preview in dry-run mode
old_content=$(cat existing_file.txt)
new_content="New content here"
show_diff_preview "$old_content" "$new_content" "existing_file.txt"

# Show progress during long operations
total_files=47
for i in $(seq 1 $total_files); do
    show_compilation_progress "$i" "$total_files" "file-$i.md"
    # ... compile file ...
done
clear_progress
echo "✓ Compiled $total_files files"
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
**Purpose**: File system operations with dry-run and transactional staging support

**Functions**:
- `ensure_dir()` - Create directory if needed (dry-run aware, staging aware)
- `copy_file()` - Copy file (dry-run aware, staging aware)
- `write_file()` - Write content to file (dry-run aware, staging aware)
- `should_skip_file()` - Determine if file should be skipped during update
- `init_staging()` - Initialize transactional staging directory
- `get_staging_path()` - Convert target path to staging path
- `commit_staging()` - Atomically commit staged files to target
- `rollback_staging()` - Clean up staging on failure/interrupt

**Dependencies**:
- Uses `print_*()` functions from output.sh (must be sourced first)
- Requires `$DRY_RUN`, `$PROJECT_DIR`, `$STAGING_ACTIVE` global variables

**Usage**:
```bash
source "scripts/lib/output.sh"
source "scripts/lib/file-operations.sh"
DRY_RUN="false"
PROJECT_DIR="/path/to/project"

# Standard file operations
ensure_dir "/tmp/test"
copy_file "source.txt" "/tmp/test/dest.txt"

# Transactional operations
init_staging "$PROJECT_DIR"
trap 'rollback_staging; exit 1' EXIT ERR INT TERM

# ... perform file operations (automatically use staging) ...

commit_staging "$PROJECT_DIR"
trap - EXIT ERR INT TERM  # Disable trap after success
```

**Transactional Staging**:
- All file operations automatically use staging when active
- Staging directory: `$PROJECT_DIR/.agent-os-staging-$$`
- Atomic commit via rsync or cp+rm
- Automatic rollback on failure/interrupt (via trap)
- Zero partial-state installations

### cache.sh
**Purpose**: Content-based caching for template compilation

**Functions**:
- `init_cache()` - Initialize cache directory and version check
- `generate_cache_key()` - Create MD5 hash from compilation inputs
- `get_from_cache()` - Retrieve cached compiled content
- `put_in_cache()` - Store compiled content with metadata
- `clear_cache()` - Clear entire cache
- `clear_cache_for_profile()` - Clear cache for specific profile
- `get_cache_stats()` - Show cache size and entry count

**Dependencies**:
- Uses `print_verbose()` from output.sh (must be sourced first)
- Requires `$USE_CACHE` global variable
- Cache stored in `$HOME/.cache/agent-os/compilation/`

**Usage**:
```bash
source "scripts/lib/output.sh"
source "scripts/lib/cache.sh"
USE_CACHE="true"
VERBOSE="true"

# Generate cache key from compilation inputs
cache_key=$(generate_cache_key "source.md" "default" "" "true" "true")

# Check cache
cached_content=""
if get_from_cache "$cache_key" cached_content; then
    echo "Cache hit: $cached_content"
else
    # Compile and cache
    compiled="<compiled content>"
    put_in_cache "$cache_key" "$compiled" "source.md"
fi

# View cache statistics
get_cache_stats
```

**Cache Key Factors**:
- Source file content (MD5 hash)
- Profile name
- Phase mode (embed vs normal)
- Claude Code subagents flag
- Standards as Skills flag
- Agent OS version

### validator.sh
**Purpose**: Pre-flight validation and configuration checking

**Functions**:
- `command_exists()` - Check if command is available
- `check_system_dependencies()` - Validate required system commands
- `validate_profile_structure()` - Check profile directory structure
- `validate_preset_name()` - Validate preset against known presets
- `validate_config_logic()` - Check configuration dependencies
- `run_preflight_validation()` - Master validation orchestrator

**Dependencies**:
- Uses `print_*()` functions from output.sh (must be sourced first)

**Usage**:
```bash
source "scripts/lib/output.sh"
source "scripts/lib/validator.sh"

# Run comprehensive pre-flight validation
if ! run_preflight_validation "$profile" "$base_dir" "$preset" \
    "$claude_code_commands" "$use_claude_code_subagents" \
    "$agent_os_commands" "$standards_as_claude_code_skills"; then
    echo "Validation failed - fix issues and try again"
    exit 1
fi

# Individual validation checks
check_system_dependencies           # Check perl, md5sum, etc.
validate_preset_name "cursor"       # Validate preset name
validate_profile_structure "default" "$BASE_DIR"  # Check profile structure
```

**Validation Checks**:
1. **System Dependencies**: perl, md5sum (with install hints)
2. **Profile Structure**: Required directories (standards, commands, agents, workflows)
3. **Preset Names**: Against known preset list
4. **Config Logic**: Dependency checks (subagents requires commands, etc.)

## Migration Status

### ✅ Completed Modules
- **output.sh**: All output functions extracted and tested
- **yaml-parser.sh**: All YAML functions extracted and tested
- **file-operations.sh**: Core file operations extracted and tested
- **cache.sh**: Compilation caching system implemented and tested
- **validator.sh**: Pre-flight validation system implemented and tested

### ⏳ Planned Modules
- **profile-manager.sh**: Profile resolution and inheritance
- **compiler.sh**: Template compilation (workflows, standards, conditionals)

### 📊 Migration Progress

| Category | Lines | Status | Module |
|----------|-------|--------|--------|
| Output functions | ~90 | ✅ Complete | output.sh |
| YAML parsing | ~140 | ✅ Complete | yaml-parser.sh |
| File operations | ~90 | ✅ Complete | file-operations.sh |
| Caching system | ~180 | ✅ Complete | cache.sh |
| Validation | ~200 | ✅ Complete | validator.sh |
| Profile management | ~200 | ⏳ Pending | profile-manager.sh |
| Template compilation | ~600 | ⏳ Pending | compiler.sh |
| Other utilities | ~200 | ⏳ Pending | TBD |

**Total**: ~700 lines migrated out of ~1,468 lines (~48% complete)

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

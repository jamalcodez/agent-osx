#!/bin/bash

# =============================================================================
# Agent OS Validation Functions
# Pre-flight validation and configuration checking
# =============================================================================

# -----------------------------------------------------------------------------
# System Dependency Checks
# -----------------------------------------------------------------------------

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system dependencies
# Returns 0 if all dependencies met, 1 otherwise
check_system_dependencies() {
    local errors=0

    print_verbose "Checking system dependencies..."

    # Required commands
    local required_commands="perl md5sum"

    for cmd in $required_commands; do
        if ! command_exists "$cmd"; then
            print_error "Required command not found: $cmd"

            # Provide installation hints
            case "$cmd" in
                perl)
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        echo "  Install: brew install perl"
                    else
                        echo "  Install: apt-get install perl"
                    fi
                    ;;
                md5sum)
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        echo "  Install: brew install md5sha1sum"
                        echo "  Or use: ln -s /sbin/md5 /usr/local/bin/md5sum"
                    else
                        echo "  Install: apt-get install coreutils"
                    fi
                    ;;
            esac
            ((errors++))
        fi
    done

    return $errors
}

# -----------------------------------------------------------------------------
# Profile Validation
# -----------------------------------------------------------------------------

# Validate profile structure
# Returns 0 if valid, 1 otherwise
validate_profile_structure() {
    local profile=$1
    local base_dir=$2
    local errors=0

    print_verbose "Validating profile structure: $profile"

    local profile_dir="$base_dir/profiles/$profile"

    # Check if profile exists
    if [[ ! -d "$profile_dir" ]]; then
        print_error "Profile directory not found: $profile"
        echo "  Expected: $profile_dir"
        echo "  Available profiles:"
        ls -1 "$base_dir/profiles" 2>/dev/null | sed 's/^/    - /' || echo "    (none)"
        return 1
    fi

    # Check required directories
    local required_dirs="standards commands agents workflows"
    for dir in $required_dirs; do
        if [[ ! -d "$profile_dir/$dir" ]]; then
            print_warning "Profile missing directory: $dir"
            echo "  Path: $profile_dir/$dir"
            ((errors++))
        fi
    done

    # Check for at least some content
    local has_content=false
    for dir in $required_dirs; do
        if [[ -d "$profile_dir/$dir" ]] && [[ -n "$(ls -A "$profile_dir/$dir" 2>/dev/null)" ]]; then
            has_content=true
            break
        fi
    done

    if [[ "$has_content" == "false" ]]; then
        print_error "Profile appears to be empty: $profile"
        echo "  No content found in: $profile_dir"
        return 1
    fi

    if [[ $errors -gt 0 ]]; then
        print_warning "Profile validation completed with $errors warning(s)"
    else
        print_verbose "Profile structure valid: $profile"
    fi

    return 0
}

# -----------------------------------------------------------------------------
# Preset Validation
# -----------------------------------------------------------------------------

# Validate preset name
# Returns 0 if valid or empty, 1 if invalid
validate_preset_name() {
    local preset=$1

    # Empty preset is valid (means no preset)
    if [[ -z "$preset" ]]; then
        return 0
    fi

    # "custom" is always valid (means manual config)
    if [[ "$preset" == "custom" ]]; then
        return 0
    fi

    print_verbose "Validating preset: $preset"

    # Valid preset names
    local valid_presets="claude-code-full claude-code-simple claude-code-basic cursor multi-tool"

    if [[ ! " $valid_presets " =~ " $preset " ]]; then
        print_error "Invalid preset name: '$preset'"
        echo "  Valid presets:"
        echo "    - claude-code-full    (Recommended: all features)"
        echo "    - claude-code-simple  (Claude Code without subagents)"
        echo "    - claude-code-basic   (Minimal Claude Code features)"
        echo "    - cursor              (Optimized for Cursor)"
        echo "    - multi-tool          (Both Claude Code and agent-os)"
        echo "    - custom              (Manual configuration)"
        return 1
    fi

    print_verbose "Preset valid: $preset"
    return 0
}

# -----------------------------------------------------------------------------
# Configuration Logic Validation
# -----------------------------------------------------------------------------

# Validate configuration logic and dependencies
# Returns 0 if valid, 1 otherwise
validate_config_logic() {
    local claude_code_commands=$1
    local use_claude_code_subagents=$2
    local agent_os_commands=$3
    local standards_as_claude_code_skills=$4

    print_verbose "Validating configuration logic..."

    local errors=0

    # Subagents require Claude Code commands
    if [[ "$use_claude_code_subagents" == "true" ]] && [[ "$claude_code_commands" != "true" ]]; then
        print_error "Configuration conflict: use_claude_code_subagents=true requires claude_code_commands=true"
        echo "  Fix: Set claude_code_commands=true or use_claude_code_subagents=false"
        ((errors++))
    fi

    # Skills require Claude Code commands
    if [[ "$standards_as_claude_code_skills" == "true" ]] && [[ "$claude_code_commands" != "true" ]]; then
        print_error "Configuration conflict: standards_as_claude_code_skills=true requires claude_code_commands=true"
        echo "  Fix: Set claude_code_commands=true or standards_as_claude_code_skills=false"
        ((errors++))
    fi

    # At least one output format should be enabled
    if [[ "$claude_code_commands" != "true" ]] && [[ "$agent_os_commands" != "true" ]]; then
        print_warning "No output formats enabled (both claude_code_commands and agent_os_commands are false)"
        echo "  This will only install standards files"
        echo "  Consider: --preset claude-code-full  (or another preset)"
    fi

    if [[ $errors -gt 0 ]]; then
        return 1
    fi

    print_verbose "Configuration logic valid"
    return 0
}

# -----------------------------------------------------------------------------
# Master Pre-Flight Validation
# -----------------------------------------------------------------------------

# Run all pre-flight validations
# Returns 0 if all checks pass, 1 otherwise
run_preflight_validation() {
    local profile=$1
    local base_dir=$2
    local preset=$3
    local claude_code_commands=$4
    local use_claude_code_subagents=$5
    local agent_os_commands=$6
    local standards_as_claude_code_skills=$7

    print_status "Running pre-flight validation..."
    echo ""

    local errors=0

    # 1. Check system dependencies
    if ! check_system_dependencies; then
        ((errors++))
        echo ""
    fi

    # 2. Validate profile structure
    if ! validate_profile_structure "$profile" "$base_dir"; then
        ((errors++))
        echo ""
    fi

    # 3. Validate preset name
    if ! validate_preset_name "$preset"; then
        ((errors++))
        echo ""
    fi

    # 4. Validate configuration logic
    if ! validate_config_logic "$claude_code_commands" "$use_claude_code_subagents" \
        "$agent_os_commands" "$standards_as_claude_code_skills"; then
        ((errors++))
        echo ""
    fi

    # Summary
    if [[ $errors -gt 0 ]]; then
        print_error "Pre-flight validation failed with $errors error(s)"
        echo ""
        echo "Fix the issues above and try again."
        return 1
    else
        print_success "Pre-flight validation passed"
        echo ""
        return 0
    fi
}

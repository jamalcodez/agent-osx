#!/bin/bash

# =============================================================================
# Agent OS Common Functions
# Shared utilities for Agent OS scripts
# =============================================================================
#
# ARCHITECTURE: This file is transitioning to a modular structure.
# Core utilities are being extracted into focused modules in scripts/lib/
#
# Modules (new, maintained):
#   - lib/output.sh          - Color printing and user-facing output
#   - lib/yaml-parser.sh     - YAML parsing and string normalization
#   - lib/file-operations.sh - File manipulation with dry-run support
#
# Legacy functions (below) will be progressively migrated to modules.
# All existing scripts remain fully compatible during transition.
#
# =============================================================================

# Get the directory where this file is located
COMMON_FUNCTIONS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# -----------------------------------------------------------------------------
# Load Modular Components
# -----------------------------------------------------------------------------

# Source output functions (colors, printing, errors)
source "$COMMON_FUNCTIONS_DIR/lib/output.sh"

# Source YAML parsing functions
source "$COMMON_FUNCTIONS_DIR/lib/yaml-parser.sh"

# Source file operation functions
source "$COMMON_FUNCTIONS_DIR/lib/file-operations.sh"

# -----------------------------------------------------------------------------
# Global Variables (set by scripts that source this file)
# -----------------------------------------------------------------------------
# These should be set by the calling script:
# BASE_DIR, PROJECT_DIR, DRY_RUN, VERBOSE

# -----------------------------------------------------------------------------
# Legacy Functions (To Be Migrated)
# -----------------------------------------------------------------------------
# NOTE: Functions below this line are still in the monolithic file.
# They will be progressively migrated to focused modules.
# New code should use the modular versions from lib/ when available.

# -----------------------------------------------------------------------------
# Profile Functions
# -----------------------------------------------------------------------------

# Get the effective profile path considering inheritance
get_profile_file() {
    local profile=$1
    local file_path=$2
    local base_dir=$3

    local current_profile=$profile
    local visited_profiles=""

    while true; do
        # Check for circular inheritance
        if [[ " $visited_profiles " == *" $current_profile "* ]]; then
            print_verbose "Circular inheritance detected at profile: $current_profile"
            echo ""
            return
        fi
        visited_profiles="$visited_profiles $current_profile"

        local profile_dir="$base_dir/profiles/$current_profile"
        local full_path="$profile_dir/$file_path"

        # Check for profile config first (needed for exclusion check)
        local profile_config="$profile_dir/profile-config.yml"

        # Check if file exists in current profile
        if [[ -f "$full_path" ]]; then
            # Check if this file is excluded (even in current profile)
            if [[ -f "$profile_config" ]]; then
                local excluded="false"
                while read pattern; do
                    if [[ -n "$pattern" ]] && match_pattern "$file_path" "$pattern"; then
                        excluded="true"
                        break
                    fi
                done < <(get_yaml_array "$profile_config" "exclude_inherited_files")

                if [[ "$excluded" == "true" ]]; then
                    echo ""
                    return
                fi
            fi
            echo "$full_path"
            return
        fi

        # Check for inheritance
        if [[ ! -f "$profile_config" ]]; then
            # No profile config means this is likely the default profile
            echo ""
            return
        fi

        local inherits_from=$(get_yaml_value "$profile_config" "inherits_from" "default")

        if [[ "$inherits_from" == "false" || -z "$inherits_from" ]]; then
            echo ""
            return
        fi

        # Check if file is excluded during inheritance
        local excluded="false"
        while read pattern; do
            if [[ -n "$pattern" ]] && match_pattern "$file_path" "$pattern"; then
                excluded="true"
                break
            fi
        done < <(get_yaml_array "$profile_config" "exclude_inherited_files")

        if [[ "$excluded" == "true" ]]; then
            echo ""
            return
        fi

        current_profile=$inherits_from
    done
}

# Get all files from profile considering inheritance
get_profile_files() {
    local profile=$1
    local base_dir=$2
    local subdir=$3

    local current_profile=$profile
    local visited_profiles=""
    local all_files=""
    local excluded_patterns=""

    # First, collect exclusion patterns and file overrides
    while true; do
        if [[ " $visited_profiles " == *" $current_profile "* ]]; then
            break
        fi
        visited_profiles="$visited_profiles $current_profile"

        local profile_dir="$base_dir/profiles/$current_profile"
        local profile_config="$profile_dir/profile-config.yml"

        # Add exclusion patterns from this profile
        if [[ -f "$profile_config" ]]; then
            local patterns=$(get_yaml_array "$profile_config" "exclude_inherited_files")
            if [[ -n "$patterns" ]]; then
                excluded_patterns="$excluded_patterns"$'\n'"$patterns"
            fi

            local inherits_from=$(get_yaml_value "$profile_config" "inherits_from" "default")
            if [[ "$inherits_from" == "false" || -z "$inherits_from" ]]; then
                break
            fi
            current_profile=$inherits_from
        else
            break
        fi
    done

    # Now collect files starting from the base profile
    local profiles_to_process=""
    current_profile=$profile
    visited_profiles=""

    while true; do
        if [[ " $visited_profiles " == *" $current_profile "* ]]; then
            break
        fi
        visited_profiles="$visited_profiles $current_profile"
        profiles_to_process="$current_profile $profiles_to_process"

        local profile_dir="$base_dir/profiles/$current_profile"
        local profile_config="$profile_dir/profile-config.yml"

        if [[ -f "$profile_config" ]]; then
            local inherits_from=$(get_yaml_value "$profile_config" "inherits_from" "default")
            if [[ "$inherits_from" == "false" || -z "$inherits_from" ]]; then
                break
            fi
            current_profile=$inherits_from
        else
            break
        fi
    done

    # Process profiles from base to specific
    for proc_profile in $profiles_to_process; do
        local profile_dir="$base_dir/profiles/$proc_profile"
        local search_dir="$profile_dir"

        if [[ -n "$subdir" ]]; then
            search_dir="$profile_dir/$subdir"
        fi

        if [[ -d "$search_dir" ]]; then
            find "$search_dir" -type f \( -name "*.md" -o -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | while read file; do
                relative_path="${file#$profile_dir/}"

                # Check if excluded
                excluded="false"
                while read pattern; do
                    if [[ -n "$pattern" ]] && match_pattern "$relative_path" "$pattern"; then
                        excluded="true"
                        break
                    fi
                done <<< "$excluded_patterns"

                if [[ "$excluded" != "true" ]]; then
                    # Check if already in list (override scenario)
                    if [[ ! " $all_files " == *" $relative_path "* ]]; then
                        echo "$relative_path"
                    fi
                fi
            done
        fi
    done | sort -u
}

# Match file path against pattern (supports wildcards)
match_pattern() {
    local path=$1
    local pattern=$2

    # Convert pattern to regex
    local regex=$(echo "$pattern" | sed 's/\*/[^\/]*/g' | sed 's/\*\*/.**/g')

    if [[ "$path" =~ ^${regex}$ ]]; then
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Template Processing Functions
# -----------------------------------------------------------------------------

# Replace Playwright tool with expanded tool list
replace_playwright_tools() {
    local tools=$1

    local playwright_tools="mcp__playwright__browser_close, mcp__playwright__browser_console_messages, mcp__playwright__browser_handle_dialog, mcp__playwright__browser_evaluate, mcp__playwright__browser_file_upload, mcp__playwright__browser_fill_form, mcp__playwright__browser_install, mcp__playwright__browser_press_key, mcp__playwright__browser_type, mcp__playwright__browser_navigate, mcp__playwright__browser_navigate_back, mcp__playwright__browser_network_requests, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_snapshot, mcp__playwright__browser_click, mcp__playwright__browser_drag, mcp__playwright__browser_hover, mcp__playwright__browser_select_option, mcp__playwright__browser_tabs, mcp__playwright__browser_wait_for, mcp__ide__getDiagnostics, mcp__ide__executeCode, mcp__playwright__browser_resize"

    echo "$tools" | sed "s/Playwright/$playwright_tools/g"
}

# Process conditional compilation tags ({{IF}}, {{UNLESS}}, {{ENDIF}}, {{ENDUNLESS}})
# Ignores {{orchestrated_standards}} and other placeholders
process_conditionals() {
    local content=$1
    local use_claude_code_subagents=$2
    local standards_as_claude_code_skills=$3
    local compiled_single_command=${4:-"false"}  # Default to false if not provided

    local result=""
    local nesting_level=0
    local should_include=true
    local stack_should_include=()

    while IFS= read -r line; do
        # Check for IF tags
        if [[ "$line" =~ \{\{IF[[:space:]]+([a-z_]+)\}\} ]]; then
            local flag_name="${BASH_REMATCH[1]}"

            # Evaluate condition
            local condition_met=false
            case "$flag_name" in
                "use_claude_code_subagents")
                    [[ "$use_claude_code_subagents" == "true" ]] && condition_met=true
                    ;;
                "standards_as_claude_code_skills")
                    [[ "$standards_as_claude_code_skills" == "true" ]] && condition_met=true
                    ;;
                "compiled_single_command")
                    [[ "$compiled_single_command" == "true" ]] && condition_met=true
                    ;;
                *)
                    print_warning "Unknown conditional flag: $flag_name"
                    ;;
            esac

            # Push current should_include onto stack
            stack_should_include+=("$should_include")

            # Update should_include based on parent's state AND current condition
            if [[ "$should_include" == true ]] && [[ "$condition_met" == true ]]; then
                should_include=true
            else
                should_include=false
            fi

            ((nesting_level++)) || true
            continue
        fi

        # Check for UNLESS tags
        if [[ "$line" =~ \{\{UNLESS[[:space:]]+([a-z_]+)\}\} ]]; then
            local flag_name="${BASH_REMATCH[1]}"

            # Evaluate condition (opposite of IF)
            local condition_met=false
            case "$flag_name" in
                "use_claude_code_subagents")
                    [[ "$use_claude_code_subagents" != "true" ]] && condition_met=true
                    ;;
                "standards_as_claude_code_skills")
                    [[ "$standards_as_claude_code_skills" != "true" ]] && condition_met=true
                    ;;
                "compiled_single_command")
                    [[ "$compiled_single_command" != "true" ]] && condition_met=true
                    ;;
                *)
                    print_warning "Unknown conditional flag: $flag_name"
                    ;;
            esac

            # Push current should_include onto stack
            stack_should_include+=("$should_include")

            # Update should_include based on parent's state AND current condition
            if [[ "$should_include" == true ]] && [[ "$condition_met" == true ]]; then
                should_include=true
            else
                should_include=false
            fi

            ((nesting_level++)) || true
            continue
        fi

        # Check for ENDIF tags
        if [[ "$line" =~ \{\{ENDIF[[:space:]]+([a-z_]+)\}\} ]]; then
            ((nesting_level--))

            # Pop should_include from stack
            if [[ ${#stack_should_include[@]} -gt 0 ]]; then
                local last_index=$((${#stack_should_include[@]} - 1))
                should_include="${stack_should_include[$last_index]}"
                unset 'stack_should_include[$last_index]'
            else
                should_include=true
            fi

            continue
        fi

        # Check for ENDUNLESS tags
        if [[ "$line" =~ \{\{ENDUNLESS[[:space:]]+([a-z_]+)\}\} ]]; then
            ((nesting_level--))

            # Pop should_include from stack
            if [[ ${#stack_should_include[@]} -gt 0 ]]; then
                local last_index=$((${#stack_should_include[@]} - 1))
                should_include="${stack_should_include[$last_index]}"
                unset 'stack_should_include[$last_index]'
            else
                should_include=true
            fi

            continue
        fi

        # Include line if should_include is true
        if [[ "$should_include" == true ]]; then
            if [[ -z "$result" ]]; then
                result="$line"
            else
                result="$result"$'\n'"$line"
            fi
        fi
    done <<< "$content"

    # Check for unclosed conditionals
    if [[ $nesting_level -ne 0 ]]; then
        print_warning "Unclosed conditional block detected (nesting level: $nesting_level)"
    fi

    echo "$result"
}

# Process workflow replacements recursively
process_workflows() {
    local content=$1
    local base_dir=$2
    local profile=$3
    local processed_files=$4

    # Process each workflow reference
    local workflow_refs=$(echo "$content" | grep -o '{{workflows/[^}]*}}' | sort -u)

    while IFS= read -r workflow_ref; do
        if [[ -z "$workflow_ref" ]]; then
            continue
        fi

        local workflow_path=$(echo "$workflow_ref" | sed 's/{{workflows\///' | sed 's/}}//')

        # Avoid infinite recursion
        if [[ " $processed_files " == *" $workflow_path "* ]]; then
            print_warning "Circular workflow reference detected: $workflow_path"
            continue
        fi

        # Get workflow file
        local workflow_file=$(get_profile_file "$profile" "workflows/${workflow_path}.md" "$base_dir")

        if [[ -f "$workflow_file" ]]; then
            local workflow_content=$(cat "$workflow_file")

            # Recursively process nested workflows
            workflow_content=$(process_workflows "$workflow_content" "$base_dir" "$profile" "$processed_files $workflow_path")

            # Create temp files for safe replacement
            local temp_content=$(mktemp)
            local temp_replacement=$(mktemp)
            echo "$content" > "$temp_content"
            echo "$workflow_content" > "$temp_replacement"

            # Use perl to do the replacement without escaping newlines
            content=$(perl -e '
                use strict;
                use warnings;

                my $ref = $ARGV[0];
                my $replacement_file = $ARGV[1];
                my $content_file = $ARGV[2];

                # Read replacement content
                open(my $fh, "<", $replacement_file) or die $!;
                my $replacement = do { local $/; <$fh> };
                close($fh);

                # Read main content
                open($fh, "<", $content_file) or die $!;
                my $content = do { local $/; <$fh> };
                close($fh);

                # Do the replacement - use quotemeta on entire reference
                my $pattern = quotemeta($ref);
                $content =~ s/$pattern/$replacement/g;

                print $content;
            ' "$workflow_ref" "$temp_replacement" "$temp_content")

            rm -f "$temp_content" "$temp_replacement"
        else
            # Instead of printing warning to stderr, insert it into the content
            local warning_msg="⚠️ This workflow file was not found in your Agent OS base installation at ~/agent-os/profiles/$profile/workflows/${workflow_path}.md"
            # Use perl for safer replacement with special characters
            local temp_content=$(mktemp)
            echo "$content" > "$temp_content"
            content=$(perl -pe "s|\Q$workflow_ref\E|$workflow_ref\n$warning_msg|g" "$temp_content")
            rm -f "$temp_content"
        fi
    done <<< "$workflow_refs"

    echo "$content"
}

# Process standards replacements
process_standards() {
    local content=$1
    local base_dir=$2
    local profile=$3
    local standards_patterns=$4

    local standards_list=""

    echo "$standards_patterns" | while read pattern; do
        if [[ -z "$pattern" ]]; then
            continue
        fi

        local base_path=$(echo "$pattern" | sed 's/\*//')

        if [[ "$pattern" == *"*"* ]]; then
            # Wildcard pattern - find all files
            local search_dir="standards/$base_path"
            get_profile_files "$profile" "$base_dir" "$search_dir" | while read file; do
                if [[ "$file" == standards/* ]] && [[ "$file" == *.md ]]; then
                    echo "@agent-os/$file"
                fi
            done
        else
            # Specific file
            local file_path="standards/${pattern}.md"
            local full_file=$(get_profile_file "$profile" "$file_path" "$base_dir")
            if [[ -f "$full_file" ]]; then
                echo "@agent-os/$file_path"
            fi
        fi
    done | sort -u
}

# Process PHASE tag replacements in command files
# Embeds the content of referenced files with H1 headers
process_phase_tags() {
    local content=$1
    local base_dir=$2
    local profile=$3
    local mode=$4  # "embed" or empty (no processing)

    # If no mode specified, return content unchanged
    if [[ -z "$mode" ]]; then
        echo "$content"
        return 0
    fi

    # Find all PHASE tags: {{PHASE X: @agent-os/commands/path/to/file.md}}
    local phase_refs=$(echo "$content" | grep -o '{{PHASE [^}]*}}' | sort -u)

    if [[ -z "$phase_refs" ]]; then
        echo "$content"
        return 0
    fi

    while IFS= read -r phase_ref; do
        if [[ -z "$phase_ref" ]]; then
            continue
        fi

        if [[ "$mode" == "embed" ]]; then
            # CASE A: Embed the file content with H1 header
            # Extract: {{PHASE 1: @agent-os/commands/plan-product/1-product-concept.md}}
            # To get: PHASE 1, plan-product/1-product-concept.md, "Product Concept"

            local phase_label=$(echo "$phase_ref" | sed 's/{{//' | sed 's/:.*$//')  # "PHASE 1"
            local file_ref=$(echo "$phase_ref" | sed 's/.*@agent-os\/commands\///' | sed 's/}}$//')  # "plan-product/1-product-concept.md"
            local file_name=$(basename "$file_ref" .md)  # "1-product-concept"

            # Convert "1-product-concept" to "Product Concept"
            local title=$(echo "$file_name" | sed 's/^[0-9]*-//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

            # Get the actual file path in the profile
            # Insert /single-agent/ into the path: create-tasks/1-file.md -> create-tasks/single-agent/1-file.md
            local cmd_name=$(dirname "$file_ref")
            local filename=$(basename "$file_ref")
            local source_file=$(get_profile_file "$profile" "commands/$cmd_name/single-agent/$filename" "$base_dir")

            if [[ -f "$source_file" ]]; then
                # Read the file content
                local file_content=$(cat "$source_file")

                # Process the file content through the compilation pipeline
                # (conditionals, workflows, standards) before embedding
                # Set compiled_single_command=true to exclude content wrapped in {{UNLESS compiled_single_command}}
                file_content=$(process_conditionals "$file_content" "${EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS:-true}" "${EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS:-true}" "true")
                file_content=$(process_workflows "$file_content" "$base_dir" "$profile" "")

                # Process standards replacements in the embedded file
                local standards_refs=$(echo "$file_content" | grep -o '{{standards/[^}]*}}' | sort -u)
                while IFS= read -r standards_ref; do
                    if [[ -z "$standards_ref" ]]; then
                        continue
                    fi

                    local standards_pattern=$(echo "$standards_ref" | sed 's/{{standards\///' | sed 's/}}//')
                    local standards_list=$(process_standards "$file_content" "$base_dir" "$profile" "$standards_pattern")

                    # Create temp files for the replacement
                    local temp_file_content=$(mktemp)
                    local temp_standards=$(mktemp)
                    echo "$file_content" > "$temp_file_content"
                    echo "$standards_list" > "$temp_standards"

                    # Use perl to replace without escaping newlines
                    file_content=$(perl -e '
                        use strict;
                        use warnings;

                        my $ref = $ARGV[0];
                        my $standards_file = $ARGV[1];
                        my $content_file = $ARGV[2];

                        # Read standards list
                        open(my $fh, "<", $standards_file) or die $!;
                        my $standards = do { local $/; <$fh> };
                        close($fh);
                        chomp $standards;

                        # Read content
                        open($fh, "<", $content_file) or die $!;
                        my $content = do { local $/; <$fh> };
                        close($fh);

                        # Do the replacement - use quotemeta on entire reference
                        my $pattern = quotemeta($ref);
                        $content =~ s/$pattern/$standards/g;

                        print $content;
                    ' "$standards_ref" "$temp_standards" "$temp_file_content")

                    rm -f "$temp_file_content" "$temp_standards"
                done <<< "$standards_refs"

                # Create the replacement text with H1 header
                local replacement="# $phase_label: $title"$'\n\n'"$file_content"

                # Replace the tag with the embedded content
                local temp_content=$(mktemp)
                local temp_replacement=$(mktemp)
                echo "$content" > "$temp_content"
                echo "$replacement" > "$temp_replacement"

                content=$(perl -e '
                    use strict;
                    use warnings;

                    my $ref = $ARGV[0];
                    my $replacement_file = $ARGV[1];
                    my $content_file = $ARGV[2];

                    # Read replacement
                    open(my $fh, "<", $replacement_file) or die $!;
                    my $replacement = do { local $/; <$fh> };
                    close($fh);
                    chomp $replacement;

                    # Read content
                    open($fh, "<", $content_file) or die $!;
                    my $content = do { local $/; <$fh> };
                    close($fh);

                    # Do the replacement - use quotemeta on the tag
                    my $pattern = quotemeta($ref);
                    $content =~ s/$pattern/$replacement/g;

                    print $content;
                ' "$phase_ref" "$temp_replacement" "$temp_content")

                rm -f "$temp_content" "$temp_replacement"
            else
                print_verbose "Warning: File not found for PHASE tag: $file_ref"
            fi
        fi

    done <<< "$phase_refs"

    echo "$content"
}

# Compile agent file with all replacements
compile_agent() {
    local source_file=$1
    local dest_file=$2
    local base_dir=$3
    local profile=$4
    local role_data=$5
    local phase_mode=${6:-""}  # Optional: "embed" to embed PHASE content, or empty for no processing

    local content=$(cat "$source_file")

    # Process role replacements if provided
    if [[ -n "$role_data" ]]; then
        # Process each role replacement using delimiter-based format
        local temp_role_data=$(mktemp)
        echo "$role_data" > "$temp_role_data"

        # Parse the delimiter-based format
        while IFS= read -r line; do
            if [[ "$line" =~ ^'<<<'(.+)'>>>'$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value=""

                # Read until we hit <<<END>>>
                while IFS= read -r value_line; do
                    if [[ "$value_line" == "<<<END>>>" ]]; then
                        break
                    fi
                    if [[ -n "$value" ]]; then
                        value="${value}"$'\n'"${value_line}"
                    else
                        value="${value_line}"
                    fi
                done

                if [[ -n "$key" ]]; then
                    # Create temp files for the replacement
                    local temp_content=$(mktemp)
                    local temp_value=$(mktemp)
                    echo "$content" > "$temp_content"
                    echo "$value" > "$temp_value"

                    # Use perl to replace without escaping newlines
                    content=$(perl -e '
                        use strict;
                        use warnings;

                        my $key = $ARGV[0];
                        my $value_file = $ARGV[1];
                        my $content_file = $ARGV[2];

                        # Read value
                        open(my $fh, "<", $value_file) or die $!;
                        my $value = do { local $/; <$fh> };
                        close($fh);
                        chomp $value;

                        # Read content
                        open($fh, "<", $content_file) or die $!;
                        my $content = do { local $/; <$fh> };
                        close($fh);

                        # Do the replacement - use quotemeta on entire pattern (no role. prefix)
                        my $pattern = quotemeta("{{" . $key . "}}");
                        $content =~ s/$pattern/$value/g;

                        print $content;
                    ' "$key" "$temp_value" "$temp_content")

                    rm -f "$temp_content" "$temp_value"
                fi
            fi
        done < "$temp_role_data"

        rm -f "$temp_role_data"
    fi

    # Process conditional compilation tags
    # Uses global variables: EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS, EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS
    # compiled_single_command=false for main file (will be true for embedded PHASE files)
    content=$(process_conditionals "$content" "${EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS:-true}" "${EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS:-true}" "false")

    # Process workflow replacements
    content=$(process_workflows "$content" "$base_dir" "$profile" "")

    # Process standards replacements
    local standards_refs=$(echo "$content" | grep -o '{{standards/[^}]*}}' | sort -u)

    while IFS= read -r standards_ref; do
        if [[ -z "$standards_ref" ]]; then
            continue
        fi

        local standards_pattern=$(echo "$standards_ref" | sed 's/{{standards\///' | sed 's/}}//')
        local standards_list=$(process_standards "$content" "$base_dir" "$profile" "$standards_pattern")

        # Create temp files for the replacement
        local temp_content=$(mktemp)
        local temp_standards=$(mktemp)
        echo "$content" > "$temp_content"
        echo "$standards_list" > "$temp_standards"

        # Use perl to replace without escaping newlines
        content=$(perl -e '
            use strict;
            use warnings;

            my $ref = $ARGV[0];
            my $standards_file = $ARGV[1];
            my $content_file = $ARGV[2];

            # Read standards list
            open(my $fh, "<", $standards_file) or die $!;
            my $standards = do { local $/; <$fh> };
            close($fh);
            chomp $standards;

            # Read content
            open($fh, "<", $content_file) or die $!;
            my $content = do { local $/; <$fh> };
            close($fh);

            # Do the replacement - use quotemeta on entire reference
            my $pattern = quotemeta($ref);
            $content =~ s/$pattern/$standards/g;

            print $content;
        ' "$standards_ref" "$temp_standards" "$temp_content")

        rm -f "$temp_content" "$temp_standards"
    done <<< "$standards_refs"

    # Process PHASE tag replacements
    content=$(process_phase_tags "$content" "$base_dir" "$profile" "$phase_mode")

    # Replace Playwright in tools
    if echo "$content" | grep -q "^tools:.*Playwright"; then
        local tools_line=$(echo "$content" | grep "^tools:")
        local new_tools_line=$(replace_playwright_tools "$tools_line")
        # Simple replacement since this is a single line
        content=$(echo "$content" | sed "s|^tools:.*$|$new_tools_line|")
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        # Show diff if file exists
        if [[ -f "$dest_file" ]]; then
            local old_content=$(cat "$dest_file")
            show_diff_preview "$old_content" "$content" "$dest_file"
        fi
        echo "$dest_file"
    else
        ensure_dir "$(dirname "$dest_file")"
        echo "$content" > "$dest_file"
        print_verbose "Compiled agent: $dest_file"
    fi
}

# Compile command file with all replacements
compile_command() {
    local source_file=$1
    local dest_file=$2
    local base_dir=$3
    local profile=$4
    local phase_mode=${5:-""}  # Optional: "embed" to embed PHASE content, or empty for no processing

    compile_agent "$source_file" "$dest_file" "$base_dir" "$profile" "" "$phase_mode"
}

# -----------------------------------------------------------------------------
# Version Functions
# -----------------------------------------------------------------------------

# Compare versions (returns 0 if compatible, 1 if not)
check_version_compatibility() {
    local base_version=$1
    local project_version=$2

    # Extract major version
    local base_major=$(echo "$base_version" | cut -d'.' -f1)
    local project_major=$(echo "$project_version" | cut -d'.' -f1)

    if [[ "$base_major" != "$project_major" ]]; then
        return 1
    fi

    return 0
}

# Check if project needs migration to 2.1.0
check_needs_migration() {
    local project_version=$1

    # Empty or missing version needs migration
    if [[ -z "$project_version" ]]; then
        return 0  # needs migration
    fi

    # Parse version components
    local major=$(echo "$project_version" | cut -d'.' -f1)
    local minor=$(echo "$project_version" | cut -d'.' -f2)

    # Check if < 2.1.0
    if [[ "$major" -lt 2 ]]; then
        return 0  # needs migration
    elif [[ "$major" -eq 2 ]] && [[ "$minor" -lt 1 ]]; then
        return 0  # needs migration
    fi

    return 1  # no migration needed
}

# -----------------------------------------------------------------------------
# Installation Check Functions
# -----------------------------------------------------------------------------

# Check if Agent OS is installed in project
is_agent_os_installed() {
    local project_dir=$1

    if [[ -f "$project_dir/agent-os/config.yml" ]]; then
        return 0
    else
        return 1
    fi
}

# Get project installation config
get_project_config() {
    local project_dir=$1
    local key=$2

    get_yaml_value "$project_dir/agent-os/config.yml" "$key" ""
}

# -----------------------------------------------------------------------------
# Validation Functions (Common to both scripts)
# -----------------------------------------------------------------------------

# Validate base installation exists
validate_base_installation() {
    if [[ ! -d "$BASE_DIR" ]]; then
        echo ""
        print_error_with_context \
            "Agent OS base installation not found" \
            "Expected location: $BASE_DIR" \
            "Run base installation: curl -sSL https://raw.githubusercontent.com/buildermethods/agent-os/main/scripts/base-install.sh | bash"
        echo ""
        exit 1
    fi

    if [[ ! -f "$BASE_DIR/config.yml" ]]; then
        echo ""
        print_error_with_context \
            "Base installation config.yml not found" \
            "Expected location: $BASE_DIR/config.yml" \
            "Your base installation may be corrupted. Try running base-install.sh again."
        echo ""
        exit 1
    fi

    print_verbose "Base installation found at: $BASE_DIR"
}

# Check if current directory is the base installation directory
check_not_base_installation() {
    if [[ -f "$PROJECT_DIR/agent-os/config.yml" ]]; then
        if grep -q "base_install: true" "$PROJECT_DIR/agent-os/config.yml"; then
            echo ""
            print_error_with_context \
                "Cannot install Agent OS in base installation directory" \
                "You are currently in: $PROJECT_DIR (appears to be base installation)" \
                "Navigate to your project directory: cd /path/to/your/project && ~/agent-os/scripts/project-install.sh"
            echo ""
            exit 1
        fi
    fi
}

# -----------------------------------------------------------------------------
# Argument Parsing Helpers
# -----------------------------------------------------------------------------

# Parse boolean flag value
# Outputs: "value shift_count" (e.g., "true 1" or "false 2")
parse_bool_flag() {
    local current_value=$1
    local next_value=$2

    if [[ "$next_value" == "true" ]] || [[ "$next_value" == "false" ]]; then
        echo "$next_value 2"
    else
        echo "true 1"
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Configuration Loading Helpers
# -----------------------------------------------------------------------------

# Apply preset configuration
# Returns configuration values for a given preset
apply_preset() {
    local preset=$1

    case "$preset" in
        "claude-code-full")
            # Claude Code with all features (recommended)
            echo "claude_code_commands=true"
            echo "use_claude_code_subagents=true"
            echo "agent_os_commands=false"
            echo "standards_as_claude_code_skills=true"
            ;;
        "claude-code-simple")
            # Claude Code without subagents or Skills
            echo "claude_code_commands=true"
            echo "use_claude_code_subagents=false"
            echo "agent_os_commands=false"
            echo "standards_as_claude_code_skills=false"
            ;;
        "claude-code-basic")
            # Minimal Claude Code setup
            echo "claude_code_commands=true"
            echo "use_claude_code_subagents=false"
            echo "agent_os_commands=false"
            echo "standards_as_claude_code_skills=false"
            ;;
        "cursor")
            # Optimized for Cursor and similar tools
            echo "claude_code_commands=false"
            echo "use_claude_code_subagents=false"
            echo "agent_os_commands=true"
            echo "standards_as_claude_code_skills=false"
            ;;
        "multi-tool")
            # Both Claude Code and agent-os formats
            echo "claude_code_commands=true"
            echo "use_claude_code_subagents=true"
            echo "agent_os_commands=true"
            echo "standards_as_claude_code_skills=false"
            ;;
        "custom"|"")
            # No preset - use manual configuration
            echo "preset=custom"
            ;;
        *)
            # Unknown preset - warn and use custom
            print_warning "Unknown preset '$preset' - using custom configuration"
            echo "preset=custom"
            ;;
    esac
}

# Load base installation configuration
load_base_config() {
    BASE_VERSION=$(get_yaml_value "$BASE_DIR/config.yml" "version" "2.1.0")
    BASE_PROFILE=$(get_yaml_value "$BASE_DIR/config.yml" "profile" "default")

    # Check for preset configuration (command line override takes precedence)
    local preset="${PRESET_OVERRIDE:-$(get_yaml_value "$BASE_DIR/config.yml" "preset" "custom")}"

    if [[ "$preset" != "custom" ]] && [[ -n "$preset" ]]; then
        # Apply preset defaults
        print_verbose "Applying preset: $preset"
        local preset_config=$(apply_preset "$preset")

        # Extract values from preset
        BASE_CLAUDE_CODE_COMMANDS=$(echo "$preset_config" | grep "claude_code_commands=" | cut -d= -f2)
        BASE_USE_CLAUDE_CODE_SUBAGENTS=$(echo "$preset_config" | grep "use_claude_code_subagents=" | cut -d= -f2)
        BASE_AGENT_OS_COMMANDS=$(echo "$preset_config" | grep "agent_os_commands=" | cut -d= -f2)
        BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS=$(echo "$preset_config" | grep "standards_as_claude_code_skills=" | cut -d= -f2)

        # Allow overrides from config file (if explicitly set)
        local file_claude_code=$(get_yaml_value "$BASE_DIR/config.yml" "claude_code_commands" "")
        local file_subagents=$(get_yaml_value "$BASE_DIR/config.yml" "use_claude_code_subagents" "")
        local file_agent_os=$(get_yaml_value "$BASE_DIR/config.yml" "agent_os_commands" "")
        local file_skills=$(get_yaml_value "$BASE_DIR/config.yml" "standards_as_claude_code_skills" "")

        # Only override if value exists in file (allows preset + selective overrides)
        [[ -n "$file_claude_code" ]] && BASE_CLAUDE_CODE_COMMANDS="$file_claude_code"
        [[ -n "$file_subagents" ]] && BASE_USE_CLAUDE_CODE_SUBAGENTS="$file_subagents"
        [[ -n "$file_agent_os" ]] && BASE_AGENT_OS_COMMANDS="$file_agent_os"
        [[ -n "$file_skills" ]] && BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS="$file_skills"
    else
        # No preset - use manual configuration from file
        BASE_CLAUDE_CODE_COMMANDS=$(get_yaml_value "$BASE_DIR/config.yml" "claude_code_commands" "true")
        BASE_USE_CLAUDE_CODE_SUBAGENTS=$(get_yaml_value "$BASE_DIR/config.yml" "use_claude_code_subagents" "true")
        BASE_AGENT_OS_COMMANDS=$(get_yaml_value "$BASE_DIR/config.yml" "agent_os_commands" "false")
        BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS=$(get_yaml_value "$BASE_DIR/config.yml" "standards_as_claude_code_skills" "false")
    fi

    # Check for old config flags to set variables for validation
    MULTI_AGENT_MODE=$(get_yaml_value "$BASE_DIR/config.yml" "multi_agent_mode" "")
    SINGLE_AGENT_MODE=$(get_yaml_value "$BASE_DIR/config.yml" "single_agent_mode" "")
    MULTI_AGENT_TOOL=$(get_yaml_value "$BASE_DIR/config.yml" "multi_agent_tool" "")
}

# Load project installation configuration
load_project_config() {
    PROJECT_VERSION=$(get_project_config "$PROJECT_DIR" "version")
    PROJECT_PROFILE=$(get_project_config "$PROJECT_DIR" "profile")
    PROJECT_CLAUDE_CODE_COMMANDS=$(get_project_config "$PROJECT_DIR" "claude_code_commands")
    PROJECT_USE_CLAUDE_CODE_SUBAGENTS=$(get_project_config "$PROJECT_DIR" "use_claude_code_subagents")
    PROJECT_AGENT_OS_COMMANDS=$(get_project_config "$PROJECT_DIR" "agent_os_commands")
    PROJECT_STANDARDS_AS_CLAUDE_CODE_SKILLS=$(get_project_config "$PROJECT_DIR" "standards_as_claude_code_skills")

    # Check for old config flags to set variables for validation
    MULTI_AGENT_MODE=$(get_project_config "$PROJECT_DIR" "multi_agent_mode")
    SINGLE_AGENT_MODE=$(get_project_config "$PROJECT_DIR" "single_agent_mode")
    MULTI_AGENT_TOOL=$(get_project_config "$PROJECT_DIR" "multi_agent_tool")
}

# Validate configuration
validate_config() {
    local claude_code_commands=$1
    local use_claude_code_subagents=$2
    local agent_os_commands=$3
    local standards_as_claude_code_skills=$4
    local profile=$5
    local print_warnings=${6:-true}  # Default to true if not provided

    # Validate at least one output is enabled
    if [[ "$claude_code_commands" != "true" ]] && [[ "$agent_os_commands" != "true" ]]; then
        echo ""
        print_error_with_context \
            "Invalid configuration: No output target enabled" \
            "Both 'claude_code_commands' and 'agent_os_commands' are set to false" \
            "Edit $BASE_DIR/config.yml and set at least one to 'true'"
        echo ""
        exit 1
    fi

    # Validate subagents require Claude Code
    if [[ "$use_claude_code_subagents" == "true" ]] && [[ "$claude_code_commands" != "true" ]]; then
        if [[ "$print_warnings" == "true" ]]; then
            print_warning "use_claude_code_subagents requires claude_code_commands to be true"
            print_warning "Ignoring subagent setting"
        fi
    fi

    # Validate standards as skills require Claude Code
    if [[ "$standards_as_claude_code_skills" == "true" ]] && [[ "$claude_code_commands" != "true" ]]; then
        if [[ "$print_warnings" == "true" ]]; then
            print_warning "standards_as_claude_code_skills requires claude_code_commands to be true"
            print_warning "Treating standards_as_claude_code_skills as false"
        fi
        # Set global variable to override the effective value
        EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS="false"
    fi

    # Validate profile exists
    if [[ ! -d "$BASE_DIR/profiles/$profile" ]]; then
        echo ""
        print_error_with_context \
            "Profile '$profile' not found" \
            "Expected location: $BASE_DIR/profiles/$profile/" \
            "Run './scripts/create-profile.sh' to create it, or check 'profile' setting in $BASE_DIR/config.yml"
        echo ""
        # List available profiles to help user
        if [[ -d "$BASE_DIR/profiles" ]]; then
            echo "  Available profiles:"
            for dir in "$BASE_DIR/profiles"/*/ ; do
                if [[ -d "$dir" ]]; then
                    basename "$dir"
                fi
            done | sed 's/^/    - /'
            echo ""
        fi
        exit 1
    fi
}

# Create or update project config.yml
write_project_config() {
    local version=$1
    local profile=$2
    local claude_code_commands=$3
    local use_claude_code_subagents=$4
    local agent_os_commands=$5
    local standards_as_claude_code_skills=$6
    local dest="$PROJECT_DIR/agent-os/config.yml"

    local config_content="version: $version
last_compiled: $(date '+%Y-%m-%d %H:%M:%S')

# ================================================
# Compiled with the following settings:
#
# To change these settings, run ~/agent-os/scripts/project-update.sh to re-compile your project with the new settings.
# ================================================
profile: $profile
claude_code_commands: $claude_code_commands
use_claude_code_subagents: $use_claude_code_subagents
agent_os_commands: $agent_os_commands
standards_as_claude_code_skills: $standards_as_claude_code_skills"

    local result=$(write_file "$config_content" "$dest")
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "$dest"
    fi
}

# -----------------------------------------------------------------------------
# Claude Code Skills Functions
# -----------------------------------------------------------------------------

# Convert filename to human-readable name with acronym handling
# Returns lowercase with acronyms in uppercase
# Example: "api-design.md" -> "API design"
#          "frontend/css.md" -> "frontend CSS"
#          "rest-api-conventions.md" -> "REST API conventions"
convert_filename_to_human_name() {
    local filename=$1

    # List of common acronyms to preserve in uppercase
    local acronyms=("API" "CSS" "HTML" "SQL" "REST" "JSON" "XML" "HTTP" "HTTPS" "URL" "URI" "CLI" "GUI" "IDE" "SDK" "JWT")

    # Remove .md extension
    local name=$(echo "$filename" | sed 's/\.md$//')

    # Replace hyphens, underscores, and slashes with spaces
    name=$(echo "$name" | sed 's|[-_/]| |g')

    # Convert to lowercase first
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Replace known acronyms with uppercase version
    # Match all case variations: lowercase, Capitalized, UPPERCASE
    for acronym in "${acronyms[@]}"; do
        local lowercase=$(echo "$acronym" | tr '[:upper:]' '[:lower:]')
        local capitalized=$(echo "$lowercase" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

        # Replace all variations with the uppercase acronym
        # Use Perl for portable word boundary matching (\b works consistently across platforms)
        name=$(echo "$name" | perl -pe "s/\\b$lowercase\\b/$acronym/g")
        name=$(echo "$name" | perl -pe "s/\\b$capitalized\\b/$acronym/g")
        name=$(echo "$name" | perl -pe "s/\\b$acronym\\b/$acronym/g")
    done

    echo "$name"
}

# Convert filename to human-readable name with title case and acronym handling
# Returns title case with acronyms in uppercase
# Example: "api-design.md" -> "API Design"
#          "frontend/css.md" -> "Frontend CSS"
#          "rest-api-conventions.md" -> "REST API Conventions"
convert_filename_to_human_name_capitalized() {
    local filename=$1

    # List of common acronyms to preserve in uppercase
    local acronyms=("API" "CSS" "HTML" "SQL" "REST" "JSON" "XML" "HTTP" "HTTPS" "URL" "URI" "CLI" "GUI" "IDE" "SDK" "JWT")

    # Remove .md extension
    local name=$(echo "$filename" | sed 's/\.md$//')

    # Replace hyphens, underscores, and slashes with spaces
    name=$(echo "$name" | sed 's|[-_/]| |g')

    # Capitalize first letter of each word
    name=$(echo "$name" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')

    # Replace known acronyms with uppercase version
    # Match all case variations: lowercase, Capitalized, UPPERCASE
    for acronym in "${acronyms[@]}"; do
        local lowercase=$(echo "$acronym" | tr '[:upper:]' '[:lower:]')
        local capitalized=$(echo "$lowercase" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

        # Replace all variations with the uppercase acronym
        # Use Perl for portable word boundary matching (\b works consistently across platforms)
        name=$(echo "$name" | perl -pe "s/\\b$lowercase\\b/$acronym/g")
        name=$(echo "$name" | perl -pe "s/\\b$capitalized\\b/$acronym/g")
        name=$(echo "$name" | perl -pe "s/\\b$acronym\\b/$acronym/g")
    done
    echo "$name"
}

# Create a Claude Code Skill from a standards file
# Args: $1=standards file path (relative to profile, e.g., "standards/frontend/css.md")
#       $2=dest base directory (project directory)
#       $3=base directory (~/agent-os)
#       $4=profile name
create_standard_skill() {
    local standards_file=$1
    local dest_base=$2
    local base_dir=$3
    local profile=$4

    # Remove "standards/" prefix and ".md" extension for skill directory name
    # Convert path separators to hyphens
    # Example: "standards/frontend/css.md" -> "frontend-css"
    local skill_name=$(echo "$standards_file" | sed 's|^standards/||' | sed 's|\.md$||' | sed 's|/|-|g')

    # Get human-readable name from the full path (excluding "standards/")
    # Example: "standards/frontend/css.md" -> "frontend CSS" (lowercase)
    local path_without_standards=$(echo "$standards_file" | sed 's|^standards/||')
    local human_name=$(convert_filename_to_human_name "$path_without_standards")
    local human_name_capitalized=$(convert_filename_to_human_name_capitalized "$path_without_standards")

    # Create skill directory (directly in .claude/skills/, not in agent-os subfolder)
    local skill_dir="$dest_base/.claude/skills/$skill_name"
    ensure_dir "$skill_dir"

    # Get the skill template from the profile
    local template_file=$(get_profile_file "$profile" "claude-code-skill-template.md" "$base_dir")
    if [[ ! -f "$template_file" ]]; then
        print_error "Skill template not found: $template_file"
        return 1
    fi

    # Prepend agent-os/ to the standards file path for the file reference
    local standard_file_path_with_prefix="agent-os/$standards_file"

    # Read template and replace placeholders
    local skill_content=$(cat "$template_file")
    skill_content=$(echo "$skill_content" | sed "s|{{standard_name_humanized}}|$human_name|g")
    skill_content=$(echo "$skill_content" | sed "s|{{standard_name_humanized_capitalized}}|$human_name_capitalized|g")
    skill_content=$(echo "$skill_content" | sed "s|{{standard_file_path}}|$standard_file_path_with_prefix|g")

    # Write SKILL.md
    local skill_file="$skill_dir/SKILL.md"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "$skill_file"
    else
        echo "$skill_content" > "$skill_file"
        print_verbose "Created skill: $skill_file"
    fi
}

# Install Claude Code Skills from standards files
install_claude_code_skills() {
    # Only install skills if both flags are enabled
    if [[ "$EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS" != "true" ]] || [[ "$EFFECTIVE_CLAUDE_CODE_COMMANDS" != "true" ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Installing Claude Code Skills..."
    fi

    local skills_count=0

    # Get all standards files for the current profile
    while read file; do
        if [[ "$file" == standards/* ]] && [[ "$file" == *.md ]]; then
            # Create skill from this standards file
            create_standard_skill "$file" "$PROJECT_DIR" "$BASE_DIR" "$EFFECTIVE_PROFILE"

            # Track the skill file for dry run
            local skill_name=$(echo "$file" | sed 's|^standards/||' | sed 's|\.md$||' | sed 's|/|-|g')
            local skill_file="$PROJECT_DIR/.claude/skills/$skill_name/SKILL.md"
            if [[ "$DRY_RUN" == "true" ]]; then
                INSTALLED_FILES+=("$skill_file")
            fi
            ((skills_count++)) || true
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "standards")

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ $skills_count -gt 0 ]]; then
            echo "✓ Installed $skills_count Claude Code Skills"
            echo -e "${YELLOW}  👉 Be sure to run the /improve-skills command next using Claude Code${NC}"
        fi
    fi
}

# Install improve-skills command (only when Skills are enabled)
install_improve_skills_command() {
    # Only install if both Claude Code commands AND Skills are enabled
    if [[ "$EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS" != "true" ]] || [[ "$EFFECTIVE_CLAUDE_CODE_COMMANDS" != "true" ]]; then
        return 0
    fi

    local target_dir="$PROJECT_DIR/.claude/commands/agent-os"
    mkdir -p "$target_dir"

    # Find the improve-skills command file
    local source_file=$(get_profile_file "$EFFECTIVE_PROFILE" "commands/improve-skills/improve-skills.md" "$BASE_DIR")

    if [[ -f "$source_file" ]]; then
        local dest="$target_dir/improve-skills.md"

        # Compile the command (with workflow and standards injection)
        local compiled=$(compile_command "$source_file" "$dest" "$BASE_DIR" "$EFFECTIVE_PROFILE")

        if [[ "$DRY_RUN" == "true" ]]; then
            INSTALLED_FILES+=("$dest")
        fi
    fi
}

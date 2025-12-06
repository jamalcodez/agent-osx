#!/bin/bash

# =============================================================================
# Agent OS Template Validator
# Validates template syntax in markdown files
# =============================================================================

# Note: We don't use 'set -e' here because validation functions
# may return non-zero status for errors, which we want to collect

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$HOME/agent-os"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# -----------------------------------------------------------------------------
# Validation Functions
# -----------------------------------------------------------------------------

validate_file_exists() {
    local file=$1

    if [[ ! -f "$file" ]]; then
        echo ""
        print_error_with_context \
            "File not found" \
            "Path: $file" \
            "Provide a valid file path to validate"
        echo ""
        exit 1
    fi
}

# Check for unclosed conditional blocks
check_conditionals() {
    local file=$1
    local errors=0
    local warnings=0

    # grep -c returns 0 when no matches, so we don't need || echo 0
    local if_count=$(grep -c "{{IF " "$file" 2>/dev/null)
    local endif_count=$(grep -c "{{ENDIF " "$file" 2>/dev/null)
    local unless_count=$(grep -c "{{UNLESS " "$file" 2>/dev/null)
    local endunless_count=$(grep -c "{{ENDUNLESS " "$file" 2>/dev/null)

    # Check IF/ENDIF balance
    if [[ $if_count -ne $endif_count ]]; then
        print_error "Unbalanced IF/ENDIF blocks: $if_count IF, $endif_count ENDIF"
        ((errors++))
    else
        if [[ $if_count -gt 0 ]]; then
            print_success "$if_count IF/ENDIF block(s) properly closed"
        fi
    fi

    # Check UNLESS/ENDUNLESS balance
    if [[ $unless_count -ne $endunless_count ]]; then
        print_error "Unbalanced UNLESS/ENDUNLESS blocks: $unless_count UNLESS, $endunless_count ENDUNLESS"
        ((errors++))
    else
        if [[ $unless_count -gt 0 ]]; then
            print_success "$unless_count UNLESS/ENDUNLESS block(s) properly closed"
        fi
    fi

    # Check for flag name consistency
    while IFS= read -r line; do
        if [[ "$line" =~ \{\{(IF|UNLESS)[[:space:]]+([a-zA-Z_]+)\}\} ]]; then
            local tag_type="${BASH_REMATCH[1]}"
            local flag_name="${BASH_REMATCH[2]}"
            local line_num=$(grep -n "$line" "$file" | cut -d: -f1 | head -1)

            # Look for matching closing tag
            if [[ "$tag_type" == "IF" ]]; then
                if ! grep -q "{{ENDIF $flag_name}}" "$file"; then
                    print_warning "IF block at line $line_num may be missing matching {{ENDIF $flag_name}}"
                    ((warnings++))
                fi
            else
                if ! grep -q "{{ENDUNLESS $flag_name}}" "$file"; then
                    print_warning "UNLESS block at line $line_num may be missing matching {{ENDUNLESS $flag_name}}"
                    ((warnings++))
                fi
            fi
        fi
    done < "$file"

    echo "errors=$errors warnings=$warnings"
}

# Check workflow references
check_workflow_refs() {
    local file=$1
    local profile=${2:-default}
    local errors=0
    local warnings=0
    local checked=0

    local workflow_refs=$(grep -o "{{workflows/[^}]*}}" "$file" 2>/dev/null || echo "")

    if [[ -z "$workflow_refs" ]]; then
        return
    fi

    while IFS= read -r ref; do
        if [[ -z "$ref" ]]; then
            continue
        fi

        ((checked++))
        local workflow_path=$(echo "$ref" | sed 's/{{workflows\///' | sed 's/}}//')
        local workflow_file="$BASE_DIR/profiles/$profile/workflows/${workflow_path}.md"

        if [[ -f "$workflow_file" ]]; then
            print_success "Workflow found: $workflow_path"
        else
            print_error "Workflow not found: $workflow_path"
            echo "  Expected: $workflow_file"
            ((errors++))
        fi
    done <<< "$workflow_refs"

    if [[ $checked -eq 0 ]]; then
        print_status "No workflow references found"
    fi

    echo "errors=$errors warnings=$warnings"
}

# Check standards references
check_standards_refs() {
    local file=$1
    local profile=${2:-default}
    local errors=0
    local warnings=0
    local checked=0

    local standards_refs=$(grep -o "{{standards/[^}]*}}" "$file" 2>/dev/null || echo "")

    if [[ -z "$standards_refs" ]]; then
        return
    fi

    while IFS= read -r ref; do
        if [[ -z "$ref" ]]; then
            continue
        fi

        ((checked++))
        local pattern=$(echo "$ref" | sed 's/{{standards\///' | sed 's/}}//')

        if [[ "$pattern" == *"*"* ]]; then
            # Wildcard pattern
            local base_path=$(echo "$pattern" | sed 's/\*//')
            local search_dir="$BASE_DIR/profiles/$profile/standards/$base_path"
            local match_count=0

            if [[ -d "$search_dir" ]]; then
                match_count=$(find "$search_dir" -name "*.md" 2>/dev/null | wc -l)
            fi

            if [[ $match_count -gt 0 ]]; then
                print_success "Standards pattern matches $match_count file(s): $pattern"
            else
                print_warning "Standards pattern matches 0 files: $pattern"
                ((warnings++))
            fi
        else
            # Specific file
            local standards_file="$BASE_DIR/profiles/$profile/standards/${pattern}"
            if [[ "$pattern" != *.md ]]; then
                standards_file="${standards_file}.md"
            fi

            if [[ -f "$standards_file" ]]; then
                print_success "Standards file found: $pattern"
            else
                print_error "Standards file not found: $pattern"
                echo "  Expected: $standards_file"
                ((errors++))
            fi
        fi
    done <<< "$standards_refs"

    if [[ $checked -eq 0 ]]; then
        print_status "No standards references found"
    fi

    echo "errors=$errors warnings=$warnings"
}

# Check PHASE tags
check_phase_tags() {
    local file=$1
    local profile=${2:-default}
    local errors=0
    local warnings=0
    local checked=0

    local phase_refs=$(grep -o "{{PHASE [0-9]*: @agent-os/[^}]*}}" "$file" 2>/dev/null || echo "")

    if [[ -z "$phase_refs" ]]; then
        return
    fi

    while IFS= read -r ref; do
        if [[ -z "$ref" ]]; then
            continue
        fi

        ((checked++))

        # Extract phase number and path
        if [[ "$ref" =~ \{\{PHASE\ ([0-9]+):\ @agent-os/(.+)\}\} ]]; then
            local phase_num="${BASH_REMATCH[1]}"
            local file_path="${BASH_REMATCH[2]}"
            local full_path="$BASE_DIR/profiles/$profile/$file_path"

            if [[ -f "$full_path" ]]; then
                print_success "PHASE $phase_num file found: $file_path"
            else
                print_error "PHASE $phase_num file not found: $file_path"
                echo "  Expected: $full_path"
                ((errors++))
            fi
        else
            print_error "Invalid PHASE tag syntax: $ref"
            ((errors++))
        fi
    done <<< "$phase_refs"

    if [[ $checked -eq 0 ]]; then
        print_status "No PHASE tags found"
    fi

    echo "errors=$errors warnings=$warnings"
}

# Check for common syntax errors
check_syntax_errors() {
    local file=$1
    local errors=0
    local warnings=0

    # Check for unclosed double braces
    local open_braces=$(grep -o "{{" "$file" | wc -l)
    local close_braces=$(grep -o "}}" "$file" | wc -l)

    if [[ $open_braces -ne $close_braces ]]; then
        print_error "Unbalanced braces: $open_braces opening {{, $close_braces closing }}"
        ((errors++))
    fi

    # Check for typos in common tags
    if grep -q "{{ENDF " "$file" 2>/dev/null; then
        print_warning "Found '{{ENDF' - did you mean '{{ENDIF'?"
        ((warnings++))
    fi

    if grep -q "{{ENDUNLES " "$file" 2>/dev/null; then
        print_warning "Found '{{ENDUNLES' - did you mean '{{ENDUNLESS'?"
        ((warnings++))
    fi

    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        print_success "No common syntax errors found"
    fi

    echo "errors=$errors warnings=$warnings"
}

# -----------------------------------------------------------------------------
# Main Validation Function
# -----------------------------------------------------------------------------

validate_template() {
    local file=$1
    local profile=${2:-default}

    print_section "Validating Template: $(basename "$file")"

    local total_errors=0
    local total_warnings=0

    # Check file exists
    validate_file_exists "$file"

    echo ""
    print_status "Checking conditional blocks..."
    result=$(check_conditionals "$file")
    local errors=$(echo "$result" | grep -o "errors=[0-9]*" | cut -d= -f2)
    local warnings=$(echo "$result" | grep -o "warnings=[0-9]*" | cut -d= -f2)
    ((total_errors += errors))
    ((total_warnings += warnings))

    echo ""
    print_status "Checking workflow references..."
    result=$(check_workflow_refs "$file" "$profile")
    errors=$(echo "$result" | grep -o "errors=[0-9]*" | cut -d= -f2)
    warnings=$(echo "$result" | grep -o "warnings=[0-9]*" | cut -d= -f2)
    ((total_errors += errors))
    ((total_warnings += warnings))

    echo ""
    print_status "Checking standards references..."
    result=$(check_standards_refs "$file" "$profile")
    errors=$(echo "$result" | grep -o "errors=[0-9]*" | cut -d= -f2)
    warnings=$(echo "$result" | grep -o "warnings=[0-9]*" | cut -d= -f2)
    ((total_errors += errors))
    ((total_warnings += warnings))

    echo ""
    print_status "Checking PHASE tags..."
    result=$(check_phase_tags "$file" "$profile")
    errors=$(echo "$result" | grep -o "errors=[0-9]*" | cut -d= -f2)
    warnings=$(echo "$result" | grep -o "warnings=[0-9]*" | cut -d= -f2)
    ((total_errors += errors))
    ((total_warnings += warnings))

    echo ""
    print_status "Checking for syntax errors..."
    result=$(check_syntax_errors "$file")
    errors=$(echo "$result" | grep -o "errors=[0-9]*" | cut -d= -f2)
    warnings=$(echo "$result" | grep -o "warnings=[0-9]*" | cut -d= -f2)
    ((total_errors += errors))
    ((total_warnings += warnings))

    # Print summary
    echo ""
    print_section "Validation Summary"
    echo ""

    if [[ $total_errors -eq 0 && $total_warnings -eq 0 ]]; then
        print_success "✓ Template is valid! No errors or warnings."
        echo ""
        return 0
    elif [[ $total_errors -eq 0 ]]; then
        print_warning "Template has $total_warnings warning(s) but no errors"
        echo ""
        return 0
    else
        print_error "Template has $total_errors error(s) and $total_warnings warning(s)"
        echo ""
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

show_help() {
    cat << EOF
Usage: $0 [OPTIONS] FILE

Validate Agent OS template syntax in markdown files.

Arguments:
    FILE                    Path to template file to validate

Options:
    --profile PROFILE       Profile to use for validation (default: default)
    -h, --help             Show this help message

Examples:
    $0 profiles/default/commands/write-spec/write-spec.md
    $0 --profile custom profiles/custom/agents/implementer.md
    $0 .claude/commands/agent-os/implement-tasks.md

Checks performed:
    ✓ Conditional block balance (IF/ENDIF, UNLESS/ENDUNLESS)
    ✓ Workflow reference resolution
    ✓ Standards reference resolution
    ✓ PHASE tag syntax and file existence
    ✓ Common syntax errors (unclosed braces, typos)

See profiles/default/TEMPLATE_SYNTAX.md for full documentation.
EOF
    exit 0
}

# Parse arguments
FILE=""
PROFILE="default"

while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            if [[ -z "$FILE" ]]; then
                FILE="$1"
            else
                print_error "Unknown argument: $1"
                echo ""
                echo "Run with --help for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$FILE" ]]; then
    print_error "No file specified"
    echo ""
    echo "Usage: $0 [OPTIONS] FILE"
    echo "Run with --help for more information"
    echo ""
    exit 1
fi

# Run validation
validate_template "$FILE" "$PROFILE"

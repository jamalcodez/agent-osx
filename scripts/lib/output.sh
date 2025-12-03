#!/bin/bash

# =============================================================================
# Agent OS Output Functions
# Color printing and user-facing output utilities
# =============================================================================

# Colors for output
RED='\033[38;2;255;32;86m'
GREEN='\033[38;2;0;234;179m'
YELLOW='\033[38;2;255;185;0m'
BLUE='\033[38;2;0;208;255m'
PURPLE='\033[38;2;142;81;255m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Basic Color Printing
# -----------------------------------------------------------------------------

# Print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Print section header
print_section() {
    echo ""
    print_color "$BLUE" "=== $1 ==="
    echo ""
}

# Print status message
print_status() {
    print_color "$BLUE" "$1"
}

# Print success message
print_success() {
    print_color "$GREEN" "✓ $1"
}

# Print warning message
print_warning() {
    print_color "$YELLOW" "⚠️  $1"
}

# Print error message
print_error() {
    print_color "$RED" "✗ $1"
}

# -----------------------------------------------------------------------------
# Contextual Error Messages
# -----------------------------------------------------------------------------

# Print error message with context and remedy
# Usage: print_error_with_context "error message" "context details" "how to fix"
print_error_with_context() {
    local error=$1
    local context=$2
    local remedy=$3

    print_color "$RED" "✗ ERROR: $error"
    if [[ -n "$context" ]]; then
        echo -e "  ${BLUE}Context:${NC} $context"
    fi
    if [[ -n "$remedy" ]]; then
        echo -e "  ${GREEN}Fix:${NC} $remedy"
    fi
}

# Print error with just a remedy (convenience function)
# Usage: print_error_with_remedy "error message" "how to fix"
print_error_with_remedy() {
    local error=$1
    local remedy=$2
    print_error_with_context "$error" "" "$remedy"
}

# -----------------------------------------------------------------------------
# Verbose Output
# -----------------------------------------------------------------------------

# Print verbose message (only in verbose mode)
print_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[VERBOSE] $1" >&2
    fi
}

# -----------------------------------------------------------------------------
# Diff Preview
# -----------------------------------------------------------------------------

# Show colored diff preview of file changes
# Usage: show_diff_preview "old_content" "new_content" "file_path"
show_diff_preview() {
    local old_content=$1
    local new_content=$2
    local file_path=$3

    # Create temp files for diff
    local temp_old=$(mktemp)
    local temp_new=$(mktemp)
    echo "$old_content" > "$temp_old"
    echo "$new_content" > "$temp_new"

    # Generate unified diff
    local diff_output=$(diff -u "$temp_old" "$temp_new" 2>/dev/null || true)

    # Clean up temp files
    rm -f "$temp_old" "$temp_new"

    # If no diff, skip
    if [[ -z "$diff_output" ]]; then
        return
    fi

    # Count changes
    local added=$(echo "$diff_output" | grep -c "^+" || true)
    local removed=$(echo "$diff_output" | grep -c "^-" || true)
    # Subtract header lines (---, +++)
    ((added = added > 0 ? added - 1 : 0)) || true
    ((removed = removed > 0 ? removed - 1 : 0)) || true

    # Show file header
    echo ""
    print_color "$PURPLE" "━━━ Changes to: $file_path ━━━"
    echo -e "${GREEN}+$added${NC} ${RED}-$removed${NC} lines"
    echo ""

    # Color-code and print diff
    echo "$diff_output" | while IFS= read -r line; do
        if [[ "$line" =~ ^--- ]]; then
            # Old file header - don't print (temp file path)
            continue
        elif [[ "$line" =~ ^\+\+\+ ]]; then
            # New file header - don't print (temp file path)
            continue
        elif [[ "$line" =~ ^@@ ]]; then
            # Chunk header
            print_color "$BLUE" "$line"
        elif [[ "$line" =~ ^\+ ]]; then
            # Addition
            print_color "$GREEN" "$line"
        elif [[ "$line" =~ ^- ]]; then
            # Deletion
            print_color "$RED" "$line"
        else
            # Context line
            echo "$line"
        fi
    done
    echo ""
}

# -----------------------------------------------------------------------------
# Progress Reporting
# -----------------------------------------------------------------------------

# Show progress counter for long operations
# Usage: show_progress "current" "total" "description"
show_progress() {
    local current=$1
    local total=$2
    local description=$3

    # Calculate percentage
    local percent=$(( current * 100 / total ))

    # Show progress on same line (carriage return)
    echo -ne "\r${BLUE}Progress: [${current}/${total}] ${percent}% - ${description}${NC}$(tput el)"
}

# Clear progress line and show completion
# Usage: clear_progress
clear_progress() {
    echo -ne "\r$(tput el)"
}

# Show progress with optional cache hit indicator
# Usage: show_compilation_progress "current" "total" "filename" "cache_hit"
show_compilation_progress() {
    local current=$1
    local total=$2
    local filename=$3
    local cache_hit=${4:-""}

    local status=""
    if [[ "$cache_hit" == "true" ]]; then
        status=" ${GREEN}[cached]${NC}"
    fi

    echo -ne "\r${BLUE}Compiling: [${current}/${total}]${NC} ${filename}${status}$(tput el)"
}


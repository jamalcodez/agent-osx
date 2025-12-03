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

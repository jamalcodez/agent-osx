#!/bin/bash

# Test helper functions and setup
# This file is sourced by test files

# Get the project root directory
AGENT_OS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export AGENT_OS_ROOT

# Source the common functions for testing
export BASE_DIR="$AGENT_OS_ROOT"
export VERBOSE="false"
export DRY_RUN="false"

# Source common functions
source "$AGENT_OS_ROOT/scripts/common-functions.sh"

# Create a temporary directory for test files
setup_test_dir() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export PROJECT_DIR="$TEST_TEMP_DIR"
}

# Clean up temporary directory
teardown_test_dir() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a mock YAML file for testing
create_test_yaml() {
    local file="$1"
    local content="$2"
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
}

# Strip color codes from output for easier testing
strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}

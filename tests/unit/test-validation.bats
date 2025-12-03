#!/usr/bin/env bats

# Test configuration validation functions

load '../test-helper'

setup() {
    setup_test_dir
    export BASE_DIR="$TEST_TEMP_DIR/base"
    mkdir -p "$BASE_DIR/profiles/default"
}

teardown() {
    teardown_test_dir
}

@test "validate_config: accepts valid configuration (both outputs enabled)" {
    run validate_config "true" "true" "true" "false" "default" "false"
    [ "$status" -eq 0 ]
}

@test "validate_config: accepts claude_code_commands only" {
    run validate_config "true" "false" "false" "false" "default" "false"
    [ "$status" -eq 0 ]
}

@test "validate_config: accepts agent_os_commands only" {
    run validate_config "false" "false" "true" "false" "default" "false"
    [ "$status" -eq 0 ]
}

@test "validate_config: rejects when both outputs disabled" {
    run validate_config "false" "false" "false" "false" "default" "false"
    [ "$status" -eq 1 ]
    echo "$output" | strip_colors | grep -qi "no output target"
}

@test "validate_config: rejects non-existent profile" {
    run validate_config "true" "false" "false" "false" "nonexistent" "false"
    [ "$status" -eq 1 ]
    echo "$output" | strip_colors | grep -qi "profile.*not found"
}

@test "validate_config: accepts existing profile" {
    mkdir -p "$BASE_DIR/profiles/custom"
    run validate_config "true" "false" "false" "false" "custom" "false"
    [ "$status" -eq 0 ]
}

@test "parse_bool_flag: parses explicit true" {
    result=$(parse_bool_flag "" "true")
    echo "$result" | grep -q "true 2"
}

@test "parse_bool_flag: parses explicit false" {
    result=$(parse_bool_flag "" "false")
    echo "$result" | grep -q "false 2"
}

@test "parse_bool_flag: defaults to true for non-bool" {
    result=$(parse_bool_flag "" "something")
    echo "$result" | grep -q "true 1"
}

@test "parse_bool_flag: defaults to true for empty" {
    result=$(parse_bool_flag "" "")
    echo "$result" | grep -q "true 1"
}

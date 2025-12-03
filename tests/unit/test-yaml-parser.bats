#!/usr/bin/env bats

# Test YAML parsing functions

load '../test-helper'

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "get_yaml_value: extracts simple key-value pair" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "version: 2.1.1"

    result=$(get_yaml_value "$TEST_TEMP_DIR/test.yml" "version" "")
    [ "$result" = "2.1.1" ]
}

@test "get_yaml_value: handles missing key with default" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "version: 2.1.1"

    result=$(get_yaml_value "$TEST_TEMP_DIR/test.yml" "missing_key" "default_value")
    [ "$result" = "default_value" ]
}

@test "get_yaml_value: handles quoted values" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "name: \"test profile\""

    result=$(get_yaml_value "$TEST_TEMP_DIR/test.yml" "name" "")
    [ "$result" = "test profile" ]
}

@test "get_yaml_value: handles boolean values" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "claude_code_commands: true"

    result=$(get_yaml_value "$TEST_TEMP_DIR/test.yml" "claude_code_commands" "")
    [ "$result" = "true" ]
}

@test "get_yaml_value: handles spaces around colon" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "profile  :   default"

    result=$(get_yaml_value "$TEST_TEMP_DIR/test.yml" "profile" "")
    [ "$result" = "default" ]
}

@test "get_yaml_value: handles tabs" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "$(printf 'version:\t2.1.1')"

    result=$(get_yaml_value "$TEST_TEMP_DIR/test.yml" "version" "")
    [ "$result" = "2.1.1" ]
}

@test "get_yaml_value: returns default for non-existent file" {
    result=$(get_yaml_value "$TEST_TEMP_DIR/nonexistent.yml" "key" "default")
    [ "$result" = "default" ]
}

@test "get_yaml_array: extracts array items" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "$(cat <<'EOF'
items:
  - first
  - second
  - third
EOF
)"

    result=$(get_yaml_array "$TEST_TEMP_DIR/test.yml" "items")
    [ "$(echo "$result" | wc -l)" -eq 3 ]
    echo "$result" | grep -q "first"
    echo "$result" | grep -q "second"
    echo "$result" | grep -q "third"
}

@test "get_yaml_array: handles empty array" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "$(cat <<'EOF'
items:
other_key: value
EOF
)"

    result=$(get_yaml_array "$TEST_TEMP_DIR/test.yml" "items")
    [ -z "$result" ]
}

@test "get_yaml_array: handles quoted array items" {
    create_test_yaml "$TEST_TEMP_DIR/test.yml" "$(cat <<'EOF'
items:
  - "first item"
  - 'second item'
EOF
)"

    result=$(get_yaml_array "$TEST_TEMP_DIR/test.yml" "items")
    echo "$result" | grep -q "first item"
    echo "$result" | grep -q "second item"
}

@test "normalize_name: converts to lowercase" {
    result=$(normalize_name "MyProfile")
    [ "$result" = "myprofile" ]
}

@test "normalize_name: replaces spaces with hyphens" {
    result=$(normalize_name "my profile name")
    [ "$result" = "my-profile-name" ]
}

@test "normalize_name: replaces underscores with hyphens" {
    result=$(normalize_name "my_profile_name")
    [ "$result" = "my-profile-name" ]
}

@test "normalize_name: removes special characters" {
    result=$(normalize_name "my-profile!@#")
    [ "$result" = "my-profile" ]
}

@test "normalize_name: handles mixed case and characters" {
    result=$(normalize_name "My_Profile Name!")
    [ "$result" = "my-profile-name" ]
}

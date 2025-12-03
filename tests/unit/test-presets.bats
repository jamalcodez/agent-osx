#!/usr/bin/env bats

# Test preset configuration system

load '../test-helper'

setup() {
    setup_test_dir
    export BASE_DIR="$TEST_TEMP_DIR/base"
    mkdir -p "$BASE_DIR"
}

teardown() {
    teardown_test_dir
}

@test "apply_preset: claude-code-full returns correct settings" {
    result=$(apply_preset "claude-code-full")
    echo "$result" | grep -q "claude_code_commands=true"
    echo "$result" | grep -q "use_claude_code_subagents=true"
    echo "$result" | grep -q "agent_os_commands=false"
    echo "$result" | grep -q "standards_as_claude_code_skills=true"
}

@test "apply_preset: claude-code-simple returns correct settings" {
    result=$(apply_preset "claude-code-simple")
    echo "$result" | grep -q "claude_code_commands=true"
    echo "$result" | grep -q "use_claude_code_subagents=false"
    echo "$result" | grep -q "agent_os_commands=false"
    echo "$result" | grep -q "standards_as_claude_code_skills=false"
}

@test "apply_preset: claude-code-basic returns correct settings" {
    result=$(apply_preset "claude-code-basic")
    echo "$result" | grep -q "claude_code_commands=true"
    echo "$result" | grep -q "use_claude_code_subagents=false"
    echo "$result" | grep -q "agent_os_commands=false"
    echo "$result" | grep -q "standards_as_claude_code_skills=false"
}

@test "apply_preset: cursor returns correct settings" {
    result=$(apply_preset "cursor")
    echo "$result" | grep -q "claude_code_commands=false"
    echo "$result" | grep -q "use_claude_code_subagents=false"
    echo "$result" | grep -q "agent_os_commands=true"
    echo "$result" | grep -q "standards_as_claude_code_skills=false"
}

@test "apply_preset: multi-tool returns correct settings" {
    result=$(apply_preset "multi-tool")
    echo "$result" | grep -q "claude_code_commands=true"
    echo "$result" | grep -q "use_claude_code_subagents=true"
    echo "$result" | grep -q "agent_os_commands=true"
    echo "$result" | grep -q "standards_as_claude_code_skills=false"
}

@test "apply_preset: custom returns custom indicator" {
    result=$(apply_preset "custom")
    echo "$result" | grep -q "preset=custom"
}

@test "apply_preset: empty preset returns custom" {
    result=$(apply_preset "")
    echo "$result" | grep -q "preset=custom"
}

@test "apply_preset: unknown preset warns and returns custom" {
    run apply_preset "nonexistent"
    echo "$output" | strip_colors | grep -qi "unknown preset"
    echo "$output" | grep -q "preset=custom"
}

@test "load_base_config: applies claude-code-full preset" {
    create_test_yaml "$BASE_DIR/config.yml" "$(cat <<'EOF'
version: 2.1.1
preset: claude-code-full
profile: default
EOF
)"

    load_base_config

    [ "$BASE_CLAUDE_CODE_COMMANDS" = "true" ]
    [ "$BASE_USE_CLAUDE_CODE_SUBAGENTS" = "true" ]
    [ "$BASE_AGENT_OS_COMMANDS" = "false" ]
    [ "$BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS" = "true" ]
}

@test "load_base_config: applies cursor preset" {
    create_test_yaml "$BASE_DIR/config.yml" "$(cat <<'EOF'
version: 2.1.1
preset: cursor
profile: default
EOF
)"

    load_base_config

    [ "$BASE_CLAUDE_CODE_COMMANDS" = "false" ]
    [ "$BASE_USE_CLAUDE_CODE_SUBAGENTS" = "false" ]
    [ "$BASE_AGENT_OS_COMMANDS" = "true" ]
    [ "$BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS" = "false" ]
}

@test "load_base_config: preset with override works" {
    create_test_yaml "$BASE_DIR/config.yml" "$(cat <<'EOF'
version: 2.1.1
preset: claude-code-full
claude_code_commands: false
profile: default
EOF
)"

    load_base_config

    # Preset would set to true, but override sets to false
    [ "$BASE_CLAUDE_CODE_COMMANDS" = "false" ]
    # Other preset values still apply
    [ "$BASE_USE_CLAUDE_CODE_SUBAGENTS" = "true" ]
    [ "$BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS" = "true" ]
}

@test "load_base_config: custom preset uses manual config" {
    create_test_yaml "$BASE_DIR/config.yml" "$(cat <<'EOF'
version: 2.1.1
preset: custom
claude_code_commands: true
use_claude_code_subagents: false
agent_os_commands: true
standards_as_claude_code_skills: false
profile: default
EOF
)"

    load_base_config

    [ "$BASE_CLAUDE_CODE_COMMANDS" = "true" ]
    [ "$BASE_USE_CLAUDE_CODE_SUBAGENTS" = "false" ]
    [ "$BASE_AGENT_OS_COMMANDS" = "true" ]
    [ "$BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS" = "false" ]
}

@test "load_base_config: no preset uses manual config" {
    create_test_yaml "$BASE_DIR/config.yml" "$(cat <<'EOF'
version: 2.1.1
claude_code_commands: false
use_claude_code_subagents: false
agent_os_commands: true
standards_as_claude_code_skills: false
profile: default
EOF
)"

    load_base_config

    [ "$BASE_CLAUDE_CODE_COMMANDS" = "false" ]
    [ "$BASE_USE_CLAUDE_CODE_SUBAGENTS" = "false" ]
    [ "$BASE_AGENT_OS_COMMANDS" = "true" ]
    [ "$BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS" = "false" ]
}

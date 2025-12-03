#!/usr/bin/env bats

# Test error handling functions

load '../test-helper'

@test "print_error: outputs error message" {
    run print_error "Test error message"
    [ "$status" -eq 0 ]
    echo "$output" | strip_colors | grep -q "✗ Test error message"
}

@test "print_error_with_context: outputs error with context" {
    run print_error_with_context "Error message" "Context info" "Fix instructions"
    [ "$status" -eq 0 ]
    echo "$output" | strip_colors | grep -q "✗ ERROR: Error message"
    echo "$output" | strip_colors | grep -q "Context: Context info"
    echo "$output" | strip_colors | grep -q "Fix: Fix instructions"
}

@test "print_error_with_context: handles empty context" {
    run print_error_with_context "Error message" "" "Fix instructions"
    [ "$status" -eq 0 ]
    echo "$output" | strip_colors | grep -q "✗ ERROR: Error message"
    echo "$output" | strip_colors | grep -q "Fix: Fix instructions"
    ! echo "$output" | grep -q "Context:"
}

@test "print_error_with_context: handles empty remedy" {
    run print_error_with_context "Error message" "Context info" ""
    [ "$status" -eq 0 ]
    echo "$output" | strip_colors | grep -q "✗ ERROR: Error message"
    echo "$output" | strip_colors | grep -q "Context: Context info"
    ! echo "$output" | grep -q "Fix:"
}

@test "print_error_with_remedy: outputs error with fix" {
    run print_error_with_remedy "Error message" "Fix instructions"
    [ "$status" -eq 0 ]
    echo "$output" | strip_colors | grep -q "✗ ERROR: Error message"
    echo "$output" | strip_colors | grep -q "Fix: Fix instructions"
    ! echo "$output" | grep -q "Context:"
}

@test "print_success: outputs success message" {
    run print_success "Test success"
    [ "$status" -eq 0 ]
    echo "$output" | strip_colors | grep -q "✓ Test success"
}

@test "print_warning: outputs warning message" {
    run print_warning "Test warning"
    [ "$status" -eq 0 ]
    echo "$output" | strip_colors | grep -q "⚠️  Test warning"
}

@test "print_status: outputs status message" {
    run print_status "Test status"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Test status"
}

@test "print_verbose: outputs when VERBOSE is true" {
    VERBOSE="true"
    run print_verbose "Test verbose message"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "\[VERBOSE\] Test verbose message"
}

@test "print_verbose: suppresses output when VERBOSE is false" {
    VERBOSE="false"
    run print_verbose "Test verbose message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

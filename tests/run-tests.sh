#!/bin/bash

# Agent OS Test Runner
# Runs all test suites and reports results

set -e

# Colors for output
RED='\033[38;2;255;32;86m'
GREEN='\033[38;2;0;234;179m'
YELLOW='\033[38;2;255;185;0m'
BLUE='\033[38;2;0;208;255m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}✗ ERROR: bats is not installed${NC}"
    echo ""
    echo "Please install bats-core first:"
    echo ""
    echo "  # macOS"
    echo "  brew install bats-core"
    echo ""
    echo "  # Ubuntu/Debian"
    echo "  sudo apt-get install bats"
    echo ""
    echo "  # From source"
    echo "  git clone https://github.com/bats-core/bats-core.git"
    echo "  cd bats-core"
    echo "  sudo ./install.sh /usr/local"
    echo ""
    exit 1
fi

echo -e "${BLUE}=== Agent OS Test Suite ===${NC}"
echo ""

# Parse arguments
VERBOSE=false
SPECIFIC_TEST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -t|--test)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose       Show detailed test output"
            echo "  -t, --test FILE     Run specific test file"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Run all tests"
            echo "  $0 -v                                 # Run with verbose output"
            echo "  $0 -t tests/unit/test-yaml-parser.bats  # Run specific test"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Build bats options
BATS_OPTS=""
if [[ "$VERBOSE" == "true" ]]; then
    BATS_OPTS="-t"
fi

# Track results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run tests and track results
run_test_suite() {
    local test_path=$1
    local suite_name=$2

    echo -e "${BLUE}Running $suite_name...${NC}"

    if bats $BATS_OPTS "$test_path" 2>&1; then
        echo -e "${GREEN}✓ $suite_name passed${NC}"
        return 0
    else
        echo -e "${RED}✗ $suite_name failed${NC}"
        return 1
    fi
    echo ""
}

# Run tests
if [[ -n "$SPECIFIC_TEST" ]]; then
    # Run specific test file
    if [[ ! -f "$SPECIFIC_TEST" ]]; then
        echo -e "${RED}✗ Test file not found: $SPECIFIC_TEST${NC}"
        exit 1
    fi

    echo "Running specific test: $SPECIFIC_TEST"
    echo ""
    bats $BATS_OPTS "$SPECIFIC_TEST"
    exit_code=$?
    echo ""

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ Tests passed${NC}"
    else
        echo -e "${RED}✗ Tests failed${NC}"
    fi

    exit $exit_code
else
    # Run all test suites
    echo "Running all tests..."
    echo ""

    # Unit tests
    if [[ -d "tests/unit" ]] && [[ $(ls -1 tests/unit/*.bats 2>/dev/null | wc -l) -gt 0 ]]; then
        echo -e "${BLUE}=== Unit Tests ===${NC}"
        for test_file in tests/unit/*.bats; do
            suite_name=$(basename "$test_file" .bats)
            if run_test_suite "$test_file" "$suite_name"; then
                ((PASSED_TESTS++)) || true
            else
                ((FAILED_TESTS++)) || true
            fi
            ((TOTAL_TESTS++)) || true
        done
        echo ""
    fi

    # Integration tests
    if [[ -d "tests/integration" ]] && [[ $(ls -1 tests/integration/*.bats 2>/dev/null | wc -l) -gt 0 ]]; then
        echo -e "${BLUE}=== Integration Tests ===${NC}"
        for test_file in tests/integration/*.bats; do
            suite_name=$(basename "$test_file" .bats)
            if run_test_suite "$test_file" "$suite_name"; then
                ((PASSED_TESTS++)) || true
            else
                ((FAILED_TESTS++)) || true
            fi
            ((TOTAL_TESTS++)) || true
        done
        echo ""
    fi

    # Print summary
    echo -e "${BLUE}=== Test Summary ===${NC}"
    echo "Total test suites: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"

    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo -e "${RED}Failed: $FAILED_TESTS${NC}"
        echo ""
        exit 1
    else
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        exit 0
    fi
fi

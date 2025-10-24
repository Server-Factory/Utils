#!/bin/bash

# Mail Server Factory - ISO Link Test Suite
# Automated tests for ISO download link validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR="$SCRIPT_DIR/validate_iso_links.sh"
CONFIG_FILE="$SCRIPT_DIR/distributions.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Test 1: Configuration file exists
test_config_exists() {
    log_test "Configuration file exists"
    if [ -f "$CONFIG_FILE" ]; then
        log_pass "Configuration file found: $CONFIG_FILE"
        return 0
    else
        log_fail "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
}

# Test 2: Validator script exists and is executable
test_validator_exists() {
    log_test "Validator script exists and is executable"
    if [ -x "$VALIDATOR" ]; then
        log_pass "Validator script is executable"
        return 0
    elif [ -f "$VALIDATOR" ]; then
        log_fail "Validator script exists but is not executable"
        return 1
    else
        log_fail "Validator script not found: $VALIDATOR"
        return 1
    fi
}

# Test 3: Configuration file has valid format
test_config_format() {
    log_test "Configuration file format is valid"
    local invalid_lines=0

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Check format: should have 5 fields separated by |
        local field_count=$(echo "$line" | awk -F'|' '{print NF}')
        if [ "$field_count" -ne 5 ]; then
            log_fail "Invalid format in line: $line (expected 5 fields, got $field_count)"
            invalid_lines=$((invalid_lines + 1))
        fi
    done < "$CONFIG_FILE"

    if [ $invalid_lines -eq 0 ]; then
        log_pass "Configuration format is valid"
        return 0
    else
        log_fail "Found $invalid_lines invalid line(s)"
        return 1
    fi
}

# Test 4: All URLs use HTTPS
test_https_urls() {
    log_test "All URLs use HTTPS protocol"
    local non_https=0

    while IFS='|' read -r distro version arch filename url; do
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        if [[ ! "$url" =~ ^https:// ]]; then
            log_fail "$distro $version: URL does not use HTTPS: $url"
            non_https=$((non_https + 1))
        fi
    done < "$CONFIG_FILE"

    if [ $non_https -eq 0 ]; then
        log_pass "All URLs use HTTPS"
        return 0
    else
        log_fail "Found $non_https non-HTTPS URL(s)"
        return 1
    fi
}

# Test 5: Run full validation
test_full_validation() {
    log_test "Running full ISO link validation"
    if "$VALIDATOR" > /dev/null 2>&1; then
        log_pass "All publicly accessible ISO links are valid"
        return 0
    else
        log_fail "Some ISO links are invalid or inaccessible"
        return 1
    fi
}

# Test 6: Configuration completeness
test_config_completeness() {
    log_test "Configuration includes all documented distributions"
    local expected_distros=(
        "UBUNTU"
        "CENTOS"
        "RHEL"
        "FEDORA"
        "DEBIAN"
        "ALMALINUX"
        "ROCKY"
        "OPENSUSE"
    )

    local missing=0
    for distro in "${expected_distros[@]}"; do
        if ! grep -q "^$distro|" "$CONFIG_FILE"; then
            log_fail "Distribution $distro not found in configuration"
            missing=$((missing + 1))
        fi
    done

    if [ $missing -eq 0 ]; then
        log_pass "All expected distributions are configured"
        return 0
    else
        log_fail "$missing distribution(s) missing from configuration"
        return 1
    fi
}

# Test 7: Ubuntu LTS versions present
test_ubuntu_lts() {
    log_test "Ubuntu LTS versions are present"
    local has_2204=false
    local has_2404=false

    while IFS='|' read -r distro version arch filename url; do
        [[ "$distro" != "UBUNTU" ]] && continue
        [[ "$version" =~ 22\.04 ]] && has_2204=true
        [[ "$version" =~ 24\.04 ]] && has_2404=true
    done < "$CONFIG_FILE"

    if [ "$has_2204" = true ] && [ "$has_2404" = true ]; then
        log_pass "Both Ubuntu 22.04 LTS and 24.04 LTS are present"
        return 0
    else
        log_fail "Missing Ubuntu LTS versions (22.04: $has_2204, 24.04: $has_2404)"
        return 1
    fi
}

# Main test execution
run_all_tests() {
    echo "========================================================================"
    echo "Mail Server Factory - ISO Link Test Suite"
    echo "========================================================================"
    echo ""

    test_config_exists
    test_validator_exists
    test_config_format
    test_https_urls
    test_config_completeness
    test_ubuntu_lts
    test_full_validation

    echo ""
    echo "========================================================================"
    echo "Test Summary"
    echo "========================================================================"
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo "========================================================================"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed!${NC}"
        return 1
    fi
}

# Run tests
run_all_tests

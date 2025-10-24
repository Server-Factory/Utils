#!/bin/bash

# Mail Server Factory - Recipe Coverage Test Suite
# Verifies that all supported distributions have corresponding recipe files
# Tests both host OS and destination OS coverage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/distributions.conf"
EXAMPLES_DIR="$PROJECT_ROOT/Examples"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Test 1: Examples directory exists
test_examples_directory() {
    log_test "Examples directory exists"
    if [ -d "$EXAMPLES_DIR" ]; then
        log_pass "Examples directory found: $EXAMPLES_DIR"
        return 0
    else
        log_fail "Examples directory not found: $EXAMPLES_DIR"
        return 1
    fi
}

# Test 2: All distributions in conf have recipe files
test_recipe_coverage() {
    log_test "All distributions have recipe files"

    local missing_recipes=()
    local checked_distros=()

    while IFS='|' read -r distro version arch filename url; do
        # Skip comments and empty lines
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        # Build expected recipe filename patterns
        local distro_lower=$(echo "$distro" | tr '[:upper:]' '[:lower:]')
        local version_clean=$(echo "$version" | tr '.' '_' | sed 's/-/_/g')

        # Check multiple possible naming patterns
        local found=false
        local patterns=(
            "${distro}*.json"
            "${distro_lower}*.json"
            "*${version}*.json"
            "*${version_clean}*.json"
        )

        for pattern in "${patterns[@]}"; do
            if compgen -G "$EXAMPLES_DIR/$pattern" > /dev/null 2>&1; then
                found=true
                break
            fi
        done

        if [ "$found" = false ]; then
            missing_recipes+=("$distro $version")
        fi

        checked_distros+=("$distro $version")

    done < "$CONFIG_FILE"

    if [ ${#missing_recipes[@]} -eq 0 ]; then
        log_pass "All ${#checked_distros[@]} distributions have recipe files"
        return 0
    else
        log_fail "Missing recipe files for ${#missing_recipes[@]} distribution(s):"
        for missing in "${missing_recipes[@]}"; do
            echo "  - $missing"
        done
        return 1
    fi
}

# Test 3: All recipe files are valid JSON
test_recipe_json_validity() {
    log_test "All recipe files are valid JSON"

    local invalid_files=()
    local total_files=0

    for recipe in "$EXAMPLES_DIR"/*.json; do
        [ -f "$recipe" ] || continue
        total_files=$((total_files + 1))

        if ! python3 -m json.tool "$recipe" > /dev/null 2>&1; then
            invalid_files+=("$(basename "$recipe")")
        fi
    done

    if [ ${#invalid_files[@]} -eq 0 ]; then
        log_pass "All $total_files recipe files are valid JSON"
        return 0
    else
        log_fail "${#invalid_files[@]} recipe file(s) have invalid JSON:"
        for invalid in "${invalid_files[@]}"; do
            echo "  - $invalid"
        done
        return 1
    fi
}

# Test 4: Required recipe structure
test_recipe_structure() {
    log_test "Recipe files have required structure"

    local invalid_structure=()
    local total_checked=0

    for recipe in "$EXAMPLES_DIR"/*.json; do
        [ -f "$recipe" ] || continue
        [[ "$(basename "$recipe")" == "_"* ]] && continue  # Skip private files

        total_checked=$((total_checked + 1))

        # Check for required fields
        if ! grep -q '"name"' "$recipe"; then
            invalid_structure+=("$(basename "$recipe"): missing 'name' field")
        fi

        if ! grep -q '"remote"' "$recipe"; then
            invalid_structure+=("$(basename "$recipe"): missing 'remote' field")
        fi
    done

    if [ ${#invalid_structure[@]} -eq 0 ]; then
        log_pass "All $total_checked recipe files have required structure"
        return 0
    else
        log_fail "${#invalid_structure[@]} recipe file(s) have invalid structure:"
        for invalid in "${invalid_structure[@]}"; do
            echo "  - $invalid"
        done
        return 1
    fi
}

# Test 5: Distribution family coverage
test_distribution_families() {
    log_test "All major distribution families are covered"

    local families=(
        "Debian:Ubuntu|Debian|Astra|Deepin|openKylin"
        "RHEL:CentOS|Fedora|AlmaLinux|Rocky|openEuler|ROSA"
        "SUSE:openSUSE"
        "ALT:ALT"
    )

    local missing_families=()

    for family_def in "${families[@]}"; do
        local family_name="${family_def%%:*}"
        local distros="${family_def#*:}"

        local found=false
        IFS='|' read -ra DISTRO_LIST <<< "$distros"
        for distro in "${DISTRO_LIST[@]}"; do
            if grep -qi "^$distro|" "$CONFIG_FILE"; then
                found=true
                break
            fi
        done

        if [ "$found" = false ]; then
            missing_families+=("$family_name")
        fi
    done

    if [ ${#missing_families[@]} -eq 0 ]; then
        log_pass "All major distribution families are covered"
        return 0
    else
        log_fail "Missing distribution families: ${missing_families[*]}"
        return 1
    fi
}

# Test 6: Russian distributions coverage
test_russian_distributions() {
    log_test "Russian Linux distributions are supported"

    local russian_distros=("ALTLINUX" "ASTRA" "ROSA")
    local found_count=0

    for distro in "${russian_distros[@]}"; do
        if grep -q "^$distro|" "$CONFIG_FILE"; then
            found_count=$((found_count + 1))
        fi
    done

    if [ $found_count -eq ${#russian_distros[@]} ]; then
        log_pass "All ${#russian_distros[@]} major Russian distributions supported"
        return 0
    else
        log_fail "Only $found_count/${#russian_distros[@]} Russian distributions found"
        echo "  Expected: ${russian_distros[*]}"
        return 1
    fi
}

# Test 7: Chinese distributions coverage
test_chinese_distributions() {
    log_test "Chinese Linux distributions are supported"

    local chinese_distros=("OPENEULER" "OPENKYLIN" "DEEPIN")
    local found_count=0

    for distro in "${chinese_distros[@]}"; do
        if grep -q "^$distro|" "$CONFIG_FILE"; then
            found_count=$((found_count + 1))
        fi
    done

    if [ $found_count -eq ${#chinese_distros[@]} ]; then
        log_pass "All ${#chinese_distros[@]} major Chinese distributions supported"
        return 0
    else
        log_fail "Only $found_count/${#chinese_distros[@]} Chinese distributions found"
        echo "  Expected: ${chinese_distros[*]}"
        return 1
    fi
}

# Test 8: Recipe files match distribution names
test_recipe_naming_convention() {
    log_test "Recipe files follow naming convention"

    local inconsistent_names=()

    while IFS='|' read -r distro version arch filename url; do
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        # Check if there's at least one recipe file matching the distro name
        local found=false
        for recipe in "$EXAMPLES_DIR"/*.json; do
            local recipe_name=$(basename "$recipe" .json)
            if echo "$recipe_name" | grep -qi "$distro"; then
                found=true
                break
            fi
        done

        if [ "$found" = false ]; then
            inconsistent_names+=("$distro: no matching recipe file")
        fi

    done < "$CONFIG_FILE"

    if [ ${#inconsistent_names[@]} -eq 0 ]; then
        log_pass "All distributions have appropriately named recipe files"
        return 0
    else
        log_fail "${#inconsistent_names[@]} distribution(s) lack matching recipe files:"
        for name in "${inconsistent_names[@]}"; do
            echo "  - $name"
        done
        return 1
    fi
}

# Test 9: No orphaned recipe files
test_no_orphaned_recipes() {
    log_test "No orphaned recipe files (recipes without distributions)"

    local orphaned_recipes=()

    for recipe in "$EXAMPLES_DIR"/*.json; do
        [ -f "$recipe" ] || continue
        local recipe_basename=$(basename "$recipe" .json)

        # Skip include files and special files
        [[ "$recipe_basename" == *"Include"* ]] && continue
        [[ "$recipe_basename" == "_"* ]] && continue
        [[ "$recipe_basename" == "Common" ]] && continue

        # Extract distro name from recipe filename
        local recipe_distro=$(echo "$recipe_basename" | sed 's/[_-][0-9].*//' | tr '[:lower:]' '[:upper:]')

        # Check if this distro exists in distributions.conf
        if ! grep -qi "^$recipe_distro" "$CONFIG_FILE"; then
            orphaned_recipes+=("$recipe_basename")
        fi
    done

    if [ ${#orphaned_recipes[@]} -eq 0 ]; then
        log_pass "No orphaned recipe files found"
        return 0
    else
        log_fail "${#orphaned_recipes[@]} orphaned recipe file(s) found:"
        for orphan in "${orphaned_recipes[@]}"; do
            echo "  - $orphan (no matching distribution in conf)"
        done
        return 1
    fi
}

# Test 10: Recipe hostname uniqueness
test_hostname_uniqueness() {
    log_test "Recipe hostnames are unique"

    local hostnames=()
    local duplicate_hostnames=()

    for recipe in "$EXAMPLES_DIR"/*.json; do
        [ -f "$recipe" ] || continue
        [[ "$(basename "$recipe")" == *"Include"* ]] && continue

        local hostname=$(grep -o '"HOSTNAME"[[:space:]]*:[[:space:]]*"[^"]*"' "$recipe" | sed 's/.*"\([^"]*\)".*/\1/' | head -1)

        if [ -n "$hostname" ]; then
            # Check for duplicates
            for existing in "${hostnames[@]}"; do
                if [ "$existing" = "$hostname" ]; then
                    duplicate_hostnames+=("$hostname (in $(basename "$recipe"))")
                fi
            done
            hostnames+=("$hostname")
        fi
    done

    if [ ${#duplicate_hostnames[@]} -eq 0 ]; then
        log_pass "All ${#hostnames[@]} recipe hostnames are unique"
        return 0
    else
        log_fail "${#duplicate_hostnames[@]} duplicate hostname(s) found:"
        for dup in "${duplicate_hostnames[@]}"; do
            echo "  - $dup"
        done
        return 1
    fi
}

# Generate coverage report
generate_coverage_report() {
    echo ""
    echo "========================================================================"
    log_info "Recipe Coverage Report"
    echo "========================================================================"

    local total_distros=$(grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$' | wc -l)
    local total_recipes=$(find "$EXAMPLES_DIR" -name "*.json" ! -name "*Include*" ! -name "_*" ! -name "Common.json" | wc -l)

    echo "Total distributions configured: $total_distros"
    echo "Total recipe files available:   $total_recipes"
    echo ""

    log_info "Distribution families:"
    echo "  • Debian-based:  $(grep -E '^(UBUNTU|DEBIAN|ASTRA|DEEPIN|OPENKYLIN)' "$CONFIG_FILE" | wc -l) distributions"
    echo "  • RHEL-based:    $(grep -E '^(CENTOS|FEDORA|ALMA|ROCKY|OPENEULER|ROSA)' "$CONFIG_FILE" | wc -l) distributions"
    echo "  • SUSE-based:    $(grep -E '^(OPENSUSE)' "$CONFIG_FILE" | wc -l) distributions"
    echo "  • ALT-based:     $(grep -E '^(ALTLINUX)' "$CONFIG_FILE" | wc -l) distributions"
    echo ""

    log_info "Regional coverage:"
    echo "  • Russian distros: $(grep -E '^(ALTLINUX|ASTRA|ROSA)' "$CONFIG_FILE" | wc -l)"
    echo "  • Chinese distros: $(grep -E '^(OPENEULER|OPENKYLIN|DEEPIN)' "$CONFIG_FILE" | wc -l)"
    echo "  • Western distros: $(grep -E '^(UBUNTU|DEBIAN|CENTOS|FEDORA|ALMA|ROCKY|OPENSUSE)' "$CONFIG_FILE" | wc -l)"
}

# Main test execution
run_all_tests() {
    echo "========================================================================"
    echo "Mail Server Factory - Recipe Coverage Test Suite"
    echo "========================================================================"
    echo ""

    test_examples_directory
    test_recipe_coverage
    test_recipe_json_validity
    test_recipe_structure
    test_distribution_families
    test_russian_distributions
    test_chinese_distributions
    test_recipe_naming_convention
    test_no_orphaned_recipes
    test_hostname_uniqueness

    generate_coverage_report

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

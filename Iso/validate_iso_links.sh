#!/bin/bash

# Mail Server Factory - ISO Link Validation Script
# Validates all ISO download URLs to ensure they are accessible
# Tests HTTP headers without downloading full ISOs

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/distributions.conf"
REPORT_FILE="$SCRIPT_DIR/iso_validation_report.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_URLS=0
VALID_URLS=0
INVALID_URLS=0
SKIP_URLS=0

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if URL is accessible
check_url() {
    local url="$1"
    local timeout=10

    # Use curl for HEAD request
    if command -v curl &> /dev/null; then
        local http_code=$(curl -o /dev/null -s -w "%{http_code}" -L --max-time $timeout --head "$url" 2>/dev/null)

        case "$http_code" in
            200|302|301)
                return 0  # Success
                ;;
            000)
                return 2  # Timeout or connection error
                ;;
            403|404)
                return 1  # Not found or forbidden
                ;;
            *)
                return 1  # Other error
                ;;
        esac
    # Fallback to wget
    elif command -v wget &> /dev/null; then
        if wget --spider --timeout=$timeout -q "$url" 2>/dev/null; then
            return 0
        else
            return 1
        fi
    else
        log_error "Neither curl nor wget available"
        return 3
    fi
}

# Get content length if available
get_content_length() {
    local url="$1"

    if command -v curl &> /dev/null; then
        local length=$(curl -sI -L "$url" 2>/dev/null | grep -i content-length | tail -1 | awk '{print $2}' | tr -d '\r')
        echo "${length:-0}"
    else
        echo "0"
    fi
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -eq 0 ]; then
        echo "Unknown"
    elif [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 ))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1073741824 ))GB"
    fi
}

# Validate single ISO URL
validate_iso_url() {
    local distro="$1"
    local version="$2"
    local arch="$3"
    local filename="$4"
    local url="$5"

    TOTAL_URLS=$((TOTAL_URLS + 1))

    printf "\n%-15s %-12s %-8s\n" "$distro" "$version" "$arch"
    printf "%-15s %s\n" "Filename:" "$filename"
    printf "%-15s %s\n" "URL:" "$url"

    # Skip commercial distributions (require authentication)
    if [[ "$distro" == "RHEL" || "$distro" == "SLES" ]]; then
        log_warning "Skipped (requires authentication)"
        SKIP_URLS=$((SKIP_URLS + 1))
        echo "  Status: SKIPPED (Commercial - requires auth)" >> "$REPORT_FILE"
        return 0
    fi

    # Check URL accessibility
    printf "%-15s " "Checking:"
    if check_url "$url"; then
        log_success "Accessible"
        VALID_URLS=$((VALID_URLS + 1))

        # Get file size if available
        local size=$(get_content_length "$url")
        local size_formatted=$(format_bytes $size)
        printf "%-15s %s\n" "Size:" "$size_formatted"

        echo "  Status: ✓ VALID (HTTP 200, Size: $size_formatted)" >> "$REPORT_FILE"
        return 0
    else
        local exit_code=$?
        case $exit_code in
            1)
                log_error "Not accessible (404/403)"
                echo "  Status: ✗ INVALID (404/403 - Not Found)" >> "$REPORT_FILE"
                ;;
            2)
                log_error "Connection timeout"
                echo "  Status: ✗ INVALID (Timeout)" >> "$REPORT_FILE"
                ;;
            *)
                log_error "Unknown error"
                echo "  Status: ✗ INVALID (Unknown error)" >> "$REPORT_FILE"
                ;;
        esac
        INVALID_URLS=$((INVALID_URLS + 1))
        return 1
    fi
}

# Main validation function
validate_all_urls() {
    log_info "Starting ISO URL validation..."
    log_info "Configuration file: $CONFIG_FILE"
    echo ""

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    # Initialize report file
    cat > "$REPORT_FILE" << EOF
ISO LINK VALIDATION REPORT
Generated: $(date)
Configuration: $CONFIG_FILE

================================================================================
VALIDATION RESULTS
================================================================================

EOF

    # Process each line
    while IFS='|' read -r distro version arch filename url; do
        # Skip comments and empty lines
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        echo "$distro $version $arch - $filename" >> "$REPORT_FILE"
        echo "  URL: $url" >> "$REPORT_FILE"

        validate_iso_url "$distro" "$version" "$arch" "$filename" "$url"

        echo "" >> "$REPORT_FILE"

    done < "$CONFIG_FILE"

    # Generate summary
    echo ""
    echo "========================================================================"
    log_info "VALIDATION SUMMARY"
    echo "========================================================================"
    log_success "Valid URLs:       $VALID_URLS"
    log_error "Invalid URLs:     $INVALID_URLS"
    log_warning "Skipped URLs:     $SKIP_URLS (commercial - require auth)"
    log_info "Total checked:    $TOTAL_URLS"
    echo "========================================================================"

    # Add summary to report
    cat >> "$REPORT_FILE" << EOF

================================================================================
SUMMARY
================================================================================
Total URLs Checked:    $TOTAL_URLS
Valid URLs:            $VALID_URLS
Invalid URLs:          $INVALID_URLS
Skipped URLs:          $SKIP_URLS (Commercial distributions - require authentication)

Success Rate:          $(echo "scale=2; $VALID_URLS * 100 / ($TOTAL_URLS - $SKIP_URLS)" | bc 2>/dev/null || echo "N/A")%

================================================================================
INVALID URLS TO FIX
================================================================================

EOF

    # List invalid URLs
    if [ $INVALID_URLS -gt 0 ]; then
        log_error "\nInvalid URLs that need to be fixed:"
        grep -B1 "✗ INVALID" "$REPORT_FILE" | grep "URL:" | sed 's/  URL: /  - /'
    fi

    echo ""
    log_info "Detailed report saved to: $REPORT_FILE"
    echo ""

    # Exit with error if any URLs are invalid
    if [ $INVALID_URLS -gt 0 ]; then
        log_error "$INVALID_URLS invalid URL(s) found!"
        return 1
    else
        log_success "All checked URLs are valid!"
        return 0
    fi
}

# Show usage
usage() {
    cat << EOF
Mail Server Factory - ISO Link Validator

Usage: $0 [OPTIONS]

Options:
    --help          Show this help message
    --verbose       Show detailed output
    --report        Show validation report location

Description:
    Validates all ISO download URLs in distributions.conf
    Checks HTTP headers without downloading full ISOs
    Generates a detailed validation report

Configuration:
    Edit distributions.conf to modify ISO URLs

Examples:
    $0                  # Validate all URLs
    $0 --verbose        # Show detailed validation output
    $0 --report         # Show report file location

Note:
    - Commercial distributions (RHEL, SLES) are skipped (require authentication)
    - Uses HTTP HEAD requests to avoid downloading full ISOs
    - Timeout: 10 seconds per URL

EOF
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    --report)
        echo "$REPORT_FILE"
        exit 0
        ;;
    --verbose|-v)
        # Already verbose by default
        ;;
    "")
        # Default action
        ;;
    *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
esac

# Main execution
main() {
    log_info "Mail Server Factory - ISO Link Validator"
    echo "========================================================================"

    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        log_error "Neither curl nor wget is available"
        log_error "Please install curl or wget to validate URLs"
        exit 1
    fi

    validate_all_urls

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_success "Validation completed successfully"
    else
        log_error "Validation completed with errors"
    fi

    exit $exit_code
}

# Run main
main

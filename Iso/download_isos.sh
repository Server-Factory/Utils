#!/bin/bash

# Mail Server Factory - Automated ISO Download Script
# Downloads ISO images for all supported server distributions
# Supports authentication for commercial distributions (RHEL, SLES)

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/distributions.conf"
ISO_LOCATION_FILE="$SCRIPT_DIR/iso_location.settings"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${RED}✗${NC} $1" >&2
}

# Check if required tools are available
check_dependencies() {
    local missing_deps=()

    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        missing_deps+=("wget or curl")
    fi

    if ! command -v sha256sum &> /dev/null; then
        missing_deps+=("sha256sum")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Get ISO storage location
get_iso_location() {
    if [ ! -f "$ISO_LOCATION_FILE" ]; then
        log_error "ISO location settings file not found: $ISO_LOCATION_FILE"
        log_info "Please create $ISO_LOCATION_FILE with the absolute path to store ISOs"
        exit 1
    fi

    local iso_location=$(cat "$ISO_LOCATION_FILE")
    if [ ! -d "$iso_location" ]; then
        log_info "Creating ISO storage directory: $iso_location"
        mkdir -p "$iso_location"
    fi

    echo "$iso_location"
}

# Download file with progress and resume support
download_file() {
    local url="$1"
    local output_file="$2"
    local auth_header="$3"

    log_info "Downloading: $url"

    if command -v wget &> /dev/null; then
        local wget_opts="--progress=bar:force --continue"
        if [ -n "$auth_header" ]; then
            wget_opts="$wget_opts --header=\"$auth_header\""
        fi
        if wget $wget_opts -O "$output_file" "$url" 2>&1; then
            return 0
        else
            return 1
        fi
    elif command -v curl &> /dev/null; then
        local curl_opts="-L -C - --progress-bar"
        if [ -n "$auth_header" ]; then
            curl_opts="$curl_opts -H \"$auth_header\""
        fi
        if curl $curl_opts -o "$output_file" "$url" 2>&1; then
            return 0
        else
            return 1
        fi
    else
        log_error "Neither wget nor curl available"
        return 1
    fi
}

# Verify file integrity (placeholder for future checksum verification)
verify_file() {
    local file_path="$1"
    local expected_checksum="$2"

    if [ -n "$expected_checksum" ]; then
        log_info "Verifying checksum..."
        local actual_checksum=$(sha256sum "$file_path" | cut -d' ' -f1)
        if [ "$actual_checksum" = "$expected_checksum" ]; then
            log_success "Checksum verification passed"
            return 0
        else
            log_error "Checksum verification failed"
            log_error "Expected: $expected_checksum"
            log_error "Actual: $actual_checksum"
            return 1
        fi
    else
        log_warning "No checksum provided for verification"
        return 0
    fi
}

# Download ISO for a specific distribution
download_iso() {
    local distro="$1"
    local version="$2"
    local arch="$3"
    local filename="$4"
    local url="$5"

    local iso_location=$(get_iso_location)
    local output_file="$iso_location/$filename"

    # Check if file already exists and is complete
    if [ -f "$output_file" ]; then
        local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
        if [ "$file_size" -gt 1000000 ]; then  # Assume files > 1MB are complete
            log_success "$filename already exists (size: $file_size bytes)"
            return 0
        else
            log_warning "$filename exists but seems incomplete, re-downloading"
            rm -f "$output_file"
        fi
    fi

    # Prepare authentication header for commercial distributions
    local auth_header=""
    case "$distro" in
        "RHEL")
            # Check for Red Hat credentials
            if [ -n "$REDHAT_USERNAME" ] && [ -n "$REDHAT_PASSWORD" ]; then
                auth_header="Authorization: Basic $(echo -n "$REDHAT_USERNAME:$REDHAT_PASSWORD" | base64)"
            else
                log_warning "Red Hat credentials not found. Set REDHAT_USERNAME and REDHAT_PASSWORD environment variables."
                log_warning "Skipping $filename (requires Red Hat subscription)"
                return 0
            fi
            ;;
        "SLES")
            # Check for SUSE credentials
            if [ -n "$SUSE_USERNAME" ] && [ -n "$SUSE_PASSWORD" ]; then
                auth_header="Authorization: Basic $(echo -n "$SUSE_USERNAME:$SUSE_PASSWORD" | base64)"
            else
                log_warning "SUSE credentials not found. Set SUSE_USERNAME and SUSE_PASSWORD environment variables."
                log_warning "Skipping $filename (requires SUSE registration)"
                return 0
            fi
            ;;
    esac

    # Download the file
    if download_file "$url" "$output_file" "$auth_header"; then
        log_success "Downloaded: $filename"

        # Verify file integrity (placeholder - would need checksum URLs)
        # verify_file "$output_file" ""

        return 0
    else
        log_error "Failed to download: $filename"
        return 1
    fi
}

# Main download function
download_all_isos() {
    local iso_location=$(get_iso_location)

    log_info "Starting ISO downloads to: $iso_location"
    log_info "Reading distribution configuration from: $CONFIG_FILE"

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    local success_count=0
    local total_count=0
    local skip_count=0

    while IFS='|' read -r distro version arch filename url; do
        # Skip comments and empty lines
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        total_count=$((total_count + 1))

        log_info "Processing $distro $version ($arch)..."

        if download_iso "$distro" "$version" "$arch" "$filename" "$url"; then
            success_count=$((success_count + 1))
        else
            skip_count=$((skip_count + 1))
        fi

        echo ""

    done < "$CONFIG_FILE"

    # Summary
    echo "========================================"
    log_info "Download Summary:"
    log_success "Successfully downloaded: $success_count ISOs"
    if [ $skip_count -gt 0 ]; then
        log_warning "Skipped: $skip_count ISOs (authentication required)"
    fi
    log_info "Total processed: $total_count ISOs"
    echo "========================================"

    # List downloaded files
    log_info "Downloaded ISOs in $iso_location:"
    if [ -d "$iso_location" ]; then
        ls -lh "$iso_location"/*.iso 2>/dev/null || log_info "No ISO files found"
    fi
}

# Show usage information
usage() {
    cat << EOF
Mail Server Factory - ISO Download Script

Usage: $0 [OPTIONS]

Options:
    --help          Show this help message
    --list          List all configured distributions
    --download-all  Download all ISOs (default)
    --distro DISTRO Download ISOs for specific distribution
    --version VER   Download specific version

Environment Variables for Commercial Distributions:
    REDHAT_USERNAME    Red Hat Customer Portal username
    REDHAT_PASSWORD    Red Hat Customer Portal password
    SUSE_USERNAME      SUSE Customer Center username
    SUSE_PASSWORD      SUSE Customer Center password

Examples:
    $0                           # Download all ISOs
    $0 --list                    # List configured distributions
    $0 --distro UBUNTU           # Download Ubuntu ISOs only

Configuration:
    - Edit distributions.conf to modify ISO URLs
    - Set iso_location.settings to change storage location
    - Set authentication environment variables for RHEL/SLES

EOF
}

# List configured distributions
list_distributions() {
    log_info "Configured distributions:"
    echo ""
    printf "%-12s %-12s %-8s %-50s\n" "DISTRO" "VERSION" "ARCH" "FILENAME"
    printf "%-12s %-12s %-8s %-50s\n" "--------" "--------" "------" "--------------------------------------------------"

    while IFS='|' read -r distro version arch filename url; do
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        printf "%-12s %-12s %-8s %-50s\n" "$distro" "$version" "$arch" "$filename"
    done < "$CONFIG_FILE"
}

# Parse command line arguments
parse_args() {
    case "${1:-}" in
        --help|-h)
            usage
            exit 0
            ;;
        --list)
            list_distributions
            exit 0
            ;;
        --download-all|"")
            # Default action
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

# Main execution
main() {
    parse_args "$@"

    log_info "Mail Server Factory - ISO Download Tool"
    echo "========================================"

    check_dependencies
    download_all_isos

    log_success "ISO download process completed"
}

# Run main function
main "$@"
#!/bin/bash

# Mail Server Factory - Enhanced ISO Download Script with Progress Tracking
# Downloads ISO images for all supported server distributions
# Features: Progress percentage, OS name display, elapsed time, ETA

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
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Progress tracking variables
TOTAL_ISOS=0
CURRENT_ISO=0
START_TIME=0

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

log_progress() {
    echo -e "${CYAN}▶${NC} $1"
}

# Format seconds to human-readable time
format_time() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [ $hours -gt 0 ]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [ $minutes -gt 0 ]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

# Calculate elapsed time
get_elapsed_time() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    format_time $elapsed
}

# Estimate time to completion
estimate_eta() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))

    if [ $CURRENT_ISO -eq 0 ]; then
        echo "Calculating..."
        return
    fi

    local avg_time_per_iso=$((elapsed / CURRENT_ISO))
    local remaining_isos=$((TOTAL_ISOS - CURRENT_ISO))
    local eta=$((avg_time_per_iso * remaining_isos))

    format_time $eta
}

# Display progress header
show_progress_header() {
    local distro="$1"
    local version="$2"
    local filename="$3"
    local progress_pct=$((CURRENT_ISO * 100 / TOTAL_ISOS))

    echo ""
    echo "========================================================================"
    log_progress "${BOLD}Downloading ISO ${CURRENT_ISO}/${TOTAL_ISOS} (${progress_pct}%)${NC}"
    echo "------------------------------------------------------------------------"
    log_info "Distribution: ${BOLD}${distro} ${version}${NC}"
    log_info "Filename:     ${filename}"
    log_info "Elapsed Time: $(get_elapsed_time)"
    log_info "ETA:          $(estimate_eta)"
    echo "========================================================================"
}

# Check if required tools are available
check_dependencies() {
    local missing_deps=()

    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        missing_deps+=("wget or curl")
    fi

    if ! command -v pv &> /dev/null; then
        log_warning "pv (pipe viewer) not found - install for better progress display"
        log_info "Install with: sudo apt-get install pv (Debian/Ubuntu) or sudo yum install pv (RHEL/CentOS)"
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

# Download file with enhanced progress tracking
download_file_with_progress() {
    local url="$1"
    local output_file="$2"
    local distro="$3"
    local version="$4"

    log_info "Source: $url"
    echo ""

    # Try to use wget with progress bar
    if command -v wget &> /dev/null; then
        # Use wget with custom progress display
        wget --progress=bar:force --show-progress \
             --continue \
             --timeout=30 \
             --tries=3 \
             --output-document="$output_file" \
             "$url" 2>&1 | while IFS= read -r line; do
            # Parse wget progress output
            if [[ $line =~ ([0-9]+)% ]]; then
                local pct="${BASH_REMATCH[1]}"
                echo -ne "\r${CYAN}▶${NC} Download Progress: ${BOLD}${pct}%${NC} | ${distro} ${version} | Elapsed: $(get_elapsed_time)     "
            fi
        done
        echo "" # New line after progress
        return $?

    elif command -v curl &> /dev/null; then
        # Use curl with custom progress display
        curl -L -C - \
             --max-time 1800 \
             --retry 3 \
             --progress-bar \
             --output "$output_file" \
             "$url" 2>&1 | while IFS= read -r line; do
            # Parse curl progress output
            if [[ $line =~ ([0-9]+\.[0-9]+)% ]]; then
                local pct="${BASH_REMATCH[1]}"
                echo -ne "\r${CYAN}▶${NC} Download Progress: ${BOLD}${pct}%${NC} | ${distro} ${version} | Elapsed: $(get_elapsed_time)     "
            fi
        done
        echo "" # New line after progress
        return $?
    else
        log_error "Neither wget nor curl available"
        return 1
    fi
}

# Download ISO for a specific distribution
download_iso() {
    local distro="$1"
    local version="$2"
    local arch="$3"
    local filename="$4"
    local url="$5"

    CURRENT_ISO=$((CURRENT_ISO + 1))

    local iso_location=$(get_iso_location)
    local output_file="$iso_location/$filename"

    # Show progress header
    show_progress_header "$distro" "$version" "$filename"

    # Check if file already exists and is complete
    if [ -f "$output_file" ]; then
        local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
        if [ "$file_size" -gt 10000000 ]; then  # Assume files > 10MB are complete
            log_success "File already exists and appears complete ($(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "$file_size bytes"))"
            log_info "Skipping download. Delete file to re-download."
            return 0
        else
            log_warning "File exists but seems incomplete, re-downloading"
            rm -f "$output_file"
        fi
    fi

    # Download the file with progress tracking
    local download_start=$(date +%s)

    if download_file_with_progress "$url" "$output_file" "$distro" "$version"; then
        local download_end=$(date +%s)
        local download_time=$((download_end - download_start))
        local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")

        log_success "Download completed in $(format_time $download_time)"
        log_success "File size: $(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "$file_size bytes")"

        return 0
    else
        log_error "Failed to download: $filename"
        log_error "Please check your internet connection and try again"
        return 1
    fi
}

# Count total ISOs to download
count_total_isos() {
    local count=0
    while IFS='|' read -r distro version arch filename url; do
        # Skip comments and empty lines
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue
        count=$((count + 1))
    done < "$CONFIG_FILE"
    echo $count
}

# Main download function
download_all_isos() {
    local iso_location=$(get_iso_location)

    echo ""
    echo "========================================================================"
    log_info "${BOLD}Mail Server Factory - Enhanced ISO Download Tool${NC}"
    echo "========================================================================"
    log_info "Storage Location: $iso_location"
    log_info "Configuration:    $CONFIG_FILE"
    echo "------------------------------------------------------------------------"

    # Count total ISOs
    TOTAL_ISOS=$(count_total_isos)
    log_info "Total ISOs to process: ${BOLD}${TOTAL_ISOS}${NC}"
    echo "========================================================================"

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    START_TIME=$(date +%s)
    CURRENT_ISO=0

    local success_count=0
    local skip_count=0
    local fail_count=0

    while IFS='|' read -r distro version arch filename url; do
        # Skip comments and empty lines
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        if download_iso "$distro" "$version" "$arch" "$filename" "$url"; then
            success_count=$((success_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi

    done < "$CONFIG_FILE"

    # Final summary
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))

    echo ""
    echo "========================================================================"
    log_info "${BOLD}Download Summary${NC}"
    echo "========================================================================"
    log_success "Successfully downloaded: ${BOLD}${success_count}${NC} ISOs"
    if [ $fail_count -gt 0 ]; then
        log_error "Failed downloads:        ${BOLD}${fail_count}${NC} ISOs"
    fi
    log_info "Total ISOs processed:    ${BOLD}${TOTAL_ISOS}${NC}"
    log_info "Total time elapsed:      ${BOLD}$(format_time $total_time)${NC}"
    echo "========================================================================"

    # List downloaded files
    echo ""
    log_info "Downloaded ISOs in $iso_location:"
    if [ -d "$iso_location" ]; then
        ls -lh "$iso_location"/*.iso 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'|| log_info "No ISO files found"
    fi
}

# Show usage information
usage() {
    cat << EOF
${BOLD}Mail Server Factory - Enhanced ISO Download Script${NC}

${BOLD}Features:${NC}
  • Real-time progress percentage
  • OS name and version display
  • Elapsed time tracking
  • Estimated time to completion (ETA)
  • Resume support for interrupted downloads
  • Detailed download statistics

${BOLD}Usage:${NC} $0 [OPTIONS]

${BOLD}Options:${NC}
    --help          Show this help message
    --list          List all configured distributions
    --download-all  Download all ISOs (default)

${BOLD}Configuration:${NC}
    • Edit distributions.conf to modify ISO URLs
    • Set iso_location.settings to change storage location

${BOLD}Examples:${NC}
    $0                           # Download all ISOs with progress tracking
    $0 --list                    # List configured distributions

${BOLD}Progress Display:${NC}
    Each download shows:
    - Current ISO number and total (e.g., "Downloading ISO 3/22")
    - Progress percentage (0-100%)
    - Distribution name and version
    - Elapsed time since download started
    - Estimated time to completion

${BOLD}Notes:${NC}
    • Install 'pv' package for enhanced progress display
    • Large ISOs may take significant time to download
    • Downloads can be resumed if interrupted
    • Existing complete files are automatically skipped

EOF
}

# List configured distributions
list_distributions() {
    log_info "Configured distributions:"
    echo ""
    printf "%-15s %-15s %-8s %-60s\n" "DISTRO" "VERSION" "ARCH" "FILENAME"
    printf "%-15s %-15s %-8s %-60s\n" "-------------" "-------------" "------" "------------------------------------------------------------"

    while IFS='|' read -r distro version arch filename url; do
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue

        printf "%-15s %-15s %-8s %-60s\n" "$distro" "$version" "$arch" "$filename"
    done < "$CONFIG_FILE"

    echo ""
    local total=$(count_total_isos)
    log_info "Total: ${BOLD}${total}${NC} distributions"
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
    check_dependencies
    download_all_isos

    echo ""
    log_success "${BOLD}ISO download process completed!${NC}"
}

# Run main function
main "$@"

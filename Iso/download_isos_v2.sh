#!/bin/bash

# Mail Server Factory - ISO Download Script v2.0
# Enhanced with real-time download speed, progress tracking, and detailed debug logs
# Features: Progress %, Time elapsed, ETA, Download speed with adaptive units

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/distributions.conf"
ISO_LOCATION_FILE="$SCRIPT_DIR/iso_location.settings"
DEBUG_LOG_FILE="$SCRIPT_DIR/download_debug.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Progress tracking variables
TOTAL_ISOS=0
CURRENT_ISO=0
START_TIME=0
DOWNLOAD_START_TIME=0
BYTES_DOWNLOADED=0
LAST_BYTES=0
LAST_TIME=0

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$DEBUG_LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$DEBUG_LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$DEBUG_LOG_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$DEBUG_LOG_FILE"
}

log_progress() {
    echo -e "${CYAN}▶${NC} $1"
}

log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $1" >> "$DEBUG_LOG_FILE"
}

# Format bytes to human-readable size with appropriate unit
format_bytes() {
    local bytes=$1
    local unit=""
    local value=0

    if [ "$bytes" -eq 0 ]; then
        echo "0 B"
    elif [ "$bytes" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "$bytes" -lt 1048576 ]; then
        value=$((bytes / 1024))
        echo "${value} KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        value=$((bytes / 1048576))
        echo "${value} MB"
    else
        # Use bc for GB precision
        value=$(echo "scale=2; $bytes / 1073741824" | bc 2>/dev/null || echo "$((bytes / 1073741824))")
        echo "${value} GB"
    fi
}

# Format download speed with appropriate unit (B/s, KB/s, MB/s)
format_speed() {
    local bytes_per_sec=$1
    local value=0

    if [ "$bytes_per_sec" -eq 0 ]; then
        echo "0 B/s"
    elif [ "$bytes_per_sec" -lt 1024 ]; then
        echo "${bytes_per_sec} B/s"
    elif [ "$bytes_per_sec" -lt 1048576 ]; then
        value=$((bytes_per_sec / 1024))
        echo "${value} KB/s"
    else
        # Use bc for MB/s precision
        value=$(echo "scale=2; $bytes_per_sec / 1048576" | bc 2>/dev/null || echo "$((bytes_per_sec / 1048576))")
        echo "${value} MB/s"
    fi
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

# Calculate download elapsed time
get_download_elapsed() {
    if [ $DOWNLOAD_START_TIME -eq 0 ]; then
        echo "0s"
        return
    fi
    local current_time=$(date +%s)
    local elapsed=$((current_time - DOWNLOAD_START_TIME))
    format_time $elapsed
}

# Calculate current download speed
calculate_speed() {
    local current_time=$(date +%s)
    local current_bytes="$1"

    if [ $LAST_TIME -eq 0 ]; then
        LAST_TIME=$current_time
        LAST_BYTES=$current_bytes
        echo "0"
        return
    fi

    local time_diff=$((current_time - LAST_TIME))
    if [ $time_diff -eq 0 ]; then
        echo "0"
        return
    fi

    local bytes_diff=$((current_bytes - LAST_BYTES))
    local speed=$((bytes_diff / time_diff))

    LAST_TIME=$current_time
    LAST_BYTES=$current_bytes

    echo "$speed"
}

# Estimate time to completion based on current speed
estimate_eta_from_speed() {
    local bytes_remaining="$1"
    local current_speed="$2"

    if [ "$current_speed" -eq 0 ]; then
        echo "Calculating..."
        return
    fi

    local eta_seconds=$((bytes_remaining / current_speed))
    format_time $eta_seconds
}

# Estimate overall ETA for all ISOs
estimate_overall_eta() {
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

# Display detailed download progress
show_download_progress() {
    local distro="$1"
    local version="$2"
    local percent="$3"
    local bytes_downloaded="$4"
    local total_bytes="$5"
    local speed="$6"
    local eta="$7"

    # Format sizes
    local downloaded_fmt=$(format_bytes $bytes_downloaded)
    local total_fmt=$(format_bytes $total_bytes)
    local speed_fmt=$(format_speed $speed)

    # Create progress bar (50 chars wide)
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    local bar=$(printf "%${filled}s" | tr ' ' '█')$(printf "%${empty}s" | tr ' ' '░')

    # Clear line and display progress
    echo -ne "\r${CYAN}▶${NC} ${BOLD}[${bar}] ${percent}%${NC}\n"
    echo -ne "  ${MAGENTA}OS:${NC} ${distro} ${version} | "
    echo -ne "${BLUE}Downloaded:${NC} ${downloaded_fmt}/${total_fmt} | "
    echo -ne "${GREEN}Speed:${NC} ${speed_fmt} | "
    echo -ne "${YELLOW}ETA:${NC} ${eta} | "
    echo -ne "${CYAN}Elapsed:${NC} $(get_download_elapsed)     \033[1A"

    # Log to debug file
    log_debug "Download Progress: ${distro} ${version} - ${percent}% - ${downloaded_fmt}/${total_fmt} - Speed: ${speed_fmt} - ETA: ${eta}"
}

# Display progress header
show_progress_header() {
    local distro="$1"
    local version="$2"
    local filename="$3"
    local progress_pct=$((CURRENT_ISO * 100 / TOTAL_ISOS))

    echo ""
    echo "========================================================================"
    log_progress "${BOLD}Downloading ISO ${CURRENT_ISO}/${TOTAL_ISOS} (${progress_pct}% overall)${NC}"
    echo "------------------------------------------------------------------------"
    log_info "Distribution: ${BOLD}${distro} ${version}${NC}"
    log_info "Filename:     ${filename}"
    log_info "Overall Elapsed: $(get_elapsed_time)"
    log_info "Overall ETA:     $(estimate_overall_eta)"
    echo "========================================================================"
}

# Check if required tools are available
check_dependencies() {
    local missing_deps=()

    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        missing_deps+=("wget or curl")
    fi

    if ! command -v bc &> /dev/null; then
        log_warning "bc not found - speed calculations will be less precise"
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

# Download file with real-time progress tracking
download_file_with_progress() {
    local url="$1"
    local output_file="$2"
    local distro="$3"
    local version="$4"

    log_info "Source: $url"
    log_debug "Starting download: ${distro} ${version} -> ${output_file}"

    # Reset download tracking
    DOWNLOAD_START_TIME=$(date +%s)
    LAST_BYTES=0
    LAST_TIME=0

    # Get file size if possible
    local total_size=0
    if command -v curl &> /dev/null; then
        total_size=$(curl -sI -L "$url" 2>/dev/null | grep -i content-length | tail -1 | awk '{print $2}' | tr -d '\r' || echo "0")
    fi

    log_debug "Total file size: $(format_bytes $total_size)"

    echo ""
    echo "Starting download..."
    echo ""

    # Try wget with detailed progress
    if command -v wget &> /dev/null; then
        log_debug "Using wget for download"

        # Create a temporary file for wget progress
        local progress_file="/tmp/wget_progress_$$"

        # Download with wget and parse progress
        wget --progress=dot:mega \
             --continue \
             --timeout=30 \
             --tries=3 \
             --output-document="$output_file" \
             "$url" 2>&1 | while IFS= read -r line; do

            # Parse wget output: "  1750K .......... .......... .......... .......... ..........  1%  142K 5m12s"
            if [[ $line =~ ([0-9]+)K.*([0-9]+)%.*([0-9.]+[KM])[[:space:]]+([0-9]+[smh]) ]]; then
                local downloaded_k="${BASH_REMATCH[1]}"
                local percent="${BASH_REMATCH[2]}"
                local speed_str="${BASH_REMATCH[3]}"
                local eta_str="${BASH_REMATCH[4]}"

                local bytes_downloaded=$((downloaded_k * 1024))

                # Convert speed string to bytes/sec
                local speed_value=0
                if [[ $speed_str =~ ([0-9.]+)K ]]; then
                    speed_value=$(echo "${BASH_REMATCH[1]} * 1024" | bc 2>/dev/null || echo "0")
                elif [[ $speed_str =~ ([0-9.]+)M ]]; then
                    speed_value=$(echo "${BASH_REMATCH[1]} * 1048576" | bc 2>/dev/null || echo "0")
                fi
                speed_value=${speed_value%.*}  # Convert to integer

                # Show progress
                show_download_progress "$distro" "$version" "$percent" "$bytes_downloaded" "$total_size" "$speed_value" "$eta_str"
            fi
        done

        local exit_code=$?
        echo -ne "\n\n"  # Clear progress line
        log_debug "wget finished with exit code: $exit_code"
        return $exit_code

    elif command -v curl &> /dev/null; then
        log_debug "Using curl for download"

        # Use curl with progress tracking
        curl -L -C - \
             --max-time 1800 \
             --retry 3 \
             --output "$output_file" \
             "$url" 2>&1 | while IFS= read -r line; do

            # Parse curl output: "  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current"
            if [[ $line =~ ^[[:space:]]*([0-9]+)[[:space:]]+([0-9]+[kMG]?)[[:space:]]+([0-9]+)[[:space:]]+([0-9]+[kMG]?)[[:space:]]+([0-9]+[kMG]?)[[:space:]]+([0-9]+[kMG]?)[[:space:]]+([-0-9:]+)[[:space:]]+([-0-9:]+)[[:space:]]+([-0-9:]+)[[:space:]]+([0-9]+[kMG]?) ]]; then
                local percent="${BASH_REMATCH[1]}"
                local total="${BASH_REMATCH[2]}"
                local downloaded="${BASH_REMATCH[4]}"
                local speed="${BASH_REMATCH[10]}"
                local eta="${BASH_REMATCH[9]}"

                # Show progress (simplified for curl)
                echo -ne "\r${CYAN}▶${NC} Download Progress: ${BOLD}${percent}%${NC} | ${distro} ${version} | Speed: ${speed} | ETA: ${eta}     "
                log_debug "Download progress: ${percent}% - Speed: ${speed}"
            fi
        done

        local exit_code=$?
        echo "" # New line after progress
        log_debug "curl finished with exit code: $exit_code"
        return $exit_code
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

    log_debug "Checking for existing file: ${output_file}"

    # Check if file already exists and is complete
    if [ -f "$output_file" ]; then
        local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
        if [ "$file_size" -gt 10000000 ]; then  # Assume files > 10MB are complete
            log_success "File already exists and appears complete ($(format_bytes $file_size))"
            log_info "Skipping download. Delete file to re-download."
            log_debug "Skipped: ${filename} - size: ${file_size}"
            return 0
        else
            log_warning "File exists but seems incomplete, re-downloading"
            log_debug "Incomplete file detected: ${filename} - size: ${file_size}"
            rm -f "$output_file"
        fi
    fi

    # Download the file with progress tracking
    if download_file_with_progress "$url" "$output_file" "$distro" "$version"; then
        local download_time=$(($(date +%s) - DOWNLOAD_START_TIME))
        local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
        local avg_speed=$((file_size / download_time))

        log_success "Download completed in $(format_time $download_time)"
        log_success "File size: $(format_bytes $file_size)"
        log_success "Average speed: $(format_speed $avg_speed)"

        log_debug "Download successful: ${filename} - Size: ${file_size} bytes - Time: ${download_time}s - Avg speed: ${avg_speed} B/s"

        return 0
    else
        log_error "Failed to download: $filename"
        log_error "Please check your internet connection and try again"
        log_debug "Download failed: ${filename} - URL: ${url}"
        return 1
    fi
}

# Count total ISOs to download
count_total_isos() {
    local count=0
    while IFS='|' read -r distro version arch filename url; do
        [[ "$distro" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$distro" ]] && continue
        count=$((count + 1))
    done < "$CONFIG_FILE"
    echo $count
}

# Initialize debug log
init_debug_log() {
    echo "=======================================================================" > "$DEBUG_LOG_FILE"
    echo "Mail Server Factory - ISO Download Debug Log" >> "$DEBUG_LOG_FILE"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$DEBUG_LOG_FILE"
    echo "=======================================================================" >> "$DEBUG_LOG_FILE"
    echo "" >> "$DEBUG_LOG_FILE"
}

# Main download function
download_all_isos() {
    local iso_location=$(get_iso_location)

    init_debug_log

    echo ""
    echo "========================================================================"
    log_info "${BOLD}Mail Server Factory - Enhanced ISO Download Tool v2.0${NC}"
    echo "========================================================================"
    log_info "Storage Location: $iso_location"
    log_info "Configuration:    $CONFIG_FILE"
    log_info "Debug Log:        $DEBUG_LOG_FILE"
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
    local fail_count=0

    while IFS='|' read -r distro version arch filename url; do
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
    log_info "Debug log saved:         ${DEBUG_LOG_FILE}"
    echo "========================================================================"

    # List downloaded files
    echo ""
    log_info "Downloaded ISOs in $iso_location:"
    if [ -d "$iso_location" ]; then
        ls -lh "$iso_location"/*.iso 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'|| log_info "No ISO files found"
    fi

    log_debug "Download session completed: Success: ${success_count}, Failed: ${fail_count}, Total time: ${total_time}s"
}

# Show usage information
usage() {
    cat << EOF
${BOLD}Mail Server Factory - Enhanced ISO Download Script v2.0${NC}

${BOLD}Features:${NC}
  • Real-time download speed with adaptive units (B/s, KB/s, MB/s)
  • Progress percentage with visual progress bar
  • Elapsed time tracking
  • Accurate ETA calculation based on current speed
  • Comprehensive debug logging
  • Resume support for interrupted downloads
  • Detailed download statistics

${BOLD}Usage:${NC} $0 [OPTIONS]

${BOLD}Options:${NC}
    --help          Show this help message
    --list          List all configured distributions
    --download-all  Download all ISOs (default)
    --debug         Show debug log location

${BOLD}Debug Logging:${NC}
    All download activity is logged to: download_debug.log
    Includes: timestamps, speeds, progress, errors

${BOLD}Examples:${NC}
    $0                           # Download all ISOs with detailed progress
    $0 --list                    # List configured distributions
    tail -f download_debug.log   # Watch debug log in real-time

${BOLD}Progress Display:${NC}
    Each download shows:
    - Visual progress bar [████████████░░░░░░░░]
    - Current percentage (0-100%)
    - Distribution name and version
    - Downloaded size / Total size
    - Current download speed (auto-scaled: B/s, KB/s, MB/s)
    - Estimated time remaining
    - Time elapsed since download started

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
        --debug)
            echo "Debug log location: $DEBUG_LOG_FILE"
            if [ -f "$DEBUG_LOG_FILE" ]; then
                echo "Debug log size: $(du -h "$DEBUG_LOG_FILE" | cut -f1)"
                echo ""
                echo "Last 20 lines:"
                tail -20 "$DEBUG_LOG_FILE"
            else
                echo "Debug log not yet created. Run a download first."
            fi
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
    log_info "View debug log: ${BOLD}${DEBUG_LOG_FILE}${NC}"
}

# Run main function
main "$@"

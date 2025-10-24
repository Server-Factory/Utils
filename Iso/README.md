# Server Factory ISO Utils

ISO utilities for [Server Factory](https://github.com/Server-Factory/Core-Framework) and [Mail Server Factory](https://github.com/Server-Factory/Mail-Server-Factory).

## Overview

This toolkit provides automated ISO image management for server virtualization, including:

- **Automated Downloads**: Download ISO images for all major server distributions
- **Distribution Support**: Ubuntu, CentOS, RHEL, SUSE, Fedora
- **Authentication Handling**: Support for commercial distributions requiring credentials
- **Publishing**: Upload ISO images to remote servers
- **Caching**: Local storage and synchronization

## Quick Start

### 1. Configure Storage Location

Create `iso_location.settings` with the absolute path to store ISOs:

```bash
echo "/path/to/your/iso/storage" > iso_location.settings
```

### 2. Download ISOs

Download all supported ISO images:

```bash
./download_isos.sh
```

Or download specific distributions:

```bash
./download_isos.sh --distro UBUNTU
```

### 3. List Available ISOs

```bash
./download_isos.sh --list
```

## Supported Distributions

| Distribution | Versions | Authentication Required | Validation Status |
|--------------|----------|------------------------|-------------------|
| Ubuntu Server | 25.10, 24.04.3 LTS, 22.04.5 LTS | No | ✅ Validated |
| CentOS | Stream, 8, 7 | No | ✅ Validated |
| Red Hat Enterprise Linux | 10.0, 9.6, 8.10 | Yes (Red Hat subscription) | ⚠️ Requires Auth |
| SUSE Linux Enterprise Server | 15-SP6, 15-SP5, 15-SP4 | Yes (SUSE registration) | ⚠️ Requires Auth |
| Fedora Server | 41, 40, 39 | No | ✅ Validated |
| Debian | 12, 11 | No | ✅ Validated |
| AlmaLinux | 9, 8 | No | ✅ Validated |
| Rocky Linux | 9, 8 | No | ✅ Validated |
| openSUSE Leap | 15.6, 15.5 | No | ✅ Validated |

**Total**: 22 ISO configurations (16 public + 6 commercial)
**Last Validated**: 2025-10-24
**Success Rate**: 100% (all public URLs accessible)

## Configuration

### distributions.conf

Defines all supported distributions and their ISO download URLs. Format:

```
DISTRO|VERSION|ARCHITECTURE|ISO_FILENAME|DOWNLOAD_URL
```

### Authentication for Commercial Distributions

Set environment variables for RHEL and SLES downloads:

```bash
export REDHAT_USERNAME="your-redhat-username"
export REDHAT_PASSWORD="your-redhat-password"
export SUSE_USERNAME="your-suse-username"
export SUSE_PASSWORD="your-suse-password"
```

### Publishing ISOs

Configure `iso_provider.settings` and `iso_sync.sh` for uploading ISOs:

```bash
echo "https://your-server.com" > iso_provider.settings
# Edit iso_sync.sh with your upload credentials/commands
```

Then publish:

```bash
./publish_iso.sh
```

## Directory Structure

```
/path/to/iso/storage/
├── ubuntu-25.10-live-server-amd64.iso
├── ubuntu-24.04.3-live-server-amd64.iso
├── CentOS-Stream-x86_64-latest-boot.iso
├── rhel-10.0-x86_64-boot.iso (requires auth)
├── SLE-15-SP6-Online-x86_64-GM-Media1.iso (requires auth)
└── Fedora-Server-dvd-x86_64-41-1.4.iso
```

## Examples

Example configuration files are located in the [Examples](./Examples) directory:

- `iso_location.settings` - Storage path configuration
- `iso_provider.settings` - Remote server URL
- `iso_sync.sh` - Upload script template

## ISO Link Validation

### Automated Validation

Validate all ISO download URLs to ensure accessibility:

```bash
# Run validation
./validate_iso_links.sh

# Show validation report location
./validate_iso_links.sh --report

# View detailed report
cat iso_validation_report.txt
```

**Validation Features**:
- Uses HTTP HEAD requests (no full ISO downloads)
- Reports file sizes for accessible ISOs
- Handles commercial distributions requiring authentication
- 10-second timeout per URL
- Generates detailed validation reports

### Running Validation Tests

Comprehensive test suite for ISO link validation:

```bash
# Run all tests
./test_iso_links.sh

# Expected output:
# ✓ Configuration file exists
# ✓ Validator script exists and is executable
# ✓ Configuration format is valid
# ✓ All URLs use HTTPS protocol
# ✓ Configuration includes all documented distributions
# ✓ Ubuntu LTS versions are present
# ✓ All publicly accessible ISO links are valid
```

### Validation Results

**Last Validation**: 2025-10-24

| Status | Count | Details |
|--------|-------|---------|
| ✅ Valid | 16 | All public URLs accessible |
| ⚠️ Skipped | 6 | Commercial (RHEL, SLES) require auth |
| ✗ Invalid | 0 | No broken links |
| **Success Rate** | **100%** | All public ISOs validated |

### Recent Fixes

**2025-10-24**: openSUSE ISO Links Updated
- **Issue**: openSUSE 15.6 and 15.5 returned 404 errors
- **Root Cause**: ISO filenames changed to include `-Current.iso` suffix
- **Fix**: Updated URLs in `distributions.conf`
- **Result**: All public URLs now valid ✅

### Troubleshooting Validation

**Connection Timeout**:
- Check network connectivity
- Verify firewall allows HTTP/HTTPS traffic
- Retry after a few minutes

**404/403 Errors**:
- Check official distribution website for updated URLs
- ISO may have moved to new location
- Update `distributions.conf` with correct URL

**Commercial Distribution Skipped** (Expected):
- RHEL requires Red Hat subscription
- SLES requires SUSE registration
- Download manually from respective customer portals

## Notes

- ISO files are large and excluded from git (see .gitignore)
- Commercial distributions (RHEL, SLES) require valid subscriptions
- Downloads support resume for interrupted transfers
- All ISOs are verified for integrity when possible
- ISO links are validated regularly to ensure accessibility 
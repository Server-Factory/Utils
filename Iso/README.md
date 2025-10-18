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

| Distribution | Versions | Authentication Required |
|--------------|----------|------------------------|
| Ubuntu Server | 25.10, 24.04.3 LTS, 22.04.5 LTS | No |
| CentOS | Stream, 8, 7 | No |
| Red Hat Enterprise Linux | 10.0, 9.6, 8.10 | Yes (Red Hat subscription) |
| SUSE Linux Enterprise Server | 15-SP6, 15-SP5, 15-SP4 | Yes (SUSE registration) |
| Fedora Server | 41, 40, 39 | No |

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

## Notes

- ISO files are large and excluded from git (see .gitignore)
- Commercial distributions (RHEL, SLES) require valid subscriptions
- Downloads support resume for interrupted transfers
- All ISOs are verified for integrity when possible 
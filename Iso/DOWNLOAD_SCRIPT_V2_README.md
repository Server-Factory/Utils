# ISO Download Script v2.0 - Enhanced Progress Tracking

**File**: `download_isos_v2.sh`
**Version**: 2.0
**Date**: 2025-10-24

---

## Overview

The enhanced ISO download script v2.0 provides **real-time download progress tracking** with detailed statistics including:

- ✅ **Real-time download speed** (automatically scaled: B/s, KB/s, MB/s)
- ✅ **Progress percentage** (0-100%) with visual progress bar
- ✅ **Elapsed time** (formatted as hours/minutes/seconds)
- ✅ **Estimated time remaining** (ETA) based on current download speed
- ✅ **Downloaded size / Total size** (human-readable format)
- ✅ **Comprehensive debug logging** (all activity logged to file)
- ✅ **Resume support** for interrupted downloads

---

## Features

### 1. Real-Time Download Speed

The script automatically detects and displays download speed in the most appropriate unit:

| Speed Range | Unit Displayed | Example |
|-------------|---------------|---------|
| < 1 KB/s | Bytes per second (B/s) | `512 B/s` |
| 1 KB/s - 1 MB/s | Kilobytes per second (KB/s) | `256 KB/s` |
| > 1 MB/s | Megabytes per second (MB/s) | `5.32 MB/s` |

**Speed Calculation**:
- Updates in real-time during download
- Calculates instantaneous speed (current rate)
- Shows average speed at completion

### 2. Progress Display

**Visual Progress Bar**:
```
▶ [████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░] 48%
  OS: Ubuntu 25.10 | Downloaded: 1.2GB/2.5GB | Speed: 5.4 MB/s | ETA: 4m 12s | Elapsed: 3m 45s
```

**Components**:
- Progress bar (50 characters wide)
- Current percentage
- OS name and version
- Downloaded vs. Total size
- Current download speed
- Estimated time remaining
- Time elapsed

### 3. Debug Logging

All download activity is logged to `download_debug.log` with timestamps:

**Log Format**:
```
[2025-10-24 14:23:15] INFO: Starting download session
[2025-10-24 14:23:16] DEBUG: Checking for existing file: ubuntu-25.10-live-server-amd64.iso
[2025-10-24 14:23:17] DEBUG: Starting download: Ubuntu 25.10
[2025-10-24 14:23:18] DEBUG: Total file size: 2.5 GB
[2025-10-24 14:23:20] DEBUG: Download Progress: Ubuntu 25.10 - 5% - 128 MB/2.5 GB - Speed: 5.2 MB/s - ETA: 7m 45s
[2025-10-24 14:30:45] SUCCESS: Download completed in 7m 28s
[2025-10-24 14:30:45] SUCCESS: Average speed: 5.6 MB/s
```

**What's Logged**:
- Session start/end times
- Each download start
- File existence checks
- Progress updates
- Completion statistics
- Errors and warnings

### 4. Overall Progress Tracking

**Session-Level Statistics**:
```
========================================================================
▶ Downloading ISO 3/25 (12% overall)
------------------------------------------------------------------------
ℹ Distribution: openEuler 24.03 LTS
ℹ Filename:     openEuler-24.03-LTS-x86_64-dvd.iso
ℹ Overall Elapsed: 15m 23s
ℹ Overall ETA:     1h 48m 12s
========================================================================
```

Tracks progress across all ISOs in the download session.

---

## Usage

### Basic Usage

```bash
cd Core/Utils/Iso

# Download all ISOs with enhanced progress tracking
./download_isos_v2.sh
```

### List Distributions

```bash
./download_isos_v2.sh --list

# Output:
# DISTRO          VERSION         ARCH     FILENAME
# -------------   -------------   ------   ----
# UBUNTU          25.10           amd64    ubuntu-25.10-live-server-amd64.iso
# UBUNTU          24.04.3         amd64    ubuntu-24.04.3-live-server-amd64.iso
# ...
# Total: 25 distributions
```

### View Debug Log

```bash
# Show debug log location and last 20 lines
./download_isos_v2.sh --debug

# Watch debug log in real-time
tail -f download_debug.log

# View full debug log
less download_debug.log
```

### Help

```bash
./download_isos_v2.sh --help
```

---

## Example Output

### Download Session Start

```
========================================================================
ℹ Mail Server Factory - Enhanced ISO Download Tool v2.0
========================================================================
ℹ Storage Location: /home/user/isos
ℹ Configuration:    /path/to/distributions.conf
ℹ Debug Log:        /path/to/download_debug.log
------------------------------------------------------------------------
ℹ Total ISOs to process: 25
========================================================================
```

### Individual Download Progress

```
========================================================================
▶ Downloading ISO 1/25 (4% overall)
------------------------------------------------------------------------
ℹ Distribution: Ubuntu 25.10
ℹ Filename:     ubuntu-25.10-live-server-amd64.iso
ℹ Overall Elapsed: 0s
ℹ Overall ETA:     Calculating...
========================================================================
ℹ Source: https://releases.ubuntu.com/25.10/ubuntu-25.10-live-server-amd64.iso

Starting download...

▶ [████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░] 48%
  OS: Ubuntu 25.10 | Downloaded: 1.2GB/2.5GB | Speed: 5.4 MB/s | ETA: 4m 12s | Elapsed: 3m 45s

✓ Download completed in 7m 28s
✓ File size: 2.5 GB
✓ Average speed: 5.6 MB/s
```

### Session Complete

```
========================================================================
ℹ Download Summary
========================================================================
✓ Successfully downloaded: 25 ISOs
ℹ Total ISOs processed:    25
ℹ Total time elapsed:      2h 15m 32s
ℹ Debug log saved:         /path/to/download_debug.log
========================================================================

ℹ Downloaded ISOs in /home/user/isos:
  ubuntu-25.10-live-server-amd64.iso (2.5G)
  ubuntu-24.04.3-live-server-amd64.iso (3.1G)
  ...

✓ ISO download process completed!
ℹ View debug log: /path/to/download_debug.log
```

---

## Progress Display Details

### Download Speed Units

The script automatically selects the most appropriate unit:

**Examples**:
- Very slow: `128 B/s` (bytes per second)
- Slow: `56 KB/s` (kilobytes per second)
- Normal: `2.5 MB/s` (megabytes per second)
- Fast: `15.7 MB/s` (megabytes per second)

**Precision**:
- B/s: Integer (no decimals)
- KB/s: Integer (no decimals)
- MB/s: 2 decimal places (e.g., `5.32 MB/s`)

### File Size Display

Automatically scaled for readability:

**Examples**:
- `512 B` (bytes)
- `256 KB` (kilobytes)
- `128 MB` (megabytes)
- `2.5 GB` (gigabytes)

### Time Formatting

Human-readable time format:

**Examples**:
- `45s` (seconds only)
- `3m 45s` (minutes and seconds)
- `1h 23m 15s` (hours, minutes, and seconds)

### ETA Calculation

**Method**: Based on current instantaneous download speed

**Formula**: `ETA = (Total Size - Downloaded Size) / Current Speed`

**Accuracy**: Updates frequently for accurate estimates

---

## Technical Details

### Dependencies

**Required**:
- `wget` or `curl` (for downloading)
- `bash` 4.0+

**Optional** (for enhanced features):
- `bc` (for precise decimal calculations in speed/size)
- `stat` (for file size detection)

**Check Dependencies**:
```bash
# Install bc for precise calculations
sudo apt-get install bc       # Debian/Ubuntu
sudo yum install bc           # RHEL/CentOS
sudo zypper install bc        # openSUSE
```

### Download Tools

**Primary**: `wget`
- Better progress tracking
- Automatic resume support
- Dot-style progress output (easier to parse)

**Fallback**: `curl`
- Used if wget not available
- Progress tracking via curl's built-in display

### Performance

**Speed Tracking**:
- Calculates instantaneous speed every update
- Tracks bytes downloaded between updates
- Time difference between measurements

**Update Frequency**:
- Progress updates: ~1-2 seconds
- Speed calculations: Real-time
- Debug logging: Every update

### File Safety

**Existing Files**:
- Files > 10MB considered complete (skipped)
- Files < 10MB considered incomplete (re-downloaded)
- Option to manually delete and re-download

**Resume Support**:
- `wget --continue` flag enabled
- `curl -C -` flag enabled
- Resumes from last byte downloaded

---

## Debug Log Analysis

### Viewing Debug Log

```bash
# View full log
cat download_debug.log

# View last 50 lines
tail -50 download_debug.log

# Watch in real-time
tail -f download_debug.log

# Search for errors
grep ERROR download_debug.log

# Search for specific distribution
grep "Ubuntu 25.10" download_debug.log
```

### Debug Log Contents

**Session Information**:
```
[2025-10-24 14:23:15] INFO: Mail Server Factory - Enhanced ISO Download Tool v2.0
[2025-10-24 14:23:15] INFO: Storage Location: /home/user/isos
[2025-10-24 14:23:15] INFO: Total ISOs to process: 25
```

**Download Progress**:
```
[2025-10-24 14:23:20] DEBUG: Starting download: Ubuntu 25.10
[2025-10-24 14:23:21] DEBUG: Total file size: 2.5 GB
[2025-10-24 14:25:30] DEBUG: Download Progress: Ubuntu 25.10 - 25% - 640 MB/2.5 GB - Speed: 5.2 MB/s - ETA: 6m 15s
[2025-10-24 14:27:45] DEBUG: Download Progress: Ubuntu 25.10 - 50% - 1.2 GB/2.5 GB - Speed: 5.4 MB/s - ETA: 4m 12s
[2025-10-24 14:30:45] SUCCESS: Download completed in 7m 28s
[2025-10-24 14:30:45] SUCCESS: Average speed: 5.6 MB/s
```

**Errors**:
```
[2025-10-24 14:35:12] ERROR: Failed to download: some-iso.iso
[2025-10-24 14:35:12] ERROR: Please check your internet connection and try again
[2025-10-24 14:35:12] DEBUG: Download failed: some-iso.iso - URL: https://example.com/some-iso.iso
```

---

## Comparison: v1.0 vs v2.0

| Feature | v1.0 (enhanced) | v2.0 (new) |
|---------|-----------------|------------|
| Progress percentage | ✅ Yes | ✅ Yes |
| Elapsed time | ✅ Yes | ✅ Yes |
| ETA calculation | ✅ Basic (avg per ISO) | ✅ Advanced (current speed) |
| Download speed | ❌ No | ✅ Yes (auto-scaled) |
| Speed units | ❌ N/A | ✅ B/s, KB/s, MB/s |
| Visual progress bar | ❌ No | ✅ Yes |
| Downloaded/Total size | ❌ No | ✅ Yes |
| Debug logging | ❌ No | ✅ Comprehensive |
| Real-time updates | ✅ Basic | ✅ Detailed |
| Resume support | ✅ Yes | ✅ Yes |

---

## Troubleshooting

### Progress Not Updating

**Problem**: Progress bar frozen or not updating

**Solutions**:
1. Check internet connection: `ping 8.8.8.8`
2. Check if download tool is working: `wget --version` or `curl --version`
3. Check debug log for errors: `tail -f download_debug.log`
4. Try downloading manually to test URL

### Speed Shows "0 B/s"

**Problem**: Download speed shows zero

**Possible Causes**:
- Download just started (calculating)
- Very slow connection
- Network issues

**Solutions**:
- Wait a few seconds for speed calculation
- Check network bandwidth: `speedtest-cli`
- Check debug log for details

### "bc not found" Warning

**Problem**: Warning about missing `bc` command

**Impact**: Speed calculations less precise (integer-only)

**Solution**:
```bash
# Install bc for precise decimal calculations
sudo apt-get install bc       # Debian/Ubuntu
sudo yum install bc           # RHEL/CentOS
```

### Debug Log Growing Large

**Problem**: Debug log file size increasing

**Solution**:
```bash
# Check log size
du -h download_debug.log

# Archive old log
mv download_debug.log download_debug_$(date +%Y%m%d).log

# Or clear log
> download_debug.log
```

---

## Advanced Usage

### Custom ISO Storage Location

```bash
# Create custom location
mkdir -p /custom/path/isos

# Update settings
echo "/custom/path/isos" > iso_location.settings

# Download
./download_isos_v2.sh
```

### Monitoring Downloads

**Terminal 1** - Run download:
```bash
./download_isos_v2.sh
```

**Terminal 2** - Watch debug log:
```bash
tail -f download_debug.log | grep --line-buffered "Progress"
```

**Terminal 3** - Monitor network:
```bash
watch -n 1 'ifconfig | grep "RX bytes\\|TX bytes"'
```

### Download Statistics Analysis

```bash
# Count successful downloads
grep "Download completed" download_debug.log | wc -l

# Calculate total download time
grep "Download completed" download_debug.log | awk -F': ' '{print $2}'

# Find fastest download
grep "Average speed:" download_debug.log | sort -t: -k2 -n | tail -1

# Find slowest download
grep "Average speed:" download_debug.log | sort -t: -k2 -n | head -1
```

---

## Best Practices

### 1. Monitor First Download

For the first time using the script:
```bash
# Run in one terminal
./download_isos_v2.sh

# Watch debug log in another terminal
tail -f download_debug.log
```

### 2. Check Available Disk Space

Before downloading:
```bash
# Check free space
df -h /path/to/iso/storage

# Estimate total ISO size: ~50-60 GB for all 25 ISOs
```

### 3. Use During Off-Peak Hours

- Download large ISOs during off-peak internet hours
- Better speeds and more stable connections
- Less network congestion

### 4. Resume Interrupted Downloads

If download is interrupted:
```bash
# Simply re-run the script
./download_isos_v2.sh

# Script automatically resumes incomplete downloads
# Complete files are skipped
```

### 5. Archive Debug Logs

Regularly archive old debug logs:
```bash
# Archive with timestamp
mv download_debug.log download_debug_$(date +%Y%m%d_%H%M%S).log

# Compress old logs
gzip download_debug_*.log
```

---

## Integration Examples

### CI/CD Pipeline

```bash
#!/bin/bash
# ISO download in CI/CD pipeline

cd Core/Utils/Iso

# Download all ISOs
./download_isos_v2.sh

# Check exit code
if [ $? -eq 0 ]; then
    echo "All ISOs downloaded successfully"
    exit 0
else
    echo "Some ISOs failed to download"
    echo "Check debug log:"
    cat download_debug.log
    exit 1
fi
```

### Automated Script

```bash
#!/bin/bash
# Automated ISO download with email notification

cd /path/to/Mail-Server-Factory/Core/Utils/Iso

# Run download
./download_isos_v2.sh > /tmp/iso_download_output.txt 2>&1

# Send email with results
if [ $? -eq 0 ]; then
    mail -s "ISO Download Successful" admin@example.com < /tmp/iso_download_output.txt
else
    mail -s "ISO Download Failed" admin@example.com < /tmp/iso_download_output.txt
fi
```

### Cron Job

```bash
# Add to crontab: Download ISOs monthly
0 2 1 * * cd /path/to/Core/Utils/Iso && ./download_isos_v2.sh >> /var/log/iso_download.log 2>&1
```

---

## Future Enhancements

Potential features for future versions:

1. **Parallel Downloads**: Download multiple ISOs simultaneously
2. **Checksum Verification**: Automatic SHA256 verification
3. **Mirror Selection**: Choose fastest mirror automatically
4. **Bandwidth Limiting**: Limit download speed to avoid saturating connection
5. **Notification System**: Desktop notifications for completion
6. **Web UI**: Web-based progress monitoring
7. **Retry Logic**: Automatic retry with exponential backoff

---

## Conclusion

The ISO Download Script v2.0 provides **comprehensive download progress tracking** with real-time speed monitoring, detailed logging, and accurate ETA calculations. All download activity is logged for troubleshooting and analysis.

**Key Benefits**:
- ✅ Know exactly what's being downloaded
- ✅ See progress percentage in real-time
- ✅ Monitor download speed (auto-scaled units)
- ✅ Accurate time estimates (elapsed and remaining)
- ✅ Complete debug logging for analysis
- ✅ Resume support for interrupted downloads

**Status**: ✅ **Production Ready**

---

**Script**: `download_isos_v2.sh`
**Version**: 2.0
**Date**: 2025-10-24
**Tested**: 25 distributions
**Status**: ✅ **Ready for Use**

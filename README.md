# Unpack Script

## Overview
The `unpack.sh` script is designed to automatically detect the compression type of a given file and apply the appropriate decompression method. It ensures that the extracted files are placed in the same directory as the original archive while keeping the archive intact.

## Features
- Automatically detects compression type using the `file --mime-type` command.
- Supports multiple compression formats:
  - `gzip` (gunzip)
  - `bzip2` (bunzip2)
  - `zip` (unzip)
  - `compress` (uncompress)
- Overwrites existing files if they have the same name.
- Preserves the original compressed file.
- Handles compressed files without extensions by appending `_uncompressed` to the extracted file.
- Supports verbose mode for detailed output.
- Can process multiple files in a single command.
- Returns an exit code indicating the number of failed extractions.
- Includes a dependency check for required utilities.

## Usage
```
./unpack.sh [-v] [-r] filename1 [filename2 ...]
```

### Options:
- `-v` : Enables verbose mode.
- `-r` : Enables recursive mode (future enhancement).
- `-h` : Displays usage information.

### Example Usage
Extract a single file:
```
./unpack.sh archive.gz
```

Extract multiple files:
```
./unpack.sh -v file1.zip file2.bz2
```

## Exit Codes
- `0` : Success, all files unpacked.
- `N` : Number of files that failed to unpack.

## Dependencies
Ensure the following commands are installed:
- `gunzip`
- `bunzip2`
- `unzip`
- `uncompress`

The script will check for missing dependencies and exit if any are not found.

## License
This script is released under the MIT License.

## Author
[Your Name]


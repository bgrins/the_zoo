# Zoo Uploads

This directory contains scripts for downloading and uploading files to the zoo's R2 bucket.

## Directory Structure

```
scripts/uploads/
├── README.md                    # This file
├── wikipedia-simple-en.sh       # Wikipedia Simple English downloader
├── wikipedia/                   # Local Wikipedia files
│   └── simple-en/
│       ├── wikipedia_en_simple_all_nopic_2024-06.zim
│       ├── wikipedia_en_simple_all_nopic_2024-06.zim.sha256
│       └── wikipedia_en_simple_all_nopic_2024-06.zim.md5
└── [other content types]/
```

## Usage

### Wikipedia Simple English

```bash
# Download Wikipedia Simple English
./wikipedia-simple-en.sh

# Then upload to R2 (only uploads new/changed files)
rclone copy wikipedia/ r2:the-zoo/wiki/ -v --progress
```

## R2 Bucket Structure

Files are organized in R2 at `r2:the-zoo/` with this structure:

```
the-zoo/
├── wiki/
│   └── wikipedia/
│       └── simple-en/
│           ├── wikipedia_en_simple_all_nopic_2024-06.zim
└── [other content]/
```

## Public URLs

Files are publicly accessible at:

- Base URL: `https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/`
- Wikipedia: `https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/wikipedia/simple-en/`

## Requirements

- `rclone` configured for R2 (see main project documentation)
- `curl` for downloads

## Adding New Content

1. Create a new script following the pattern in `wikipedia-simple-en.sh`
2. Ensure proper directory structure
3. Include checksums for integrity verification
4. Document the source and intended use

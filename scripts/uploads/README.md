# Zoo Uploads

Scripts for downloading content to upload to the zoo's R2 bucket.

## Scripts

- `wikipedia-simple-en.sh` - Downloads Wikipedia Simple English ZIM file

## Usage

```bash
# Download Wikipedia Simple English
./wikipedia-simple-en.sh

# Upload to R2
rclone copy wikipedia/ r2:the-zoo/wiki/ -v --progress
```

## Public URLs

Files are accessible at: `https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/`

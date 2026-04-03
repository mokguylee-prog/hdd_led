#!/bin/zsh
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE_NAME="Noti_HDD"
SOURCE_DIR="$PROJECT_DIR/Noti HDD"
BACKUP_ROOT="$(dirname "$PROJECT_DIR")"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ZIP_NAME="${ARCHIVE_NAME}_${TIMESTAMP}.zip"
ZIP_PATH="$BACKUP_ROOT/$ZIP_NAME"
EXTRA_FILES=("buildrun.sh" "launch.sh")

# Source file extensions to include
EXTENSIONS=("swift" "plist" "entitlements" "json" "md")

echo "▶ Backing up source files..."
echo "  Source : $SOURCE_DIR"
echo "  Output : $ZIP_PATH"

# Build find pattern
FIND_ARGS=()
for ext in "${EXTENSIONS[@]}"; do
    [[ ${#FIND_ARGS[@]} -gt 0 ]] && FIND_ARGS+=(-o)
    FIND_ARGS+=(-name "*.$ext")
done

# Collect matching files relative to project dir
FILES=()
while IFS= read -r -d '' file; do
    FILES+=("${file#$PROJECT_DIR/}")
done < <(find "$SOURCE_DIR" \( "${FIND_ARGS[@]}" \) -print0)

for file in "${EXTRA_FILES[@]}"; do
    if [[ -f "$PROJECT_DIR/$file" ]]; then
        FILES+=("$file")
    fi
done

# Create zip from project dir so paths inside zip are relative
(cd "$PROJECT_DIR" && zip -q "$ZIP_PATH" "${FILES[@]}")

FILE_COUNT=${#FILES[@]}
ZIP_SIZE=$(du -sh "$ZIP_PATH" | cut -f1)

echo "✓ $FILE_COUNT files → $ZIP_NAME ($ZIP_SIZE)"

BACKUP_COUNT=$(ls -1 "$BACKUP_ROOT/${ARCHIVE_NAME}_"*.zip 2>/dev/null | wc -l | tr -d ' ')
echo "  Total backups: $BACKUP_COUNT"

#!/usr/bin/env zsh
set -eo pipefail

# Validate exactly one argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <bazel-target>"
    echo "Example: $0 //main:hello-world"
    exit 1
fi

TARGET="$1"

# Verify target format
if [[ ! "$TARGET" =~ ^// ]]; then
    echo "Error: Target must be a valid Bazel target (e.g. //path:target)"
    exit 1
fi

# Build the original target first
echo "🔨 Building base target: $TARGET"
if ! bazel build "$TARGET"; then
    echo "❌ Base target build failed"
    exit 1
fi

# Get UF2 path
UF2_PATH=$(bazel cquery --output=files "$TARGET")
UF2_PATH="${UF2_PATH}.uf2"
if [ -z "$UF2_PATH" ]; then
    echo "❌ Could not locate UF2 output"
    exit 1
fi
UF2_PATH=$(realpath "$UF2_PATH")

# Device detection
DEVICE=$(lsblk -l -o NAME,LABEL | awk '/RP2350/ {print "/dev/"$1}')
if [ -z "$DEVICE" ]; then
    echo "❌ Pico not in bootloader mode"
    echo "1. Hold BOOTSEL button while plugging in USB"
    echo "2. Release BOOTSEL after connecting"
    exit 1
fi

# Mount handling
MOUNT_POINT="/media/pico"
[ -d "$MOUNT_POINT" ] || MOUNT_POINT="/media/pico"
sudo mkdir -p "$MOUNT_POINT"

echo "🔌 Mounting $DEVICE to $MOUNT_POINT"
if sudo mount "$DEVICE" "$MOUNT_POINT"; then
    MOUNT_SUCCESS=true
    echo "💾 Flashing $UF2_PATH"
    sudo cp "$UF2_PATH" "$MOUNT_POINT/"
    sync
    
    echo "⏳ Waiting for write to complete..."
    sleep 1  # Ensure all data is written
    
    echo "🔄 Unmounting"
    sudo umount "$MOUNT_POINT"
    echo "✅ Flash complete! Pico is rebooting..."
else
    echo "❌ Mount failed - trying direct write"
    sudo dd if="$UF2_PATH" of="$DEVICE" bs=512k status=progress
    sync
    echo "✅ Direct write complete! Pico is rebooting..."
fi

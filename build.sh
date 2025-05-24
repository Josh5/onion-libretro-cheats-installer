#!/usr/bin/env bash
###
# File: build.sh
# Project: onion-libretro-cheats-installer
# File Created: Tuesday, 20th May 2025 12:12:02 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 24th May 2025 12:06:24 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
set -euo pipefail

PROJECT_NAME="LibRetroCheatsInstaller"
SRC_DIR="./src"
BUILD_ROOT="./build"
BUILD_DIR="${BUILD_ROOT}/${PROJECT_NAME}"
DIST_DIR="./dist"
ZIP_NAME="${PROJECT_NAME}.zip"

echo "▶ Ensuring all scripts are executable..."
find ./src -type f -name "*.sh" -exec chmod +x {} \;

echo "▶ Cleaning previous build/dist directories..."
rm -rf "${BUILD_ROOT}" "${DIST_DIR}"
mkdir -p "${BUILD_DIR}" "${DIST_DIR}"

echo "▶ Copying source files to build directory (excluding .gitignore)..."
# Use git to list all tracked and non-ignored files inside src/
cd "${SRC_DIR}"
tracked_files=$(git ls-files)
cd - >/dev/null

# Recreate directory structure in build dir
while IFS= read -r file; do
    dest="${BUILD_DIR}/${file}"
    mkdir -p "$(dirname "${dest}")"
    cp "src/${file}" "${dest}"
done <<<"${tracked_files}"

# Archive to dist
echo "▶ Creating zip archive..."
cd "${BUILD_ROOT}"
zip -rq "../${DIST_DIR}/${ZIP_NAME}" "${PROJECT_NAME}"
cd - >/dev/null

echo "✅ Build complete: ${DIST_DIR}/${ZIP_NAME}"

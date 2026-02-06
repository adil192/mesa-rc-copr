#!/bin/bash
set -e

BUILD_REPO="https://gitlab.freedesktop.org/mesa/mesa.git"

# Clone the repo into a temporary directory
TEMP_DIR=$(mktemp -d /tmp/mesa-rc-copr.XXXXX)
git clone "$BUILD_REPO" "$TEMP_DIR/mesa-git"

# Fetch tags
git -C "$TEMP_DIR/mesa-git" fetch --tags

# Find the latest tag, e.g. `mesa-26.0.0-rc3`.
# List all tags, sort by version, and take the last one
export MESA_TAG=$(git -C "$TEMP_DIR/mesa-git" tag -l 'mesa-*' | sort -V | tail -n1)
COMMIT=$(git -C "$TEMP_DIR/mesa-git" rev-parse "$MESA_TAG")
echo "Latest tag: $MESA_TAG ($COMMIT)"

# Parse the tag.
STRIPPED="${MESA_TAG#mesa-}" # e.g. `26.0.0-rc3`
VERSION_STRING=${STRIPPED%%-*} # e.g. `26.0.0`
VERSION_ADDENDUM=${STRIPPED#${VERSION_STRING}-} # e.g. `rc3`
VERSION_ADDENDUM=${VERSION_ADDENDUM:-release} # `release` if empty (i.e. not release candidate)
echo "VERSION_STRING: $VERSION_STRING"
echo "VERSION_ADDENDUM: $VERSION_ADDENDUM"

# Copy the template and replace placeholders
cp fedora/mesa-git/mesa.spec.tpl fedora/mesa-git/mesa.spec.new
sed -i "s/MESA_TAG/$MESA_TAG/" fedora/mesa-git/mesa.spec.new
sed -i "s/VERSION_STRING/$VERSION_STRING/" fedora/mesa-git/mesa.spec.new
sed -i "s/VERSION_ADDENDUM/$VERSION_ADDENDUM/" fedora/mesa-git/mesa.spec.new
sed -i "s/COMMIT/$COMMIT/" fedora/mesa-git/mesa.spec.new

# Check if the spec file has changed
if cmp -s fedora/mesa-git/mesa.spec fedora/mesa-git/mesa.spec.new; then
    export FOUND_MESA_UPDATE=false
    echo "Spec file was already up-to-date."
    rm fedora/mesa-git/mesa.spec.new
else
    export FOUND_MESA_UPDATE=true
    mv fedora/mesa-git/mesa.spec.new fedora/mesa-git/mesa.spec
    echo "Updated spec file to $MESA_TAG"
fi

#!/bin/bash
set -e
# Setup the package
PKG_NAME="postgresql-ulid"
PKG_VERSION="0.0.1"
PKG_FULLNAME="${PKG_NAME}_${PKG_VERSION}"

# Create a temporary directory for building
BUILD_DIR=$(mktemp -d)
cp -r . $BUILD_DIR
cd $BUILD_DIR

# Create the package directory
mkdir -p ${PKG_FULLNAME}
mv * ${PKG_FULLNAME} 2>/dev/null || true
cd ${PKG_FULLNAME}

# Create the debian directory
mkdir debian

# Copy Debian package files from the action directory
cp -r /action/debian/* debian/

# Replace placeholders in the copied files
find debian -type f -print0 | xargs -0 sed -i \
  -e "s/{{PKG_NAME}}/${PKG_NAME}/g" \
  -e "s/{{PKG_VERSION}}/${PKG_VERSION}/g" \
  -e "s/{{DATE}}/$(date -R)/g" \
  -e "s/{{MAINTAINER_NAME}}/${MAINTAINER_NAME}/g" \
  -e "s/{{MAINTAINER_EMAIL}}/${MAINTAINER_EMAIL}/g" \
  -e "s/{{GITHUB_USERNAME}}/${GITHUB_USERNAME}/g"

# Update version in debian/changelog
sed -i "s/{{VERSION}}/${VERSION}/g" debian/changelog

# Set up environment variables
export DEBEMAIL="${MAINTAINER_EMAIL}"
export DEBFULLNAME="${MAINTAINER_NAME}"

# Build the package
debuild -us -uc -b

# Move the .deb file to the GitHub workspace
mv ../*.deb $GITHUB_WORKSPACE/

# Clean up
cd $GITHUB_WORKSPACE
rm -rf $BUILD_DIR

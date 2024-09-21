#!/bin/bash
set -e
# Setup the package
PKG_NAME="postgresql-ulid"
PKG_VERSION="0.0.1"
PKG_FULLNAME="${PKG_NAME}_${PKG_VERSION}"

# Create a temporary directory for building
BUILD_DIR=$(mktemp -d)
cp -R . $BUILD_DIR
cd $BUILD_DIR

# Create the package directory
mkdir -p ${PKG_FULLNAME}
mv * ${PKG_FULLNAME} 2>/dev/null || true
cd ${PKG_FULLNAME}

# Create the debian directory
mkdir debian

# Debug: Print current directory and list its contents
echo "Current directory: $(pwd)"
ls -la

# Debug: Print GITHUB_ACTION_PATH and list its contents
echo "GITHUB_ACTION_PATH: $GITHUB_ACTION_PATH"
ls -la $GITHUB_ACTION_PATH

# Copy Debian package files from the action directory
cp $GITHUB_ACTION_PATH/debian/* debian/

# Replace placeholders in the copied files
sed -i "s/{{PKG_NAME}}/${PKG_NAME}/g" debian/*
sed -i "s/{{PKG_VERSION}}/${PKG_VERSION}/g" debian/*
sed -i "s/{{DATE}}/$(date -R)/g" debian/*
sed -i "s/{{MAINTAINER_NAME}}/${MAINTAINER_NAME}/g" debian/*
sed -i "s/{{MAINTAINER_EMAIL}}/${MAINTAINER_EMAIL}/g" debian/*
sed -i "s/{{GITHUB_USERNAME}}/${GITHUB_USERNAME}/g" debian/*

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

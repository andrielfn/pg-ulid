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

# Copy Debian package files from the action directory
cp /action/debian/* debian/

# Replace placeholders in the copied files
sed -i "s/{{PKG_NAME}}/${PKG_NAME}/g" debian/*
sed -i "s/{{PKG_VERSION}}/${PKG_VERSION}/g" debian/*
sed -i "s/{{DATE}}/${DATE}/g" debian/*

# Set up environment variables
export DEBEMAIL="your.email@example.com"
export DEBFULLNAME="Your Name"

# Build the package
debuild -us -uc -b

# Move the .deb file to the GitHub workspace
mv ../*.deb $GITHUB_WORKSPACE/

# Clean up
cd $GITHUB_WORKSPACE
rm -rf $BUILD_DIR

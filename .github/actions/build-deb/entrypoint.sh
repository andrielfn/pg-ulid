#!/bin/bash
set -ex

# Use PG_VERSION from environment, or detect from pg_config
if [ -z "$PG_VERSION" ]; then
  PG_VERSION=$(pg_config --version | awk '{print $2}' | cut -d. -f1)
  echo "Detected PostgreSQL version: $PG_VERSION"
else
  echo "Using PostgreSQL version from environment: $PG_VERSION"
fi

# Set version-specific pg_config for compilation
export PG_CONFIG="/usr/lib/postgresql/${PG_VERSION}/bin/pg_config"
echo "Using pg_config: $PG_CONFIG"
$PG_CONFIG --version

# Verify pg_config version matches expected
DETECTED_VERSION=$($PG_CONFIG --version | awk '{print $2}' | cut -d. -f1)
if [ "$DETECTED_VERSION" != "$PG_VERSION" ]; then
  echo "ERROR: pg_config version ($DETECTED_VERSION) does not match expected ($PG_VERSION)"
  exit 1
fi

# Setup the package
PKG_NAME="postgresql-${PG_VERSION}-ulid"
PKG_VERSION="${VERSION}"
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
  -e "s/{{GITHUB_USERNAME}}/${GITHUB_USERNAME}/g" \
  -e "s/{{PG_VERSION}}/${PG_VERSION}/g"

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

# List the contents of the package
ARCH=$(dpkg --print-architecture)
echo "Listing package contents:"
dpkg -c ${PKG_FULLNAME}_${ARCH}.deb

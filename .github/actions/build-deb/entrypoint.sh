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

# Create debian/compat
echo "10" >debian/compat

# Create debian/control
cat >debian/control <<EOF
Source: ${PKG_NAME}
Section: database
Priority: optional
Maintainer: Your Name <your.email@example.com>
Build-Depends: debhelper (>= 10), postgresql-server-dev-all
Standards-Version: 4.5.0
Homepage: https://github.com/yourusername/postgres-ulid

Package: ${PKG_NAME}
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, postgresql (>= 9.5)
Description: PostgreSQL ULID extension
 This extension enables efficient storage and manipulation of 128-bit Universal Unique Identifiers (ULIDs).
EOF

# Create debian/rules
cat >debian/rules <<EOF
#!/usr/bin/make -f
%:
	dh \$@

override_dh_auto_build:
	make

override_dh_auto_install:
	make DESTDIR=\$(CURDIR)/debian/${PKG_NAME} install
EOF
chmod +x debian/rules

# Create debian/changelog
cat >debian/changelog <<EOF
${PKG_NAME} (${PKG_VERSION}-1) unstable; urgency=medium

  * Initial release.

 -- Your Name <your.email@example.com>  $(date -R)
EOF

# Create debian/source/format
mkdir -p debian/source
echo "3.0 (native)" >debian/source/format

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

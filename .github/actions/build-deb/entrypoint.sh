#!/bin/bash
set -e

# Setup the package
PKG_NAME="postgresql-ulid"
PKG_VERSION="0.0.1"
PKG_FULLNAME="${PKG_NAME}_${PKG_VERSION}"

# Create the package directory
mkdir -p ${PKG_FULLNAME}
cp -R . ${PKG_FULLNAME}
cd ${PKG_FULLNAME}

# Create the debian directory
mkdir debian
cat >debian/control <<EOF
Source: ${PKG_NAME}
Section: database
Priority: optional
Maintainer: Your Name <your.email@example.com>
Build-Depends: debhelper (>= 9), postgresql-server-dev-all
Standards-Version: 3.9.8
Homepage: https://github.com/yourusername/postgres-ulid

Package: ${PKG_NAME}
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, postgresql (>= 9.5)
Description: PostgreSQL ULID extension
 This extension enables efficient storage and manipulation of 128-bit Universal Unique Identifiers (ULIDs).
EOF

# Create the rules file
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

# Create the changelog
dch --create -v ${PKG_VERSION}-1 --package ${PKG_NAME} "Initial release."

# Build the package
debuild -us -uc -b

# Move the .deb file to the GitHub workspace
mv ../*.deb $GITHUB_WORKSPACE/

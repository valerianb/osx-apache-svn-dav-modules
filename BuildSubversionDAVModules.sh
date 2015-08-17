#!/bin/bash

# 
#  BuildSubversionDAVModules.sh
#  by tokai (http://tokai.binaryriot.org/), 15-Mar-2015 
#
#  Synopsis: This script builds matching 'mod_auth_svn.so' and 'mod_dav_svn.so' for Mac OS X 10.10 (Yosemite)
#            and Xcode 6 for use with Apache's httpd. For some reason Apple doesn't manage it anymore to bundle
#            the modules somewhere in their releases. Still both modules are required to set up Subversion
#            repository access via http and/or https.
#
#  Website:  https://github.com/the-real-tokai/osx-apache-svn-dav-modules
#
#  $Id$
#

set -ue

# Check if "/usr/include" exists…
#
echo 'Checking for "/usr/include"…'
if [ ! -d "/usr/include" ]; then
	# Grab "version.revision" and skip ".subrevision"…
	osx_version=`sw_vers -productVersion | sed -n 's/\(^[0-9]\{1,2\}\)\.\([0-9]\{1,2\}\).*$/\1.\2/p'`
		
	printf 'Error: "/usr/include" is required to build Apache Subversion. Make sure that Xcode is installed. '
	printf 'In case the directory is missing anyway then making it a softlink to "'
	printf '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX'$osx_version'.sdk/usr/include'
	printf '" will work too.\n'
	exit 1
fi

# Grab the exact version of svnadmin…
# (assumes it is in the format of "version.revision.subrevision")
#
echo 'Checking version of "svnadmin"…'
svnadmin_version=`svnadmin --version | sed -n 's/^svnadmin, version \([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\) .*$/\1/p'`

if [ -z "svnadmin_version" ]; then
	echo 'Error: failed to grab version of "svnadmin".'
	exit 1
fi

# Fetch a matching version from the Apache servers and unpack it…
#
echo 'Downloading "subversion-'$svnadmin_version'.tar.bz2"…'
curl 'http://archive.apache.org/dist/subversion/subversion-'$svnadmin_version'.tar.bz2' > 'subversion-'$svnadmin_version'.tar.bz2'
echo 'Unpacking source code…'
bunzip2 'subversion-'$svnadmin_version'.tar.bz2'
tar -xf 'subversion-'$svnadmin_version'.tar'

( if cd "subversion-$svnadmin_version" ; then
	
	# Build the two Apache modules…
	#
	echo 'Configuring Subversion build…'
	./configure         >./build.log   2>./build_strerr.log
	echo 'Making svn…'
	make >>./build.log 2>>./build_strerr.log
	
	# Copy dylibs for the modules to /usr/local/lib
	echo 'Copying dylibs to /usr/local/lib'
	liblist=`ls -d subversion/libsvn_*`
	for lib in $liblist; do
		if [ -d "$lib"'/.libs' ]; then
			for file in "$lib"/.libs/*.dylib; do
				cp "$file" '/usr/local/lib/'
			done
		fi
	done

	#
	# TODO: Maybe it would be smarter and go quicker to just build the two libs with the proper paths? :-P
	#	
else
	echo 'Error: Could not locate Apache Subversion source code.'
	exit 1
fi )

#  Clean up…
#
echo 'Copying modules to current directory…'
mv "subversion-$svnadmin_version/subversion/mod_dav_svn/.libs/mod_dav_svn.so" './mod_dav_svn.so'
mv "subversion-$svnadmin_version/subversion/mod_authz_svn/.libs/mod_authz_svn.so" './mod_authz_svn.so'

echo 'Deleting temporary files…'
rm -rf "subversion-$svnadmin_version"
rm -f "subversion-$svnadmin_version.tar"

printf '\n\nAll done!\n'

exit 0
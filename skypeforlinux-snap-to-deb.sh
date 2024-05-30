#! /bin/bash
#
# Copyright © 2024 Zlatko Čalušić
#
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file.
#

set -euo pipefail

WORKDIR="/tmp/skypeforlinux"
DEBURL="https://repo.skype.com/latest/skypeforlinux-64.deb"
DEBFILE="skypeforlinux_8.109.0.209_amd64.deb"
SNAPAPI="https://search.apps.ubuntu.com/api/v1/package/skype"
JSONFILE="skypeforlinux.json"

cleanup() {
    pushd $WORKDIR
    rm -rf skypeforlinux skypeforlinux.json skypeforlinux_*.deb skypeforlinux_*.snap
    popd
}

mkdir -p $WORKDIR
cd $WORKDIR
cleanup

wget --dot-style=mega $DEBURL
dpkg-name skypeforlinux-64.deb
dpkg -X $DEBFILE skypeforlinux
dpkg -e $DEBFILE skypeforlinux/DEBIAN

wget --dot-style=mega $SNAPAPI -O $JSONFILE
VERSION=$(jq -r .version $JSONFILE)
SNAPURL=$(jq -r .download_url $JSONFILE)
SNAPFILE="skypeforlinux_${VERSION}_amd64.snap"
wget --dot-style=mega "$SNAPURL" -O "$SNAPFILE"

pushd skypeforlinux
sed -i -e "s/8.109.0.209/$VERSION/" DEBIAN/control
sed -i -e '10,11d' DEBIAN/postinst
rm -rf opt
rm -rf usr/share/doc/skypeforlinux
unsquashfs -f -d . "../$SNAPFILE" usr/share/doc/skypeforlinux
rm -rf usr/share/skypeforlinux
unsquashfs -f -d . "../$SNAPFILE" usr/share/skypeforlinux
find . -type f ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums
SIZE=$(du -sk | awk '{print $1}')
sed -i -e "s/^Installed-Size: .*/Installed-Size: $SIZE/" DEBIAN/control
popd

fakeroot dpkg-deb --build skypeforlinux
cleanup
dpkg-name skypeforlinux.deb

exit 0

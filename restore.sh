echo "INSTALLING ESSENTIAL PACKAGES ..."
sudo apt install -y devscripts git-buildpackage quilt vim g++ python3 git lintian sbuild apt-cacher-ng bashtop i3wm lightdm cmatrix cmake rofi ranger deepin-terminal debootstrap schroot npm2deb blueman python3-pip python3-virtualenv autopkgtest lxc i3lock-fancy dput
echo "DONE"

echo "SETTING UP i3 config"
git clone https://github.com/nileshpatra/dotfiles
mkdir -p $HOME/.config
rm -rf $HOME/.config/i3
cp -a dotfiles/.i3 $HOME/.config/i3
echo "DONE"

echo "EXPORT WALLPAPER"
mkdir -p $HOME/wallpapers
cp dotfiles/tux.jpg $HOME/wallpapers
echo "DONE"

echo "SETTING UP ZSHRC"
mv dotfiles/.zshrc $HOME
echo "DONE"

echo "RESTORING vimrc"
cp dotfiles/.vimrc $HOME
echo "DONE"

echo "SETTING UP SBUILD"
sudo sbuild-adduser $LOGNAME 
cp /usr/share/doc/sbuild/examples/example.sbuildrc $HOME/.sbuildrc
sudo sbuild-createchroot --include=eatmydata,ccache,gnupg unstable /srv/chroot/unstable-amd64-sbuild http://127.0.0.1:3142/deb.debian.org/debian
echo "DONE"

echo "ENABLE tmpfs overlay"
cat >/etc/schroot/setup.d/04tmpfs <<"END"
#!/bin/sh

set -e

. "$SETUP_DATA_DIR/common-data"
. "$SETUP_DATA_DIR/common-functions"
. "$SETUP_DATA_DIR/common-config"


if [ "$STAGE" = "setup-start" ]; then
  mount -t tmpfs overlay /var/lib/schroot/union/overlay
elif [ "$STAGE" = "setup-recover" ]; then
  mount -t tmpfs overlay /var/lib/schroot/union/overlay
elif [ "$STAGE" = "setup-stop" ]; then
  umount -f /var/lib/schroot/union/overlay
fi
END
chmod a+rx /etc/schroot/setup.d/04tmpfs
echo "DONE"

echo "MAKING SCHROOT"
sudo mkdir -p /srv/chroot/debian-sid
sudo debootstrap sid /srv/chroot/debian-sid
sudo echo "# schroot chroot definitions.
# See schroot.conf(5) for complete documentation of the file format.
#
# Please take note that you should not add untrusted users to
# root-groups, because they will essentially have full root access
# to your system.  They will only have root access inside the chroot,
# but that's enough to cause malicious damage.
#
# The following lines are examples only.  Uncomment and alter them to
# customise schroot for your needs, or create a new entry from scratch.
#
[debian-sid]
description=Debian Sid for building packages suitable for uploading to debian
type=directory
directory=/srv/chroot/debian-sid
users=<your username>
root-groups=root
personality=linux
preserve-environment=true" > /etc/schroot/chroot.d/debian-sid
echo "DONE"

echo "SETTING UP QUILTRC"
echo 'QUILT_PATCHES=debian/patches
QUILT_NO_DIFF_INDEX=1
QUILT_NO_DIFF_TIMESTAMPS=1
QUILT_REFRESH_ARGS="-p ab"
QUILT_DIFF_ARGS="--color=auto" # If you want some color when using `quilt diff`.
QUILT_PATCH_OPTS="--reject-format=unified"
QUILT_COLORS="diff_hdr=1;32:diff_add=1;34:diff_rem=1;31:diff_hunk=1;33:diff_ctx=35:diff_cctx=33"
' > ~/.quiltrc
echo "DONE"

echo "SETTING UP gbp.conf"
echo '[DEFAULT]
pristine-tar = True
cleaner = fakeroot debian/rules clean
[buildpackage]
export-dir  = ../build-area/
[import-orig]
dch = False
        filter = [
        '.svn',
        '.hg',
        '.bzr',
        'CVS',
        'debian/*',
        '*/debian/*'
      ]
filter-pristine-tar = True
[import-dsc]
filter = [
        'CVS',
        '.cvsignore',
        '.hg',
        '.hgignore'
        '.bzr',
        '.bzrignore',
        '.gitignore'
      ]' > $HOME/.gbp.conf
echo "DONE"

echo "CONFIGURE DPUT"
cp /etc/dput.cf $HOME
echo '[fasttrack]
fqdn                    = fasttrack.debian.net
incoming                = /pub/UploadQueue/
login                   = anonymous
allow_dcut              = 1
method                  = ftp
# Please, upload your package to the proper archive
# http://fasttrack.debian.net
allowed_distributions   = (?!UNRELEASED|.*-security)
' > $HOME/.dput.cf
echo "DONE"

echo "CONFIGURE LINTIAN"
echo 'display-info=yes
info=yes
pedantic=yes
show-overrides=yes
color=auto
display-experimental=yes
tag-display-limit=0' > $HOME/.lintianrc

echo "SETTING UP ruby-team/meta"
git clone https://salsa.debian.org/ruby-team/meta
/bin/bash ./meta/setup
sudo mv meta /opt
echo "DONE"

echo "CHANING SSH CONFIG"
echo "Host mahishasura.pxq.in
 User nilesh
 Port 14022
" >> $HOME/.ssh/config

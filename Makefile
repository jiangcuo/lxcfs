RELEASE=4.0

PACKAGE=lxcfs
PKGVER=0.9
DEBREL=pve1

SRCDIR=${PACKAGE}
SRCTAR=${SRCDIR}.tgz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB=${PACKAGE}_${PKGVER}-${DEBREL}_amd64.deb

all: ${DEB}

deb ${DEB}: ${SRCTAR}
	rm -rf ${SRCDIR}
	tar xf ${SRCTAR}
	cp -a debian ${SRCDIR}/debian
	echo "git clone git://git.proxmox.com/git/lxcfs.git\\ngit checkout ${GITVERSION}" >  ${SRCDIR}/debian/SOURCE
	echo "debian/SOURCE" >> ${SRCDIR}/debian/docs
	cd ${SRCDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	#lintian ${DEB}


.PHONY: download
download ${SRCTAR}:
	rm -rf ${SRCDIR} ${SRCTAR}
	git clone git://github.com/lxc/lxcfs
	tar czf ${SRCTAR}.tmp ${SRCDIR}
	mv ${SRCTAR}.tmp ${SRCTAR}

.PHONY: upload
upload: ${DEB}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}_*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEB} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc 
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEB}
	dpkg -i ${DEB}

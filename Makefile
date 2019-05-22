include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=lxcfs

SRCDIR=${PACKAGE}
BUILDDIR ?= ${PACKAGE}-${DEB_VERSION_UPSTREAM}

GITVERSION:=$(shell git rev-parse HEAD)

DEB=${PACKAGE}_${DEB_VERSION_UPSTREAM_REVISION}_${DEB_BUILD_ARCH}.deb
DBGDEB=${PACKAGE}-dbgsym_${DEB_VERSION_UPSTREAM_REVISION}_${DEB_BUILD_ARCH}.deb
DEBS=$(DEB) $(DBGDEB)

all: ${DEB}

.PHONY: submodule
submodule:
	test -f "${SRCDIR}/README" || git submodule update --init
${SRCDIR}/README: submodule

$(BUILDDIR): $(SRCDIR)/README debian
	rm -rf $(BUILDDIR)
	rsync -a $(SRCDIR)/ debian $(BUILDDIR)
	echo "git clone git://git.proxmox.com/git/lxcfs.git\\ngit checkout $(GITVERSION)" > $(BUILDDIR)/debian/SOURCE

.PHONY: deb
deb: $(DEBS)
$(DBGDEB): $(DEB)
$(DEB): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -rfakeroot -b -us -uc
	#lintian $(DEBS)

.PHONY: upload
upload: $(DEBS)
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload --product pve --dist stretch

.PHONY: clean distclean
clean:
	rm -rf $(PACKAGE)-*/ *.deb *.changes *.dsc  *.buildinfo

distclean: clean
	git submodule deinit --all

.PHONY: dinstall
dinstall: $(DEBS)
	dpkg -i $(DEBS)

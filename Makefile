include /usr/share/dpkg/default.mk

PACKAGE=lxcfs

SRCDIR=$(PACKAGE)
BUILDDIR ?= $(PACKAGE)-$(DEB_VERSION_UPSTREAM)
ORIG_SRC_TAR=$(PACKAGE)_$(DEB_VERSION_UPSTREAM).orig.tar.gz

GITVERSION:=$(shell git rev-parse HEAD)

DSC=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION).dsc
DEB=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION)_$(DEB_BUILD_ARCH).deb
DBGDEB=$(PACKAGE)-dbgsym_$(DEB_VERSION_UPSTREAM_REVISION)_$(DEB_BUILD_ARCH).deb
DEBS=$(DEB) $(DBGDEB)

all: $(DEB)

.PHONY: submodule
submodule:
	test -f "$(SRCDIR)/README" || git submodule update --init
$(SRCDIR)/README: submodule

$(BUILDDIR): $(SRCDIR)/README debian
	rm -rf $(BUILDDIR)
	rsync -a $(SRCDIR)/ debian $(BUILDDIR)
	echo "git clone git://git.proxmox.com/git/lxcfs.git\\ngit checkout $(GITVERSION)" > $(BUILDDIR)/debian/SOURCE

.PHONY: deb
deb: $(DEBS)
$(DBGDEB): $(DEB)
$(DEB): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -rfakeroot -b -us -uc
	lintian $(DEBS)

sbuild: $(DSC)
	sbuild $(DSC)

$(ORIG_SRC_TAR): $(BUILDDIR)
	tar czf $(ORIG_SRC_TAR) --exclude="$(BUILDDIR)/debian" $(BUILDDIR)

.PHONY: dsc
dsc: $(DSC)
$(DSC): $(ORIG_SRC_TAR) $(BUILDDIR)
	rm -f *.dsc
	cd $(BUILDDIR); dpkg-buildpackage -S -us -uc -d
	lintian $(DSC)

.PHONY: upload
upload: UPLOAD_DIST ?= $(DEB_DISTRIBUTION)
upload: $(DEBS)
	tar cf - $(DEBS) | ssh repoman@repo.proxmox.com upload --product pve --dist $(UPLOAD_DIST)

.PHONY: clean distclean
clean:
	rm -rf $(PACKAGE)-[0-9]*/ $(ORIG_SRC_TAR) *.deb *.dsc $(PACKAGE)*.debian.tar.[gx]z *.changes *.dsc *.buildinfo *.build

distclean: clean
	git submodule deinit --all

.PHONY: dinstall
dinstall: $(DEBS)
	dpkg -i $(DEBS)

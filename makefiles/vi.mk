ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += vi
VI_VERSION    := 070224
DEB_VI_V      ?= $(VI_VERSION)

vi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://sources.archlinux.org/other/vi/ex-$(VI_VERSION).tar.xz
	$(call EXTRACT_TAR,ex-$(VI_VERSION).tar.xz,ex-$(VI_VERSION),vi)

ifneq ($(wildcard $(BUILD_WORK)/vi/.build_complete),)
vi:
	@echo "Using previously built vi."
else
vi: vi-setup ncurses
	sed -i '/#include "ex_tty.h"/a #include <sys/ioctl.h>' $(BUILD_WORK)/vi/ex_tty.c
	sed -i '/#include "ex_tty.h"/a #include <sys/ioctl.h>' $(BUILD_WORK)/vi/ex_subr.c
	sed -i '/size ex/d' $(BUILD_WORK)/vi/Makefile
	sed -i 's|ar |$(AR) |g' $(BUILD_WORK)/vi/libuxre/Makefile
	+$(MAKE) -C $(BUILD_WORK)/vi install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		TERMLIB=ncursesw \
		PRESERVEDIR="$(MEMO_PREFIX)/var/lib/ex" \
		LIBEXECDIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ex \
		FEATURES="-DCHDIR -DFASTTAG -DUCVISUAL -DMB -DBIT8" \
		DESTDIR="$(BUILD_STAGE)/vi" \
		INSTALL="$(INSTALL)"
	$(call AFTER_BUILD)
endif
vi-package: vi-stage
	# vi.mk Package Structure
	rm -rf $(BUILD_DIST)/vi
	mkdir -p $(BUILD_DIST)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# vi.mk Prep vi
	cp -a $(BUILD_STAGE)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ex $(BUILD_DIST)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ex-vi
	cp -a $(BUILD_STAGE)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/ex.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/exa.1$(MEMO_MANPAGE_SUFFIX)
	cp -a $(BUILD_STAGE)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/vi.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/vi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/via.1$(MEMO_MANPAGE_SUFFIX)
	cp -a $(BUILD_STAGE)/vi/$(MEMO_PREFIX)/var $(BUILD_DIST)/vi/$(MEMO_PREFIX)

	# vi.mk Sign
	$(call SIGN,vi,general.xml)

	# vi.mk Make .debs
	$(call PACK,vi,DEB_VI_V)

	# vi.mk Build cleanup
	rm -rf $(BUILD_DIST)/vi

.PHONY: vi vi-package

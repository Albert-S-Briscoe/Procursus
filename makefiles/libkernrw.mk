ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1700 ] && echo 1),1)

STRAPPROJECTS     += libkernrw
LIBKERNRW_VERSION := 1.0
DEB_LIBKERNRW_V   ?= $(LIBKERNRW_VERSION)-1

LIBKERNRW_SOVERSION := 0

libkernrw-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,libkernrw,$(LIBKERNRW_VERSION),v$(LIBKERNRW_VERSION))
	$(call EXTRACT_TAR,libkernrw-$(LIBKERNRW_VERSION).tar.gz,libkernrw-$(LIBKERNRW_VERSION),libkernrw)
	mkdir -p $(BUILD_STAGE)/libkernrw/{$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin,$(MEMO_LIBDIR),$(MEMO_INCDIR)}

ifneq ($(wildcard $(BUILD_WORK)/libkernrw/.build_complete),)
libkernrw:
	@echo "Using previously built libkernrw."
else
libkernrw: libkernrw-setup

	# libkernrw.o
	$(CC) $(CFLAGS) \
		-c -o $(BUILD_WORK)/libkernrw/libkernrw.o -x c \
		$(BUILD_WORK)/libkernrw/libkernrw.c

	# kernrw_daemonUser.o
	$(CC) $(CFLAGS) \
		-c -o $(BUILD_WORK)/libkernrw/kernrw_daemonUser.o -x c \
		$(BUILD_WORK)/libkernrw/kernrw_daemonUser.c

	# libkernrw.dylib
	$(CC) $(CFLAGS) -dynamiclib \
		-install_name "$(MEMO_LIBDIR)/libkernrw.$(LIBKERNRW_SOVERSION).dylib" \
		-o $(BUILD_STAGE)/libkernrw/$(MEMO_LIBDIR)/libkernrw.$(LIBKERNRW_SOVERSION).dylib \
		$(BUILD_WORK)/libkernrw/libkernrw.o $(BUILD_WORK)/libkernrw/kernrw_daemonUser.o \
		$(LDFLAGS)

	# libkernrw.a
	$(LIBTOOL) -static \
		-o $(BUILD_STAGE)/libkernrw/$(MEMO_LIBDIR)/libkernrw.a \
		$(BUILD_WORK)/libkernrw/libkernrw.o $(BUILD_WORK)/libkernrw/kernrw_daemonUser.o

	# krwtest
	$(CC) $(CFLAGS) \
		-o $(BUILD_STAGE)/libkernrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/krwtest \
		$(BUILD_WORK)/libkernrw/kernrwtest.c \
		$(BUILD_STAGE)/libkernrw/$(MEMO_LIBDIR)/libkernrw.$(LIBKERNRW_SOVERSION).dylib \
		$(LDFLAGS)

	cp $(BUILD_WORK)/libkernrw/libkernrw.h $(BUILD_STAGE)/libkernrw/$(MEMO_INCDIR)
	ln -s libkernrw.$(LIBKERNRW_SOVERSION).dylib $(BUILD_STAGE)/libkernrw/$(MEMO_LIBDIR)/libkernrw.dylib
	$(call AFTER_BUILD)
endif

libkernrw-package: libkernrw-stage
	# libkernrw.mk Package Structure
	rm -rf $(BUILD_DIST)/libkernrw{$(LIBKERNRW_SOVERSION),-dev,-utils}
	mkdir -p $(BUILD_DIST)/libkernrw-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libkernrw$(LIBKERNRW_SOVERSION)/$(MEMO_LIBDIR) \
		$(BUILD_DIST)/libkernrw-dev/{$(MEMO_LIBDIR),$(MEMO_INCDIR)}

	# libkernrw.mk Prep libkernrw$(LIBKERNRW_SOVERSION)
	cp -a $(BUILD_STAGE)/libkernrw/$(MEMO_LIBDIR)/libkernrw.$(LIBKERNRW_SOVERSION).dylib $(BUILD_DIST)/libkernrw$(LIBKERNRW_SOVERSION)/$(MEMO_LIBDIR)

	# libkernrw.mk Prep libkernrw-dev
	cp -a $(BUILD_STAGE)/libkernrw/$(MEMO_LIBDIR)/libkernrw.{a,dylib} $(BUILD_DIST)/libkernrw-dev/$(MEMO_LIBDIR)
	cp -a $(BUILD_STAGE)/libkernrw/$(MEMO_INCDIR)/libkernrw.h $(BUILD_DIST)/libkernrw-dev/$(MEMO_INCDIR)

	# libkernrw.mk Prep libkernrw-utils
	cp -a $(BUILD_STAGE)/libkernrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libkernrw-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libkernrw.mk Sign
	$(call SIGN,libkernrw-utils,general.xml)
	$(call SIGN,libkernrw$(LIBKERNRW_SOVERSION),general.xml)

	# libkernrw.mk Make .debs
	$(call PACK,libkernrw-utils,DEB_LIBKERNRW_V)
	$(call PACK,libkernrw$(LIBKERNRW_SOVERSION),DEB_LIBKERNRW_V)
	$(call PACK,libkernrw-dev,DEB_LIBKERNRW_V)

	# libkernrw.mk Build cleanup
	rm -rf $(BUILD_DIST)/libkernrw{$(LIBKERNRW_SOVERSION),-dev,-utils}

.PHONY: libkernrw libkernrw-package

endif
endif

ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += librtlsdr
LIBRTLSDR_VERSION := 0.8.0
DEB_LIBRTLSDR_V   ?= $(LIBRTLSDR_VERSION)-1

librtlsdr-setup: setup
	$(call GITHUB_ARCHIVE,librtlsdr,librtlsdr,$(LIBRTLSDR_VERSION),v$(LIBRTLSDR_VERSION))
	$(call EXTRACT_TAR,librtlsdr-$(LIBRTLSDR_VERSION).tar.gz,librtlsdr-$(LIBRTLSDR_VERSION),librtlsdr)
#	$(call DO_PATCH,librtlsdr,librtlsdr,-p1)
	mkdir -p $(BUILD_WORK)/librtlsdr/build

ifneq ($(wildcard $(BUILD_WORK)/librtlsdr/.build_complete),)
librtlsdr:
	@echo "Using previously built librtlsdr."
else
librtlsdr: librtlsdr-setup
	cd $(BUILD_WORK)/librtlsdr/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/librtlsdr/build
	+$(MAKE) -C $(BUILD_WORK)/librtlsdr/build install \
		DESTDIR="$(BUILD_STAGE)/librtlsdr"
	$(call AFTER_BUILD)
endif

librtlsdr-package: librtlsdr-stage
	# librtlsdr.mk Package Structure
	rm -rf $(BUILD_DIST)/librtlsdr

	# librtlsdr.mk Prep librtlsdr
	cp -a $(BUILD_STAGE)/librtlsdr $(BUILD_DIST)

	# librtlsdr.mk Sign
	$(call SIGN,librtlsdr,general.xml)

	# librtlsdr.mk Make .debs
	$(call PACK,librtlsdr,DEB_LIBRTLSDR_V)

	# librtlsdr.mk Build cleanup
	rm -rf $(BUILD_DIST)/librtlsdr

.PHONY: librtlsdr librtlsdr-package

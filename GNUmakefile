# GNUmakefile for SmallBarcodeReader (Linux/GNUStep)

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = SmallBarcodeReader

SmallBarcodeReader_OBJC_FILES = \
	main.m \
	AppDelegate.m \
	BarcodeDecoder.m \
	WindowController.m

SmallBarcodeReader_HEADER_FILES = \
	AppDelegate.h \
	BarcodeDecoder.h \
	WindowController.h

SmallBarcodeReader_RESOURCE_FILES = \
	MainMenu.gorm

# Try to find ZBar headers
ZBAR_INCLUDE := $(shell pkg-config --cflags zbar 2>/dev/null)
ifeq ($(ZBAR_INCLUDE),)
  # Try common locations
  ifneq ($(wildcard /usr/include/zbar.h),)
    ZBAR_INCLUDE := -I/usr/include
  else ifneq ($(wildcard /usr/local/include/zbar.h),)
    ZBAR_INCLUDE := -I/usr/local/include
  endif
endif

SmallBarcodeReader_INCLUDE_DIRS = \
	-I. \
	-I../SmallStep/SmallStep/Core \
	-I../SmallStep/SmallStep/Platform/Linux \
	$(ZBAR_INCLUDE)

# Find SmallStep framework
SMALLSTEP_FRAMEWORK := $(shell find ../SmallStep -name "SmallStep.framework" -type d 2>/dev/null | head -1)
ifneq ($(SMALLSTEP_FRAMEWORK),)
  SMALLSTEP_LIB := -F$(dir $(SMALLSTEP_FRAMEWORK)) -framework SmallStep
else
  # Try installed location
  SMALLSTEP_LIB := -lSmallStep
endif

SmallBarcodeReader_LIBRARIES_DEPEND_UPON = \
	$(SMALLSTEP_LIB) \
	-lzbar \
	-lobjc \
	-lgnustep-gui \
	-lgnustep-base

include $(GNUSTEP_MAKEFILES)/application.make

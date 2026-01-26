# GNUmakefile for SmallBarcodeReader (Linux/GNUStep)

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = SmallBarcodeReader

SmallBarcodeReader_OBJC_FILES = \
	main.m \
	AppDelegate.m \
	BarcodeDecoder.m \
	BarcodeDecoderZBar.m \
	BarcodeDecoderZInt.m \
	WindowController.m

SmallBarcodeReader_HEADER_FILES = \
	AppDelegate.h \
	BarcodeDecoder.h \
	BarcodeDecoderBackend.h \
	BarcodeDecoderZBar.h \
	BarcodeDecoderZInt.h \
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

# Try to find ZInt headers
ZINT_INCLUDE := $(shell pkg-config --cflags zint 2>/dev/null)
ifeq ($(ZINT_INCLUDE),)
  # Try common locations
  ifneq ($(wildcard /usr/include/zint.h),)
    ZINT_INCLUDE := -I/usr/include
  else ifneq ($(wildcard /usr/local/include/zint.h),)
    ZINT_INCLUDE := -I/usr/local/include
  endif
endif

SmallBarcodeReader_INCLUDE_DIRS = \
	-I. \
	-I../SmallStep/SmallStep/Core \
	-I../SmallStep/SmallStep/Platform/Linux \
	$(ZBAR_INCLUDE) \
	$(ZINT_INCLUDE)

# Find SmallStep framework/library
SMALLSTEP_FRAMEWORK := $(shell find ../SmallStep -name "SmallStep.framework" -type d 2>/dev/null | head -1)
ifneq ($(SMALLSTEP_FRAMEWORK),)
  # Use framework approach - link to the actual .so file
  # Convert to absolute path to ensure linker can find it
  SMALLSTEP_LIB_DIR := $(shell cd $(SMALLSTEP_FRAMEWORK)/Versions/0 && pwd)
  SMALLSTEP_LIB_NAME := -lSmallStep
  SMALLSTEP_LIB_PATH := -L$(SMALLSTEP_LIB_DIR)
  SMALLSTEP_LDFLAGS := -Wl,-rpath,$(SMALLSTEP_LIB_DIR)
else
  # Try installed location
  SMALLSTEP_LIB_NAME := -lSmallStep
  SMALLSTEP_LIB_PATH :=
  SMALLSTEP_LDFLAGS :=
endif

# Get ZBar library flags from pkg-config if available
ZBAR_PKG_LIBS := $(shell pkg-config --libs zbar 2>/dev/null)
ifeq ($(ZBAR_PKG_LIBS),)
  # Default to -lzbar (library is in standard paths, no -L needed)
  ZBAR_LIBS := -lzbar
  ZBAR_LIB_PATH :=
else
  # Use pkg-config output (usually just -lzbar, library is in standard paths)
  ZBAR_LIBS := $(ZBAR_PKG_LIBS)
  # Extract library path if pkg-config provides it
  ZBAR_LIB_PATH := $(shell echo "$(ZBAR_PKG_LIBS)" | grep -o '\-L[^ ]*' || echo "")
endif

# Detect available libraries (library names only, no -L flags)
# Note: ZBar and SmallStep are added via ADDITIONAL_TOOL_LIBS for applications
LIBRARIES := -lobjc -lgnustep-gui -lgnustep-base

# Add ZInt if available (for future use)
ifneq ($(ZINT_INCLUDE),)
  LIBRARIES += -lzint
endif

# Set library dependencies (library names)
# Note: ZBar and SmallStep are handled via ADDITIONAL_TOOL_LIBS instead
SmallBarcodeReader_LIBRARIES_DEPEND_UPON = $(LIBRARIES)

# Set linker flags (library paths and runtime paths)
# Library paths must be in LDFLAGS so linker can find the libraries
SmallBarcodeReader_LDFLAGS = $(SMALLSTEP_LIB_PATH) $(ZBAR_LIB_PATH) $(SMALLSTEP_LDFLAGS)

# Additional linker flags (ensure library paths are also here)
SmallBarcodeReader_ADDITIONAL_LDFLAGS = $(SMALLSTEP_LIB_PATH) $(SMALLSTEP_LDFLAGS)

# Add to tool libraries (this is part of ALL_LIBS for applications)
# This is the correct way to link external libraries for GNUstep applications
# Try ZBar first, then SmallStep
SmallBarcodeReader_ADDITIONAL_TOOL_LIBS = -lzbar -lSmallStep

include $(GNUSTEP_MAKEFILES)/application.make

# GNUmakefile for SmallBarcodeReader (Linux/GNUStep)

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = SmallBarcodeReader

# Base Objective-C files (always compiled)
SmallBarcodeReader_OBJC_FILES = \
	main.m \
	AppDelegate.m \
	BarcodeDecoder.m \
	BarcodeDecoderZInt.m \
	WindowController.m

# Conditionally add ZBar files only if headers are available
ifneq ($(ZBAR_INCLUDE),)
  SmallBarcodeReader_OBJC_FILES += BarcodeDecoderZBar.m
endif

# Base header files (always included)
SmallBarcodeReader_HEADER_FILES = \
	AppDelegate.h \
	BarcodeDecoder.h \
	BarcodeDecoderBackend.h \
	BarcodeDecoderZInt.h \
	WindowController.h

# Conditionally add ZBar headers only if headers are available
ifneq ($(ZBAR_INCLUDE),)
  SmallBarcodeReader_HEADER_FILES += BarcodeDecoderZBar.h
endif

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
	$(ZINT_INCLUDE)

# Conditionally add ZBar include and define HAVE_ZBAR only if ZBar backend is being compiled
# HAVE_ZBAR should only be defined when BarcodeDecoderZBar.m is actually in the build
ifneq ($(ZBAR_INCLUDE),)
  SmallBarcodeReader_INCLUDE_DIRS += $(ZBAR_INCLUDE)
  # Only define HAVE_ZBAR if we're actually compiling the ZBar backend
  # (This is checked by seeing if BarcodeDecoderZBar.m is in OBJC_FILES)
  # For now, we're not compiling ZBar, so don't define HAVE_ZBAR
  # SmallBarcodeReader_OBJCFLAGS += -DHAVE_ZBAR=1
endif

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

# Get ZBar library flags from pkg-config if available (optional, not required)
ZBAR_PKG_LIBS := $(shell pkg-config --libs zbar 2>/dev/null)
ifeq ($(ZBAR_PKG_LIBS),)
  # Default to -lzbar (library is in standard paths, no -L needed)
  # But don't add it if headers aren't found
  ifneq ($(ZBAR_INCLUDE),)
    ZBAR_LIBS := -lzbar
  else
    ZBAR_LIBS :=
  endif
  ZBAR_LIB_PATH :=
else
  # Use pkg-config output (usually just -lzbar, library is in standard paths)
  ZBAR_LIBS := $(ZBAR_PKG_LIBS)
  # Extract library path if pkg-config provides it
  ZBAR_LIB_PATH := $(shell echo "$(ZBAR_PKG_LIBS)" | grep -o '\-L[^ ]*' || echo "")
endif

# Get ZInt library (prioritize ZInt for this build)
ZINT_LIBS :=
ifneq ($(ZINT_INCLUDE),)
  # ZInt is available, use it for linking
  ZINT_LIBS := -lzint
endif

# Detect available libraries (library names only, no -L flags)
# Note: These go into LIBRARIES_DEPEND_UPON for dependency tracking
LIBRARIES := -lobjc -lgnustep-gui -lgnustep-base

# Add ZInt if available
ifneq ($(ZINT_INCLUDE),)
  LIBRARIES += -lzint
endif

# Set library dependencies (library names)
# Note: SmallStep is added via ADDITIONAL_TOOL_LIBS, not here
SmallBarcodeReader_LIBRARIES_DEPEND_UPON = $(LIBRARIES)

# Set linker flags (library paths and runtime paths)
# Library paths must be in LDFLAGS so linker can find the libraries
# Only include ZBar path if ZBar is being used
SMALLSTEP_AND_ZINT_LDFLAGS = $(SMALLSTEP_LIB_PATH) $(SMALLSTEP_LDFLAGS)
ifneq ($(ZBAR_LIB_PATH),)
  SMALLSTEP_AND_ZINT_LDFLAGS += $(ZBAR_LIB_PATH)
endif
SmallBarcodeReader_LDFLAGS = $(SMALLSTEP_AND_ZINT_LDFLAGS)

# Additional linker flags (ensure library paths are also here)
# Also explicitly add -lSmallStep here to ensure it's linked
SmallBarcodeReader_ADDITIONAL_LDFLAGS = $(SMALLSTEP_LIB_PATH) $(SMALLSTEP_LDFLAGS) -lSmallStep

# Add to tool libraries (this is part of ALL_LIBS for applications)
# Use TOOL_LIBS (not ADDITIONAL_TOOL_LIBS) as per GNUstep rules
# Prioritize ZInt, then SmallStep
# Note: ZInt is an encoding library, but we link it to test the build
# ZBar is excluded from linking for now (as requested)
SmallBarcodeReader_TOOL_LIBS = $(ZINT_LIBS) -lSmallStep

include $(GNUSTEP_MAKEFILES)/application.make

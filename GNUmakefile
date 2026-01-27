# GNUmakefile for SmallBarcodeReader (Linux/GNUStep)
#
# Build options:
#   make DYNAMIC_ONLY=1    - Build without static library linking (dynamic loading only)
#   make                    - Build with static linking if libraries are available (default)

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = SmallBarcodeReader

# Check if dynamic-only build is requested
DYNAMIC_ONLY ?= 0

# Try to find ZBar headers and library (must be before OBJC_FILES to use in conditionals)
ZBAR_INCLUDE := $(shell pkg-config --cflags zbar 2>/dev/null)
ZBAR_LIBS := $(shell pkg-config --libs zbar 2>/dev/null)
ifeq ($(ZBAR_INCLUDE),)
  # Try common locations
  ifneq ($(wildcard /usr/include/zbar.h),)
    ZBAR_INCLUDE := -I/usr/include
    # Check if library exists
    ifneq ($(wildcard /usr/lib/x86_64-linux-gnu/libzbar.so),)
      ZBAR_LIBS := -lzbar
    else ifneq ($(wildcard /usr/lib/libzbar.so),)
      ZBAR_LIBS := -lzbar
    endif
  else ifneq ($(wildcard /usr/local/include/zbar.h),)
    ZBAR_INCLUDE := -I/usr/local/include
    ifneq ($(wildcard /usr/local/lib/libzbar.so),)
      ZBAR_LIBS := -lzbar
    endif
  endif
endif

# Try to find ZInt headers and library (must be before OBJC_FILES to use in conditionals)
ZINT_INCLUDE := $(shell pkg-config --cflags zint 2>/dev/null)
ZINT_LIBS := $(shell pkg-config --libs zint 2>/dev/null)
ifeq ($(ZINT_INCLUDE),)
  # Try common locations
  ifneq ($(wildcard /usr/include/zint.h),)
    ZINT_INCLUDE := -I/usr/include
    # Check if library exists
    ifneq ($(wildcard /usr/lib/x86_64-linux-gnu/libzint.so),)
      ZINT_LIBS := -lzint
    else ifneq ($(wildcard /usr/lib/libzint.so),)
      ZINT_LIBS := -lzint
    endif
  else ifneq ($(wildcard /usr/local/include/zint.h),)
    ZINT_INCLUDE := -I/usr/local/include
    ifneq ($(wildcard /usr/local/lib/libzint.so),)
      ZINT_LIBS := -lzint
    endif
  endif
endif

# Base Objective-C files (always compiled)
SmallBarcodeReader_OBJC_FILES = \
	main.m \
	ui/AppDelegate.m \
	decoder/BarcodeDecoder.m \
	encoder/BarcodeEncoder.m \
	image/ImageMatrix.m \
	image/ImageDistorter.m \
	core/DynamicLibraryLoader.m \
	core/BackendFactory.m \
	tester/BarcodeTestResult.m \
	tester/BarcodeTester.m \
	ui/WindowController.m \
	ui/FloatingMenuPanel.m

# Conditionally add ZBar files only if both headers and library are available
# Skip if DYNAMIC_ONLY=1
ifeq ($(DYNAMIC_ONLY),0)
  ifneq ($(ZBAR_INCLUDE),)
    ifneq ($(ZBAR_LIBS),)
      SmallBarcodeReader_OBJC_FILES += decoder/BarcodeDecoderZBar.m
    endif
  endif

  # Conditionally add ZInt files only if both headers and library are available
  ifneq ($(ZINT_INCLUDE),)
    ifneq ($(ZINT_LIBS),)
      SmallBarcodeReader_OBJC_FILES += decoder/BarcodeDecoderZInt.m
      SmallBarcodeReader_OBJC_FILES += encoder/BarcodeEncoderZInt.m
    endif
  endif
else
  # Dynamic-only build: still compile backend files but don't link libraries
  # This allows the code to be present but backends won't be available at compile time
  # They can be loaded dynamically at runtime
  ifneq ($(ZBAR_INCLUDE),)
    SmallBarcodeReader_OBJC_FILES += decoder/BarcodeDecoderZBar.m
  endif
  ifneq ($(ZINT_INCLUDE),)
    SmallBarcodeReader_OBJC_FILES += decoder/BarcodeDecoderZInt.m
    SmallBarcodeReader_OBJC_FILES += encoder/BarcodeEncoderZInt.m
  endif
endif

# Base header files (always included)
SmallBarcodeReader_HEADER_FILES = \
	ui/AppDelegate.h \
	decoder/BarcodeDecoder.h \
	decoder/BarcodeDecoderBackend.h \
	encoder/BarcodeEncoder.h \
	encoder/BarcodeEncoderBackend.h \
	image/ImageMatrix.h \
	image/ImageDistorter.h \
	core/DynamicLibraryLoader.h \
	core/BackendFactory.h \
	tester/BarcodeTestResult.h \
	tester/BarcodeTester.h \
	ui/WindowController.h \
	ui/FloatingMenuPanel.h

# Conditionally add ZBar headers only if headers are available
ifneq ($(ZBAR_INCLUDE),)
  SmallBarcodeReader_HEADER_FILES += decoder/BarcodeDecoderZBar.h
endif

# Conditionally add ZInt headers only if headers are available
ifneq ($(ZINT_INCLUDE),)
  SmallBarcodeReader_HEADER_FILES += decoder/BarcodeDecoderZInt.h
  SmallBarcodeReader_HEADER_FILES += encoder/BarcodeEncoderZInt.h
endif

SmallBarcodeReader_RESOURCE_FILES = \
	MainMenu.gorm

SmallBarcodeReader_INCLUDE_DIRS = \
	-I. \
	-Iencoder \
	-Idecoder \
	-Itester \
	-Icore \
	-Iimage \
	-Iui \
	-I../SmallStep/SmallStep/Core \
	-I../SmallStep/SmallStep/Platform/Linux \
	$(ZINT_INCLUDE)

# Conditionally add ZBar include and define HAVE_ZBAR
# In dynamic-only mode, still include headers but don't link library
ifneq ($(ZBAR_INCLUDE),)
  SmallBarcodeReader_INCLUDE_DIRS += $(ZBAR_INCLUDE)
  ifeq ($(DYNAMIC_ONLY),0)
    ifneq ($(ZBAR_LIBS),)
      # Define HAVE_ZBAR when both headers and library are available (static linking)
      SmallBarcodeReader_OBJCFLAGS += -DHAVE_ZBAR=1
    endif
  else
    # Dynamic-only: define HAVE_ZBAR if headers are available (for compilation)
    # But don't link the library - it will be loaded at runtime
    SmallBarcodeReader_OBJCFLAGS += -DHAVE_ZBAR=1 -DDYNAMIC_ONLY=1
  endif
endif

# Conditionally add ZInt include and define HAVE_ZINT
# In dynamic-only mode, still include headers but don't link library
ifneq ($(ZINT_INCLUDE),)
  SmallBarcodeReader_INCLUDE_DIRS += $(ZINT_INCLUDE)
  ifeq ($(DYNAMIC_ONLY),0)
    ifneq ($(ZINT_LIBS),)
      # Define HAVE_ZINT when both headers and library are available (static linking)
      SmallBarcodeReader_OBJCFLAGS += -DHAVE_ZINT=1
    endif
  else
    # Dynamic-only: define HAVE_ZINT if headers are available (for compilation)
    # But don't link the library - it will be loaded at runtime
    SmallBarcodeReader_OBJCFLAGS += -DHAVE_ZINT=1 -DDYNAMIC_ONLY=1
  endif
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

# ZBar and ZInt library variables are already set above during header detection
# Extract library paths if pkg-config provided them (already done above, but keep for clarity)
ZBAR_LIB_PATH := $(shell echo "$(ZBAR_LIBS)" | grep -o '\-L[^ ]*' || echo "")
ZINT_LIB_PATH := $(shell echo "$(ZINT_LIBS)" | grep -o '\-L[^ ]*' || echo "")

# Detect available libraries (library names only, no -L flags)
# Note: These go into LIBRARIES_DEPEND_UPON for dependency tracking
# ZInt and ZBar are optional - app should build without them
LIBRARIES := -lobjc -lgnustep-gui -lgnustep-base

# Add ZInt if available (optional - only if library was found)
# Skip in dynamic-only mode
ifeq ($(DYNAMIC_ONLY),0)
  ifneq ($(ZINT_LIBS),)
    LIBRARIES += $(ZINT_LIBS)
  endif

  # Add ZBar if available (optional - only if library was found)
  ifneq ($(ZBAR_LIBS),)
    LIBRARIES += $(ZBAR_LIBS)
  endif
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
# ZInt and ZBar are optional - only link if available and not in dynamic-only mode
# SmallStep is required
TOOL_LIBS_LIST = -lSmallStep
ifeq ($(DYNAMIC_ONLY),0)
  ifneq ($(ZINT_LIBS),)
    TOOL_LIBS_LIST += $(ZINT_LIBS)
  endif
  ifneq ($(ZBAR_LIBS),)
    TOOL_LIBS_LIST += $(ZBAR_LIBS)
  endif
endif
SmallBarcodeReader_TOOL_LIBS = $(TOOL_LIBS_LIST)

include $(GNUSTEP_MAKEFILES)/application.make

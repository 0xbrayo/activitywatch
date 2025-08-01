# =====================================
# Makefile for the ActivityWatch bundle
# =====================================
#
# [GUIDE] How to install from source:
#  - https://activitywatch.readthedocs.io/en/latest/installing-from-source.html
#
# We recommend creating and activating a Python virtualenv before building.
# Instructions on how to do this can be found in the guide linked above.
.PHONY: build install test clean clean_all

SHELL := /usr/bin/env bash

OS := $(shell uname -s)

SUBMODULES := aw-core aw-client aw-server aw-server-rust aw-watcher-afk aw-watcher-window aw-tauri

# Exclude aw-server-rust if SKIP_SERVER_RUST is true
ifeq ($(SKIP_SERVER_RUST),true)
        SUBMODULES := $(filter-out aw-server-rust,$(SUBMODULES))
endif

# Build in release mode by default, unless RELEASE=false
ifeq ($(RELEASE), false)
		targetdir := debug
else
		targetdir := release
endif


#Include awatcher on linux
ifeq ($(OS),Linux)
	SUBMODULES := $(SUBMODULES) awatcher
endif

# Include extras if AW_EXTRAS is true
ifeq ($(AW_EXTRAS),true)
	SUBMODULES := $(SUBMODULES) aw-notify aw-watcher-input
endif

# A function that checks if a target exists in a Makefile
# Usage: $(call has_target,<dir>,<target>)
define has_target
$(shell make -q -C $1 $2 >/dev/null 2>&1; if [ $$? -eq 0 -o $$? -eq 1 ]; then echo $1; fi)
endef

# Submodules with test/package/lint/typecheck targets
TESTABLES := $(foreach dir,$(SUBMODULES),$(call has_target,$(dir),test))
PACKAGEABLES := $(foreach dir,$(SUBMODULES),$(call has_target,$(dir),package))
LINTABLES := $(foreach dir,$(SUBMODULES),$(call has_target,$(dir),lint))
TYPECHECKABLES := $(foreach dir,$(SUBMODULES),$(call has_target,$(dir),typecheck))

ifeq ($(TAURI_BUILD),true)
	PACKAGEABLES := $(filter-out aw-server-rust aw-server, $(PACKAGEABLES))
endif

# The `build` target
# ------------------
#
# What it does:
#  - Installs all the Python modules
#  - Builds the web UI and bundles it with aw-server
build: aw-core/.git
#	needed due to https://github.com/pypa/setuptools/issues/1963
#	would ordinarily be specified in pyproject.toml, but is not respected due to https://github.com/pypa/setuptools/issues/1963
	pip install 'setuptools>49.1.1'
	for module in $(SUBMODULES); do \
		echo "Building $$module"; \
		if [ "$$module" = "aw-server-rust" ] && [ "$(TAURI_BUILD)" = "true" ]; then \
			make --directory=$$module aw-sync SKIP_WEBUI=$(SKIP_WEBUI) || { echo "Error in $$module aw-sync"; exit 2; }; \
		else \
			make --directory=$$module build SKIP_WEBUI=$(SKIP_WEBUI) || { echo "Error in $$module build"; exit 2; }; \
		fi; \
	done
#   The below is needed due to: https://github.com/ActivityWatch/activitywatch/issues/173
	make --directory=aw-client build
	make --directory=aw-core build
#	Needed to ensure that the server has the correct version set
	python3 -c "import aw_server; print(aw_server.__version__)"

# Update
# ------
#
# Pulls the latest version, updates all the submodules, then runs `make build`.
update:
	git pull
	git submodule update --init --recursive
	make build


lint:
	@for module in $(LINTABLES); do \
		echo "Linting $$module"; \
		make --directory=$$module lint || { echo "Error in $$module lint"; exit 2; }; \
	done

typecheck:
	@for module in $(TYPECHECKABLES); do \
		echo "Typechecking $$module"; \
		make --directory=$$module typecheck || { echo "Error in $$module typecheck"; exit 2; }; \
	done

# Uninstall
# ---------
#
# Uninstalls all the Python modules.
uninstall:
	modules=$$(pip3 list --format=legacy | grep 'aw-' | grep -o '^aw-[^ ]*'); \
	for module in $$modules; do \
		echo "Uninstalling $$module"; \
		pip3 uninstall -y $$module; \
	done

test:
	@for module in $(TESTABLES); do \
		echo "Running tests for $$module"; \
		poetry run make -C $$module test || { echo "Error in $$module tests"; exit 2; }; \
    done

test-integration:
	# TODO: Move "integration tests" to aw-client
	# FIXME: For whatever reason the script stalls on Appveyor
	#        Example: https://ci.appveyor.com/project/ErikBjare/activitywatch/build/1.0.167/job/k1ulexsc5ar5uv4v
	# aw-server-python
	@echo "== Integration testing aw-server =="
	@pytest ./scripts/tests/integration_tests.py ./aw-server/tests/ -v

%/.git:
	git submodule update --init --recursive

ICON := "aw-tauri/aw-webui/media/logo/logo.png"

aw-tauri/aw-webui/media/logo/logo.icns:
	mkdir -p build/MyIcon.iconset
	sips -z 16 16     $(ICON) --out build/MyIcon.iconset/icon_16x16.png
	sips -z 32 32     $(ICON) --out build/MyIcon.iconset/icon_16x16@2x.png
	sips -z 32 32     $(ICON) --out build/MyIcon.iconset/icon_32x32.png
	sips -z 64 64     $(ICON) --out build/MyIcon.iconset/icon_32x32@2x.png
	sips -z 128 128   $(ICON) --out build/MyIcon.iconset/icon_128x128.png
	sips -z 256 256   $(ICON) --out build/MyIcon.iconset/icon_128x128@2x.png
	sips -z 256 256   $(ICON) --out build/MyIcon.iconset/icon_256x256.png
	sips -z 512 512   $(ICON) --out build/MyIcon.iconset/icon_256x256@2x.png
	sips -z 512 512   $(ICON) --out build/MyIcon.iconset/icon_512x512.png
	cp				  $(ICON)       build/MyIcon.iconset/icon_512x512@2x.png
	iconutil -c icns build/MyIcon.iconset
	rm -R build/MyIcon.iconset
	mv build/MyIcon.icns aw-tauri/aw-webui/media/logo/logo.icns

dist/ActivityWatch.app: aw-tauri/aw-webui/media/logo/logo.icns
	scripts/package/build_app.sh

dist/ActivityWatch.dmg: dist/ActivityWatch.app
	# NOTE: This does not codesign the dmg, that is done in the CI config
	pip install dmgbuild
	dmgbuild -s scripts/package/dmgbuild-settings.py -D app=dist/ActivityWatch.app "ActivityWatch" dist/ActivityWatch.dmg

dist/notarize:
	./scripts/notarize.sh

package:
	rm -rf dist
	mkdir -p dist/activitywatch
	for dir in $(PACKAGEABLES); do \
		make --directory=$$dir package; \
		cp -r $$dir/dist/$$dir dist/activitywatch; \
	done
ifeq ($(TAURI_BUILD),true)
	mkdir -p dist/activitywatch/aw-server-rust
	cp aw-server-rust/target/$(targetdir)/aw-sync dist/activitywatch/aw-server-rust/aw-sync
endif
# Remove problem-causing binaries
	rm -f dist/activitywatch/libdrm.so.2       # see: https://github.com/ActivityWatch/activitywatch/issues/161
	rm -f dist/activitywatch/libharfbuzz.so.0  # see: https://github.com/ActivityWatch/activitywatch/issues/660#issuecomment-959889230
# These should be provided by the distro itself
# Had to be removed due to otherwise causing the error:
#   aw-qt: symbol lookup error: /opt/activitywatch/libQt5XcbQpa.so.5: undefined symbol: FT_Get_Font_Format
	rm -f dist/activitywatch/libfontconfig.so.1
	rm -f dist/activitywatch/libfreetype.so.6
# Remove unnecessary files
	rm -rf dist/activitywatch/pytz
# Builds zips and setups
	bash scripts/package/package-all.sh

clean:
	rm -rf build dist

# Clean all subprojects
clean_all: clean
	for dir in $(SUBMODULES); do \
		make --directory=$$dir clean; \
	done

clean-auto:
	rm -rIv **/aw-android/mobile/build
	rm -rIfv **/node_modules

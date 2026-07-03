APP  := YabaiStackSwitcher.app
BIN  := YabaiStackSwitcher
VER  := $(shell plutil -extract CFBundleShortVersionString raw Info.plist 2>/dev/null || echo 0.0.0)
ZIP  := $(BIN)-$(VER).zip
ICONSET := AppIcon.iconset
ICON_SRC := assets/icon-1782783900905.png

.PHONY: build bundle icon run zip clean

build:
	swift build -c release

icon:
	@rm -rf "$(ICONSET)"
	@mkdir -p "$(ICONSET)"
	@sips -z 16 16   "$(ICON_SRC)" --out "$(ICONSET)/icon_16x16.png"      >/dev/null
	@sips -z 32 32   "$(ICON_SRC)" --out "$(ICONSET)/icon_16x16@2x.png"   >/dev/null
	@sips -z 32 32   "$(ICON_SRC)" --out "$(ICONSET)/icon_32x32.png"      >/dev/null
	@sips -z 64 64   "$(ICON_SRC)" --out "$(ICONSET)/icon_32x32@2x.png"   >/dev/null
	@sips -z 128 128 "$(ICON_SRC)" --out "$(ICONSET)/icon_128x128.png"    >/dev/null
	@sips -z 256 256 "$(ICON_SRC)" --out "$(ICONSET)/icon_128x128@2x.png" >/dev/null
	@sips -z 256 256 "$(ICON_SRC)" --out "$(ICONSET)/icon_256x256.png"    >/dev/null
	@sips -z 512 512 "$(ICON_SRC)" --out "$(ICONSET)/icon_256x256@2x.png" >/dev/null
	@sips -z 512 512 "$(ICON_SRC)" --out "$(ICONSET)/icon_512x512.png"    >/dev/null
	@sips -z 1024 1024 "$(ICON_SRC)" --out "$(ICONSET)/icon_512x512@2x.png" >/dev/null
	@iconutil -c icns "$(ICONSET)" -o AppIcon.icns
	@rm -rf "$(ICONSET)"

bundle: build icon
	@rm -rf "$(APP)"
	@mkdir -p "$(APP)/Contents/MacOS"
	@mkdir -p "$(APP)/Contents/Resources"
	@cp ".build/release/$(BIN)" "$(APP)/Contents/MacOS/$(BIN)"
	@cp Info.plist "$(APP)/Contents/Info.plist"
	@cp AppIcon.icns "$(APP)/Contents/Resources/AppIcon.icns"
	@echo "Built $(APP)"

run: build
	".build/release/$(BIN)"

zip: bundle
	@rm -f "$(ZIP)"
	@ditto -c -k --keepParent "$(APP)" "$(ZIP)"
	@echo "Created $(ZIP)"

clean:
	swift package clean
	@rm -rf "$(APP)" "$(ZIP)"

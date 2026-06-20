APP  := YabaiStackSwitcher.app
BIN  := YabaiStackSwitcher
VER  := $(shell plutil -extract CFBundleShortVersionString raw Info.plist 2>/dev/null || echo 0.0.0)
ZIP  := $(BIN)-$(VER).zip

.PHONY: build bundle run zip clean

build:
	swift build -c release

bundle: build
	@rm -rf "$(APP)"
	@mkdir -p "$(APP)/Contents/MacOS"
	@mkdir -p "$(APP)/Contents/Resources"
	@cp ".build/release/$(BIN)" "$(APP)/Contents/MacOS/$(BIN)"
	@cp Info.plist "$(APP)/Contents/Info.plist"
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

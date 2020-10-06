## Makefile which is used to generate a .app and .dmg for MacOS.
##
## Credits:
## This Makefile is heaviliy inspirred by Alacrittys.
## https://github.com/alacritty/alacritty/blob/master/Makefile

TARGET = ajour

RESOURCES_DIR = resources
RELEASE_DIR = target/release

APP_NAME = Ajour.app
APP_TEMPLATE = $(RESOURCES_DIR)/osx/$(APP_NAME)
APP_DIR = $(RELEASE_DIR)/osx
APP_BINARY = $(RELEASE_DIR)/$(TARGET)
APP_BINARY_DIR  = $(APP_DIR)/$(APP_NAME)/Contents/MacOS
APP_RESOURCES_DIR = $(APP_DIR)/$(APP_NAME)/Contents/Resources

APPIMAGE_DIR = $(RELEASE_DIR)/AppDir
APPIMAGE_DESKTOP_FILE = $(RESOURCES_DIR)/linux/ajour.desktop
APPIMAGE_LOGO_FILE = $(RESOURCES_DIR)/logo/256x256/ajour.png

DMG_NAME = Ajour.dmg
DMG_DIR = $(RELEASE_DIR)/osx

vpath $(TARGET) $(RELEASE_DIR)
vpath $(APP_NAME) $(APP_DIR)
vpath $(DMG_NAME) $(APP_DIR)

all: help

help: ## Prints help for targets with comments
	@grep -E '^[a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

binary: | $(TARGET) ## Build release binary with cargo
$(TARGET):
	MACOSX_DEPLOYMENT_TARGET="10.11" cargo build --release

app: | $(APP_NAME) ## Clone Ajour.app template and mount binary
$(APP_NAME): $(TARGET)
	@mkdir -p $(APP_BINARY_DIR)
	@mkdir -p $(APP_RESOURCES_DIR)
	@cp -fRp $(APP_TEMPLATE) $(APP_DIR)
	@cp -fp $(APP_BINARY) $(APP_BINARY_DIR)
	@touch -r "$(APP_BINARY)" "$(APP_DIR)/$(APP_NAME)"
	@echo "Created '$@' in '$(APP_DIR)'"

dmg: | $(DMG_NAME) ## Pack Ajour.app into .dmg
$(DMG_NAME): $(APP_NAME)
	@echo "Packing disk image..."
	@ln -sf /Applications $(DMG_DIR)/Applications
	@hdiutil create $(DMG_DIR)/$(DMG_NAME) \
		-volname "Ajour" \
		-fs HFS+ \
		-srcfolder $(APP_DIR) \
		-ov -format UDZO
	@echo "Packed '$@' in '$(APP_DIR)'"

install: $(DMG_NAME) ## Mount disk image
	@open $(DMG_DIR)/$(DMG_NAME)

appimage: ## Bundle release binary as AppImage
	OUTPUT=ajour.AppImage linuxdeploy-x86_64.AppImage \
		--appdir $(APPIMAGE_DIR) \
		-e $(APP_BINARY) \
		-d $(APPIMAGE_DESKTOP_FILE) \
		-i $(APPIMAGE_LOGO_FILE) \
		--output appimage
	@rm -rf $(APPIMAGE_DIR)

.PHONY: app binary clean dmg install $(TARGET)

clean: ## Remove all artifacts
	-rm -rf $(APP_DIR)

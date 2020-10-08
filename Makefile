TARGET = ajour

RESOURCES_DIR = resources
RELEASE_DIR = target/release

APP_NAME = Ajour.app
APP_TEMPLATE = $(RESOURCES_DIR)/osx/$(APP_NAME)
APP_DIR = $(RELEASE_DIR)/osx
APP_BINARY = $(RELEASE_DIR)/$(TARGET)
APP_BINARY_DIR  = $(APP_DIR)/$(APP_NAME)/Contents/MacOS
APP_RESOURCES_DIR = $(APP_DIR)/$(APP_NAME)/Contents/Resources

APPIMAGE_NAME ?=
APPIMAGE_DIR = $(RELEASE_DIR)/AppDir
APPIMAGE_DESKTOP_FILE = $(RESOURCES_DIR)/linux/ajour.desktop
APPIMAGE_LOGO_FILE = $(RESOURCES_DIR)/logo/256x256/ajour.png

DMG_NAME ?=
DMG_DIR = $(RELEASE_DIR)/osx

OPENGL ?=
MACOS ?=

ifdef MACOS
  ENV :=MACOSX_DEPLOYMENT_TARGET="10.11"
endif

ifdef OPENGL
  DMG_NAME :=ajour-opengl.dmg
  APPIMAGE_NAME :=ajour-opengl.AppImage
  FEATURE_FLAG :=--no-default-features --features opengl
else
  DMG_NAME :=ajour.dmg
  APPIMAGE_NAME :=ajour.AppImage
  FEATURE_FLAG :=
endif

vpath $(TARGET) $(RELEASE_DIR)
vpath $(APP_NAME) $(APP_DIR)
vpath $(DMG_NAME) $(APP_DIR)


binary: $(TARGET) ## Build release binary with cargo
$(TARGET):
	$(ENV) cargo build --release $(FEATURE_FLAG)

app: $(APP_NAME) ## Clone Ajour.app template and mount binary
$(APP_NAME): $(TARGET)
	@mkdir -p $(APP_BINARY_DIR)
	@mkdir -p $(APP_RESOURCES_DIR)
	@cp -fRp $(APP_TEMPLATE) $(APP_DIR)
	@cp -fp $(APP_BINARY) $(APP_BINARY_DIR)
	@touch -r "$(APP_BINARY)" "$(APP_DIR)/$(APP_NAME)"
	@echo "Created '$@' in '$(APP_DIR)'"

dmg: $(DMG_NAME) ## Pack Ajour.app into .dmg
$(DMG_NAME): $(APP_NAME)
	@echo "Packing disk image..."
	@ln -sf /Applications $(DMG_DIR)/Applications
	@hdiutil create $(DMG_DIR)/$(DMG_NAME) \
		-volname "Ajour" \
		-fs HFS+ \
		-srcfolder $(APP_DIR) \
		-ov -format UDZO
	@echo "Packed '$@' in '$(APP_DIR)'"

appimage: $(APPIMAGE_NAME) ## Bundle release binary as AppImage
$(APPIMAGE_NAME): $(TARGET)
	OUTPUT=$(APPIMAGE_NAME) ./linuxdeploy-x86_64.AppImage \
		--appdir $(APPIMAGE_DIR) \
		-e $(APP_BINARY) \
		-d $(APPIMAGE_DESKTOP_FILE) \
		-i $(APPIMAGE_LOGO_FILE) \
		--output appimage
	@rm -rf $(APPIMAGE_DIR)

.PHONY: app binary dmg appimage

clean: ## Remove all artifacts
	-rm -rf $(APP_DIR)

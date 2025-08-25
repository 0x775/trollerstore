ARCHS = arm64 arm64e
TARGET = iphone:clang:13.7:15.6

# 设置包输出目录
THEOS_PACKAGE_DIR_NAME = packages
THEOS_PACKAGE_DIR = $(THEOS_PROJECT_DIR)/$(THEOS_PACKAGE_DIR_NAME)

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TrollMMAuto

TrollMMAuto_FILES = main.m TrollMMAutoAppDelegate.m
TrollMMAuto_FRAMEWORKS = UIKit
TrollMMAuto_PRIVATE_FRAMEWORKS = FrontBoardServices
TrollMMAuto_CFLAGS = -fobjc-arc

# 嵌入服务应用
TrollMMAuto_EMBEDDED_BUNDLES = HMDServices/HMDServices.app

include $(THEOS_MAKE_PATH)/application.mk

# 构建服务应用
before-all::
	$(MAKE) -C HMDServices

# 确保服务应用被复制到正确的位置
after-stage::
	@echo "复制 HMDServices 到应用包..."
	@mkdir -p $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/
	@cp -R HMDServices/.theos/obj/debug/arm64/HMDServices.app $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/
	
	# 复制 HMDServices 的 Info.plist
	@cp HMDServices/Info.plist $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/HMDServices.app/
	
	# 复制主应用的 Info.plist
	@cp Info.plist $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app/
	
	@echo "所有文件已复制到应用包"

# 使用 Theos 的标准打包流程
# 不需要定义 package 目标，Theos 会自动处理
ARCHS = arm64 arm64e
TARGET = iphone:clang:13.7:15.6

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HMDServices

HMDServices_FILES = main.m
HMDServices_FRAMEWORKS = UIKit FrontBoardServices
HMDServices_PRIVATE_FRAMEWORKS = FrontBoardServices
HMDServices_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
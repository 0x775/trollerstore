#!/bin/bash

# 进入项目目录
echo "启动自动编译脚本..."

# 编译 HMDServices
echo "编译 HMDServices..."
cd HMDServices
make clean
make
cd ..

# 检查 HMDServices 是否编译成功
if [ ! -d "HMDServices/.theos/obj/debug/HMDServices.app" ] || [ -z "$(ls -A HMDServices/.theos/obj/debug/HMDServices.app)" ]; then
    echo "错误: HMDServices 编译失败或生成了空的 .app 包"
    exit 1
fi

# 编译主应用
echo "编译主应用..."
make clean
make

# 创建 Payload 目录
rm -rf Payload
mkdir -p Payload

# 复制主应用
cp -R .theos/obj/debug/TrollMMAuto.app Payload/

# 复制主应用的 Info.plist
cp Info.plist Payload/TrollMMAuto.app/

# 复制服务应用到主应用中
mkdir -p Payload/TrollMMAuto.app/HMDServices
#cp -R HMDServices/.theos/obj/debug/HMDServices.app/ Payload/TrollMMAuto.app/HMDServices/
cp -R HMDServices/.theos/obj/debug/HMDServices.app/HMDServices Payload/TrollMMAuto.app/HMDServices/
chmod +x Payload/TrollMMAuto.app/HMDServices/HMDServices

# 复制服务应用的 Info.plist
cp HMDServices/Info.plist Payload/TrollMMAuto.app/HMDServices/

# 创建 IPA 文件
rm -f TrollMMAuto.ipa
zip -r TrollMMAuto.ipa Payload

# 清理临时文件
rm -rf Payload

# 移动 IPA 文件到包目录
mkdir -p packages
mv TrollMMAuto.ipa packages/

echo "IPA 文件已创建: packages/TrollMMAuto.ipa"
echo "请使用巨魔商店安装此 IPA 文件"
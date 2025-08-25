#!/bin/bash
echo "注入打包自动化脚本.."

echo "到指定目录"
cd /Users/apple/Project/ios_crack/tipa/xiaohongshu/Payload/discover.app/
echo "拷贝原始程序"
cp /tmp/discover discover
echo "拷贝dylib"
cp ~/Project/trollerstore/hookdemo/.theos/obj/debug/hookdemo.dylib .
echo "设置+x权限"
chmod +x hookdemo.dylib
echo "optool修改加载"
optool install -c load -p "@executable_path/hookdemo.dylib" -t discover
cd ../../
echo "重新打包ipa文件"
zip -qr xiaohongshuo.ipa Payload

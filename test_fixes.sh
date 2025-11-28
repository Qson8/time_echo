#!/bin/bash

# 修复功能测试脚本
# 用于在模拟器/设备上测试修复的功能

echo "=========================================="
echo "开始测试修复的功能"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Flutter环境
echo -e "${YELLOW}检查Flutter环境...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}错误: Flutter未安装或不在PATH中${NC}"
    exit 1
fi

# 检查可用设备
echo -e "${YELLOW}检查可用设备...${NC}"
flutter devices

# 选择测试平台
echo ""
echo -e "${YELLOW}请选择测试平台:${NC}"
echo "1. HarmonyOS 模拟器/设备"
echo "2. Android 模拟器/设备"
echo "3. iOS 模拟器/设备"
echo "4. 所有平台"
read -p "请输入选项 (1-4): " platform_choice

case $platform_choice in
    1)
        TARGET_PLATFORM="ohos"
        echo -e "${GREEN}选择HarmonyOS平台${NC}"
        ;;
    2)
        TARGET_PLATFORM="android"
        echo -e "${GREEN}选择Android平台${NC}"
        ;;
    3)
        TARGET_PLATFORM="ios"
        echo -e "${GREEN}选择iOS平台${NC}"
        ;;
    4)
        TARGET_PLATFORM="all"
        echo -e "${GREEN}选择所有平台${NC}"
        ;;
    *)
        echo -e "${RED}无效选项，默认使用HarmonyOS${NC}"
        TARGET_PLATFORM="ohos"
        ;;
esac

# 清理构建
echo ""
echo -e "${YELLOW}清理旧的构建文件...${NC}"
flutter clean

# 获取依赖
echo ""
echo -e "${YELLOW}获取依赖...${NC}"
flutter pub get

# 运行测试
echo ""
echo -e "${YELLOW}运行单元测试...${NC}"
flutter test

# 构建并运行应用
echo ""
echo -e "${YELLOW}构建并运行应用...${NC}"

if [ "$TARGET_PLATFORM" == "ohos" ]; then
    echo -e "${GREEN}在HarmonyOS设备上运行...${NC}"
    flutter run -d ohos
elif [ "$TARGET_PLATFORM" == "android" ]; then
    echo -e "${GREEN}在Android设备上运行...${NC}"
    flutter run -d android
elif [ "$TARGET_PLATFORM" == "ios" ]; then
    echo -e "${GREEN}在iOS设备上运行...${NC}"
    flutter run -d ios
else
    echo -e "${GREEN}在所有可用设备上运行...${NC}"
    flutter run
fi

echo ""
echo -e "${GREEN}=========================================="
echo "测试完成！"
echo "==========================================${NC}"
echo ""
echo "请按照以下步骤进行手动测试："
echo "1. 测试开始拾光功能（首页和设置页面）"
echo "2. 测试记忆胶囊的图片选择/拍照功能"
echo "3. 测试录音权限提示"
echo "4. 测试记忆胶囊保存功能"
echo "5. 测试收藏功能的刷新机制"
echo ""
echo "详细测试步骤请参考: TEST_FIXES.md"


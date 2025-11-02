#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   测试 Python 爬虫"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查参数
if [ -z "$1" ]; then
    echo "用法: ./test-scraper.sh <twitter_username>"
    echo "示例: ./test-scraper.sh elonmusk"
    exit 1
fi

USERNAME=$1

echo "🔍 正在获取 @$USERNAME 的最新推文..."
echo ""

python3 scraper.py "$USERNAME" 3

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 测试成功！"
else
    echo ""
    echo "❌ 测试失败"
    echo ""
    echo "可能的问题："
    echo "1. snscrape 未安装: pip3 install snscrape"
    echo "2. 用户名不存在"
    echo "3. 网络连接问题"
fi

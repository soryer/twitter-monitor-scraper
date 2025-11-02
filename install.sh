#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Twitter Monitor Scraper - 快速部署脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    echo "   请访问: https://nodejs.org/"
    exit 1
fi
echo "✅ Node.js: $(node -v)"

# 检查 Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi
echo "✅ Python3: $(python3 --version)"

# 检查 pip3
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 未安装"
    exit 1
fi
echo "✅ pip3: $(pip3 --version)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   开始安装依赖..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 安装 Python 依赖
echo "📦 安装 Python 依赖..."
echo ""
echo "⚠️  注意: snscrape 已停止维护，将使用 ntscraper 作为替代"
echo ""

# 优先安装 ntscraper
echo "正在安装 ntscraper..."
if pip3 install ntscraper requests beautifulsoup4; then
    echo "✅ ntscraper 安装成功"
else
    echo "⚠️  ntscraper 安装失败"
    echo "尝试从 Git 安装 snscraper..."
    
    if pip3 install git+https://github.com/JustAnotherArchivist/snscraper.git 2>/dev/null; then
        echo "✅ snscraper (Git 版本) 安装成功"
    else
        echo "⚠️  snscraper 也失败了"
        echo "安装基础爬虫依赖..."
        pip3 install requests beautifulsoup4
        echo "⚠️  将使用基础爬虫（功能受限）"
    fi
fi

# 安装 Node.js 依赖
echo ""
echo "📦 安装 Node.js 依赖..."
npm install
if [ $? -ne 0 ]; then
    echo "❌ Node.js 依赖安装失败"
    exit 1
fi
echo "✅ Node.js 依赖安装成功"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   配置环境变量"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "📝 创建 .env 配置文件..."
    cp .env.example .env
    echo "✅ 已创建 .env 文件"
    echo ""
    echo "⚠️  请编辑 .env 文件，填入你的配置："
    echo "   • TELEGRAM_BOT_TOKEN"
    echo "   • TELEGRAM_CHAT_ID"
    echo "   • TWITTER_USERNAMES"
    echo ""
    echo "编辑命令: vi .env"
    echo ""
else
    echo "✅ .env 文件已存在"
fi

# 创建日志目录
mkdir -p logs

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ✅ 安装完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📖 后续步骤:"
echo ""
echo "1. 编辑配置文件:"
echo "   vi .env"
echo ""
echo "2. 本地测试:"
echo "   npm start"
echo ""
echo "3. 后台运行 (需要 PM2):"
echo "   npm install -g pm2"
echo "   pm2 start ecosystem.config.js"
echo "   pm2 logs twitter-monitor-scraper"
echo ""
echo "4. 查看帮助:"
echo "   cat README.md"
echo ""

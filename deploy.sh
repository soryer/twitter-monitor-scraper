#!/bin/bash

#####################################################
# Twitter Monitor Scraper - VPS 一键部署脚本
# 支持: CentOS 7/8, Ubuntu 18.04/20.04/22.04
#####################################################

set -e  # 遇到错误立即退出

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Twitter Monitor Scraper - VPS 部署脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}❌ 无法检测操作系统${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 检测到系统: $OS $VERSION${NC}"
}

# 安装 Node.js
install_nodejs() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   安装 Node.js..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v)
        echo -e "${GREEN}✅ Node.js 已安装: $NODE_VERSION${NC}"
        return
    fi
    
    # 使用 NodeSource 安装 Node.js 18.x
    if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
        yum install -y nodejs
    elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    echo -e "${GREEN}✅ Node.js 安装完成: $(node -v)${NC}"
}

# 安装 Python3 和 pip3
install_python() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   安装 Python3..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        echo -e "${GREEN}✅ Python3 已安装: $PYTHON_VERSION${NC}"
    else
        if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
            yum install -y python3 python3-pip
        elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
            apt-get update
            apt-get install -y python3 python3-pip
        fi
        echo -e "${GREEN}✅ Python3 安装完成: $(python3 --version)${NC}"
    fi
    
    # 确保 pip3 可用
    if ! command -v pip3 &> /dev/null; then
        if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
            yum install -y python3-pip
        elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
            apt-get install -y python3-pip
        fi
    fi
    
    echo -e "${GREEN}✅ pip3: $(pip3 --version)${NC}"
}

# 安装 Git
install_git() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   安装 Git..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v git &> /dev/null; then
        echo -e "${GREEN}✅ Git 已安装: $(git --version)${NC}"
        return
    fi
    
    if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
        yum install -y git
    elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        apt-get install -y git
    fi
    
    echo -e "${GREEN}✅ Git 安装完成: $(git --version)${NC}"
}

# 安装 PM2
install_pm2() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   安装 PM2..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v pm2 &> /dev/null; then
        echo -e "${GREEN}✅ PM2 已安装: $(pm2 -v)${NC}"
        return
    fi
    
    npm install -g pm2
    echo -e "${GREEN}✅ PM2 安装完成: $(pm2 -v)${NC}"
}

# 克隆项目
clone_project() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   克隆项目..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    REPO_URL="https://github.com/soryer/twitter-monitor-scraper.git"
    INSTALL_DIR="/root/twitter-monitor-scraper"
    
    # 如果目录存在，询问是否删除
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}⚠️  目录已存在: $INSTALL_DIR${NC}"
        read -p "是否删除并重新克隆？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 如果正在运行，先停止
            cd $INSTALL_DIR
            if pm2 list | grep -q "twitter-monitor-scraper"; then
                pm2 delete twitter-monitor-scraper
            fi
            cd /root
            rm -rf $INSTALL_DIR
        else
            echo -e "${GREEN}✅ 使用现有目录${NC}"
            return
        fi
    fi
    
    # 克隆项目
    git clone $REPO_URL $INSTALL_DIR
    echo -e "${GREEN}✅ 项目克隆完成${NC}"
}

# 安装项目依赖
install_dependencies() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   安装项目依赖..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    INSTALL_DIR="/root/twitter-monitor-scraper"
    cd $INSTALL_DIR
    
    # 安装 Python 依赖
    echo "📦 安装 Python 依赖..."
    
    # 优先尝试 ntscraper
    echo "   尝试安装 ntscraper..."
    if pip3 install ntscraper requests beautifulsoup4; then
        echo "   ✅ ntscraper 安装成功"
    else
        echo "   ⚠️  ntscraper 安装失败，尝试备用方案..."
        
        # 备用方案：尝试从 Git 安装 snscraper
        if pip3 install git+https://github.com/JustAnotherArchivist/snscraper.git 2>/dev/null; then
            echo "   ✅ snscraper 安装成功"
        else
            echo "   ⚠️  snscraper 也失败了，仅安装基础爬虫..."
            pip3 install requests beautifulsoup4
            echo "   ⚠️  将使用基础爬虫功能（功能受限）"
        fi
    fi
    
    # 安装 Node.js 依赖
    echo "📦 安装 Node.js 依赖..."
    npm install --production
    
    echo -e "${GREEN}✅ 依赖安装完成${NC}"
}

# 配置环境变量
configure_env() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   配置环境变量"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    INSTALL_DIR="/root/twitter-monitor-scraper"
    cd $INSTALL_DIR
    
    if [ -f ".env" ]; then
        echo -e "${YELLOW}⚠️  .env 文件已存在${NC}"
        read -p "是否重新配置？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}✅ 保留现有配置${NC}"
            return
        fi
    fi
    
    cp .env.example .env
    
    echo ""
    echo "请输入配置信息："
    echo ""
    
    # Telegram Bot Token
    read -p "Telegram Bot Token: " BOT_TOKEN
    sed -i "s/TELEGRAM_BOT_TOKEN=.*/TELEGRAM_BOT_TOKEN=$BOT_TOKEN/" .env
    
    # Telegram Chat ID
    read -p "Telegram Chat ID: " CHAT_ID
    sed -i "s/TELEGRAM_CHAT_ID=.*/TELEGRAM_CHAT_ID=$CHAT_ID/" .env
    
    # Twitter Usernames
    read -p "监控的 Twitter 用户名 (逗号分隔): " USERNAMES
    sed -i "s/TWITTER_USERNAMES=.*/TWITTER_USERNAMES=$USERNAMES/" .env
    
    # Check Interval
    read -p "检查间隔（秒，建议30）: " INTERVAL
    INTERVAL_MS=$((INTERVAL * 1000))
    sed -i "s/CHECK_INTERVAL=.*/CHECK_INTERVAL=$INTERVAL_MS/" .env
    
    echo ""
    echo -e "${GREEN}✅ 配置完成${NC}"
    echo ""
    echo "配置内容预览:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat .env | grep -v "^#" | grep -v "^$"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 测试运行
test_run() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   测试运行"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    INSTALL_DIR="/root/twitter-monitor-scraper"
    cd $INSTALL_DIR
    
    echo ""
    read -p "是否进行测试运行？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo ""
    echo "测试 Python 爬虫..."
    python3 scraper.py elonmusk 1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Python 爬虫测试成功${NC}"
    else
        echo -e "${RED}❌ Python 爬虫测试失败${NC}"
        echo "请检查网络连接和 snscrape 安装"
    fi
}

# 启动服务
start_service() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   启动服务"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    INSTALL_DIR="/root/twitter-monitor-scraper"
    cd $INSTALL_DIR
    
    # 停止旧服务（如果存在）
    if pm2 list | grep -q "twitter-monitor-scraper"; then
        echo "停止旧服务..."
        pm2 delete twitter-monitor-scraper
    fi
    
    # 创建日志目录
    mkdir -p logs
    
    # 启动新服务
    pm2 start ecosystem.config.js
    
    # 设置开机自启
    pm2 save
    pm2 startup
    
    echo ""
    echo -e "${GREEN}✅ 服务启动成功！${NC}"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   🎉 部署完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📖 常用命令:"
    echo ""
    echo "  查看日志:"
    echo "    pm2 logs twitter-monitor-scraper"
    echo ""
    echo "  查看状态:"
    echo "    pm2 status"
    echo ""
    echo "  重启服务:"
    echo "    pm2 restart twitter-monitor-scraper"
    echo ""
    echo "  停止服务:"
    echo "    pm2 stop twitter-monitor-scraper"
    echo ""
    echo "  更新代码:"
    echo "    cd /root/twitter-monitor-scraper"
    echo "    git pull"
    echo "    pm2 restart twitter-monitor-scraper"
    echo ""
    echo "  修改配置:"
    echo "    cd /root/twitter-monitor-scraper"
    echo "    vi .env"
    echo "    pm2 restart twitter-monitor-scraper"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🚀 服务已在后台运行，监控已开始！"
    echo ""
}

# 主函数
main() {
    # 检查是否为 root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ 请使用 root 用户运行此脚本${NC}"
        echo "   使用: sudo bash $0"
        exit 1
    fi
    
    detect_os
    install_git
    install_nodejs
    install_python
    install_pm2
    clone_project
    install_dependencies
    configure_env
    test_run
    start_service
    show_usage
}

# 执行主函数
main

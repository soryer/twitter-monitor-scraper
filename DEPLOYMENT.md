# VPS 部署指南

## 🚀 一键部署（推荐）

### 方式一：直接运行部署脚本

在你的 VPS 上执行：

```bash
# 下载并运行部署脚本
curl -fsSL https://raw.githubusercontent.com/soryer/twitter-monitor-scraper/main/deploy.sh | bash
```

或者：

```bash
# 手动下载
wget https://raw.githubusercontent.com/soryer/twitter-monitor-scraper/main/deploy.sh
chmod +x deploy.sh
sudo ./deploy.sh
```

脚本会自动完成：
- ✅ 检测操作系统（CentOS/Ubuntu）
- ✅ 安装 Node.js 18.x
- ✅ 安装 Python 3 和 pip3
- ✅ 安装 Git 和 PM2
- ✅ 克隆项目代码
- ✅ 安装所有依赖
- ✅ 配置环境变量
- ✅ 测试运行
- ✅ 启动服务并设置开机自启

---

## 📋 手动部署

如果你想手动控制每一步，可以按以下步骤操作：

### 步骤 1: 登录 VPS

```bash
ssh root@your-vps-ip
```

### 步骤 2: 安装基础环境

#### CentOS 7/8

```bash
# 更新系统
yum update -y

# 安装 Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# 安装 Python3 和 pip3
yum install -y python3 python3-pip

# 安装 Git
yum install -y git

# 安装 PM2
npm install -g pm2
```

#### Ubuntu 18.04/20.04/22.04

```bash
# 更新系统
apt-get update && apt-get upgrade -y

# 安装 Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 安装 Python3 和 pip3
apt-get install -y python3 python3-pip

# 安装 Git
apt-get install -y git

# 安装 PM2
npm install -g pm2
```

### 步骤 3: 克隆项目

```bash
cd /root
git clone https://github.com/soryer/twitter-monitor-scraper.git
cd twitter-monitor-scraper
```

### 步骤 4: 安装依赖

```bash
# 安装 Python 依赖
pip3 install -r requirements.txt

# 安装 Node.js 依赖
npm install
```

### 步骤 5: 配置环境变量

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置
vi .env
```

填入你的配置：

```env
TELEGRAM_BOT_TOKEN=你的Bot_Token
TELEGRAM_CHAT_ID=你的Chat_ID
TWITTER_USERNAMES=cz_binance,elonmusk
CHECK_INTERVAL=30000
```

### 步骤 6: 测试运行

```bash
# 测试 Python 爬虫
python3 scraper.py elonmusk 3

# 测试完整程序
npm start
```

如果看到成功连接 Telegram，按 `Ctrl+C` 停止。

### 步骤 7: 启动后台服务

```bash
# 使用 PM2 启动
pm2 start ecosystem.config.js

# 查看日志
pm2 logs twitter-monitor-scraper

# 设置开机自启
pm2 startup
pm2 save
```

---

## 🔧 常用操作

### 查看运行状态

```bash
pm2 status
pm2 monit
```

### 查看日志

```bash
# 实时日志
pm2 logs twitter-monitor-scraper

# 查看最近的日志
pm2 logs twitter-monitor-scraper --lines 100

# 清空日志
pm2 flush
```

### 重启服务

```bash
pm2 restart twitter-monitor-scraper
```

### 停止服务

```bash
pm2 stop twitter-monitor-scraper
```

### 删除服务

```bash
pm2 delete twitter-monitor-scraper
```

### 更新代码

```bash
cd /root/twitter-monitor-scraper
git pull
pm2 restart twitter-monitor-scraper
```

### 修改配置

```bash
cd /root/twitter-monitor-scraper
vi .env
pm2 restart twitter-monitor-scraper
```

---

## 🛠️ 故障排除

### 1. Python 爬虫失败

```bash
# 重新安装 snscrape
pip3 install --upgrade snscrape

# 测试爬虫
python3 scraper.py elonmusk 1
```

### 2. 找不到 Python3

```bash
# 检查 Python 路径
which python3

# 如果路径不同，修改 .env
echo "PYTHON_COMMAND=/usr/bin/python3" >> .env
pm2 restart twitter-monitor-scraper
```

### 3. PM2 启动失败

```bash
# 查看错误日志
pm2 logs twitter-monitor-scraper --err

# 手动运行检查问题
cd /root/twitter-monitor-scraper
npm start
```

### 4. Telegram 通知失败

```bash
# 检查配置
cat .env | grep TELEGRAM

# 测试 Telegram 连接
curl -X POST "https://api.telegram.org/bot你的TOKEN/sendMessage" \
  -d "chat_id=你的CHAT_ID" \
  -d "text=测试消息"
```

### 5. 网络连接问题

如果 Twitter 访问受限，可能需要配置代理：

```bash
# 编辑 scraper.py，添加代理设置
vi scraper.py

# 在文件开头添加：
# import os
# os.environ['HTTP_PROXY'] = 'http://proxy:port'
# os.environ['HTTPS_PROXY'] = 'http://proxy:port'
```

---

## 📊 监控和维护

### 设置定时重启（可选）

```bash
# 每天凌晨 3 点重启
pm2 restart twitter-monitor-scraper --cron "0 3 * * *"
```

### 查看资源使用

```bash
pm2 monit
```

### 日志管理

```bash
# 启用日志轮转
pm2 install pm2-logrotate

# 配置日志大小限制
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

### 监控告警（可选）

```bash
# 安装 pm2-web
npm install -g pm2-web

# 启动 Web 监控界面
pm2-web
```

---

## 🔐 安全建议

### 1. 使用非 root 用户

```bash
# 创建专用用户
useradd -m -s /bin/bash twittermon
su - twittermon

# 在用户目录下克隆项目
cd ~
git clone https://github.com/soryer/twitter-monitor-scraper.git
# ... 后续步骤相同
```

### 2. 保护配置文件

```bash
chmod 600 /root/twitter-monitor-scraper/.env
```

### 3. 配置防火墙

```bash
# CentOS
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# Ubuntu
ufw allow ssh
ufw enable
```

---

## 📈 性能优化

### 1. 减少内存占用

```bash
# 修改 ecosystem.config.js
vi ecosystem.config.js

# 调整内存限制
max_memory_restart: '100M'
```

### 2. 调整检查间隔

```bash
# 编辑 .env
vi .env

# 根据用户数量调整
# 1-2 个用户: 30000 (30秒)
# 3-5 个用户: 60000 (60秒)
# 5+ 个用户: 120000 (2分钟)
```

### 3. 启用 Node.js 集群模式（可选）

```bash
# 修改 ecosystem.config.js
instances: 1,  # 改为 2 或更多
exec_mode: 'cluster'
```

---

## 🚀 多服务器部署

如果你有多台 VPS，可以分布式部署：

```bash
# 服务器 A 监控用户 1-5
TWITTER_USERNAMES=user1,user2,user3,user4,user5

# 服务器 B 监控用户 6-10
TWITTER_USERNAMES=user6,user7,user8,user9,user10
```

---

## 📞 获取帮助

如果遇到问题：

1. 查看日志：`pm2 logs twitter-monitor-scraper`
2. 检查 GitHub Issues
3. 阅读 README.md 和 QUICKSTART.md

---

## ✅ 部署检查清单

完成以下检查确保部署成功：

- [ ] Node.js 已安装（`node -v`）
- [ ] Python3 已安装（`python3 --version`）
- [ ] pip3 已安装（`pip3 --version`）
- [ ] snscrape 已安装（`pip3 list | grep snscrape`）
- [ ] PM2 已安装（`pm2 -v`）
- [ ] 项目已克隆到 `/root/twitter-monitor-scraper`
- [ ] 依赖已安装（`npm list` 和 `pip3 list`）
- [ ] .env 配置正确
- [ ] Python 爬虫测试成功
- [ ] PM2 服务运行中（`pm2 status`）
- [ ] 已收到 Telegram 启动通知
- [ ] 开机自启已设置（`pm2 startup`）

全部完成？🎉 恭喜，部署成功！

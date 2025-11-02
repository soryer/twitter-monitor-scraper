# 快速开始指南

## 5 分钟快速部署

### 步骤 1: 安装依赖

```bash
cd twitter-monitor-scraper
./install.sh
```

脚本会自动：
- ✅ 检查 Node.js、Python3、pip3
- ✅ 安装所有依赖
- ✅ 创建配置文件

### 步骤 2: 配置

编辑 `.env` 文件：

```bash
vi .env
```

填入以下信息：

```env
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...        # Telegram Bot Token
TELEGRAM_CHAT_ID=-1001234567890            # Telegram Chat ID
TWITTER_USERNAMES=cz_binance,elonmusk      # 监控的用户
CHECK_INTERVAL=30000                        # 30 秒检查一次
```

### 步骤 3: 测试

测试 Python 爬虫：

```bash
./test-scraper.sh elonmusk
```

应该能看到推文的 JSON 数据。

### 步骤 4: 启动

**本地测试：**
```bash
npm start
```

**后台运行：**
```bash
# 安装 PM2（如果还没有）
npm install -g pm2

# 启动
pm2 start ecosystem.config.js

# 查看日志
pm2 logs twitter-monitor-scraper

# 查看状态
pm2 status
```

## 完成！🎉

现在你的监控系统已经在运行了，每 30 秒检查一次新推文。

---

## 获取 Token 和 Chat ID

### Telegram Bot Token

1. 找 [@BotFather](https://t.me/BotFather) 创建 Bot
2. 发送 `/newbot`
3. 按提示设置名称
4. 获得 Token（格式：`123456:ABC-DEF...`）

### Telegram Chat ID

**方法 1: 私聊 Bot**
```bash
# 1. 给你的 Bot 发消息
# 2. 访问以下网址（替换 YOUR_TOKEN）
https://api.telegram.org/botYOUR_TOKEN/getUpdates

# 3. 找到 "chat":{"id":123456789}
```

**方法 2: 群组**
```bash
# 1. 创建群组，添加 Bot
# 2. 访问上面的网址
# 3. Chat ID 通常是负数（如 -1001234567890）
```

---

## 常见问题

### Q: snscrape 安装失败

```bash
# 尝试升级 pip
pip3 install --upgrade pip

# 重新安装
pip3 install --upgrade snscrape
```

### Q: Python 找不到

```bash
# 检查 Python 路径
which python3

# 如果路径不同，修改 .env
PYTHON_COMMAND=/usr/local/bin/python3
```

### Q: 爬取失败

可能原因：
- 网络连接问题
- Twitter 用户名错误（不要加 @）
- Twitter 临时限制（等待一会儿）

### Q: 想要更快的检查间隔

完全可以！无 API 限制：

```env
# 10 秒
CHECK_INTERVAL=10000

# 15 秒
CHECK_INTERVAL=15000
```

建议不低于 10 秒，避免被 Twitter 识别为爬虫。

---

## 高级配置

### 监控多个用户

```env
TWITTER_USERNAMES=cz_binance,elonmusk,vitalikbuterin,SBF_FTX
```

### 开机自启动

```bash
pm2 startup
pm2 save
```

### 定时重启（可选）

```bash
# 每天凌晨 3 点重启
pm2 restart twitter-monitor-scraper --cron "0 3 * * *"
```

---

## 下一步

- 📖 阅读 [README.md](README.md) 了解更多
- 🚀 部署到服务器（无限运行）
- 🎨 自定义通知格式（编辑 `telegram.js`）
- 📊 添加更多统计功能

祝监控愉快！🎉

# Twitter Scraper - 安装指南

由于 snscrape 已停止维护，本项目支持多种爬取方案作为替代。

## 🔧 推荐安装方案

### 方案 1: 使用 ntscraper（推荐）✨

```bash
pip3 install ntscraper requests beautifulsoup4
```

**优点：**
- ✅ 仍在维护
- ✅ 基于 Nitter 实例
- ✅ 相对稳定
- ✅ 无需配置

**测试：**
```bash
python3 scraper.py elonmusk 3
```

---

### 方案 2: 使用 Git 版本的 snscrape

snscrape PyPI 版本已停止更新，但可以从 GitHub 安装最新版本：

```bash
pip3 install git+https://github.com/JustAnotherArchivist/snscraper.git
```

或者安装特定版本：

```bash
# 安装开发版
pip3 install git+https://github.com/JustAnotherArchivist/snscraper.git@master

# 或使用最后一个稳定版本
pip3 install snscrape==0.7.0.20230622
```

**注意：** Twitter 可能已经封禁了 snscraper，该方案可能不稳定。

---

### 方案 3: 仅使用 requests（基础爬虫）

如果以上方案都不可用：

```bash
pip3 install requests beautifulsoup4
```

**说明：**
- 使用公共 Nitter 实例
- 功能有限（无互动数据）
- 作为最后的备选方案

---

## 📦 完整安装步骤

### 1. 克隆项目

```bash
git clone https://github.com/soryer/twitter-monitor-scraper.git
cd twitter-monitor-scraper
```

### 2. 选择并安装依赖

**推荐方式：**
```bash
# 安装 ntscraper（推荐）
pip3 install ntscraper requests beautifulsoup4

# 安装 Node.js 依赖
npm install
```

**或者尝试 snscrape：**
```bash
# 尝试从 Git 安装 snscraper
pip3 install git+https://github.com/JustAnotherArchivist/snscraper.git

# 如果失败，回退到 ntscraper
pip3 install ntscraper requests beautifulsoup4

# 安装 Node.js 依赖
npm install
```

### 3. 测试爬虫

```bash
# 测试是否能正常获取推文
python3 scraper.py elonmusk 3
```

如果看到 JSON 格式的推文数据，说明成功！

### 4. 配置和启动

```bash
# 配置
cp .env.example .env
vi .env

# 启动
npm start

# 或使用 PM2
pm2 start ecosystem.config.js
```

---

## 🔍 故障排除

### 问题 1: 找不到 snscrape 版本

**错误信息：**
```
No matching distribution found for snscrape>=3.5.0
```

**解决方案：**
```bash
# 不要使用 requirements.txt，手动安装
pip3 install ntscraper requests beautifulsoup4
```

---

### 问题 2: ntscraper 安装失败

```bash
# 升级 pip
pip3 install --upgrade pip

# 重新安装
pip3 install ntscraper
```

如果还是失败：
```bash
# 使用基础爬虫方案
pip3 install requests beautifulsoup4
```

---

### 问题 3: 爬取失败

**测试不同方案：**

```bash
# 测试 1: 检查是否安装成功
python3 -c "import ntscraper; print('ntscraper OK')"

# 测试 2: 尝试爬取
python3 scraper.py elonmusk 1

# 测试 3: 检查网络
curl https://nitter.net/elonmusk
```

---

### 问题 4: 脚本返回空数据

可能原因：
- Nitter 实例不可用
- Twitter 用户名错误
- 网络问题

**解决方案：**

编辑 `scraper.py`，添加更多 Nitter 实例：

```python
nitter_instances = [
    'https://nitter.net',
    'https://nitter.poast.org',
    'https://nitter.privacydev.net',
    'https://nitter.1d4.us',
    'https://nitter.kavin.rocks',
]
```

---

## 📝 VPS 部署注意事项

### CentOS/RHEL

```bash
# 安装 Python3 开发工具
yum install -y python3-devel gcc

# 安装依赖
pip3 install ntscraper requests beautifulsoup4
```

### Ubuntu/Debian

```bash
# 安装构建工具
apt-get install -y python3-dev build-essential

# 安装依赖
pip3 install ntscraper requests beautifulsoup4
```

---

## 🔄 更新项目

如果你之前安装了旧版本：

```bash
cd /root/twitter-monitor-scraper
git pull

# 重新安装依赖
pip3 install ntscraper requests beautifulsoup4
npm install

# 重启
pm2 restart twitter-monitor-scraper
```

---

## ✅ 验证安装

运行以下命令验证所有组件：

```bash
# 1. 检查 Python 包
pip3 list | grep -E "ntscraper|requests|beautifulsoup4"

# 2. 测试爬虫
python3 scraper.py elonmusk 1

# 3. 测试 Node.js
node -e "console.log('Node.js OK')"

# 4. 检查 PM2
pm2 -v
```

全部通过？✅ 可以开始使用了！

---

## 📚 相关资源

- [ntscraper GitHub](https://github.com/bocchilorenzo/ntscraper)
- [snscrape GitHub](https://github.com/JustAnotherArchivist/snscraper)
- [Nitter 实例列表](https://github.com/zedeus/nitter/wiki/Instances)

---

## 💡 推荐配置

最稳定的安装组合：

```bash
# Python 依赖
pip3 install ntscraper==0.3.2 requests==2.31.0 beautifulsoup4==4.12.0

# Node.js 依赖
npm install
```

这个组合在 2025 年 11 月测试通过！✅

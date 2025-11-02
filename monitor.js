const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const TelegramNotifier = require('./telegram');
const config = require('./config');

class TwitterMonitor {
  constructor() {
    this.telegram = new TelegramNotifier();
    this.usernames = config.monitor.usernames;
    this.checkInterval = config.monitor.checkInterval;
    this.pythonCommand = config.monitor.pythonCommand;
    this.lastTweetIdFile = path.join(__dirname, 'last_tweet_id.json');
    this.isRunning = false;
    this.stats = {
      totalChecks: 0,
      newTweets: 0,
      errors: 0,
      startTime: Date.now()
    };
  }

  /**
   * 获取上次检查的推文 ID
   */
  getLastTweetIds() {
    try {
      if (fs.existsSync(this.lastTweetIdFile)) {
        const data = fs.readFileSync(this.lastTweetIdFile, 'utf8');
        return JSON.parse(data);
      }
    } catch (error) {
      console.error('读取推文 ID 失败:', error.message);
    }
    return {};
  }

  /**
   * 保存最新推文 ID
   */
  saveLastTweetIds(lastTweetIds) {
    try {
      fs.writeFileSync(this.lastTweetIdFile, JSON.stringify(lastTweetIds, null, 2));
    } catch (error) {
      console.error('保存推文 ID 失败:', error.message);
    }
  }

  /**
   * 调用 Python 爬虫获取推文
   */
  async fetchTweets(username) {
    return new Promise((resolve, reject) => {
      const scriptPath = path.join(__dirname, 'scraper.py');
      const python = spawn(this.pythonCommand, [scriptPath, username, '5']);
      
      let stdout = '';
      let stderr = '';
      
      python.stdout.on('data', (data) => {
        stdout += data.toString();
      });
      
      python.stderr.on('data', (data) => {
        stderr += data.toString();
      });
      
      python.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`Python 脚本退出码 ${code}: ${stderr}`));
          return;
        }
        
        try {
          const result = JSON.parse(stdout);
          resolve(result);
        } catch (error) {
          reject(new Error(`解析 JSON 失败: ${error.message}\n输出: ${stdout}`));
        }
      });
      
      // 设置超时
      setTimeout(() => {
        python.kill();
        reject(new Error('爬取超时（30秒）'));
      }, 30000);
    });
  }

  /**
   * 检查单个用户的新推文
   */
  async checkUserTweets(username) {
    try {
      console.log(`\n   检查 @${username}...`);
      
      const result = await this.fetchTweets(username);
      
      if (!result.success || !result.tweets || result.tweets.length === 0) {
        console.log(`   @${username}: 暂无推文`);
        return 0;
      }
      
      const lastTweetIds = this.getLastTweetIds();
      const lastTweetId = lastTweetIds[username];
      
      // 过滤新推文
      const newTweets = lastTweetId
        ? result.tweets.filter(tweet => tweet.id > lastTweetId)
        : [];
      
      if (newTweets.length > 0) {
        console.log(`   🆕 @${username} 发现 ${newTweets.length} 条新推文！`);
        
        // 按时间顺序发送（从旧到新）
        newTweets.reverse();
        
        for (const tweet of newTweets) {
          console.log(`   📨 推文 ID: ${tweet.id}`);
          console.log(`      ${tweet.text.substring(0, 80)}${tweet.text.length > 80 ? '...' : ''}`);
          
          await this.telegram.sendTweetAlert(tweet, tweet.user);
          await new Promise(resolve => setTimeout(resolve, 1000));
        }
        
        // 更新最新推文 ID
        lastTweetIds[username] = result.tweets[0].id;
        this.saveLastTweetIds(lastTweetIds);
        
        return newTweets.length;
      } else {
        // 初始化或无新推文
        if (!lastTweetId && result.tweets.length > 0) {
          lastTweetIds[username] = result.tweets[0].id;
          this.saveLastTweetIds(lastTweetIds);
          console.log(`   📌 @${username} 初始化，最新推文 ID: ${result.tweets[0].id}`);
        } else {
          console.log(`   @${username}: 无新推文`);
        }
        return 0;
      }
      
    } catch (error) {
      console.error(`   ✗ @${username}: ${error.message}`);
      this.stats.errors++;
      
      // 发送错误通知（但不中断监控）
      if (this.stats.errors % 5 === 0) {
        await this.telegram.sendErrorAlert(error, username);
      }
      
      return 0;
    }
  }

  /**
   * 检查所有用户的新推文
   */
  async checkAllUsers() {
    const now = new Date().toLocaleTimeString('zh-CN');
    console.log(`\n[${now}] 🔍 开始检查 ${this.usernames.length} 个用户...`);
    
    this.stats.totalChecks++;
    let totalNewTweets = 0;
    
    for (const username of this.usernames) {
      const newCount = await this.checkUserTweets(username);
      totalNewTweets += newCount;
      this.stats.newTweets += newCount;
      
      // 用户之间添加小延迟
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    const endTime = new Date().toLocaleTimeString('zh-CN');
    
    if (totalNewTweets > 0) {
      console.log(`\n✅ [${endTime}] 检查完成，发现 ${totalNewTweets} 条新推文`);
    } else {
      console.log(`\n✓ [${endTime}] 检查完成，暂无新推文`);
    }
    
    // 每 10 次检查显示统计
    if (this.stats.totalChecks % 10 === 0) {
      this.showStats();
    }
  }

  /**
   * 显示统计信息
   */
  showStats() {
    const runtime = Math.floor((Date.now() - this.stats.startTime) / 60000);
    const avgChecksPerHour = runtime > 0 ? Math.floor(this.stats.totalChecks / (runtime / 60)) : 0;
    
    console.log(`\n${'='.repeat(50)}`);
    console.log(`📊 运行统计:`);
    console.log(`   运行时长: ${runtime} 分钟`);
    console.log(`   总检查次数: ${this.stats.totalChecks}`);
    console.log(`   发现新推文: ${this.stats.newTweets} 条`);
    console.log(`   错误次数: ${this.stats.errors}`);
    console.log(`   平均频率: ${avgChecksPerHour} 次/小时`);
    console.log(`${'='.repeat(50)}\n`);
  }

  /**
   * 测试 Python 环境
   */
  async testPythonEnvironment() {
    console.log('\n🔧 测试 Python 环境...');
    
    return new Promise((resolve, reject) => {
      const python = spawn(this.pythonCommand, ['-c', 'import snscrape; print("snscrape OK")']);
      
      let output = '';
      
      python.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      python.stderr.on('data', (data) => {
        output += data.toString();
      });
      
      python.on('close', (code) => {
        if (code === 0 && output.includes('snscrape OK')) {
          console.log('✅ Python 环境正常');
          resolve(true);
        } else {
          reject(new Error(`Python 环境错误:\n${output}\n\n请运行: pip3 install -r requirements.txt`));
        }
      });
    });
  }

  /**
   * 初始化监控
   */
  async initialize() {
    try {
      console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('   Twitter Monitor Scraper - 无 API 限制版');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      // 测试 Python 环境
      await this.testPythonEnvironment();
      
      // 测试 Telegram 连接
      console.log('\n🔗 测试 Telegram 连接...');
      await this.telegram.testConnection();
      
      console.log('\n✅ 所有系统检查通过！');
      
      return true;
    } catch (error) {
      console.error('\n❌ 初始化失败:', error.message);
      throw error;
    }
  }

  /**
   * 启动监控
   */
  async start() {
    if (this.isRunning) {
      console.log('⚠️  监控已在运行中');
      return;
    }
    
    try {
      await this.initialize();
      this.isRunning = true;
      
      console.log(`\n🚀 开始监控 ${this.usernames.length} 个用户:`);
      this.usernames.forEach(user => {
        console.log(`   • @${user}`);
      });
      console.log(`\n⏱️  检查间隔: ${this.checkInterval / 1000} 秒`);
      console.log(`⚡ 无 API 限制，可随意调整间隔！`);
      console.log(`\n按 Ctrl+C 停止监控\n`);
      
      // 立即检查一次
      await this.checkAllUsers();
      
      // 定时检查
      this.intervalId = setInterval(async () => {
        await this.checkAllUsers();
      }, this.checkInterval);
      
    } catch (error) {
      console.error('启动失败:', error.message);
      this.isRunning = false;
      process.exit(1);
    }
  }

  /**
   * 停止监控
   */
  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.isRunning = false;
      console.log('\n\n🛑 监控已停止');
      this.showStats();
    }
  }
}

module.exports = TwitterMonitor;

const TelegramBot = require('node-telegram-bot-api');
const config = require('./config');

class TelegramNotifier {
  constructor() {
    this.bot = new TelegramBot(config.telegram.botToken, { polling: false });
    this.chatId = config.telegram.chatId;
  }

  /**
   * 测试 Telegram 连接
   */
  async testConnection() {
    try {
      const me = await this.bot.getMe();
      console.log(`✅ Telegram Bot 连接成功: @${me.username}`);
      
      // 发送测试消息
      await this.bot.sendMessage(
        this.chatId,
        '🤖 Twitter 监控系统已启动（Scraper 版本）\n无 API 限制，实时监控中...'
      );
      
      return true;
    } catch (error) {
      console.error('❌ Telegram 连接失败:', error.message);
      throw error;
    }
  }

  /**
   * 发送推文通知
   */
  async sendTweetAlert(tweet, user) {
    try {
      const message = this.formatTweetMessage(tweet, user);
      
      await this.bot.sendMessage(this.chatId, message, {
        parse_mode: 'Markdown',
        disable_web_page_preview: false
      });
      
      return true;
    } catch (error) {
      console.error('发送 Telegram 通知失败:', error.message);
      return false;
    }
  }

  /**
   * 格式化推文消息
   */
  formatTweetMessage(tweet, user) {
    const userName = user.name || tweet.user.name;
    const username = user.username || tweet.user.username;
    const tweetUrl = tweet.url || `https://twitter.com/${username}/status/${tweet.id}`;
    
    const metrics = tweet.metrics || {};
    const likes = metrics.like_count || 0;
    const retweets = metrics.retweet_count || 0;
    const replies = metrics.reply_count || 0;
    
    // 格式化时间
    const tweetTime = new Date(tweet.created_at).toLocaleString('zh-CN', {
      timeZone: 'Asia/Shanghai'
    });
    
    let message = `🐦 *新推文提醒*\n\n`;
    message += `👤 *${userName}* (@${username})\n`;
    message += `⏰ ${tweetTime}\n\n`;
    message += `📝 ${tweet.text}\n\n`;
    message += `📊 ❤️ ${likes}  🔄 ${retweets}  💬 ${replies}\n\n`;
    message += `🔗 [查看推文](${tweetUrl})`;
    
    return message;
  }

  /**
   * 发送错误通知
   */
  async sendErrorAlert(error, username) {
    try {
      const message = `⚠️ *监控警告*\n\n` +
                     `用户: @${username}\n` +
                     `错误: ${error.message}\n` +
                     `时间: ${new Date().toLocaleString('zh-CN')}`;
      
      await this.bot.sendMessage(this.chatId, message, {
        parse_mode: 'Markdown'
      });
    } catch (e) {
      console.error('发送错误通知失败:', e.message);
    }
  }
}

module.exports = TelegramNotifier;

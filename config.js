require('dotenv').config();

const config = {
  telegram: {
    botToken: process.env.TELEGRAM_BOT_TOKEN,
    chatId: process.env.TELEGRAM_CHAT_ID
  },
  monitor: {
    usernames: process.env.TWITTER_USERNAMES 
      ? process.env.TWITTER_USERNAMES.split(',').map(u => u.trim())
      : [],
    checkInterval: parseInt(process.env.CHECK_INTERVAL) || 30000,
    pythonCommand: process.env.PYTHON_COMMAND || 'python3'
  }
};

// 验证配置
function validateConfig() {
  const errors = [];
  
  if (!config.telegram.botToken) {
    errors.push('TELEGRAM_BOT_TOKEN 未设置');
  }
  
  if (!config.telegram.chatId) {
    errors.push('TELEGRAM_CHAT_ID 未设置');
  }
  
  if (config.monitor.usernames.length === 0) {
    errors.push('TWITTER_USERNAMES 未设置或为空');
  }
  
  if (errors.length > 0) {
    console.error('\n❌ 配置错误:\n');
    errors.forEach(err => console.error(`   • ${err}`));
    console.error('\n请检查 .env 文件配置\n');
    process.exit(1);
  }
  
  console.log('\n✅ 配置验证通过');
  console.log(`   监控用户: ${config.monitor.usernames.join(', ')}`);
  console.log(`   检查间隔: ${config.monitor.checkInterval / 1000} 秒\n`);
}

module.exports = config;
module.exports.validateConfig = validateConfig;

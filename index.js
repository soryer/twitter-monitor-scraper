const config = require('./config');
const TwitterMonitor = require('./monitor');

// 验证配置
config.validateConfig();

// 创建监控实例
const monitor = new TwitterMonitor();

// 优雅退出
process.on('SIGINT', () => {
  console.log('\n\n收到退出信号...');
  monitor.stop();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n收到终止信号...');
  monitor.stop();
  process.exit(0);
});

// 启动监控
monitor.start().catch(error => {
  console.error('\n❌ 启动失败:', error.message);
  process.exit(1);
});

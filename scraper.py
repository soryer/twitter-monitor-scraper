#!/usr/bin/env python3
"""
Twitter Scraper using snscrape
获取指定用户的最新推文，无需 API Token
"""

import sys
import json
import snscrape.modules.twitter as sntwitter
from datetime import datetime

def get_latest_tweets(username, limit=5):
    """
    获取指定用户的最新推文
    
    Args:
        username: Twitter 用户名（不带 @）
        limit: 获取推文数量
    
    Returns:
        list: 推文列表
    """
    tweets = []
    
    try:
        # 使用 snscrape 获取推文
        scraper = sntwitter.TwitterUserScraper(username)
        
        for i, tweet in enumerate(scraper.get_items()):
            if i >= limit:
                break
            
            # 提取推文信息
            tweet_data = {
                'id': str(tweet.id),
                'text': tweet.rawContent,
                'created_at': tweet.date.isoformat(),
                'url': tweet.url,
                'user': {
                    'username': tweet.user.username,
                    'name': tweet.user.displayname,
                    'id': str(tweet.user.id)
                },
                'metrics': {
                    'like_count': tweet.likeCount or 0,
                    'retweet_count': tweet.retweetCount or 0,
                    'reply_count': tweet.replyCount or 0,
                    'quote_count': tweet.quoteCount or 0
                }
            }
            
            tweets.append(tweet_data)
        
        return tweets
    
    except Exception as e:
        print(json.dumps({
            'error': True,
            'message': str(e),
            'username': username
        }), file=sys.stderr)
        return []

def main():
    """
    主函数：从命令行参数获取用户名，输出 JSON 格式的推文数据
    """
    if len(sys.argv) < 2:
        print(json.dumps({
            'error': True,
            'message': 'Usage: python3 scraper.py <username> [limit]'
        }))
        sys.exit(1)
    
    username = sys.argv[1]
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    
    # 获取推文
    tweets = get_latest_tweets(username, limit)
    
    # 输出 JSON 格式
    result = {
        'success': True,
        'username': username,
        'count': len(tweets),
        'tweets': tweets,
        'timestamp': datetime.now().isoformat()
    }
    
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()

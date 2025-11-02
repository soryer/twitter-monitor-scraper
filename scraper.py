#!/usr/bin/env python3
"""
Twitter Scraper - 支持多种爬取方案
获取指定用户的最新推文，无需 API Token
"""

import sys
import json
from datetime import datetime

# 尝试导入可用的库
SCRAPER_METHOD = None

try:
    from ntscraper import Nitter
    SCRAPER_METHOD = 'ntscraper'
except ImportError:
    pass

if not SCRAPER_METHOD:
    try:
        import snscrape.modules.twitter as sntwitter
        SCRAPER_METHOD = 'snscrape'
    except ImportError:
        pass

if not SCRAPER_METHOD:
    try:
        import requests
        from bs4 import BeautifulSoup
        SCRAPER_METHOD = 'requests'
    except ImportError:
        print(json.dumps({
            'error': True,
            'message': 'No scraping library available. Please install: pip3 install ntscraper'
        }), file=sys.stderr)
        sys.exit(1)

def get_latest_tweets_ntscraper(username, limit=5):
    """使用 ntscraper 获取推文"""
    tweets = []
    try:
        scraper = Nitter(log_level=1, skip_instance_check=False)
        user_tweets = scraper.get_tweets(username, mode='user', number=limit)
        
        if user_tweets and 'tweets' in user_tweets:
            for tweet in user_tweets['tweets'][:limit]:
                tweet_data = {
                    'id': str(tweet.get('tweet_id', '')),
                    'text': tweet.get('text', ''),
                    'created_at': tweet.get('date', datetime.now().isoformat()),
                    'url': tweet.get('link', f'https://twitter.com/{username}/status/{tweet.get("tweet_id", "")}'),
                    'user': {
                        'username': username,
                        'name': tweet.get('name', username),
                        'id': tweet.get('user_id', '0')
                    },
                    'metrics': {
                        'like_count': tweet.get('likes', 0),
                        'retweet_count': tweet.get('retweets', 0),
                        'reply_count': tweet.get('comments', 0),
                        'quote_count': 0
                    }
                }
                tweets.append(tweet_data)
        
        return tweets
    except Exception as e:
        raise Exception(f'ntscraper error: {str(e)}')

def get_latest_tweets_snscrape(username, limit=5):
    """使用 snscrape 获取推文"""
    tweets = []
    try:
        scraper = sntwitter.TwitterUserScraper(username)
        
        for i, tweet in enumerate(scraper.get_items()):
            if i >= limit:
                break
            
            tweet_data = {
                'id': str(tweet.id),
                'text': tweet.rawContent if hasattr(tweet, 'rawContent') else tweet.content,
                'created_at': tweet.date.isoformat(),
                'url': tweet.url,
                'user': {
                    'username': tweet.user.username,
                    'name': tweet.user.displayname if hasattr(tweet.user, 'displayname') else tweet.user.username,
                    'id': str(tweet.user.id)
                },
                'metrics': {
                    'like_count': tweet.likeCount or 0,
                    'retweet_count': tweet.retweetCount or 0,
                    'reply_count': tweet.replyCount or 0,
                    'quote_count': getattr(tweet, 'quoteCount', 0) or 0
                }
            }
            
            tweets.append(tweet_data)
        
        return tweets
    except Exception as e:
        raise Exception(f'snscrape error: {str(e)}')

def get_latest_tweets_requests(username, limit=5):
    """使用 requests 直接爬取（最后的备选方案）"""
    tweets = []
    try:
        # 使用公开的 Nitter 实例
        nitter_instances = [
            'https://nitter.net',
            'https://nitter.poast.org',
            'https://nitter.privacydev.net'
        ]
        
        for instance in nitter_instances:
            try:
                url = f'{instance}/{username}'
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
                response = requests.get(url, headers=headers, timeout=10)
                
                if response.status_code == 200:
                    soup = BeautifulSoup(response.text, 'html.parser')
                    tweet_items = soup.find_all('div', class_='timeline-item')[:limit]
                    
                    for item in tweet_items:
                        try:
                            text_elem = item.find('div', class_='tweet-content')
                            text = text_elem.get_text(strip=True) if text_elem else ''
                            
                            link_elem = item.find('a', class_='tweet-link')
                            tweet_id = link_elem['href'].split('/')[-1].replace('#m', '') if link_elem else '0'
                            
                            tweet_data = {
                                'id': tweet_id,
                                'text': text,
                                'created_at': datetime.now().isoformat(),
                                'url': f'https://twitter.com/{username}/status/{tweet_id}',
                                'user': {
                                    'username': username,
                                    'name': username,
                                    'id': '0'
                                },
                                'metrics': {
                                    'like_count': 0,
                                    'retweet_count': 0,
                                    'reply_count': 0,
                                    'quote_count': 0
                                }
                            }
                            tweets.append(tweet_data)
                        except Exception:
                            continue
                    
                    if tweets:
                        break
            except Exception:
                continue
        
        return tweets
    except Exception as e:
        raise Exception(f'requests scraping error: {str(e)}')

def get_latest_tweets(username, limit=5):
    """
    获取指定用户的最新推文 - 自动选择可用的方法
    
    Args:
        username: Twitter 用户名（不带 @）
        limit: 获取推文数量
    
    Returns:
        list: 推文列表
    """
    tweets = []
    errors = []
    
    # 按优先级尝试不同的方法
    methods = []
    if SCRAPER_METHOD == 'ntscraper':
        methods = [
            ('ntscraper', get_latest_tweets_ntscraper),
            ('requests', get_latest_tweets_requests)
        ]
    elif SCRAPER_METHOD == 'snscrape':
        methods = [
            ('snscrape', get_latest_tweets_snscrape),
            ('requests', get_latest_tweets_requests)
        ]
    else:
        methods = [('requests', get_latest_tweets_requests)]
    
    for method_name, method_func in methods:
        try:
            tweets = method_func(username, limit)
            if tweets:
                # 在第一条推文中添加使用的方法信息
                if len(tweets) > 0 and isinstance(tweets[0], dict):
                    tweets[0]['_scraper_method'] = method_name
                return tweets
        except Exception as e:
            errors.append(f'{method_name}: {str(e)}')
            continue
    
    # 所有方法都失败
    error_msg = '; '.join(errors) if errors else 'All scraping methods failed'
    print(json.dumps({
        'error': True,
        'message': error_msg,
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

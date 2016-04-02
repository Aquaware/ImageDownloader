//
//  HTTPAsync.h
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/05/18.
//  Copyright (c) 2012年     . All rights reserved.
//


#import <Foundation/Foundation.h>

@class HTTPAsync;

typedef enum
{
    HTTPAsyncResultNone = 0,            // 初期状態
    HTTPAsyncResultSuccess = 1,         // 通信正常終了
    HTTPAsyncResultHttpError = 2,       // 通信エラー終了
    HTTPAsyncResultComCanceled = 3,     // 通信キャンセルされたとき
    HTTPAsyncResultComTimeout = 4,      // 通信タイムアウトのとき
    HTTPAsyncResultServerError = 5,     //　（未使用）
    
} HTTPAsyncResult;


typedef void (^HTTPAsyncDidReceiveResponse) (HTTPAsync* connection, NSURLResponse* response);
typedef void (^HTTPAsyncDidReceiveData) (HTTPAsync* connection, NSData* receiveData);
typedef void (^HTTPAsyncCompletion) (HTTPAsync* connection, HTTPAsyncResult result, NSMutableData* downloadedData, NSHTTPURLResponse* response, NSError* error);

@protocol HTTPAsyncDelegate <NSObject>

@optional

- (void) connection: (HTTPAsync*) connection didReceiveResponse: (NSURLResponse*) response;
- (void) connection: (HTTPAsync*) connection didFinishData: (NSMutableData*) data result: (HTTPAsyncResult) result error: (NSError*) error;

@end

/*!
 @class             HTTPAsync
 @abstract          HTTP非同期通信
 @discussion        使用方法下記の通り
 
     (1) デリゲート を用いる場合
     受信結果をデリゲートメソッドにより受け取ります
     
     ●本体
     // リクエストの生成
     NSURLRequest* request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: @"http://www.abc.co.jp"]];
     
     // リクエストとタイムアウト時間(sec)を設定してオブジェクトを生成
     HTTPAsync* httpAsysnc = [[HTTPAsync alloc] initWithRequest: request timeout: 30.0];
     
     // デリゲート設定
     httpAsysnc.delegate = self;
     
     // 通信を開始
     [httpAsysnc start];       // 通信開始
     
     [request release];
     [httpAsysnc release];
     
     
     ●サーバーレスポンス受信時デリゲートメソッド
     - (void) connection: (HTTPAsync*) connection didReceiveResponse: (NSURLResponse*) response
     
     ●通信終了時（正常受信、タイムアウト、エラー発生）デリゲートメソッド
     - (void) connection: (HTTPAsync*) connection didFinishData: (NSMutableData*) data result: (HTTPAsyncResult) result error: (NSError*) error;
     
     
     result: 結果のステータス
     data: 受信データ
     eroor: 通信エラーの内容
     
     
     ●キャンセル
     cancelメソッドでキャンセルできます、デリゲートの通知はありません
     
     
     (2) block記述を用いる場合
     受信結果を同じスコープ内で受け取ります
     
     ●本体
     // リクエストの生成
     NSURLRequest* request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: @"http://www.abc.co.jp"]];
     
     // リクエストとタイムアウト時間(sec)を設定してオブジェクトを生成
     HTTPAsync* httpAsysnc = [[HTTPAsync alloc] initWithRequest: request timeout: 30.0];
     
     // 通信終了時のblock記述
     httpAsysnc.completion = ^(HTTPAsync *connection, HTTPAsyncResult result, NSMutableData *downloadedData, NSHTTPURLResponse *response, NSError *error)
     {
     // ここに通信終了時（正常終了、エラー終了、タイムアウト、キャンセル) の処理を記述 
     }
     
     // 通信を開始
     [httpAsysnc start];       // 通信開始
 
 */
@interface HTTPAsync : NSObject <NSURLConnectionDelegate>

@property (nonatomic, assign) id <HTTPAsyncDelegate> delegate;
@property (nonatomic, copy)   HTTPAsyncDidReceiveResponse didReceiveResponse; 
@property (nonatomic, copy)   HTTPAsyncDidReceiveData didReceiveData; 
@property (nonatomic, copy)   HTTPAsyncCompletion completion;

- (id) initWithRequest: (NSURLRequest*) request timeout: (NSTimeInterval) timeoutTime;
- (void) start;
- (void) cancel;
- (void) wait;

@end


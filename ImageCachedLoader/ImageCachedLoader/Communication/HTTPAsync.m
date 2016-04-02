//
//  HTTPAsync.m
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/05/18.
//  Copyright (c) 2012年     . All rights reserved.
//

#import "HTTPAsync.h"
#define HTML_DATA_LOGOUT

#define kWaitTimeInterval 0.1



typedef enum
{
    HTTPAsyncStatusReady = 1,
    HTTPAsyncStatusInProgress = 2,
    HTTPAsyncStatusFinished = 3
    
} HTTPAsyncStatus;


@interface HTTPAsync ()

@property (nonatomic, assign) HTTPAsyncResult result;
@property (nonatomic, retain) NSConditionLock* lock;
@property (nonatomic, retain) NSURLRequest* httpRequest;      
@property (nonatomic, retain) NSURLConnection* httpConnection;  
@property (nonatomic, assign) NSTimeInterval timeout;    
@property (nonatomic, retain) NSMutableData* downloadedData;          
@property (nonatomic, retain) NSHTTPURLResponse *httpResponse; 
@property (nonatomic, retain) NSError* httpError;   
@property (nonatomic, retain) NSTimer* timeoutTimer;

- (void) timeout: (NSTimer*) timer;
- (void) terminate;
- (void) closeConnection;
- (void) notifyResult;
@end

#pragma mark-
@implementation HTTPAsync
@synthesize delegate;
@synthesize lock;
@synthesize result;
@synthesize timeoutTimer;
@synthesize httpRequest, httpConnection, timeout, downloadedData, httpResponse, httpError;
@synthesize completion, didReceiveResponse, didReceiveData;



#pragma mark -
#pragma mark == 通信初期化 ==
- (id) initWithRequest: (NSURLRequest*) request timeout: (NSTimeInterval) timeoutTime
{
    DLog();
    self.result = HTTPAsyncResultNone;
    self = [super init];
    if (self != nil) {
        self.httpRequest = request;
        lock = [[NSConditionLock alloc] initWithCondition: HTTPAsyncStatusReady];
        self.timeout = timeoutTime;
    }
    
    return self;
}

#pragma mark == 通信開始 ==
- (void) start
{   
    DLog();
    [lock lockWhenCondition: HTTPAsyncStatusReady];
    [lock unlockWithCondition: HTTPAsyncStatusInProgress];
    if (self.timeout> 0.0) {
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval: self.timeout
                                                              target: self
                                                            selector: @selector(timeout:)
                                                            userInfo: nil
                                                             repeats: NO];
    }
    
    httpConnection = [[NSURLConnection alloc]    initWithRequest: self.httpRequest
                                                           delegate: self
                                                   startImmediately: YES];
}

#pragma mark == 通信終了処理 ==
- (void) terminate
{
    if(timeoutTimer) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    
    if ([lock tryLockWhenCondition: HTTPAsyncStatusInProgress]) {
        [lock unlockWithCondition: HTTPAsyncStatusFinished];
    }
}

#pragma mark == 接続切断 ==
- (void) closeConnection
{
    if (self.httpConnection) {
        [self.httpConnection cancel];
    } 
}

#pragma mark == 通信キャンセル ==
- (void) cancel
{
    [self closeConnection];
    [self terminate];
    
    self.result = HTTPAsyncResultComCanceled;
}

#pragma mark == 通信タイムアウト ==
- (void) timeout: (NSTimer*) timer
{
    [self closeConnection];   
    [self terminate];
    self.result = HTTPAsyncResultComTimeout;    
     
    if (completion) {
        completion(self, self.result, self.downloadedData, self.httpResponse,  self.httpError);
    }

    [self notifyResult];
}

#pragma mark == 通信終了を待つ ==
- (void) wait
{
    while (YES) {
        if ([lock tryLockWhenCondition: HTTPAsyncStatusFinished]) {
            [lock unlock];
            break;
        }
        
        [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kWaitTimeInterval]];   // kWaitTimeIntervalの間隔で監視する
        if (self.result == HTTPAsyncResultComCanceled || self.result == HTTPAsyncResultComTimeout) break;
    }
}

#pragma mark ==  結果をデリゲート通知
- (void) notifyResult
{
    if ([self.delegate respondsToSelector: @selector(connection:didFinishData:result:error:)]) {
        [self.delegate connection:self didFinishData: self.downloadedData result: self.result error: self.httpError];
    } 
}


#pragma mark -
#pragma mark ------ NSURLConnection delegate メソッド -----
#pragma mark == サーバーレスポンス受信したとき ==
- (void) connection: (NSURLConnection*) connection didReceiveResponse: (NSURLResponse*) response
{
    self.downloadedData = [NSMutableData dataWithLength: 0];
    self.httpResponse = (NSHTTPURLResponse*)  response;
    
#ifdef HTML_DATA_LOGOUT
    NSLog(@"<<< HTTPAsync Http Server Response>>>");
    NSLog(@"   URL         : %@", [self.httpResponse URL].absoluteString);
    NSLog(@"   Status Code : %d", [self.httpResponse statusCode]);    
    NSLog(@"   MIME Type   : %@", [self.httpResponse MIMEType]);
    NSLog(@"   Expected Content Length: %qi", [self.httpResponse expectedContentLength]);
    NSLog(@"   TextEncoding: %@", [self.httpResponse textEncodingName]);
    NSLog(@"\n\n");
#endif
        

    if(didReceiveResponse) {
        didReceiveResponse(self, self.httpResponse);
    }
     

	if ([self.delegate respondsToSelector: @selector(connection: didReceiveResponse:)]) {
		 [self.delegate connection: self didReceiveResponse: self.httpResponse];
	}
}

#pragma mark == データ受信したとき（途中）==
- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    [self.downloadedData appendData: data];
}

#pragma mark == データ受信完了したとき ==
- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    DLog();
    
    [self terminate];
    self.result = HTTPAsyncResultSuccess;
    
    if ([self.httpResponse.MIMEType isEqualToString: @"text/plain" ] 
        || [self.httpResponse.MIMEType isEqualToString: @"text/html"]) {
        
#ifdef HTML_DATA_LOGOUT        
        NSLog(@"\n\n\n**********    Download Data Size: %d    ********** \n\n\n", [self.downloadedData length]);

        int enc = -1;
        if([self.httpResponse.textEncodingName isEqualToString:       @"utf-8"])        enc = NSUTF8StringEncoding;
        else if([self.httpResponse.textEncodingName isEqualToString:  @"utf-16"])       enc = NSUTF16StringEncoding;
        else if([self.httpResponse.textEncodingName isEqualToString:  @"shift_jis"])    enc = NSShiftJISStringEncoding;
        else if([self.httpResponse.textEncodingName isEqualToString:  @"euc-jp"])       enc = NSJapaneseEUCStringEncoding;
        else if([self.httpResponse.textEncodingName isEqualToString:  @"iso-2022-jp"])  enc = NSISO2022JPStringEncoding;
        else if([self.httpResponse.textEncodingName isEqualToString:  @"us-ascii"])     enc = NSASCIIStringEncoding;
        
        if(enc == -1) enc = NSShiftJISStringEncoding;
        NSString* str = [[NSString alloc] initWithData: self.downloadedData encoding: enc]; 
        NSLog(@"%@\n\n",  str);        
#endif
        
    }
    
    if (completion) {
         completion(self, self.result, self.downloadedData, self.httpResponse, self.httpError);
    }

    [self notifyResult];
}

#pragma mark == HTTP通信 エラー発生したとき ==
- (void) connection: (NSURLConnection*) connection didFailWithError: (NSError*) error
{
    [self terminate];
    self.result = HTTPAsyncResultHttpError;
    self.httpError = error;
    

    if (completion) {
         completion(self, self.result, self.downloadedData, self.httpResponse,  self.httpError);
    }

    
    [self notifyResult];
}


@end

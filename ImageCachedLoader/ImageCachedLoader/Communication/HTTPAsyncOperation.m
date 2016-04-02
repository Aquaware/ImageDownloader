//
//  HTTPAsyncOperation.m
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/26.
//  Copyright (c) 2012年   All rights reserved.
//

#import "HTTPAsync.h"
#import "HTTPAsyncOperation.h"
#import "ImageCache.h"

@interface HTTPAsyncOperation ()
@property (nonatomic, strong) ImageCache* cache;

@end

@implementation HTTPAsyncOperation
@synthesize resultBlock;
@synthesize cache;
@synthesize request, httpAsync;
@synthesize isExecuting, isFinished;

- (id) initWithRequest: (NSURLRequest*) aRequest cache : (ImageCache*) aCache
{
    self = [super init];
    if (self) {
        self.request = aRequest;
        self.cache = aCache;
    }
    
    isExecuting = NO;
    isFinished = NO;
    
    return self;
}

- (BOOL) isConcurrent
{
    return YES;
}

- (BOOL) isExecuting
{
    return isExecuting;
}

- (BOOL) isFinished
{
    return isFinished;
}

- (void) start
{
    if(!self.isCancelled) {
        self.isExecuting = YES;
        
        httpAsync = [[HTTPAsync alloc] initWithRequest: self.request timeout: 120];
        httpAsync.completion = ^(HTTPAsync *connection, HTTPAsyncResult result, NSMutableData *downloadedData, NSHTTPURLResponse *response, NSError *error)
        {
            if(result == HTTPAsyncResultSuccess) {
                self.isFinished = YES;
                self.isExecuting = NO;
                UIImage* img = [UIImage imageWithData: downloadedData];
                [self.cache storeImageWithKey: [self.request URL].absoluteString image: img];
                NSLog(@"image downloaded w: %4.0f h: %4.0f url: %@", [img size].width
                                                                    , [img size].height
                                                                    , [self.request URL].absoluteString);
                if(self.resultBlock) {
                    self.resultBlock(img, nil);
                }
            }
            else {
                if(self.resultBlock) {
                    self.resultBlock(nil, error);
                }
            }
        };
        
        [httpAsync start];
    }
}



- (void) cancel
{
    [httpAsync cancel];
    self.isFinished = YES;
    self.isExecuting = NO;
    
    [super cancel];
}

@end

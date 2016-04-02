//
//  HTTPAsyncOperation.h
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/26.
//  Copyright (c) 2012年   All rights reserved.
//

#import <Foundation/Foundation.h>
@class ImageCache;
@class HTTPAsync;

typedef void (^ImageResult)(UIImage *image, NSError *error);

@interface HTTPAsyncOperation : NSOperation 

@property (nonatomic, strong) ImageResult resultBlock;
@property (nonatomic, strong) HTTPAsync* httpAsync;
@property (nonatomic, strong) NSURLRequest* request;
@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) BOOL isFinished;

- (id) initWithRequest: (NSURLRequest*) aRequest cache : (ImageCache*) cache;
- (void) start;

@end

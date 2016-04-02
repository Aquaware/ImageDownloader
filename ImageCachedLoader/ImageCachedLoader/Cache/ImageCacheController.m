//
//  ImageCacheController.m
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/25.
//  Copyright (c) 2012年 . All rights reserved.
//

#import "ImageCacheController.h"
#import "ImageCache.h"
#import "HTTPAsyncOperation.h"

@interface ImageCacheController ()

@property (nonatomic, strong) ImageCache* cache;
@property (nonatomic, strong) NSOperationQueue* downloadQueue;


@end

@implementation ImageCacheController
@synthesize cache, downloadQueue, defaultImage;


- (id) init
{
    self = [super init];
    if(self) {
        cache = [ImageCache shared];
        downloadQueue = [[NSOperationQueue alloc] init];
        [downloadQueue setMaxConcurrentOperationCount: 3];
    }
    
    return self;
}

- (void) loadDefaultImage: (NSString*) imageFile
{
    self.defaultImage = [UIImage imageNamed: imageFile];
}

- (UIImage*) loadImageWithURLString : (NSString*) urlString 
{
    // キャッシュから取り出し
     UIImage* image = [cache imageWithKeyString: urlString];
    if(image) return image;
    
    // ないときは通信して取得
    NSURLRequest* request = [NSURLRequest requestWithURL: [NSURL URLWithString: urlString]];
    __block HTTPAsyncOperation* connect = [[HTTPAsyncOperation alloc] initWithRequest: request cache: cache];

    [downloadQueue addOperation: connect];
    
    connect.resultBlock = ^(UIImage *image, NSError *error) 
    {
        int dummy = 1;
    };
    
    [connect start];
    
    
    return nil;
}


@end

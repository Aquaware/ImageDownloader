//
//  ImageCache.m
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/25.
//  Copyright (c) 2012年   All rights reserved.
//

#import "ImageCache.h"
#import "ASIHTTPRequest.h"
#import <CommonCrypto/CommonHMAC.h>

@interface ImageCache() {
    NSFileManager *fileManager;
    NSString *cacheDirectory;
    
    NSCache *cache;
    
    NSOperationQueue *networkQueue;
}

@end

@implementation ImageCache

+ (ImageCache *)sharedInstance {
    static ImageCache *sharedInstance;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[ImageCache alloc] init];
    });
    
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] 
         addObserver:self 
         selector:@selector(didReceiveMemoryWarning:)
         name:UIApplicationDidReceiveMemoryWarningNotification 
         object:nil];
        
        cache = [[NSCache alloc] init];
        cache.countLimit = 20;
        
        fileManager = [[NSFileManager alloc] init];
        
        NSArray *paths = 
            NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cacheDirectory = [[[paths lastObject] 
                           stringByAppendingPathComponent:@"Images"] retain];
        
        [self createDirectories];
        
        networkQueue = [[NSOperationQueue alloc] init];
        [networkQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fileManager release];
    [cacheDirectory release];
    [cache release];
    [networkQueue release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notif {
    [self clearMemoryCache];
}

- (void)createDirectories {
    BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:cacheDirectory 
                                    isDirectory:&isDirectory];
    if (!exists || !isDirectory) {
        [fileManager createDirectoryAtPath:cacheDirectory 
               withIntermediateDirectories:YES 
                                attributes:nil 
                                     error:nil];
    }
    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++) {
            NSString *subDir = 
            [NSString stringWithFormat:@"%@/%X%X", cacheDirectory, i, j];
            BOOL isDir = NO;
            BOOL existsSubDir = 
            [fileManager fileExistsAtPath:subDir isDirectory:&isDir];
            if (!existsSubDir || !isDir) {
                [fileManager createDirectoryAtPath:subDir 
                       withIntermediateDirectories:YES 
                                        attributes:nil 
                                             error:nil];
            }
        }
    }
}

#pragma mark -

+ (NSString *)keyForURL:(NSString *)URL {
	if ([URL length] == 0) {
		return nil;
	}
	const char *cStr = [URL UTF8String];
	unsigned char result[16];
	CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]]; 	
}

- (NSString *)pathForKey:(NSString *)key {
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", cacheDirectory, [key substringToIndex:2], key];
    return path;
}

#pragma mark -

- (UIImage *)cachedImageWithURL:(NSString *)URL {
    NSString *key = [ImageCache keyForURL:URL];
    UIImage *cachedImage = [cache objectForKey:key];
    if (cachedImage) {
        return cachedImage;
    }
    
    cachedImage = [UIImage imageWithContentsOfFile:[self pathForKey:key]];
    if (cachedImage) {
        [cache setObject:cachedImage forKey:key];
    }
    
    return cachedImage;
}

#pragma mark -

- (void)storeImage:(UIImage *)image data:(NSData *)data URL:(NSString *)URL {
    NSString *key = [ImageCache keyForURL:URL];
    [cache setObject:image forKey:key];
    
    [data writeToFile:[self pathForKey:key] atomically:NO];
}

- (void)clearMemoryCache {
    [cache removeAllObjects];
}

- (void)deleteAllCacheFiles {
    [cache removeAllObjects];
    
    if ([fileManager fileExistsAtPath:cacheDirectory]) {
        if ([fileManager removeItemAtPath:cacheDirectory error:nil]) {
            [self createDirectories];
        }
    }
    
    BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
    if (!exists || !isDirectory) {
        [fileManager createDirectoryAtPath:cacheDirectory 
               withIntermediateDirectories:YES 
                                attributes:nil 
                                     error:nil];
    }
}

#pragma mark -

- (UIImage *)imageWithURL:(NSString *)URL 
                    block:(ImageResultBlock)block {    
    return [self imageWithURL:URL defaultImage:nil block:block];
}

- (UIImage *)imageWithURL:(NSString *)URL 
             defaultImage:(UIImage *)defaultImage 
                    block:(ImageResultBlock)block {    
    if (!URL) {
        return defaultImage;
    }
    
    UIImage *cachedImage = [self cachedImageWithURL:URL];
    if (cachedImage) {
        return cachedImage;
    }
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL]];
    
    [request setCompletionBlock:^{
        NSData *data = [request responseData];
        UIImage *image = [UIImage imageWithData:data];
        if (image) {
            [self storeImage:image data:data URL:URL];
            block(image, nil);
        } else {
            block(nil, [NSError errorWithDomain:@"ImageCacheErrorDomain" code:0 userInfo:nil]);
        }
    }];
    [request setFailedBlock:^{
        block(nil, request.error);
    }];
    
    [networkQueue addOperation:request];
    
    return defaultImage;
}

@end

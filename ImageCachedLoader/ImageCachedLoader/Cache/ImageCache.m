//
//  ImageCache.m
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/25.
//  Copyright (c) 2012年  All rights reserved.
//

#import "ImageCache.h"

@interface ImageCache ()
@property (nonatomic, strong)NSCache* cache;
@property (nonatomic, strong)NSString* fileCacheDir;
@property (nonatomic, strong) NSFileManager* fileManager;
@end

@implementation ImageCache
@synthesize cache, fileCacheEnable, fileManager;
@synthesize fileCacheDir;

//url encode
+ (NSString*) encodeWithString: (NSString*) string
{
    NSString* encoded = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                     NULL,
                                                                                     (__bridge CFStringRef)string,
                                                                                     NULL,
                                                                                     (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                     kCFStringEncodingUTF8);
    return encoded;
}

//url decode
+ (NSString*) decodeWithString: (NSString*) string
{
    NSString *decoded = (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                                                      NULL,
                                                                                                      (__bridge CFStringRef) string,
                                                                                                      CFSTR(""),
                                                                                                      kCFStringEncodingUTF8);
    return decoded;
}

+ (ImageCache*) shared
{
    static ImageCache *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[ImageCache alloc] init];
    });
    
    return sharedInstance;
}

- (id) init
{
    self = [super init];
    if(self) {
        cache = [[NSCache alloc] init];
        cache.countLimit = kCashCountMax;
        fileManager = [[NSFileManager alloc] init];     
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    fileCacheDir = [paths objectAtIndex: 0];
    fileCacheEnable = YES;
    
    return self;
}

- (void) storeImageWithKey : (NSString*) keyString image : (UIImage*) image
{
    NSError* error;
    
    NSString* key = [ImageCache encodeWithString: keyString];
    
    // キャッシュへの保存
    id obj = [cache objectForKey: key];
    if(obj) [cache removeObjectForKey: key];
    [cache setObject: image forKey: key];

    if(!fileCacheEnable) return;
    
    // ファイルキャッシュへの保存
    NSString* path = [NSString stringWithFormat: @"%@/%@", fileCacheDir, key];
    if([fileManager fileExistsAtPath: path]) {
        [fileManager removeItemAtPath: path error: &error];
    }
    [NSKeyedArchiver archiveRootObject: image toFile: path];
    
}

- (UIImage*) imageWithKeyString : (NSString*) keyString
{
    UIImage* image;
    
    NSString* key = [ImageCache encodeWithString: keyString];
    NSString* path = [NSString stringWithFormat: @"%@/%@", fileCacheDir, key];

    image = (UIImage*) [cache objectForKey: key];
    if(image) return image;
    
    if(!fileCacheEnable) return nil;
    
    image = (UIImage*) [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    
    return image;
}

- (void) clearCache
{
    [cache removeAllObjects];
}

@end

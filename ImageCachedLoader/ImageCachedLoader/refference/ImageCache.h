//
//  ImageCache.h
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/25.
//  Copyright (c) 2012年   All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^ImageCacheResultBlock)(UIImage *image, NSError *error);

@interface ImageCache : NSObject

+ (ImageCache *)sharedInstance;

- (UIImage *)imageWithURL:(NSString *)URL block: (ImageCacheResultBlock) block;
- (UIImage *)imageWithURL:(NSString *)URL defaultImage:(UIImage *)defaultImage block:(ImageCacheResultBlock)block;

- (void)clearMemoryCache;
- (void)deleteAllCacheFiles;

@end

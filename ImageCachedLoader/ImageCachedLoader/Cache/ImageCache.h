//
//  ImageCache.h
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/25.
//  Copyright (c) 2012年   All rights reserved.
//

#import <Foundation/Foundation.h>

#define kCashCountMax 20

@interface ImageCache : NSObject

@property (nonatomic, assign) BOOL fileCacheEnable;

+ (ImageCache*) shared;

- (void) storeImageWithKey : (NSString*) keyString image : (UIImage*) image;
- (UIImage*) imageWithKeyString : (NSString*) keyString;
- (void) clearCache;

@end

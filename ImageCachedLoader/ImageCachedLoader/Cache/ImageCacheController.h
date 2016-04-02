//
//  ImageCacheController.h
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/25.
//  Copyright (c) 2012年  All rights reserved.
//

#import <Foundation/Foundation.h>



@interface ImageCacheController : NSObject

@property (nonatomic, strong) UIImage* defaultImage;
- (UIImage*) loadImageWithURLString : (NSString*) urlString;
- (void) loadDefaultImage: (NSString*) imageFile;

@end

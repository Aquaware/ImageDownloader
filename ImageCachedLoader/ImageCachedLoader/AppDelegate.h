//
//  AppDelegate.h
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/25.
//  Copyright (c) 2012年   All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) ImageViewController* imageViewController;
@property (nonatomic, strong) UINavigationController* navigationController;
@end

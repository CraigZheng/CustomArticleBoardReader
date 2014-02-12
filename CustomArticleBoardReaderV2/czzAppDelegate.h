//
//  czzAppDelegate.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 9/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

-(void)showToast:(NSString*)string;
+ (czzAppDelegate*) sharedAppDelegate;

@end

//
//  czzAppDelegate.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 9/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADInterstitial.h"

@interface czzAppDelegate : UIResponder <UIApplicationDelegate, GADInterstitialDelegate>

@property (strong, nonatomic) UIWindow *window;

-(void)showToast:(NSString*)string;
+ (czzAppDelegate*) sharedAppDelegate;

-(void)doSingleViewShowAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration;
-(void)doSingleViewHideAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration;
@end

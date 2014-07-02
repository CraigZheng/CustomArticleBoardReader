//
//  czzAppDelegate.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 9/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADInterstitial.h"

@class czzMySelf;
@interface czzAppDelegate : UIResponder <UIApplicationDelegate, GADInterstitialDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) czzMySelf *currentLoginUser;
@property NSMutableArray *aisEmotions;
@property NSMutableArray *acEmotions;
@property NSMutableDictionary *emotionDictionary;


-(void)showToast:(NSString*)string;
+ (czzAppDelegate*) sharedAppDelegate;

-(void)doSingleViewShowAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration;
-(void)doSingleViewHideAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration;
@end

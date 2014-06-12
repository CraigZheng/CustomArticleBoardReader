//
//  czzAppDelegate.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 9/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "czzArticleListDownloader.h"

@implementation czzAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self checkStorages];
    [self checkUserDefaults];
    [self checkLoginUser];
    //ran a number
//    NSInteger upperHand = [[NSUserDefaults standardUserDefaults] integerForKey:@"oddForSplashAdScreen"];
//    if (upperHand == 0)
//        upperHand = 2;
//    NSInteger r = arc4random_uniform(upperHand);
//    //NSLog(@"%u", r);
//    if (r == 1){
//        GADInterstitial *splashInterstitial_ = [[GADInterstitial alloc] init];
//        splashInterstitial_.adUnitID = @"a153030071f04ab";
//        splashInterstitial_.delegate = self;
//        GADRequest *request = [GADRequest request];
//        request.testing = YES;
//        
//        [splashInterstitial_ loadAndDisplayRequest:request
//                                       usingWindow:self.window
//                                      initialImage:nil];
//    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark access to app delegate etc.
+ (czzAppDelegate*) sharedAppDelegate{
    return (czzAppDelegate*)[[UIApplication sharedApplication] delegate];
}

-(void)showToast:(NSString *)string{
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:string];
}

#pragma mark - check user defaults and storages
-(void)checkUserDefaults{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"shouldAutomaticallyLoadImage"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldAutomaticallyLoadImage"];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"shouldUseExperimentalBrowser"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldUseExperimentalBrowser"];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"articleOrdering"]){
        [[NSUserDefaults standardUserDefaults] setInteger:MOST_CLICKED_DAILY forKey:@"articleOrdering"];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"oddForSplashAdScreen"]){
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"oddForSplashAdScreen"];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"oddForReadingAdScreen"]){
        [[NSUserDefaults standardUserDefaults] setInteger:5 forKey:@"oddForReadingAdScreen"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)checkStorages{
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* imgFolder = [basePath
                           stringByAppendingPathComponent:@"Images"];
    NSString* favirouteFolder = [basePath stringByAppendingPathComponent:@"Faviroutes"];
    NSString* cacheFolder = [basePath stringByAppendingPathComponent:@"Cache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:imgFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:imgFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:favirouteFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:favirouteFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
}

-(void)checkLoginUser{
    //retrieve previously saved login user
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *userFile = [basePath stringByAppendingPathComponent:@"currentLoginUser.dat"];
    czzMySelf *currentLoginUser = [NSKeyedUnarchiver unarchiveObjectWithFile:userFile];
    if (currentLoginUser)
        self.currentLoginUser = currentLoginUser;
}
#pragma mark - GADInterstitialDelegate
-(void)interstitialWillPresentScreen:(GADInterstitial *)ad{
    NSInteger odd = [[NSUserDefaults standardUserDefaults] integerForKey:@"oddForSplashAdScreen"];
    if (odd == 0)
        odd = 2;
    NSString *infoString = [NSString stringWithFormat:@"起始广告掉宝几率：%d%%", (NSInteger)((1.0 / odd) * 100)];
    [self.window makeToast:infoString duration:2.0 position:@"bottom"];
}

#pragma mark - show and hide uitoolbar
-(void)doSingleViewHideAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration
{
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:animType];
    
    [animation setDuration:duration];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[incomingView layer] addAnimation:animation forKey:kCATransition];
    incomingView.hidden = YES;
}

-(void)doSingleViewShowAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration
{
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:animType];
    
    [animation setDuration:duration];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[incomingView layer] addAnimation:animation forKey:kCATransition];
    incomingView.hidden = NO;
}

@end

//
//  czzLoginViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 18/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzLoginViewController.h"
#import "czzAppDelegate.h"
#import "czzAcUser.h"
#import "czzAcUserDownloader.h"
#import "Toast+UIView.h"

#define LOGIN_HOST @"https://ssl.acfun.tv/oauth2/authorize.aspx?state=0&response_type=token&client_id=hf2QkYjrqcT3ndr9&redirect_uri=https://ssl.acfun.tv/authSuccess.aspx&scope=0"
#define REDIRECT_URL @"https://ssl.acfun.tv/authSuccess.aspx"


@interface czzLoginViewController ()<UIWebViewDelegate, czzAcUserDownloaderProtocol>

@end

@implementation czzLoginViewController
@synthesize loginWebView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [loginWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:LOGIN_HOST]]];
    
}

#pragma mark - UIWebViewDelegate
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"%@", request.URL.absoluteString);
    if ([[request.URL.absoluteString componentsSeparatedByString:@"?"][0] isEqualToString:REDIRECT_URL]){
        NSLog(@"login successful");
        NSArray *components = [request.URL.absoluteString componentsSeparatedByString:@"&"];
        for (NSString *component in components) {
            if ([component hasPrefix:@"access_token"]){
                NSLog(@"%@", component);
                NSString *access_token = [component componentsSeparatedByString:@"="][1];
                [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:@"access_token"];
            } else if ([component hasPrefix:@"expires_in"]){
                NSLog(@"%@", component);
                NSInteger expiries_in = [[component componentsSeparatedByString:@"="][1] integerValue];
                NSDate *expiry_date = [[NSDate new] dateByAddingTimeInterval:expiries_in];
                [[NSUserDefaults standardUserDefaults] setObject:expiry_date forKey:@"access_token_expiry_date"];
            } else if ([component hasPrefix:@"user_id"]){
                NSLog(@"%@", component);
                NSInteger acID = [[component componentsSeparatedByString:@"="][1] integerValue];
                [[NSUserDefaults standardUserDefaults] setInteger:acID forKey:@"my_ac_id"];
            }
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        //TODO: construct a login ac user
        [self downloadLoginUser];
        return NO;
    }
    return YES;
}

-(void)downloadLoginUser{
    NSInteger acID = [[NSUserDefaults standardUserDefaults] integerForKey:@"my_ac_id"];
    czzAcUserDownloader *acUserDownloader = [[czzAcUserDownloader alloc] initWithAcUserID:acID delegate:self];
    [acUserDownloader startDownloading];
}

#pragma mark - czzAcUserDownloaderDelegate
-(void)acUserDownloaded:(czzAcUser *)acUser withAcUserID:(NSInteger)userID success:(BOOL)success{
    NSLog(@"%@", acUser);
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"登陆成功"];
    [self.navigationController popViewControllerAnimated:YES];
}
@end

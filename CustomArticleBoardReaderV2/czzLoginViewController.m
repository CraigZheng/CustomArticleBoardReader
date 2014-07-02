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
#import "czzMySelf.h"
#import "czzAcUserDownloader.h"
#import "Toast+UIView.h"

#define LOGIN_HOST @"https://ssl.acfun.com/oauth2/authorize.aspx?state=0&response_type=token&client_id=hf2QkYjrqcT3ndr9&redirect_uri=https://ssl.acfun.tv/authSuccess.aspx&scope=0"
#define REDIRECT_URL @"https://ssl.acfun.com/authSuccess.aspx"


@interface czzLoginViewController ()<UIWebViewDelegate, czzAcUserDownloaderProtocol>
@property NSString *access_token;
@property NSDate *expiry_date;
@end

@implementation czzLoginViewController
@synthesize loginWebView;
@synthesize access_token;
@synthesize expiry_date;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [loginWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:LOGIN_HOST]]];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [loginWebView stopLoading];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

#pragma mark - UIWebViewDelegate
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    [[czzAppDelegate sharedAppDelegate].window makeToast:@"无法打开登录页面，请稍后重试" duration:2.0 position:@"center" image:[UIImage imageNamed:@"warning.png"]];
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    //ignore SSL warning for now
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"%@", request.URL.absoluteString);
    if ([[request.URL.absoluteString componentsSeparatedByString:@"?"][0] isEqualToString:REDIRECT_URL]){
        NSLog(@"login successful");
        NSArray *components = [request.URL.absoluteString componentsSeparatedByString:@"&"];
        for (NSString *component in components) {
            if ([component hasPrefix:@"access_token"]){
                NSLog(@"%@", component);
                access_token = [component componentsSeparatedByString:@"="][1];
                [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:@"access_token"];
            } else if ([component hasPrefix:@"expires_in"]){
                NSLog(@"%@", component);
                NSInteger expiries_in = [[component componentsSeparatedByString:@"="][1] integerValue] / 1000;
                expiry_date = [[NSDate new] dateByAddingTimeInterval:expiries_in];
                [[NSUserDefaults standardUserDefaults] setObject:expiry_date forKey:@"access_token_expiry_date"];
            } else if ([component hasPrefix:@"user_id"]){
                NSLog(@"%@", component);
                NSInteger acID = [[component componentsSeparatedByString:@"="][1] integerValue];
                [[NSUserDefaults standardUserDefaults] setInteger:acID forKey:@"my_ac_id"];
            }
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
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
    if (success) {
        czzMySelf *currentLoginUser = [[czzMySelf alloc] initWithAcUser:acUser access_token:access_token expiry_date:expiry_date];
        currentLoginUser.access_token = access_token;
        currentLoginUser.access_token_expiry_date = expiry_date;
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *userFile = [basePath stringByAppendingPathComponent:@"currentLoginUser.dat"];
        [NSKeyedArchiver archiveRootObject:currentLoginUser toFile:userFile];
        [[czzAppDelegate sharedAppDelegate] setCurrentLoginUser:currentLoginUser];
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"登陆成功！"];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"登陆失败，请重试"];
        [loginWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:LOGIN_HOST]]];
    }
}
@end

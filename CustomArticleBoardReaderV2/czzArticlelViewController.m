//
//  czzArticlelViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticlelViewController.h"
#import "czzArticleDownloader.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "czzImageDownloader.h"
#import "czzImageCentre.h"
#import "czzCommentViewController.h"

@interface czzArticlelViewController ()<czzArticleDownloaderDelegate, UIWebViewDelegate, UIScrollViewDelegate, czzImageDownloaderDelegate, UIDocumentInteractionControllerDelegate>
@property czzArticleDownloader *articleDownloader;
@property UIDocumentInteractionController *documentInteractionController;
@property CGPoint previousContentOffset;
@property NSMutableDictionary *imageDownloaders;
@end

@implementation czzArticlelViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize articleWebView;
@synthesize previousContentOffset;
@synthesize documentInteractionController;
@synthesize favirouteButton;
@synthesize imageDownloaders;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = [NSString stringWithFormat:@"%ld", (long)myArticle.acId];
    self.articleWebView.scrollView.delegate = self;
    imageDownloaders = [NSMutableDictionary new];
    [self startDownloadingArticle];
}

-(void)startDownloadingArticle{
    articleDownloader = [[czzArticleDownloader alloc] initWithArticleID:myArticle.acId delegate:self startImmediately:YES];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    if (articleDownloader)
        [articleDownloader stop];
    //stop all image downloader
    for (czzImageDownloader *imgDownloader in imageDownloaders.allValues) {
        if (imgDownloader)
            [imgDownloader stop];
    }
}

#pragma mark - czzArticleDownloaderDelegate
-(void)articleDownloaded:(czzArticle *)article withArticleID:(NSInteger)articleID success:(BOOL)success{
    if (article && success){
        [self setMyArticle:article];
    } else {
        NSLog(@"download failed");
    }
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

#pragma mark - UIWebView delegate
-(void)webViewDidStartLoad:(UIWebView *)webView{
    previousContentOffset = webView.scrollView.contentOffset;
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [webView.scrollView setContentSize: CGSizeMake(webView.frame.size.width, webView.scrollView.contentSize.height)];
    webView.scrollView.contentOffset = previousContentOffset;
    webView.userInteractionEnabled = YES;
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    /*
    if (navigationType == UIWebViewNavigationTypeOther){
        if ([request.URL.scheme isEqualToString:@"action"]){
            NSString *actionURLString = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:@":"].location + 1];
            czzImageDownloader *imgDownloader = [[czzImageDownloader alloc] init];
            imgDownloader.imageURLString = actionURLString;
            imgDownloader.delegate = self;
            [imgDownloader start];
            
        }

    }
     */
    if ([request.URL.scheme isEqualToString:@"action"]){
        NSString *actionURLString = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:@":"].location + 1];
        //if such imageDownloader is presented, stop the previous downloader and restart a new one
        czzImageDownloader *previousDownloader = [imageDownloaders objectForKey:actionURLString];
        if (previousDownloader)
        {
            [previousDownloader stop];
            [imageDownloaders removeObjectForKey:actionURLString];
        }
        czzImageDownloader *imgDownloader = [[czzImageDownloader alloc] init];
        imgDownloader.imageURLString = actionURLString;
        imgDownloader.delegate = self;
        [imgDownloader start];
        //set the imageDownloader as the object and actionURLString as the key
        [imageDownloaders setObject:imgDownloader forKey:actionURLString];
        
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"开始下载图片..." duration:1.0 position:@"bottom"];
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        /*
        if ([request.URL.scheme isEqualToString:@"action"]){
            NSString *actionURLString = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:@":"].location + 1];
            //if such imageDownloader is presented, stop the previous downloader and restart a new one
            czzImageDownloader *previousDownloader = [imageDownloaders objectForKey:actionURLString];
            if (previousDownloader)
            {
                [previousDownloader stop];
                [imageDownloaders removeObjectForKey:actionURLString];
            }
            czzImageDownloader *imgDownloader = [[czzImageDownloader alloc] init];
            imgDownloader.imageURLString = actionURLString;
            imgDownloader.delegate = self;
            [imgDownloader start];
            //set the imageDownloader as the object and actionURLString as the key
            [imageDownloaders setObject:imgDownloader forKey:actionURLString];
            
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"开始下载图片..." duration:1.0 position:@"bottom"];
        }
        //to open clicked image
        else */
        if ([request.URL.scheme isEqualToString:@"openfile"]){
            NSString *fileLocation = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:@":"].location + 1];
            documentInteractionController = [[UIDocumentInteractionController alloc] init];
            documentInteractionController.URL = [NSURL fileURLWithPath:fileLocation];
            documentInteractionController.delegate = self;
            [documentInteractionController presentPreviewAnimated:YES];
        }
        else
            [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

#pragma mark - czzImageDownloaderDelegate
-(void)downloadFinished:(czzImageDownloader *)imgDownloader success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString *)path error:(NSError *)error{
    if (success){
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"图片下载好了" duration:1.0 position:@"bottom"];
        [myArticle notifyImageDownloaded:imgDownloader.imageURLString saveTo:path];
        previousContentOffset = articleWebView.scrollView.contentOffset;
        [articleWebView loadHTMLString:myArticle.htmlBody baseURL:nil];

    } else {
        [self.view makeToast:error.localizedDescription duration:1.5 position:@"center" title:@"图片下载出错" image:[UIImage imageNamed:@"warning"]];
    }
}

#pragma mark - myArticle setter, also load the given html body if presented
-(void)setMyArticle:(czzArticle *)article{
    myArticle = article;
    if (myArticle.htmlBody){
        [articleWebView loadHTMLString:myArticle.htmlBody baseURL:nil];
    }
}

#pragma mark - push for segue
//assign an article ID for the comment view controller
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationViewController isKindOfClass:[czzCommentViewController class]]){
        czzCommentViewController *incomingViewController = (czzCommentViewController*)segue.destinationViewController;
        incomingViewController.articleID = self.myArticle.acId;
    }
}
#pragma mark - UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

#pragma mark - UIScrollView delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //in ios 6, the uitableview will not expand to under the uitoolbar, so hidding it won't do anything good
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        //when user do a scrolling and the tool bar is not yet hidden, hide the tool bar
        if (self.navigationController.toolbar.hidden == NO){
            [self doSingleViewHideAnimation:self.navigationController.toolbar :kCATransitionFromBottom];
        }
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        ScrollDirection scrollDirection;
        //if user drag the finger up, the scroll view direction is down, else is up
        if (self.lastContentOffsetY < scrollView.contentOffset.y){
            scrollDirection = ScrollDirectionDown;
        }
        else {
            scrollDirection = ScrollDirectionUp;
        }
        self.lastContentOffsetY = scrollView.contentOffset.y;
        //show the toolbar if user moved the finger up, and the toolbar is currently hidden
        if (scrollDirection == ScrollDirectionUp && self.navigationController.toolbar.hidden == YES){
            [self doSingleViewShowAnimation:self.navigationController.toolbar :kCATransitionFromTop];
        }
    }
}

#pragma mark - show and hide uitoolbar
-(void)doSingleViewHideAnimation:(UIView*)incomingView :(NSString*)animType
{
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:animType];
    
    [animation setDuration:0.05];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[incomingView layer] addAnimation:animation forKey:kCATransition];
    incomingView.hidden = YES;
}

-(void)doSingleViewShowAnimation:(UIView*)incomingView :(NSString*)animType
{
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:animType];
    
    [animation setDuration:0.05];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[incomingView layer] addAnimation:animation forKey:kCATransition];
    incomingView.hidden = NO;
}

- (IBAction)loadAllImages:(id)sender {
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"下载所有图片..." duration:1.0 position:@"bottom"];
    for (NSString *imgURL in myArticle.imageSrc) {
        NSURLRequest *requst = [NSURLRequest requestWithURL:[NSURL URLWithString:[@"action:" stringByAppendingString:imgURL]]];
        [articleWebView loadRequest:requst];
    }
}

- (IBAction)favirouteAction:(id)sender {
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* favirouteFolder = [basePath stringByAppendingPathComponent:@"Faviroutes"];
    [NSKeyedArchiver archiveRootObject:self.myArticle toFile:[favirouteFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)myArticle.acId]]];

}
@end

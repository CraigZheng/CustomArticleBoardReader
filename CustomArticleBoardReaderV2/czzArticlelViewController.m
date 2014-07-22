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
#import "czzCommentViewController.h"
#import "czzArticleListViewController.h"
#import "czzArticleDescriptionViewController.h"
#import "GADInterstitial.h"

#define MAX_CONCURRENT_DOWNLOADER 5

@interface czzArticlelViewController ()<czzArticleDownloaderDelegate, UIWebViewDelegate, UIScrollViewDelegate, czzImageDownloaderDelegate, UIDocumentInteractionControllerDelegate, UINavigationControllerDelegate, GADInterstitialDelegate>
@property czzArticleDownloader *articleDownloader;
@property UIDocumentInteractionController *documentInteractionController;
@property CGPoint previousContentOffset;
@property czzArticleDescriptionViewController *descViewController;
@property BOOL shouldAutomaticallyLoadImage;
@property NSMutableOrderedSet *downloaderQueue;
@property NSMutableOrderedSet *downloaderExecuting;
@property GADInterstitial *interstitial_;
@end

@implementation czzArticlelViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize articleWebView;
@synthesize previousContentOffset;
@synthesize documentInteractionController;
@synthesize descViewController;
@synthesize shouldAutomaticallyLoadImage;
@synthesize downloaderExecuting;
@synthesize downloaderQueue;
@synthesize interstitial_;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = [NSString stringWithFormat:@"%ld", (long)myArticle.acId];
    self.articleWebView.scrollView.delegate = self;
    self.navigationController.delegate = self;
    downloaderQueue = [NSMutableOrderedSet new];
    downloaderExecuting = [NSMutableOrderedSet new];
    shouldAutomaticallyLoadImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
    if (myArticle.htmlBody == nil)
        [self startDownloadingArticle];
    else
        [self.articleWebView loadHTMLString:myArticle.htmlBody baseURL:nil];
    //hide tool bar if ios 7
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        self.navigationController.toolbar.hidden = YES;
    }

    [self addBannerDescViewToTop];
    [self showAdRandomly];
}

-(void)startDownloadingArticle{
    articleDownloader = [[czzArticleDownloader alloc] initWithArticleID:myArticle.acId delegate:self startImmediately:YES];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.navigationController.delegate = nil;
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

-(void)addBannerDescViewToTop{
    //add desc view controller view into this view
    descViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"czz_description_view_controller"];

    descViewController.myArticle = myArticle;
    descViewController.parentViewController = self;
    //move every subview in the scrollview down a little
    for (UIView* view in self.articleWebView.scrollView.subviews) {
        CGRect frame = view.frame;
        frame.origin.y += descViewController.view.frame.size.height;
        view.frame = frame;
    }
    [self.articleWebView.scrollView addSubview:descViewController.view];
}

-(void)showAdRandomly{
    NSInteger upperHand = [[NSUserDefaults standardUserDefaults] integerForKey:@"oddForReadingAdScreen"];
    if (upperHand == 0)
        upperHand = 5;
    NSInteger r = arc4random_uniform(upperHand);
    if (r == 1){
        interstitial_ = [[GADInterstitial alloc] init];
        interstitial_.adUnitID = @"a153030071f04ab";
        interstitial_.delegate = self;
        GADRequest *request = [GADRequest request];
        request.testing = YES;
        
        [interstitial_ loadRequest:request];
    }
}

#pragma mark - GADInterstitialDelegate
-(void)interstitialWillPresentScreen:(GADInterstitial *)ad{
    NSInteger odd = [[NSUserDefaults standardUserDefaults] integerForKey:@"oddForReadingAdScreen"];
    if (odd == 0)
        odd = 5;
    NSString *infoString = [NSString stringWithFormat:@"阅读广告掉宝几率：%d%%", (NSInteger)((1.0 / odd) * 100)];
    [[czzAppDelegate sharedAppDelegate].window makeToast:infoString duration:2.0 position:@"bottom"];
}

-(void)interstitialDidReceiveAd:(GADInterstitial *)ad{
    [interstitial_ presentFromRootViewController:self];
}
#pragma mark - UINavigationControllerDelegate
-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    //this view has being poped from navigation controller, stop all downloaders
    if ([viewController isKindOfClass:[czzArticleListViewController class]]){
        if (articleDownloader) {
            [articleDownloader stop];
        }
        //stop all image downloader
        for (czzImageDownloader *imgDownloader in downloaderExecuting.objectEnumerator) {
            [imgDownloader stop];
        }
    }
}

#pragma mark - czzArticleDownloaderDelegate
-(void)articleDownloaded:(czzArticle *)article withArticleID:(NSInteger)articleID success:(BOOL)success{
    if (article && success){
        [self setMyArticle:article];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"文章无法打开" duration:2 position:@"center" image:[UIImage imageNamed:@"warning"]];
        NSLog(@"download failed");
    }
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

#pragma mark - UIWebView delegate
-(void)webViewDidStartLoad:(UIWebView *)webView{
    webView.userInteractionEnabled = NO;
    if (webView.scrollView.contentOffset.y >= 10)
        previousContentOffset = webView.scrollView.contentOffset;
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [webView.scrollView setContentSize: CGSizeMake(webView.frame.size.width, webView.scrollView.contentSize.height)];
    if (previousContentOffset.y >= 10)
        webView.scrollView.contentOffset = previousContentOffset;
    webView.userInteractionEnabled = YES;
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    webView.userInteractionEnabled = YES;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if ([request.URL.scheme isEqualToString:@"action"]){
        NSString *actionURLString = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:@":"].location + 1];
        czzImageDownloader *imgDownloader = [[czzImageDownloader alloc] init];
        imgDownloader.imageURLString = actionURLString;
        imgDownloader.delegate = self;
        if (downloaderExecuting.count < MAX_CONCURRENT_DOWNLOADER && ![downloaderExecuting containsObject:imgDownloader]) {
            [downloaderExecuting addObject:imgDownloader];
            [imgDownloader startDownloading];
        } else {
            [downloaderQueue addObject:imgDownloader];
        }
        //NSLog(@"executing: %d, in queue: %d", downloaderExecuting.count, downloaderQueue.count);
        if (navigationType != UIWebViewNavigationTypeOther)
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"开始下载图片..." duration:1.0 position:@"bottom"];
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        //to open clicked image
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
        CGFloat duration = 1.0;
        if (shouldAutomaticallyLoadImage)
            duration = 0.5;
        if (!error)
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"图片下载好了" duration:duration position:@"bottom"];
        [myArticle notifyImageDownloaded:imgDownloader.imageURLString saveTo:path];
        if ([articleWebView isLoading])
            [articleWebView stopLoading];
        [articleWebView loadHTMLString:myArticle.htmlBody baseURL:nil];

    } else {
        [self.view makeToast:error.localizedDescription duration:1.5 position:@"center" title:@"图片下载出错：请检查网络和储存空间" image:[UIImage imageNamed:@"warning"]];
    }
    //remove this downloading from executing stack, and insert a waiting downloading from the queue
    [downloaderExecuting removeObject:imgDownloader];
    [downloaderQueue removeObject:imgDownloader];
    NSEnumerator *objEnumerator = downloaderQueue.objectEnumerator;
    czzImageDownloader *newDownloader;
    while (downloaderExecuting.count < MAX_CONCURRENT_DOWNLOADER && (newDownloader = [objEnumerator nextObject])) {
        [downloaderExecuting addObject:newDownloader];
        [newDownloader startDownloading];
    }
    //remove any duplicate in the queue
    for (czzImageDownloader* downer in downloaderExecuting.objectEnumerator) {
        [downloaderQueue removeObject:downer];
    }
    
    //NSLog(@"executing: %d, in queue: %d", downloaderExecuting.count, downloaderQueue.count);
}

#pragma mark - myArticle setter, also load the given html body if presented
-(void)setMyArticle:(czzArticle *)article{
    myArticle = article;
    myArticle.parentViewController = self;
    if (myArticle.htmlBody){
        [articleWebView loadHTMLString:myArticle.htmlBody baseURL:nil];
    }
    if (shouldAutomaticallyLoadImage)
        [self loadAllImages:nil];
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

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    ScrollDirection scrollDirection;
    //if user drag the finger up, the scroll view direction is down, else is up
    if (self.lastContentOffsetY < scrollView.contentOffset.y){
        scrollDirection = ScrollDirectionDown;
    }
    else {
        scrollDirection = ScrollDirectionUp;
    }
    self.lastContentOffsetY = scrollView.contentOffset.y;
    //if running on ios 7+ device and have not scroll to the top
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0 && scrollView.contentOffset.y > 0) {
        //show the toolbar if user moved the finger up, and the toolbar is currently hidden
        if (scrollDirection == ScrollDirectionUp && self.navigationController.toolbar.hidden == YES){
            [self showNavigationBarAndToolBar];
        } else if (scrollDirection == ScrollDirectionDown && self.navigationController.toolbar.hidden == NO) {
            [self hideNavigationBarAndToolBar];
        }
    }
}

#pragma mark - show and hide tool bar

-(void)hideNavigationBarAndToolBar{
    [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:self.navigationController.toolbar :kCATransitionFromBottom :0.2];
    //[[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:self.navigationController.navigationBar :kCATransitionFromTop :0.2];

}

-(void)showNavigationBarAndToolBar{
    [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.navigationController.toolbar :kCATransitionFromTop :0.2];
    //[[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.navigationController.navigationBar :kCATransitionFromBottom :0.2];
}

#pragma mark - show and hide description view

-(void)showDescView{
    [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:descViewController.view :kCATransitionFromBottom :0.2];
    self.articleWebView.scrollView.contentInset = UIEdgeInsetsMake(descViewController.view.frame.size.height + descViewController.view.frame.origin.y, 0, 0, 0);
    self.articleWebView.scrollView.contentOffset = CGPointMake(0, descViewController.view.frame.size.height + descViewController.view.frame.origin.y);
}

-(void)hideDescView{
    [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:descViewController.view :kCATransitionFromTop :0.2];
    self.articleWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - tool bar menu actions
- (IBAction)loadAllImages:(id)sender {
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"自动下载所有图片..." duration:1.0 position:@"bottom"];
    for (NSString *imgURL in myArticle.imageSrc) {
        NSURLRequest *requst = [NSURLRequest requestWithURL:[NSURL URLWithString:[@"action:" stringByAppendingString:imgURL]]];
        [articleWebView loadRequest:requst];
    }
}

- (IBAction)shareAction:(id)sender {
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"this is a fucking unfinished feature, be patient fuckhead!"];
}

- (IBAction)favirouteAction:(id)sender {
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* favirouteFolder = [basePath stringByAppendingPathComponent:@"Faviroutes"];
    [NSKeyedArchiver archiveRootObject:self.myArticle toFile:[favirouteFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)myArticle.acId]]];
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"已收藏"];
}

@end

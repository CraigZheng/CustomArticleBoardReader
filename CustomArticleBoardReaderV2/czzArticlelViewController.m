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
#import "czzArticleListViewController.h"
#import "czzArticleDescriptionViewController.h"

@interface czzArticlelViewController ()<czzArticleDownloaderDelegate, UIWebViewDelegate, UIScrollViewDelegate, czzImageDownloaderDelegate, UIDocumentInteractionControllerDelegate, UINavigationControllerDelegate>
@property czzArticleDownloader *articleDownloader;
@property UIDocumentInteractionController *documentInteractionController;
@property CGPoint previousContentOffset;
@property NSMutableDictionary *imageDownloaders;
@property czzArticleDescriptionViewController *descViewController;
@property BOOL shouldAutomaticallyLoadImage;
@end

@implementation czzArticlelViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize articleWebView;
@synthesize previousContentOffset;
@synthesize documentInteractionController;
@synthesize favirouteButton;
@synthesize imageDownloaders;
@synthesize descViewController;
@synthesize shouldAutomaticallyLoadImage;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = [NSString stringWithFormat:@"%ld", (long)myArticle.acId];
    self.articleWebView.scrollView.delegate = self;
    self.navigationController.delegate = self;
    imageDownloaders = [NSMutableDictionary new];
    shouldAutomaticallyLoadImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
    if (myArticle.htmlBody == nil)
        [self startDownloadingArticle];
    else
        [self.articleWebView loadHTMLString:myArticle.htmlBody baseURL:nil];
    [self addBannerDescViewToTop];
}

-(void)startDownloadingArticle{
    articleDownloader = [[czzArticleDownloader alloc] initWithArticleID:myArticle.acId delegate:self startImmediately:YES];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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

#pragma mark - UINavigationControllerDelegate
-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    //this view has being poped from navigation controller, stop all downloaders
    if ([viewController isKindOfClass:[czzArticleListViewController class]]){
        if (articleDownloader) {
            [articleDownloader.articleProcessor cancel];
            [articleDownloader stop];
        }
        //stop all image downloader
        for (czzImageDownloader *imgDownloader in imageDownloaders.allValues) {
            if (imgDownloader)
                [imgDownloader stop];
        }
    }
}
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{

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
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"图片下载好了" duration:duration position:@"bottom"];
        [myArticle notifyImageDownloaded:imgDownloader.imageURLString saveTo:path];
        previousContentOffset = articleWebView.scrollView.contentOffset;
        if ([articleWebView isLoading])
            [articleWebView stopLoading];
        [articleWebView loadHTMLString:myArticle.htmlBody baseURL:nil];

    } else {
        [self.view makeToast:error.localizedDescription duration:1.5 position:@"center" title:@"图片下载出错：请检查网络和储存空间" image:[UIImage imageNamed:@"warning"]];
    }
}

#pragma mark - myArticle setter, also load the given html body if presented
-(void)setMyArticle:(czzArticle *)article{
    myArticle = article;
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

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //in ios 6, the uitableview will not expand to under the uitoolbar, so hidding it won't do anything good
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        //when user do a scrolling and the tool bar is not yet hidden, hide the tool bar
        if (self.navigationController.toolbar.hidden == NO){
            [self doSingleViewHideAnimation:self.navigationController.toolbar :kCATransitionFromBottom :0.1];
        }
    }
}

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
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        //show the toolbar if user moved the finger up, and the toolbar is currently hidden
        if (scrollDirection == ScrollDirectionUp && self.navigationController.toolbar.hidden == YES){
            [self doSingleViewShowAnimation:self.navigationController.toolbar :kCATransitionFromTop :0.1];
        }
    }
}

-(void)showDescView{
    [self doSingleViewShowAnimation:descViewController.view :kCATransitionFromBottom :0.2];
    self.articleWebView.scrollView.contentInset = UIEdgeInsetsMake(descViewController.view.frame.size.height + descViewController.view.frame.origin.y, 0, 0, 0);
    self.articleWebView.scrollView.contentOffset = CGPointMake(0, descViewController.view.frame.size.height + descViewController.view.frame.origin.y);
}

-(void)hideDescView{
    [self doSingleViewHideAnimation:descViewController.view :kCATransitionFromTop :0.2];
    self.articleWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
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

- (IBAction)loadAllImages:(id)sender {
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"自动下载所有图片..." duration:1.0 position:@"bottom"];
    for (NSString *imgURL in myArticle.imageSrc) {
        NSURLRequest *requst = [NSURLRequest requestWithURL:[NSURL URLWithString:[@"action:" stringByAppendingString:imgURL]]];
        [articleWebView loadRequest:requst];
    }
}

- (IBAction)favirouteAction:(id)sender {
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* favirouteFolder = [basePath stringByAppendingPathComponent:@"Faviroutes"];
    [NSKeyedArchiver archiveRootObject:self.myArticle toFile:[favirouteFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)myArticle.acId]]];
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"已收藏"];
}

@end

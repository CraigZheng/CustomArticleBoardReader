//
//  czzArticleTableViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 21/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticleTableViewController.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "czzArticleDescriptionViewController.h"
#import "czzAcUser.h"
#import "czzArticleDownloader.h"
#import "czzImageDownloader.h"
#import "czzCommentViewController.h"
#import "czzArticleListViewController.h"
#import "czzImageCentre.h"


@interface czzArticleTableViewController ()<UINavigationControllerDelegate, czzArticleDownloaderDelegate, czzImageDownloaderDelegate, UIDocumentInteractionControllerDelegate, UINavigationBarDelegate>
@property czzArticleDownloader *articleDownloader;
@property BOOL shouldAutomaticallyLoadImage;
@property czzArticleDescriptionViewController *descViewController;
@property czzImageCentre *imageCentre;
@property NSInteger lastContentOffsetY;
@end

@implementation czzArticleTableViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize shouldAutomaticallyLoadImage;
@synthesize descViewController;
@synthesize imageCentre;
@synthesize lastContentOffsetY;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.delegate = self;
    shouldAutomaticallyLoadImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
    if (myArticle){
        if (myArticle.htmlFragments.count == 0) {
            self.title = [NSString stringWithFormat:@"AcID:%d", myArticle.acId];
            [self startDownloadingArticle];
        }
    }
    else {
        NSLog(@"article nil");
    }
    imageCentre = [czzImageCentre sharedInstance];
    descViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"czz_description_view_controller"];
    
    descViewController.myArticle = myArticle;
    descViewController.parentViewController = self;
    //hide tool bar if ios 7
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        self.navigationController.toolbar.hidden = YES;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if ([viewController isKindOfClass:[czzArticleListViewController class]]){
        if (articleDownloader)
            [articleDownloader stop];
        [imageCentre stopAllDownloader];
    }
}

-(void)startDownloadingArticle{
    articleDownloader = [[czzArticleDownloader alloc] initWithArticleID:myArticle.acId delegate:self startImmediately:YES];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return myArticle.htmlFragments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row];
    if ([htmlFragment isKindOfClass:[NSURL class]]){
        NSString *imgURLString = [(NSURL*)htmlFragment absoluteString];
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        basePath = [basePath
                    stringByAppendingPathComponent:@"Images"];
        NSString *filePath = [basePath stringByAppendingPathComponent:[(NSURL*)htmlFragment absoluteString].lastPathComponent];
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        if (image){
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"image_ciew_cell_identifier" forIndexPath:indexPath];
            UIImageView *imageView = (UIImageView*)[cell viewWithTag:1];
            [imageView setImage:image];
            return cell;
        } else {
            if ([imageCentre containsImageDownloaderWithURL:imgURLString])
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloading_image_cell_identifier" forIndexPath:indexPath];
                UIActivityIndicatorView *aiView = (UIActivityIndicatorView*)[cell viewWithTag:1];
                [aiView startAnimating];
                return cell;
            }
        }
        if (shouldAutomaticallyLoadImage){
            //create a new downloader task in the background
            dispatch_async(dispatch_get_main_queue(), ^{
                [self downloadImage:imgURLString andReloadIndexPath:indexPath];
            });
        }
        return [tableView dequeueReusableCellWithIdentifier:@"clickable_url_cell_identifier" forIndexPath:indexPath];
    }
    //HTML cell
    NSString *CellIdentifier = @"html_fragment_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell){
        UITextView *fragmentTextView = (UITextView*)[cell viewWithTag:1];
        fragmentTextView.text = [htmlFragment description];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat preferHeight = 0;
    UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    newHiddenTextView.hidden = YES;
    newHiddenTextView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:newHiddenTextView];
    id htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row];
    if ([htmlFragment isKindOfClass:[NSURL class]]){
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        basePath = [basePath
                    stringByAppendingPathComponent:@"Images"];
        NSString *filePath = [basePath stringByAppendingPathComponent:[(NSURL*)htmlFragment absoluteString].lastPathComponent];
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        if (image) {
            if (image.size.width > self.tableView.frame.size.width){
                return image.size.height * (self.view.frame.size.width / image.size.width);
            } else {
                return image.size.height;
            }
        }
        return tableView.rowHeight;
    }
    newHiddenTextView.text = [htmlFragment description];
    preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height;
    [newHiddenTextView removeFromSuperview];
    return MAX(tableView.rowHeight, preferHeight);
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    id htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row];
    if ([htmlFragment isKindOfClass:[NSURL class]]){
        NSLog(@"clicked URL: %@", htmlFragment);
        NSString *imageURL = [(NSURL*)htmlFragment absoluteString];
        NSString *localImagePath;
        if ((localImagePath = [imageCentre containsImageInLocal:imageURL])) {
            UIDocumentInteractionController *documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:localImagePath]];
            documentInteractionController.delegate = self;
            [documentInteractionController presentPreviewAnimated:YES];
        } else {
            [self downloadImage:imageURL andReloadIndexPath:indexPath];
        }
    }
}

#pragma mark - download image
-(void)downloadImage:(NSString*)imageURLString andReloadIndexPath:(NSIndexPath*)indexPath{
    [imageCentre downloadImageWithURL:imageURLString];
    if (indexPath)
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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

#pragma mark - push for segue
//assign an article ID for the comment view controller
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationViewController isKindOfClass:[czzCommentViewController class]]){
        czzCommentViewController *incomingViewController = (czzCommentViewController*)segue.destinationViewController;
        incomingViewController.articleID = self.myArticle.acId;
    }
}

#pragma mark - ImageDownloader notification handler
-(void)imageDownloaded:(NSNotification*)notification {
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        id fragment = [myArticle.htmlFragments objectAtIndex:indexPath.row];
        if (indexPath && [fragment isKindOfClass:[NSURL class]]){
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

#pragma mark - czzImageDownloaderDelegate
-(void)downloadFinished:(czzImageDownloader *)imgDownloader success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString *)path error:(NSError *)error{
    if (success){
        NSLog(@"download of image success");
        [self.tableView reloadData];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"图片下载失败!"];
    }
}

#pragma mark - czzArticleDownloaderDelegate
-(void)articleDownloaded:(czzArticle *)article withArticleID:(NSInteger)articleID success:(BOOL)success{
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    if (success) {
        [self setMyArticle:article];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"出错啦" message:@"无法下载文章，请重试！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
    }
}

#pragma mark - myArticle setter, also load the given html body if presented
-(void)setMyArticle:(czzArticle *)article{
    myArticle = article;
    myArticle.parentViewController = self;
    if (myArticle.htmlFragments.count > 0){
        [self performSelectorOnMainThread:@selector(refreshTableView) withObject:nil waitUntilDone:YES];
    }
}

-(void)refreshTableView{
    [self.tableView reloadData];
}

- (IBAction)favouriteAction:(id)sender {
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* favirouteFolder = [basePath stringByAppendingPathComponent:@"Faviroutes"];
    [NSKeyedArchiver archiveRootObject:self.myArticle toFile:[favirouteFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)myArticle.acId]]];
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"已收藏"];
}


#pragma mark UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}
@end

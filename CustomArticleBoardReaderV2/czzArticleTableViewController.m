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
#import "czzCommentViewController.h"
#import "czzArticleListViewController.h"
#import "czzImageCentre.h"
#import "czzImageDownloader.h"


@interface czzArticleTableViewController ()<UINavigationControllerDelegate, czzArticleDownloaderDelegate, UIDocumentInteractionControllerDelegate, UINavigationBarDelegate>
@property czzArticleDownloader *articleDownloader;
@property BOOL shouldAutomaticallyLoadImage;
@property czzArticleDescriptionViewController *descViewController;
@property NSMutableSet *failedImageDownload;
@property czzImageCentre *imageCentre;
@property NSIndexPath *firstVisibleCellIndex;
@property NSInteger lastContentOffsetY;
@property NSString *libraryFolder;
@property NSDate *lastUpdateTime;
@end

@implementation czzArticleTableViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize shouldAutomaticallyLoadImage;
@synthesize descViewController;
@synthesize imageCentre;
@synthesize lastContentOffsetY;
@synthesize libraryFolder;
@synthesize failedImageDownload;
@synthesize firstVisibleCellIndex;
@synthesize lastUpdateTime;

- (void)viewDidLoad
{
    [super viewDidLoad];
    libraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    shouldAutomaticallyLoadImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
    
    failedImageDownload = [NSMutableSet new];
    
    if (myArticle){

        czzArticle* cachedArticle = [self readArticleFromCache:myArticle];
        if (cachedArticle) {
            [self setMyArticle:cachedArticle];
        }
        if (myArticle.htmlFragments.count == 0) {
            self.title = [NSString stringWithFormat:@"AcID:%d", myArticle.acId];
            [self startDownloadingArticle];
        }
    }
    else {
        NSLog(@"article nil");
    }
    imageCentre = [czzImageCentre sharedInstance];
    //hide tool bar if ios 7
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        self.navigationController.toolbar.hidden = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshTableView];
    });
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

#pragma mark - Caching
-(void)saveArticleToCache:(czzArticle*)article{
    if (article.htmlFragments.count > 0) {
        NSString *cacheFolder = [libraryFolder stringByAppendingPathComponent:@"Cache"];
        [NSKeyedArchiver archiveRootObject:article toFile:[cacheFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)article.acId]]];
    }
}

-(czzArticle*)readArticleFromCache:(czzArticle*)article{
    @try {
        NSString *cacheFolder = [libraryFolder stringByAppendingPathComponent:@"Cache"];
        czzArticle *cachedArticle = [NSKeyedUnarchiver unarchiveObjectWithFile:[cacheFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)article.acId]]];
        return cachedArticle;
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    return nil;
}

#pragma mark - UINavigationController delegate
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if ([viewController isKindOfClass:[czzArticleListViewController class]]){
        if (articleDownloader)
            [articleDownloader stop];
        [imageCentre stopAllDownloader];
    }
    navigationController.delegate = nil;
}

-(void)startDownloadingArticle{
    articleDownloader = [[czzArticleDownloader alloc] initWithArticleID:myArticle.acId delegate:self startImmediately:YES];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return myArticle.htmlFragments.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //first row - description row
    if (indexPath.row == 0) {
        NSString *CellIdentifier = @"description_cell_identifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (descViewController.view.superview)
            [descViewController.view removeFromSuperview];
        [cell.contentView addSubview:descViewController.view];
        return cell;
    }
    //content rows
    id htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row - 1];
    if ([htmlFragment isKindOfClass:[NSURL class]]){
        NSString *imgURLString = [(NSURL*)htmlFragment absoluteString];
        //if already previously failed to download
        if ([failedImageDownload containsObject:imgURLString]){
            return [tableView dequeueReusableCellWithIdentifier:@"image_download_failed_identifier" forIndexPath:indexPath];
        }
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        basePath = [basePath
                    stringByAppendingPathComponent:@"Images"];
        NSString *filePath = [basePath stringByAppendingPathComponent:[(NSURL*)htmlFragment absoluteString].lastPathComponent];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:filePath];
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
            [self downloadImage:imgURLString andReloadIndexPath:indexPath];
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
    CGFloat preferHeight = tableView.rowHeight;
    CGFloat width = self.view.frame.size.width;
    
    id htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row - 1];
    if ([htmlFragment isKindOfClass:[NSURL class]]){
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        basePath = [basePath
                    stringByAppendingPathComponent:@"Images"];
        NSString *filePath = [basePath stringByAppendingPathComponent:[(NSURL*)htmlFragment absoluteString].lastPathComponent];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:filePath];
        if (image) {
            if (image.size.width > width){
                preferHeight = image.size.height * (width / image.size.width);
            } else {
                preferHeight = image.size.height;
            }
        } else {
            preferHeight = tableView.rowHeight;
        }
    } else {
        @autoreleasepool {
            UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, width, 1)];
            
            [self.view addSubview:newHiddenTextView];
            
            newHiddenTextView.hidden = YES;
            newHiddenTextView.font = [UIFont systemFontOfSize:16];
            
            newHiddenTextView.text = [htmlFragment description];
            preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height;
            preferHeight = MAX(tableView.rowHeight, preferHeight);
            
            [newHiddenTextView removeFromSuperview];
            newHiddenTextView = nil;
        }
    }

    return preferHeight;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //the first row is description row
    if (indexPath.row == 0)
        return;
    id htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row - 1];
    if ([htmlFragment isKindOfClass:[NSURL class]]){
//        NSLog(@"clicked URL: %@", htmlFragment);
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
    [failedImageDownload removeObject:imageURLString];
    
    [UIView setAnimationsEnabled:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshTableView];
    });
    [UIView setAnimationsEnabled:YES];
//    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
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
    @try {
        Boolean success = [[notification.userInfo objectForKey:@"Success"] boolValue];
        if (!success) {
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"图片下载失败!"];
            [failedImageDownload addObject: [((czzImageDownloader*)[notification.userInfo objectForKey:@"ImageDownloader"]) imageURLString]];
        }
        firstVisibleCellIndex = self.tableView.indexPathsForVisibleRows.firstObject;
//        NSMutableArray *indexArray = [NSMutableArray new];
//        for (UITableViewCell *cell in [self.tableView visibleCells]) {
//            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//            [indexArray addObject:indexPath];
//        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshTableView];
            [self.tableView scrollToRowAtIndexPath:firstVisibleCellIndex atScrollPosition:UITableViewScrollPositionNone animated:NO];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }

}

#pragma mark - czzArticleDownloaderDelegate
-(void)articleDownloaded:(czzArticle *)article withArticleID:(NSInteger)articleID success:(BOOL)success{
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    lastUpdateTime = nil;
    if (success) {
        [self setMyArticle:article];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"出错啦" message:@"无法下载文章，请重试！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
    }
}


-(void)articleProcessUpdated:(czzArticle *)article finished:(BOOL)finished {
    if (!lastUpdateTime || [[NSDate new] timeIntervalSinceDate:lastUpdateTime] > 5 || finished) {
        lastUpdateTime = [NSDate new];
        NSLog(@"update article");
    } else
        return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshTableView];
    });
    if (finished)
    {
        [self performSelectorInBackground:@selector(saveArticleToCache:) withObject:self.myArticle];
    }
}

#pragma mark - myArticle setter, also load the given html body if presented
-(void)setMyArticle:(czzArticle *)article{
    myArticle = article;
    myArticle.parentViewController = self;
    
    descViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"czz_description_view_controller"];
    descViewController.myArticle = myArticle;
    descViewController.parentViewController = self;
    
    if (myArticle.htmlFragments.count > 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshTableView];
        });
    }
}

-(void)refreshTableView{
    [self.tableView reloadData];
    [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
}

- (IBAction)favouriteAction:(id)sender {
    NSString* favirouteFolder = [libraryFolder stringByAppendingPathComponent:@"Faviroutes"];
    [NSKeyedArchiver archiveRootObject:self.myArticle toFile:[favirouteFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)myArticle.acId]]];
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"已收藏"];
}

- (IBAction)shareAction:(id)sender {
    NSLog(@"shareButton pressed");
    
    NSString *texttoshare = [myArticle.desc stringByAppendingFormat:@"... http://www.acfun.tv/a/ac%ld", (long)myArticle.acId]; //this is your text string to share
//    UIImage *imagetoshare = _img; //this is your image to share
    NSArray *activityItems = @[texttoshare];//, imagetoshare];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    [self presentViewController:activityVC animated:TRUE completion:nil];

}

#pragma mark - rotation
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [descViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    firstVisibleCellIndex = self.tableView.indexPathsForVisibleRows.firstObject;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [descViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.tableView scrollToRowAtIndexPath:firstVisibleCellIndex atScrollPosition:UITableViewScrollPositionNone animated:YES];
}


#pragma mark UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}
@end

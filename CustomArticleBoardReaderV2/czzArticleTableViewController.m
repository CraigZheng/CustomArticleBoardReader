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


@interface czzArticleTableViewController ()<UINavigationControllerDelegate, czzArticleDownloaderDelegate, czzImageDownloaderDelegate>
@property czzArticleDownloader *articleDownloader;
@property BOOL shouldAutomaticallyLoadImage;
@property czzArticleDescriptionViewController *descViewController;
@end

@implementation czzArticleTableViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize shouldAutomaticallyLoadImage;
@synthesize descViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.delegate = self;
    shouldAutomaticallyLoadImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
    if (myArticle){
        if (myArticle.htmlBody == nil)
            [self startDownloadingArticle];
        else {
            NSLog(@"article nil");
        }
    }
    descViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"czz_description_view_controller"];
    
    descViewController.myArticle = myArticle;
    descViewController.parentViewController = self;

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"这个浏览器正在紧张有序地开发中！" duration:1.0 position:@"bottom"];
}

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if ([viewController isKindOfClass:[czzArticleListViewController class]]){
        if (articleDownloader)
            [articleDownloader stop];
    }
}

-(void)startDownloadingArticle{
    articleDownloader = [[czzArticleDownloader alloc] initWithArticleID:myArticle.acId delegate:self startImmediately:YES];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    /*
    NSLog(@"%d rows", myArticle.htmlFragments.count);
    if (myArticle.htmlFragments.count > 0)
        return myArticle.htmlFragments.count + 1;
     */
    return myArticle.htmlFragments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row];
    if ([htmlFragment isKindOfClass:[NSURL class]]){
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        basePath = [basePath
                    stringByAppendingPathComponent:@"Images"];
        NSString *filePath = [basePath stringByAppendingPathComponent:[(NSURL*)htmlFragment absoluteString].lastPathComponent];
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        if (image){
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"image_ciew_cell_identifier" forIndexPath:indexPath];
            UIImageView *imageView = (UIImageView*)[cell viewWithTag:1];
            [imageView setImage:image];
        } else
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
            if (image.size.width > self.view.frame.size.width){
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
        czzImageDownloader *imgDownloader = [[czzImageDownloader alloc] init];
        imgDownloader.imageURLString = [(NSURL*)htmlFragment absoluteString];
        imgDownloader.delegate = self;
        [imgDownloader startDownloading];
    }
}

#pragma mark - czzImageDownloaderDelegate
-(void)downloadFinished:(czzImageDownloader *)imgDownloader success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString *)path error:(NSError *)error{
    if (success){
        NSLog(@"download of image success");
        [self.tableView reloadData];
    }
}

#pragma mark - czzArticleDownloaderDelegate
-(void)articleDownloaded:(czzArticle *)article withArticleID:(NSInteger)articleID success:(BOOL)success{
    [self setMyArticle:article];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

#pragma mark - myArticle setter, also load the given html body if presented
-(void)setMyArticle:(czzArticle *)article{
    myArticle = article;
    myArticle.parentViewController = self;
    if (myArticle.htmlFragments.count > 0){
        [self performSelectorOnMainThread:@selector(refreshTableView) withObject:nil waitUntilDone:YES];
    }
    if (shouldAutomaticallyLoadImage){
        
    }
}

-(void)refreshTableView{
    [self.tableView reloadData];
}
@end

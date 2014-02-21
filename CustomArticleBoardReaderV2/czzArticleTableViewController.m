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


@interface czzArticleTableViewController ()<UINavigationControllerDelegate, czzArticleDownloaderDelegate>
@property czzArticleDownloader *articleDownloader;
@property BOOL shouldAutomaticallyLoadImage;
@end

@implementation czzArticleTableViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize shouldAutomaticallyLoadImage;

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
    NSLog(@"%d rows", myArticle.htmlFragments.count);
    return myArticle.htmlFragments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"html_fragment_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell){
        NSString *htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row];
        UITextView *fragmentTextView = (UITextView*)[cell viewWithTag:1];
        fragmentTextView.text = htmlFragment;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat preferHeight = 0;
    UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    newHiddenTextView.hidden = YES;
    newHiddenTextView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:newHiddenTextView];
    NSString *htmlFragment = [myArticle.htmlFragments objectAtIndex:indexPath.row];
    newHiddenTextView.text = htmlFragment;
    preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height;
    [newHiddenTextView removeFromSuperview];
    return MAX(tableView.rowHeight, preferHeight);

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

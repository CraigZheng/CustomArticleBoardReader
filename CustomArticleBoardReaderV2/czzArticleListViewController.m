//
//  czzArticleListViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticleListViewController.h"
#import "czzArticleListDownloader.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"
#import "czzArticlelViewController.h"
#import "czzArticleTableViewController.h"
#import "czzArticle.h"

@interface czzArticleListViewController ()<czzArticleListDownloaderDelegate>
@property NSDictionary *articleCategoris;
@property NSMutableArray *articleList;
@property NSIndexPath *selectedIndexPath;
@property NSInteger cursor;
@property NSNumber *selectedCategory;
@property czzArticleListDownloader *articleListDownloader;
@property NSMutableArray *heightsForRows;
@property NSMutableArray *heightsForHorizontalRows;
@end

@implementation czzArticleListViewController
@synthesize articleCategoris;
@synthesize selectedIndexPath;
@synthesize articleListDownloader;
@synthesize articleList;
@synthesize lastContentOffsetY;
@synthesize cursor;
@synthesize selectedCategory;
@synthesize categorySegmentControl;
@synthesize heightsForRows;
@synthesize heightsForHorizontalRows;

- (void)viewDidLoad
{
    [super viewDidLoad];
    cursor = 1; //default value
    articleList = [NSMutableArray new];
    articleCategoris = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:110], @"综合", [NSNumber numberWithInteger:73], @"工作·情感", [NSNumber numberWithInteger:74], @"动漫文化", [NSNumber numberWithInteger:75], @"漫画·小说", nil];
    UIRefreshControl *refControl = [UIRefreshControl new];
    [refControl addTarget:self action:@selector(refreshArticleList) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refControl;
    //hide tool bar if ios 7
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        self.navigationController.toolbar.hidden = YES;
    }
    heightsForRows = [NSMutableArray new];
    heightsForHorizontalRows = [NSMutableArray new];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (articleList.count <= 0)
    {
        [self refreshArticleList];
    }
    //[self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"ad_view_controller"] animated:YES completion:nil];
}

-(void)refreshArticleList{
    [self performSelector:@selector(categorySelectedAction:) withObject:categorySegmentControl];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (articleList.count == 0)
        return 0;
    return articleList.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //load more cell and loading cell - the last row of the whole table
    if (indexPath.row >= articleList.count){
        NSString *last_row_identifier = @"load_more_cell_identifier";
        //if articleListDownloader is not nil, it means its currently downloading
        if (articleListDownloader){
            last_row_identifier = @"loading_cell_identifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:last_row_identifier];
            UIActivityIndicatorView *aiView = (UIActivityIndicatorView*)[cell viewWithTag:1];
            [aiView startAnimating];
            return cell;
        }
        return [tableView dequeueReusableCellWithIdentifier:last_row_identifier];
    }
    static NSString *CellIdentifier = @"article_desc_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell){
        UILabel *title = (UILabel*)[cell viewWithTag:1];
        UILabel *info = (UILabel*)[cell viewWithTag:2];
        UILabel *desc = (UILabel*)[cell viewWithTag:3];
        czzArticle *article = [articleList objectAtIndex:indexPath.row];
        //info strip
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"MMM-dd, HH:mm";
        NSString *dateString = [dateFormatter stringFromDate:article.createTime];
        title.text = article.name;
        NSString *infoString = [NSString stringWithFormat:@"%@, 评论：%ld, 点击：%ld", dateString, (long)article.commentCount, (long)article.viewCount];
        info.text = infoString;
        desc.text = article.desc;
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //row for load more cell
    if (indexPath.row >= articleList.count){
        return tableView.rowHeight;
    }
    NSMutableArray *heightsArray;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        heightsArray = heightsForRows;
    } else {
        heightsArray = heightsForHorizontalRows;
    }
    CGFloat preferHeight = tableView.rowHeight;
    if (indexPath.row < heightsArray.count) {
        preferHeight = [[heightsArray objectAtIndex:indexPath.row] floatValue];
        return preferHeight;
    }
    UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    newHiddenTextView.hidden = YES;
    newHiddenTextView.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:newHiddenTextView];
    czzArticle *article = [articleList objectAtIndex:indexPath.row];
    newHiddenTextView.text = article.desc;
    preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 20 + 16;
    [newHiddenTextView removeFromSuperview];
    preferHeight = MAX(tableView.rowHeight, preferHeight);
    [heightsArray addObject:[NSNumber numberWithFloat:preferHeight]];
    return preferHeight;
}

#pragma mark - UITableview delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndexPath = indexPath;
    if (selectedIndexPath.row != articleList.count) {
        if (YES)//[[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUseExperimentalBrowser"])
        [self performSegueWithIdentifier:@"go_article_table_view_controller_identifier" sender:self];
        else
            [self performSegueWithIdentifier:@"go_article_view_controller_identifier" sender:self];
    }
    else {
        [self performSelector:@selector(loadMoreAction)];
    }
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    if ([segue.identifier isEqualToString:@"go_article_view_controller_identifier"]){
        czzArticlelViewController *articleViewController = (czzArticlelViewController*)segue.destinationViewController;
        articleViewController.myArticle = [articleList objectAtIndex:selectedIndexPath.row];
    } else if ([segue.identifier isEqualToString:@"go_article_table_view_controller_identifier"]){
        czzArticleTableViewController *articleTableViewController = (czzArticleTableViewController*)segue.destinationViewController;
        articleTableViewController.myArticle = [articleList objectAtIndex:selectedIndexPath.row];
    }
}

#pragma mark - czzArticleListDownloader delegate
-(void)articleListDownloaded:(NSArray *)articles withClass:(NSInteger)classNumber success:(BOOL)success{
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    [self.refreshControl endRefreshing];
    if (success && articles.count > 0){
        [articleList addObjectsFromArray:articles];
        [self.tableView reloadData];
    }
    else
    {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载文章列表，请重试！" duration:1.0 position:@"bottom" image:[UIImage imageNamed:@"warning"]];
    }
    [articleListDownloader stop];
    articleListDownloader = nil;
}

- (void)loadMoreAction {
    cursor = articleList.count + 1;
    [self startDownloadingWithCategory:selectedCategory.integerValue];
    NSIndexPath *lastRowIndexPath = [NSIndexPath indexPathForRow:articleList.count inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:lastRowIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)categorySelectedAction:(id)sender {
    cursor = 1;//reset cursor
    articleList = [NSMutableArray new]; //clear previously downloaded list
    heightsForRows = [NSMutableArray new];
    heightsForHorizontalRows = [NSMutableArray new];

    [self.tableView reloadData];
    UISegmentedControl *segmentControl = (UISegmentedControl*)sender;
    NSString *selectedTitle = [segmentControl titleForSegmentAtIndex:segmentControl.selectedSegmentIndex];
    selectedCategory = [articleCategoris objectForKey:selectedTitle];
    
    [self startDownloadingWithCategory:selectedCategory.integerValue];
}

-(void)startDownloadingWithCategory:(NSInteger)category{
    //stop any previously started downloader
    if (articleListDownloader)
        [articleListDownloader stop];
    articleListDownloader = [[czzArticleListDownloader alloc] initWithDelegate:self class:category startImmediately:NO];
    articleListDownloader.cursor = cursor;
    [articleListDownloader startDownloadingWithOrdering];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
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
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0 && scrollView.contentOffset.y > 0) {
        //show the toolbar if user moved the finger up, and the toolbar is currently hidden
        if (scrollDirection == ScrollDirectionUp && self.navigationController.toolbar.hidden == YES){
            [self showToolbar];
        } else if (scrollDirection == ScrollDirectionDown){
            [self hideToolbar];
        }
    }
}

-(void)showToolbar{
    [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.navigationController.toolbar :kCATransitionFromTop:0.2];
}

-(void)hideToolbar{
    [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:self.navigationController.toolbar :kCATransitionFromBottom:0.2];
}
@end

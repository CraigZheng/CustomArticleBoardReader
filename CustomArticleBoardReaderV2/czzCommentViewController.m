//
//  czzCommentViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 12/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzCommentViewController.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"
#import "czzComment.h"
#import "czzCommentDownloader.h"
#import "czzPostCommentViewController.h"

@interface czzCommentViewController ()<czzCommentDownloaderDelegate>
@property czzCommentDownloader *commentDownloader;
@property NSMutableArray *comments;
@property NSInteger lastContentOffsetY;

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

@end

@implementation czzCommentViewController
@synthesize commentDownloader;
@synthesize comments;
@synthesize lastContentOffsetY;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self refreshComments];
    UIRefreshControl *refControl = [[UIRefreshControl alloc] init];
    [refControl addTarget:self action:@selector(refreshComments) forControlEvents:UIControlEventValueChanged];
    //hide tool bar if ios 7
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        self.navigationController.toolbar.hidden = YES;
    }
}

-(void)refreshComments{
    comments = [NSMutableArray new];
    [self.tableView reloadData];
    [self startDownloadingCommentWithCursor:comments.count + 1];
}
-(void)startDownloadingCommentWithCursor:(NSInteger)cursor{
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
    commentDownloader = [[czzCommentDownloader alloc] initWithArticleID:self.articleID downloadMultipleReferedComment:YES delegate:self];
    commentDownloader.cursor = cursor;
    [commentDownloader startDownloadingComment];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    if (commentDownloader)
        [commentDownloader stop];
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (comments.count <= 0 || [[comments lastObject] floorIndex] <= 2)
        return comments.count;
    return comments.count + 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //load more cell and loading cell - the last row of the whole table
    if (indexPath.row >= comments.count){
        NSString *last_row_identifier = @"load_more_cell_identifier";
        //if articleListDownloader is not nil, it means its currently downloading
        if (commentDownloader){
            last_row_identifier = @"loading_cell_identifier";
        }
        return [tableView dequeueReusableCellWithIdentifier:last_row_identifier];
    }

    NSString *identifier = @"comment_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if (cell){
        UILabel *authorLabel = (UILabel*)[cell viewWithTag:1];
        UITextView *contentTextView = (UITextView*)[cell viewWithTag:2];
        czzComment *comment = [comments objectAtIndex:indexPath.row];
        NSString *authorString;
        if (comment.refCommentFlow.count > 0) {
            czzComment *referedComment = comment.refCommentFlow.lastObject;
            NSString *referedCommentString = [NSString stringWithFormat:@"#%ld %@", (long)referedComment.floorIndex, referedComment.user.name];
            authorString = [NSString stringWithFormat:@"#%ld %@ 对 %@ 说：", (long)comment.floorIndex, comment.user.name, referedCommentString];
        } else
        authorString = [NSString stringWithFormat:@"#%ld %@ 说：", (long)comment.floorIndex, comment.user.name];
        authorLabel.text = authorString;
        contentTextView.text = comment.content;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >= comments.count){
        return tableView.rowHeight;
    }
    CGFloat preferHeight = 0;
    UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    newHiddenTextView.hidden = YES;
    newHiddenTextView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:newHiddenTextView];
    czzComment *comment = [comments objectAtIndex:indexPath.row];
    newHiddenTextView.text = comment.content;
    preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 15;
    [newHiddenTextView removeFromSuperview];
    return MAX(tableView.rowHeight, preferHeight);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //the last row is selected
    if (indexPath.row == comments.count)
        [self performSelector:@selector(loadMoreAction)];
}

#pragma mark - UIScrollViewDelegate
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
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0 && scrollView.contentOffset.y > 10) {
        //show the toolbar if user moved the finger up, and the toolbar is currently hidden
        if (scrollDirection == ScrollDirectionUp && self.navigationController.toolbar.hidden == YES){
            [self showNavigationBarAndToolBar];
        } else if (scrollDirection == ScrollDirectionDown && self.navigationController.toolbar.hidden == NO) {
            [self hideNavigationBarAndToolBar];
        }
    }
}
#pragma mark - czzCommentDownloaderDelegate
-(void)commentDownloaded:(NSArray *)com withArticleID:(NSInteger)articleID success:(BOOL)success{
    if (success){
        [self.comments addObjectsFromArray:com];
        [self.tableView reloadData];
    }
    else
        [self.view makeToast:@"下载失败：请检查网络" duration:1.0 position:@"center" image:[UIImage imageNamed:@"warning"]];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    self.tableView.userInteractionEnabled = YES;
    commentDownloader = nil;
}

- (void)loadMoreAction {
    NSInteger cursor = comments.count;
    [self startDownloadingCommentWithCursor:cursor];
    NSIndexPath *lastRowIndexPath = [NSIndexPath indexPathForRow:comments.count inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:lastRowIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - czzCommentUploaderDelegate
-(void)sendComment:(czzComment *)comment toVideo:(NSInteger)videoID success:(BOOL)success{
    if (success){
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"评论已发"];
        [self refreshComments];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"评论发不出去我浑身难受！"];
    }
}

#pragma mark - prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationViewController isKindOfClass:[czzPostCommentViewController class]]){
        czzPostCommentViewController *incomingViewController = segue.destinationViewController;
        //configure the destination view controller
        incomingViewController.videoID = self.articleID;
        //TODO: refer floor
    }
}

#pragma mark - show and hide navigation bar and tool bar
-(void)hideNavigationBarAndToolBar{
    [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:self.navigationController.toolbar :kCATransitionFromBottom :0.2];
    //[[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:self.navigationController.navigationBar :kCATransitionFromTop :0.2];
    
}

-(void)showNavigationBarAndToolBar{
    [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.navigationController.toolbar :kCATransitionFromTop :0.2];
    //[[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.navigationController.navigationBar :kCATransitionFromBottom :0.2];
}

@end

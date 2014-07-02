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
#import "DTAttributedTextContentView.h"
#import "DTCoreTextLayouter.h"
#import "NSAttributedString+HTML.h"
#import "czzPostCommentViewController.h"
#import "czzNavigationController.h"
#import "czzAppDelegate.h"

@interface czzCommentViewController ()<czzCommentDownloaderDelegate, DTAttributedTextContentViewDelegate>
@property czzCommentDownloader *commentDownloader;
@property NSMutableArray *comments;
@property NSInteger lastContentOffsetY;
@property NSMutableArray *heightsForRows;
@property NSMutableArray *heightsForHorizontalRows;
@property NSIndexPath *fisrtVisibleCellIndex;

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
@synthesize heightsForRows;
@synthesize heightsForHorizontalRows;
@synthesize fisrtVisibleCellIndex;

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
    heightsForRows = [NSMutableArray new];
    heightsForHorizontalRows = [NSMutableArray new];
    [self.tableView reloadData];
    [self startDownloadingCommentWithCursor:comments.count + 1];
}
-(void)startDownloadingCommentWithCursor:(NSInteger)cursor{
    [[czzAppDelegate sharedAppDelegate].window makeToastActivity];
    commentDownloader = [[czzCommentDownloader alloc] initWithArticleID:self.articleID downloadMultipleReferedComment:YES delegate:self];
    commentDownloader.cursor = cursor;
    [commentDownloader startDownloadingComment];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [(czzNavigationController*)self.navigationController setShouldRotateViewController:NO];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (commentDownloader)
        [commentDownloader stop];
    [(czzNavigationController*)self.navigationController setShouldRotateViewController:YES];
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
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:last_row_identifier];
            UIActivityIndicatorView *aiView = (UIActivityIndicatorView*)[cell viewWithTag:1];
            [aiView startAnimating];
            return cell;
        }
        return [tableView dequeueReusableCellWithIdentifier:last_row_identifier];
    }

    NSString *identifier = @"comment_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if (cell){
        czzComment *comment = [comments objectAtIndex:indexPath.row];
        UIView *commentView = [self createCommentViewWithComment:comment width:self.view.frame.size.width backgroundColor:nil isMainComment:YES];
        //remove all subviews - on top of main comment view
        [cell.contentView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
        //add referred comment views
        CGFloat lastYposition = 0; //commentView.frame.origin.y + commentView.frame.size.height;
        for (czzComment *refComment in comment.refCommentFlow) {
            UIView *refCommentView = [self createCommentViewWithComment:refComment width:self.view.frame.size.width backgroundColor:nil isMainComment:NO];
            CGRect refCommentFrame = refCommentView.frame;
            refCommentFrame.origin.y = lastYposition;
            refCommentView.frame = refCommentFrame;
            lastYposition = refCommentFrame.origin.y + refCommentFrame.size.height;
            [cell.contentView addSubview:refCommentView];
        }
        //add main comment view
        CGRect mainCommentFrame = commentView.frame;
        mainCommentFrame.origin.y = lastYposition;
        commentView.frame = mainCommentFrame;
        [cell.contentView addSubview:commentView];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >= comments.count){
        return tableView.rowHeight;
    }
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat preferHeight = tableView.rowHeight;
    NSMutableArray *heightsArray;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        heightsArray = heightsForRows;
    } else {
        heightsArray = heightsForHorizontalRows;
        screenWidth = [UIScreen mainScreen].bounds.size.height;
    }
    if (indexPath.row < heightsArray.count) {
        preferHeight = [[heightsArray objectAtIndex:indexPath.row] floatValue];
        return preferHeight;
    }
    //main comment
    czzComment *comment = [comments objectAtIndex:indexPath.row];
    UIView *hiddenCommentView = [self createCommentViewWithComment:comment width:self.view.frame.size.width backgroundColor:nil isMainComment:YES];
    hiddenCommentView.hidden = YES;
    [self.view addSubview:hiddenCommentView];
    preferHeight = hiddenCommentView.frame.size.height;
    [hiddenCommentView removeFromSuperview];
    //refered comments
    for (czzComment *refComment in comment.refCommentFlow) {
        hiddenCommentView = [self createCommentViewWithComment:refComment width:self.view.frame.size.width backgroundColor:nil isMainComment:NO];
        [self.view addSubview:hiddenCommentView];
        preferHeight += hiddenCommentView.frame.size.height;
        [hiddenCommentView removeFromSuperview];
    }
    preferHeight = MAX(tableView.rowHeight, preferHeight);
    [heightsArray addObject:[NSNumber numberWithFloat:preferHeight]];
    return preferHeight;
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

#pragma mark - commentView creator method
-(UIView*)createCommentViewWithComment:(czzComment*)comment width:(CGFloat)width backgroundColor:(UIColor*)bgColor isMainComment:(BOOL)isMainComment {
    if (!isMainComment) {
        width -= 14; //padding
    }
    UIView *commentView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - width) / 2, 0, width, 1)];
    //author label
    NSString *authorString;
    if (comment.refCommentFlow.count > 0) {
        czzComment *referedComment = comment.refCommentFlow.lastObject;
        NSString *referedCommentString = [NSString stringWithFormat:@"#%ld %@", (long)referedComment.floorIndex, referedComment.user.name];
        authorString = [NSString stringWithFormat:@"#%ld %@ 对 %@ 说：", (long)comment.floorIndex, comment.user.name, referedCommentString];
    } else {
        authorString = [NSString stringWithFormat:@"#%ld %@ 说：", (long)comment.floorIndex, comment.user.name];
    }
    UILabel *authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    authorLabel.font = [UIFont systemFontOfSize:12];
    authorLabel.textColor = [UIColor colorWithRed:238/255.0 green:145/255.0 blue:40/255.0 alpha:1.0];
    authorLabel.backgroundColor = [UIColor clearColor];
    authorLabel.text = authorString;
    authorLabel.numberOfLines = 1;
    //comment section
    DTAttributedTextContentView *dtAttributedTextContentView;
    if (isMainComment) {
         dtAttributedTextContentView = [[DTAttributedTextContentView alloc] initWithAttributedString:comment.renderedContent width:width];
    } else {
        NSMutableAttributedString *refComContent = [[NSMutableAttributedString alloc] initWithAttributedString:comment.renderedContent];
        [refComContent addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, refComContent.length)];
        dtAttributedTextContentView = [[DTAttributedTextContentView alloc] initWithAttributedString:refComContent width:width - 8];
    }
    
    CGRect frame = dtAttributedTextContentView.frame;
    //adjust the views to allow some paddings
    if (!isMainComment) {
        frame.origin.x += 4;
        CGRect authorLabelFram = authorLabel.frame;
        authorLabelFram.origin.x += 4;
        authorLabel.frame = authorLabelFram;
    }
    frame.origin.y = 20;
    dtAttributedTextContentView.frame = frame;
    dtAttributedTextContentView.backgroundColor = [UIColor clearColor];
    //add both to comment view
    [commentView addSubview:authorLabel];
    [commentView addSubview:dtAttributedTextContentView];
    //resize commentview
    CGRect commentViewFrame = commentView.frame;
    commentViewFrame.size.height = dtAttributedTextContentView.frame.origin.y + dtAttributedTextContentView.frame.size.height;
    commentView.frame = commentViewFrame;
    if (!bgColor)
        bgColor = [UIColor clearColor];
    commentView.backgroundColor = bgColor;
    if (!isMainComment)
    {
        authorLabel.textColor = [UIColor grayColor];
        commentView.backgroundColor = [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:0.9];
    }
    return commentView;
}

#pragma mark - rotation
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    fisrtVisibleCellIndex = self.tableView.indexPathsForVisibleRows.firstObject;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView scrollToRowAtIndexPath:fisrtVisibleCellIndex atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

#pragma mark - czzCommentDownloaderDelegate
-(void)commentDownloaded:(NSArray *)com withArticleID:(NSInteger)articleID success:(BOOL)success{
    if (success){
        [self.comments addObjectsFromArray:com];
        [self.tableView reloadData];
    }
    else
        [self.view makeToast:@"下载失败：请检查网络" duration:1.0 position:@"center" image:[UIImage imageNamed:@"warning"]];
    self.tableView.userInteractionEnabled = YES;
    commentDownloader = nil;
    [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
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

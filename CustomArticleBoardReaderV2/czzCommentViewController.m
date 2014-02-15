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

@interface czzCommentViewController ()<czzCommentDownloaderDelegate>
@property czzCommentDownloader *commentDownloader;
@property NSMutableArray *comments;
@end

@implementation czzCommentViewController
@synthesize commentDownloader;
@synthesize comments;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    comments = [NSMutableArray new];
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
    newHiddenTextView.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:newHiddenTextView];
    czzComment *comment = [comments objectAtIndex:indexPath.row];
    newHiddenTextView.text = comment.content;
    preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 15;
    return MAX(tableView.rowHeight, preferHeight);
}

#pragma mark - czzCommentDownloaderDelegate
-(void)commentDownloaded:(NSArray *)com withArticleID:(NSInteger)articleID success:(BOOL)success{
    if (success){
        [self.comments addObjectsFromArray:com];
        [self.tableView reloadData];
    }
    else
        [self.view makeToast:@"下载失败" duration:1.0 position:@"center" image:[UIImage imageNamed:@"warning"]];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    self.tableView.userInteractionEnabled = YES;
    commentDownloader = nil;
}

- (IBAction)loadMoreAction:(id)sender {
    NSInteger cursor = comments.count;
    [self startDownloadingCommentWithCursor:cursor];
    NSIndexPath *lastRowIndexPath = [NSIndexPath indexPathForRow:comments.count inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:lastRowIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
@end

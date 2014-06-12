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
#import "DTAttributedTextView.h"
#import "NSAttributedString+HTML.h"
#import "czzPostCommentViewController.h"

@interface czzCommentViewController ()<czzCommentDownloaderDelegate>
@property czzCommentDownloader *commentDownloader;
@property NSMutableArray *comments;
@property NSInteger lastContentOffsetY;
@property NSMutableArray *heightsForRows;
@property NSMutableArray *heightsForHorizontalRows;
@property NSIndexPath *fisrtVisibleCellIndex;
@property NSMutableArray *aisEmotions;
@property NSMutableArray *acEmotions;
@property NSMutableDictionary *emotionDictionary;

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
@synthesize aisEmotions;
@synthesize acEmotions;
@synthesize emotionDictionary;

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
    
    //emotions
    emotionDictionary = [NSMutableDictionary new];
    acEmotions = [NSMutableArray new];
    aisEmotions = [NSMutableArray new];
    NSString *acEmotionFolder = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"ac emotions01"];
    NSString *aisEmotionFolder = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"ac emotions02"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:acEmotionFolder error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.gif'"];
    NSArray *emotions = [dirContents filteredArrayUsingPredicate:fltr];

    for (NSString *emoFile in emotions) {
        [acEmotions addObject:[acEmotionFolder.lastPathComponent stringByAppendingPathComponent:emoFile]];
    }
    dirContents = [fm contentsOfDirectoryAtPath:aisEmotionFolder error:nil];
    emotions = [dirContents filteredArrayUsingPredicate:fltr];
    for (NSString *emoFile in emotions) {
        [aisEmotions addObject:[aisEmotionFolder.lastPathComponent stringByAppendingPathComponent:emoFile]];
    }
    //make emotion dictionary
    for (NSInteger i = 0; i < acEmotions.count; i++){
        NSString *key = [NSString stringWithFormat:@"emot=%@,%02d/", @"ac", i + 1];
        [emotionDictionary setObject:[acEmotions objectAtIndex:i] forKey:key];
    }
    
    for (NSInteger i = 0; i < aisEmotions.count; i++){
        NSString *key = [NSString stringWithFormat:@"emot=%@,%02d/", @"ais", i + 1];
        [emotionDictionary setObject:[aisEmotions objectAtIndex:i] forKey:key];
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
    commentDownloader = [[czzCommentDownloader alloc] initWithArticleID:self.articleID downloadMultipleReferedComment:YES delegate:self];
    commentDownloader.cursor = cursor;
    [commentDownloader startDownloadingComment];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
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
        UILabel *authorLabel = (UILabel*)[cell viewWithTag:1];
        DTAttributedTextView *dtAttributedTextView = (DTAttributedTextView*)[cell viewWithTag:2];
        czzComment *comment = [comments objectAtIndex:indexPath.row];
        NSString *authorString;
        if (comment.refCommentFlow.count > 0) {
            czzComment *referedComment = comment.refCommentFlow.lastObject;
            NSString *referedCommentString = [NSString stringWithFormat:@"#%ld %@", (long)referedComment.floorIndex, referedComment.user.name];
            authorString = [NSString stringWithFormat:@"#%ld %@ 对 %@ 说：", (long)comment.floorIndex, comment.user.name, referedCommentString];
        } else
        authorString = [NSString stringWithFormat:@"#%ld %@ 说：", (long)comment.floorIndex, comment.user.name];
        authorLabel.text = authorString;
        dtAttributedTextView.userInteractionEnabled = NO;
        dtAttributedTextView.attributedString = [self scanEmotionTags:comment.content :emotionDictionary :[UIFont systemFontOfSize:16]];
        
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >= comments.count){
        return tableView.rowHeight;
    }
    CGFloat preferHeight = tableView.rowHeight;
    NSMutableArray *heightsArray;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        heightsArray = heightsForRows;
    } else {
        heightsArray = heightsForHorizontalRows;
    }
    if (indexPath.row < heightsArray.count) {
        preferHeight = [[heightsArray objectAtIndex:indexPath.row] floatValue];
        return preferHeight;
    }
    DTAttributedTextView *newHiddenTextView = [[DTAttributedTextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    newHiddenTextView.hidden = YES;
//    newHiddenTextView.font = [UIFont systemFontOfSize:16];

    [self.view addSubview:newHiddenTextView];
    czzComment *comment = [comments objectAtIndex:indexPath.row];
//    newHiddenTextView.text = comment.content;
    newHiddenTextView.attributedString = [self scanEmotionTags:comment.content :emotionDictionary :[UIFont systemFontOfSize:16]];

//    preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 15;
    preferHeight = [[newHiddenTextView contentView] suggestedFrameSizeToFitEntireStringConstraintedToWidth:newHiddenTextView.frame.size.width] .height + 25;
    [newHiddenTextView removeFromSuperview];
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

#pragma mark - scan emotion tags
- (NSAttributedString*)scanEmotionTags:(NSString *)originalText :(NSDictionary*)emoDict :(UIFont*)font{
    
    NSDictionary *emotions = emoDict;
    NSString *text = originalText;
    
    NSString *replaced;
    NSMutableString *formatedResponse = [NSMutableString string];
    
    NSScanner *emotionScanner = [NSScanner scannerWithString:text];
    [emotionScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    while ([emotionScanner isAtEnd] == NO) {
        
        if([emotionScanner scanUpToString:@"[" intoString:&replaced]) {
            [formatedResponse appendString:replaced];
        }
        if(![emotionScanner isAtEnd]) {
            [emotionScanner scanString:@"[" intoString:nil];
            replaced = @"";
            [emotionScanner scanUpToString:@"]" intoString:&replaced];
            NSString *em = [emotions valueForKey:replaced];
            if (em) {
                [formatedResponse appendFormat:@"<img src='%@' />", em];
            }else {
                [formatedResponse appendFormat:@"[%@]", replaced];
            }
            
            [emotionScanner scanString:@"]" intoString:nil];
        }
        
    }
    
    //NSLog(@"formatedResponse: %@", formatedResponse);
    [formatedResponse replaceOccurrencesOfString:@"\n" withString:@"<br />" options:0 range:NSMakeRange(0, formatedResponse.length)];
    NSData *data = [[NSString stringWithFormat:@"<p style='font-size:%fpt'>%@</p>", font.pointSize, formatedResponse] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:/*CGSizeMake(_font.lineHeight, _font.lineHeight)*/CGSizeMake(50, 50)], DTMaxImageSize, @"System", DTDefaultFontFamily, nil];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithHTML:data options:options documentAttributes:nil
                                         ];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineSpacing = 100;
    paragraphStyle.minimumLineHeight = font.lineHeight + 5;
    paragraphStyle.maximumLineHeight = font.lineHeight + 5;
    [string addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, string.length)];
    return string;
}


@end

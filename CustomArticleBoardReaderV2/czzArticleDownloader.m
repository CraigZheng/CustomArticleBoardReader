//
//  czzArticleDownloader.m
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticleDownloader.h"

@interface czzArticleDownloader()<NSURLConnectionDelegate>
@property NSURLConnection *urlConn;
@property NSMutableData *receivedData;
@end

@implementation czzArticleDownloader
@synthesize urlConn;
@synthesize receivedData;
@synthesize articleProcessor;

-(id)initWithArticleID:(NSInteger)articleID delegate:(id<czzArticleDownloaderDelegate>)delegate startImmediately:(BOOL)start{
    self = [super init];
    if (self) {
        self.articleID = articleID;
        self.delegate = delegate;
        if (start){
            [self constructURLConnectionAndStart];
        }
    }
    return self;
}

-(void)constructURLConnectionAndStart{
    NSString *articleURLString = [ARTICLEHOST stringByReplacingOccurrencesOfString:ARTICLEID withString:[NSString stringWithFormat:@"%ld", (long)self.articleID]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:articleURLString]];
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

#pragma mark - NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //inform delegate that the download is finished with negative result
    [self.delegate articleDownloaded:nil withArticleID:self.articleID success:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedData = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSString *receivedHTMLBody = [[NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:nil] valueForKey:@"txt"];
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<img" options:NSRegularExpressionCaseInsensitive error:&error];
    @try {
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:receivedHTMLBody options:0 range:NSMakeRange(0, [receivedHTMLBody length])];
        if (!error && numberOfMatches > 200){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"图片过多" message:[NSString stringWithFormat:@"文章中共有%ld张图片，可能用电脑来看更适合。你确定要打开这篇文章吗？", (long)numberOfMatches] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
            [alertView show];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    articleProcessor = [[NSThread alloc] initWithTarget:self selector:@selector(prepareArticleInBackground) object:nil];
    [articleProcessor start];
}

-(void)prepareArticleInBackground{
    @try {
        czzArticle* newArticle = [[czzArticle alloc] initWithJSONData:receivedData];
        if (newArticle)
            [self.delegate articleDownloaded:newArticle withArticleID:self.articleID success:YES];
        else
            [self.delegate articleDownloaded:nil withArticleID:self.articleID success:NO];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
        [self.delegate articleDownloaded:nil withArticleID:self.articleID success:NO];
    }
}

-(void)stop{
    [urlConn cancel];
}

#pragma mark - UIAlertView delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"图片过多"]){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"确认"]){
            czzArticle* newArticle = [[czzArticle alloc] initWithJSONData:receivedData];
            if (newArticle)
                [self.delegate articleDownloaded:newArticle withArticleID:self.articleID success:YES];
            else
                [self.delegate articleDownloaded:nil withArticleID:self.articleID success:NO];
        } else {
            [self.delegate articleDownloaded:nil withArticleID:self.articleID success:NO];
        }
    }
}

@end

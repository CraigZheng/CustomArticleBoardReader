//
//  czzCommentDownloader.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 12/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzCommentDownloader.h"

@interface czzCommentDownloader()<NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property BOOL shouldDownloadMultipleComment;
@property NSURLConnection *urlConn;
@property NSMutableData *receivedData;
@end

@implementation czzCommentDownloader
@synthesize urlConn;
@synthesize shouldDownloadMultipleComment;
@synthesize receivedData;
@synthesize quoteLimit;

//default properties
-(id)init{
    self = [super init];
    if (self){
        shouldDownloadMultipleComment = YES;
        self.quoteLimit = 99; //default to 99
        self.cursor = 1;
    }
    return self;
}

//init with given properties
-(id)initWithArticleID:(NSInteger)articleID downloadMultipleReferedComment:(BOOL)multiple delegate:(id<czzCommentDownloaderDelegate>)delegate{
    self = [self init];
    if (self){
        self.articleID = articleID;
        self.shouldDownloadMultipleComment = multiple;
        self.delegate = delegate;
    }
    return self;
}

-(void)startDownloadingComment{
    NSString *host;
    if (shouldDownloadMultipleComment){
        host = [MULTIPLECOMMENTHOST stringByReplacingOccurrencesOfString:COMMENTID withString:[NSString stringWithFormat:@"%ld", (long)self.articleID]];
    } else
        host = [SINGLECOMMENTHOST stringByReplacingOccurrencesOfString:COMMENTID withString:[NSString stringWithFormat:@"%ld", (long)self.articleID]];
    host = [host stringByReplacingOccurrencesOfString:QUOTE_NU withString:[NSString stringWithFormat:@"%ld", (long)self.quoteLimit]];
    host = [host stringByReplacingOccurrencesOfString:CURSOR withString:[NSString stringWithFormat:@"%ld", (long)self.cursor]];
    NSLog(@"%@", host);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:host]];
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

-(void)stop{
    [urlConn cancel];
}

#pragma mark - NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.receivedData = [NSMutableData new];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.receivedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    self.receivedData = nil;
    [self.delegate commentDownloaded:nil withArticleID:self.articleID success:NO];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //finish constructing czzComment object, and pass it to the delegate
    NSError *error;
    NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
    if (error){
        NSLog(@"%@", error);
        [self.delegate commentDownloaded:nil withArticleID:self.articleID success:NO];
    }
    //render comments in background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *comments = [NSMutableArray new];
        for (NSString *key in dataDict) {
            if ([key isEqualToString:@"list"]){
                for (NSDictionary *comment in [dataDict objectForKey:key]) {
                    [comments addObject:[[czzComment alloc] initWithJSONDictionary:comment]];
                }
            }
        }
        //hide duplicate comments
        for (NSInteger i = 0; i < comments.count; i ++) {
            czzComment *currentComment = [comments objectAtIndex:i];
            for (NSInteger j = 0; j < i; j++) {
                //previous comments
                czzComment *previousComment = [comments objectAtIndex:j];
                if ([previousComment referredToComment:currentComment]) {
                    czzComment *placeboComment = [czzComment new];
                    placeboComment.floorIndex = 0;
                    placeboComment.renderedContent = [[NSAttributedString alloc] initWithString:@"* 重复引用的回复已省略 *"];
                    NSArray *placeboArray;
                    //hide duplicate comments when ref comment has more than 2 comments
                    if (currentComment.refCommentFlow.count > 2) {
                        placeboArray = @[placeboComment, currentComment.refCommentFlow.lastObject];
                    }
//                    else {
//                        placeboArray = @[placeboComment];
//                    }
                    currentComment.refCommentFlow = placeboArray;
                    break;
                }
            }
        }
        //notify delegate in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if (comments.count > 0)
                [self.delegate commentDownloaded:comments withArticleID:self.articleID success:YES];
            else
                [self.delegate commentDownloaded:nil withArticleID:self.articleID success:NO];
        });
    });
}
@end

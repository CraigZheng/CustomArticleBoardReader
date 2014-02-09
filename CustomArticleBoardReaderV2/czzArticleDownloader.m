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
    czzArticle* newArticle = [[czzArticle alloc] initWithJSONData:receivedData];
    if (newArticle)
        [self.delegate articleDownloaded:newArticle withArticleID:self.articleID success:YES];
    else
        [self.delegate articleDownloaded:nil withArticleID:self.articleID success:NO];
}

@end

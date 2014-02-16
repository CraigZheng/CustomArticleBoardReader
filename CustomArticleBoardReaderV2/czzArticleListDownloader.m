//
//  czzArticleListDownloader.m
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticleListDownloader.h"
#import "czzArticle.h"

@interface czzArticleListDownloader()<NSURLConnectionDelegate>
@property NSURLConnection *urlConn;
@property NSMutableData *receivedData;
@end

@implementation czzArticleListDownloader
@synthesize urlConn;
@synthesize receivedData;

-(id)initWithDelegate:(id<czzArticleListDownloaderDelegate>)delegate class:(NSInteger)classNumber startImmediately:(BOOL)start{
    self = [super init];
    if (self){
        self.delegate = delegate;
        self.classNumber = classNumber;
        self.cursor = 1;
        if (start){
            [self startDownloadingWithOrdering];
        }
    }
    return self;
}

-(void)startDownloadingWithOrdering{
    NSInteger ordering = DEFAULT_ORDER;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"articleOrdering"]){
        ordering = [[NSUserDefaults standardUserDefaults] integerForKey:@"articleOrdering"];
    }
    NSString *articleListString = [ARTICLE_LIST_HOST stringByReplacingOccurrencesOfString:ARTICLE_CLASS withString:[NSString stringWithFormat:@"%ld", (long)self.classNumber]];
    articleListString = [articleListString stringByReplacingOccurrencesOfString:ARTICLE_ORDER withString:[NSString stringWithFormat:@"%ld", (long)ordering]];
    articleListString = [articleListString stringByReplacingOccurrencesOfString:CURSOR withString:[NSString stringWithFormat:@"%ld", (long)self.cursor]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:articleListString]];
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
}

#pragma mark - NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //inform delegate that the download is finished with negative result
    [self.delegate articleListDownloaded:nil withClass:self.classNumber success:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedData = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSMutableArray *articles = [NSMutableArray new];
    NSError *error;
    NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
    //NSLog(@"%@", [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding]);
    if (error) {
        [self.delegate articleListDownloaded:nil withClass:self.classNumber success:NO];
    } else {
        for (NSString *key in dataDict) {
            if ([key isEqualToString:@"list"]){
                for (NSDictionary *article in [dataDict objectForKey:key]) {
                    [articles addObject:[[czzArticle alloc] initWithJSONDictonary:article]];
                }
            }
        }
        [self.delegate articleListDownloaded:articles withClass:self.classNumber success:YES];
    }
}

-(void)stop{
    [urlConn cancel];
}
@end

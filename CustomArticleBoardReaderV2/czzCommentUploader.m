//
//  czzCommentUploader.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 20/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzCommentUploader.h"
#import "czzAppDelegate.h"
#import "czzMySelf.h"

@interface czzCommentUploader()<NSURLConnectionDataDelegate>
@property NSURLConnection *urlConn;
@property NSInteger videoID;
@property czzComment *comment;
@property NSMutableData *receivedData;
@end

@implementation czzCommentUploader
@synthesize urlConn;
@synthesize receivedData;

-(void)sendComment:(czzComment *)comment toVideo:(NSInteger)videoID{
    self.comment = comment;
    self.videoID = videoID;
    czzMySelf *currentLoginUser = [czzAppDelegate sharedAppDelegate].currentLoginUser;
    NSString *post_comment_url_string = [POST_COMMENT_HOST stringByReplacingOccurrencesOfString:VIDEO_ID withString:[NSString stringWithFormat:@"%ld", (long)videoID]];
    
    if (currentLoginUser){
        post_comment_url_string = [post_comment_url_string stringByAppendingFormat:@"?access_token=%@", currentLoginUser.access_token];
    }
//    NSLog(@"U÷RL: %@", post_comment_url_string);
    
    NSURL *post_comment_url = [NSURL URLWithString:post_comment_url_string];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:post_comment_url];
    [request setHTTPMethod:@"POST"];
    NSMutableDictionary *contentDict = [NSMutableDictionary dictionaryWithObjects:@[comment.content, @""] forKeys:@[@"content", @"quoteId"]];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:contentDict options:0 error:0];
    
    [request setHTTPBody:jsonData];
    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

#pragma mark - NSURLConnectionDataDelegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    BOOL success = NO;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSLog(@"status code = %ld", (long)[httpResponse statusCode]);
    if ([httpResponse statusCode] == 200 ||
        [httpResponse statusCode] == 201 ||
        [httpResponse statusCode] == 202 ||
        [httpResponse statusCode] == 204){
        //post successfully
        success = YES;
    }
    if ([self.delegate respondsToSelector:@selector(sendComment:toVideo:success:)]){
        [self.delegate sendComment:self.comment toVideo:self.videoID success:success];
    }
    receivedData = [NSMutableData new];
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //NSString *response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    //NSLog(@"%@", response);
}

@end

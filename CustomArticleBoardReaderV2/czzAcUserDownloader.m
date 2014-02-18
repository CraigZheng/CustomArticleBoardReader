//
//  czzAcUserDownloader.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzAcUserDownloader.h"

@interface czzAcUserDownloader()<NSURLConnectionDelegate>
@property NSURLConnection *urlConn;
@property NSMutableData *receivedData;
@end

@implementation czzAcUserDownloader
@synthesize urlConn;
@synthesize receivedData;

-(id)initWithAcUserID:(NSInteger)userID delegate:(id<czzAcUserDownloaderProtocol>)delegate{
    self = [super init];
    if (self){
        self.acUserID = userID;
        self.delegate = delegate;
    }
    return self;
}

-(void)startDownloading{
    NSString *acUserIDURLString = [ACUSERHOST stringByReplacingOccurrencesOfString:ACUSERID withString:[NSString stringWithFormat:@"%ld", (long)self.acUserID]];
    NSString *access_token = [[NSUserDefaults standardUserDefaults] objectForKey:@"access_token"];
    if (!access_token){
        [self.delegate acUserDownloaded:nil withAcUserID:self.acUserID success:NO];
        return;
    }
    acUserIDURLString = [acUserIDURLString stringByReplacingOccurrencesOfString:ACCESS_TOKEN withString:access_token];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:acUserIDURLString]];
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

-(void)stop{
    [urlConn cancel];
}

#pragma mark - NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //inform delegate that the download is finished with negative result
    [self.delegate acUserDownloaded:nil withAcUserID:self.acUserID success:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedData = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //TODO: form a ac user outta json
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    czzAcUser *newUser = [[czzAcUser alloc] initWithJSONDictionary:jsonDict];
    if (newUser)
        [self.delegate acUserDownloaded:newUser withAcUserID:self.acUserID success:YES];
    else
        [self.delegate acUserDownloaded:nil withAcUserID:self.acUserID success:NO];
}

@end

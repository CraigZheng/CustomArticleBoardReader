//
//  czzImageDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzImageDownloader.h"


@interface czzImageDownloader()<NSURLConnectionDelegate>
@property NSURLConnection *urlConn;
@property NSMutableData *receivedData;
@property NSString *baseURLString;
@property NSString *fileName;
@property NSString *filePath;
@property long long fileSize;
@property NSUInteger downloadedSize;
@end

@implementation czzImageDownloader
@synthesize urlConn;
@synthesize imageURLString;
@synthesize baseURLString;
@synthesize targetURLString;
@synthesize receivedData;
@synthesize fileName;
@synthesize delegate;
@synthesize isThumbnail;
@synthesize fileSize;
@synthesize downloadedSize;
@synthesize filePath;

-(id)init{
    self = [super init];
    if (self){
        baseURLString = @"http://api.acfun.tv";
    }
    return self;
}

-(void)startDownloading{
    if (!imageURLString)
        return;
    if (urlConn){
        [urlConn cancel];
    }
    //check local image folder for the requested file, if existed, return it instead
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //save to thumbnail folder or fullsize folder
    basePath = [basePath
                stringByAppendingPathComponent:@"Images"];
    
    filePath = [basePath stringByAppendingPathComponent:imageURLString.lastPathComponent];
    UIImage* image = [[UIImage alloc] initWithContentsOfFile:filePath];
    NSError *error = [NSError errorWithDomain:@"图片为空白" code:999 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"图片已经下载过了", NSLocalizedDescriptionKey, nil]];
    if (image){
        [self.delegate downloadFinished:self success:YES isThumbnail:NO saveTo:filePath error:error];
        return;
    }

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:targetURLString]];
    urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
    [urlConn scheduleInRunLoop:[NSRunLoop mainRunLoop]
                          forMode:NSDefaultRunLoopMode];
    [urlConn start];
}

-(void)stop{
    if (urlConn)
        [urlConn cancel];
}

#pragma setter for imgURLString
-(void)setImageURLString:(NSString *)urlstring{
    imageURLString = urlstring;
    //targetURLString = [baseURLString stringByAppendingPathComponent:[imageURLString stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
    targetURLString = imageURLString;
}
#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //notify delegate that the download is failed
    if (delegate && [delegate respondsToSelector:@selector(downloadFinished:success:isThumbnail:saveTo:error:)]){
        [delegate downloadFinished:self success:NO isThumbnail:isThumbnail saveTo:nil error:error];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedData = [NSMutableData new];
    fileName = response.suggestedFilename;
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //save to thumbnail folder or fullsize folder
    basePath = [basePath
                stringByAppendingPathComponent:@"Images"];
    filePath = [basePath stringByAppendingPathComponent:fileName];
    fileSize = [response expectedContentLength];
    downloadedSize = 0;
    //notify delegate that download is started
    if (delegate && [delegate respondsToSelector:@selector(downloadStarted:)]){
        [delegate downloadStarted:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
    downloadedSize = receivedData.length;
    //inform delegate that a part of download is finished
    if ([delegate respondsToSelector:@selector(downloaderProgressUpdated:expectedLength:downloadedLength:)]){
        [delegate downloaderProgressUpdated:self expectedLength:(NSUInteger)fileSize downloadedLength:downloadedSize];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //save to library directory
    NSError *error;
    [receivedData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    //check if image is empty
    UIImage* image = [[UIImage alloc] initWithData:receivedData];
    if (!image)
    {
        error = [NSError errorWithDomain:@"图片为空白" code:999 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"图片为空白", NSLocalizedDescriptionKey, nil]];
    }
    if (delegate && [delegate respondsToSelector:@selector(downloadFinished:success:isThumbnail:saveTo:error:)]){
        if (error){
            NSLog(@"%@", error);
            [delegate downloadFinished:self success:NO isThumbnail:isThumbnail saveTo:filePath error:error];
        } else {
            [delegate downloadFinished:self success:YES isThumbnail:isThumbnail saveTo:filePath error:nil];
        }
    }
}

//current downloading progress
-(double)progress{
    double pro = (double)downloadedSize / (double)fileSize;
    return pro;
}

//determine if 2 downloaders are equal by compare the target URL
-(BOOL)isEqual:(id)object{
    if ([object isKindOfClass:[czzImageDownloader class]]) {
        czzImageDownloader *incomingDownloader = (czzImageDownloader*)object;
        return [incomingDownloader.imageURLString isEqualToString:self.imageURLString];
    }
    return NO;
}

-(NSUInteger)hash{
    return imageURLString.hash;
}

@end

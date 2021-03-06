//
//  czzImageDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzImageDownloader;
/*
 delegate that notify a download has been finished - or failed
 */
@protocol czzImageDownloaderDelegate <NSObject>
-(void)downloadFinished:(czzImageDownloader*)imgDownloader success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString*)path error:(NSError*)error;
@optional
-(void)downloadStarted:(czzImageDownloader*)imgDownloader;
-(void)downloaderProgressUpdated:(czzImageDownloader*)imgDownloader expectedLength:(NSUInteger)total downloadedLength:(NSUInteger)downloaded;
@end

@interface czzImageDownloader : NSObject
@property (nonatomic) NSString *imageURLString;
@property NSString *targetURLString;
@property id<czzImageDownloaderDelegate> delegate;
@property BOOL isThumbnail;

-(id)init;
-(void)startDownloading;
-(void)stop;
-(double)progress;
@end

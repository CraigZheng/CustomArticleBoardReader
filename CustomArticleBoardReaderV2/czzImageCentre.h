//
//  czzImageDownloadCentre.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//
/*
 czzImageDownloadCentre singleton, allows multiple image downloaders to run simoutaneously, and notify appropriate observer that images have been downloaded.
 it also serves as the service centre of local images, feeding images to appropriate view controllers, and preventing same image being downloaded twice.
 */
#import <Foundation/Foundation.h>
#import "czzImageDownloader.h"

#define MAXIMUM_CONCURRENT_DOWNLOADING 3

@interface czzImageCentre : NSObject
@property NSMutableOrderedSet *currentImageDownloaders;
@property NSMutableSet *currentLocalImages;
@property Boolean isReady;

+(id)sharedInstance;

-(void)scanCurrentLocalImages;
-(void)downloadImageWithURL:(NSString*)imgURL;
-(Boolean)containsImageDownloaderWithURL:(NSString*)imgURL;
-(NSString*)containsImageInLocal:(NSString*)imgURL;
-(void)stopAllDownloader;
-(void)stopAndRemoveImageDownloaderWithURL:(NSString*)imgURL;
-(void)removeAllImages;
@end

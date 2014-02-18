//
//  czzAcUserDownloader.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzAcUser.h"

#define ACUSERID @"AcUserID"
#define ACCESS_TOKEN @"ACCESS_TOKEN"
#define ACUSERHOST @"http://api.acfun.tv/users/AcUserID?access_token=ACCESS_TOKEN"

@protocol czzAcUserDownloaderProtocol <NSObject>
@optional
-(void)acUserDownloaded:(czzAcUser*)acUser withAcUserID:(NSInteger)userID success:(BOOL)success;
@end

@interface czzAcUserDownloader : NSObject
@property NSInteger acUserID;
@property (retain) id<czzAcUserDownloaderProtocol> delegate;

-(id)initWithAcUserID:(NSInteger)userID delegate:(id<czzAcUserDownloaderProtocol>)delegate;
-(void)startDownloading;
-(void)stop;
@end

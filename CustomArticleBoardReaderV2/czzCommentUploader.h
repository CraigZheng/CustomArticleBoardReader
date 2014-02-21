//
//  czzCommentUploader.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 20/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzComment.h"

#define VIDEO_ID @"VIDEOID"
#define POST_COMMENT_HOST @"http://api.acfun.tv/videos/VIDEOID/comments"

@protocol czzCommentUploaderDelegate<NSObject>
@optional
-(void)sendComment:(czzComment*)comment toVideo:(NSInteger)videoID success:(BOOL)success;
@end

@interface czzCommentUploader : NSObject
@property id<czzCommentUploaderDelegate> delegate;
-(void)sendComment:(czzComment*)comment toVideo:(NSInteger)videoID;
@end

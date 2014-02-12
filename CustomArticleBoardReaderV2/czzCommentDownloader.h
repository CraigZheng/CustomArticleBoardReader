//
//  czzCommentDownloader.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 12/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzComment.h"

#define COMMENTID @"articleIDForComment"

#define CURSOR @"CURSOR"
#define QUOTE_NU @"QUOTE_NU"
#define MULTIPLECOMMENTHOST @"http://api.acfun.tv/videos/articleIDForComment/androidComments?quoteNu=QUOTE_NU&cursor=CURSOR"
#define SINGLECOMMENTHOST @"http://api.acfun.tv/videos/articleIDForComment/comments?quoteNu=QUOTE_NU&cursor=CURSOR"

@protocol czzCommentDownloaderDelegate <NSObject>
-(void)commentDownloaded:(NSArray*)comments withArticleID:(NSInteger)articleID success:(BOOL)success;

@end

@interface czzCommentDownloader : NSObject
@property NSInteger articleID;
@property NSInteger quoteLimit;
@property NSInteger cursor;
@property id<czzCommentDownloaderDelegate> delegate;

-(id)initWithArticleID:(NSInteger) articleID downloadMultipleReferedComment:(BOOL)multiple delegate:(id<czzCommentDownloaderDelegate>)delegate;
-(void)startDownloadingComment;
-(void)stop;
@end

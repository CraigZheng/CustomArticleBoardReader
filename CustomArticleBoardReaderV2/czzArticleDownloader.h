//
//  czzArticleDownloader.h
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//


//TODO: not yet finish, need authentication to view full profile
#import <Foundation/Foundation.h>
#import "czzArticle.h"

#define ARTICLEID @"articleID"
#define ARTICLEHOST @"http://api.acfun.tv/videos/articleID/Article"

@protocol czzArticleDownloaderDelegate <NSObject>
-(void)articleDownloaded:(czzArticle*)article withArticleID:(NSInteger)articleID success:(BOOL)success;
-(void)articleProcessUpdated:(czzArticle*)article percent:(CGFloat)percent;
@end

@interface czzArticleDownloader : NSObject<UIAlertViewDelegate>
@property NSInteger articleID;
@property NSThread *articleProcessor;
@property id<czzArticleDownloaderDelegate> delegate;

-(id)initWithArticleID:(NSInteger)articleID delegate:(id<czzArticleDownloaderDelegate>)delegate startImmediately:(BOOL)start;
-(void)constructURLConnectionAndStart;
-(void)stop;
@end

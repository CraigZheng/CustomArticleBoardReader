//
//  czzArticleListDownloader.h
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_ORDER 0
#define MOST_CLICKED_DAILY 1
#define MOST_CLICKED_WEEKLY 2
#define MOST_COMMENTED_DAILY 3
#define NEWEST_RESPONDED 4

#define ARTICLE_ORDER @"ARTICLE_ORDER"
#define ARTICLE_CLASS @"ARTICLE_CLASS"
#define CURSOR @"CURSOR"
#define ARTICLE_LIST_HOST @"http://api.acfun.tv/videos?order=ARTICLE_ORDER&class=ARTICLE_CLASS&cursor=CURSOR"

@protocol czzArticleListDownloaderDelegate <NSObject>
-(void)articleListDownloaded:(NSArray*)articles withClass:(NSInteger)classNumber success:(BOOL)success;
@end

@interface czzArticleListDownloader : NSObject
@property NSInteger classNumber;
@property NSInteger cursor;
@property id<czzArticleListDownloaderDelegate> delegate;

-(void)startDownloadingWithOrdering:(NSInteger)ordering;
-(void)stop;
-(id)initWithDelegate:(id<czzArticleListDownloaderDelegate>)delegate class:(NSInteger)classNumber startImmediately:(BOOL)start;

@end

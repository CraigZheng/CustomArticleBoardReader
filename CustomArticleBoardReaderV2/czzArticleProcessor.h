//
//  czzArticleProcessor.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 22/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzArticle.h"

@protocol czzArticleProcessorDelegate <NSObject>
@optional
-(void)articleUpdated:(czzArticle*)article isFinished:(BOOL)finished;
@end

@interface czzArticleProcessor : NSObject
@property czzArticle *article;
@property id<czzArticleProcessorDelegate> delegate;
@property BOOL shouldStop;

-(id)initWithArticle:(czzArticle*)articleToUpdate andHTMLBody:(NSString*)htmlBody andDelegate:(id<czzArticleProcessorDelegate>)del;
@end

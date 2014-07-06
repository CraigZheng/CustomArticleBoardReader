//
//  czzArticle.h
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzAcUser.h"

@protocol czzArticleProtocol <NSObject>
@optional
-(void)articleProcessUpdated:(CGFloat)percent;
@end

@interface czzArticle : NSObject
@property NSInteger acId;
@property NSString *name;
@property NSString *desc;
@property NSString *previewUrl;
@property NSInteger viewCount;
@property NSInteger favouriteCount;
@property NSInteger commentCount;
@property NSDate *createTime;
@property czzAcUser *creator;
@property BOOL isOriginal;
@property NSArray *tags;
@property NSString *category;
@property NSString *htmlBody;
@property (nonatomic) NSString *htmlBodyWithouImage;
@property NSMutableArray *imageSrc;
@property id<czzArticleProtocol> delegate;
@property BOOL isProcessed;

@property NSMutableArray *htmlFragments;
@property UIViewController *parentViewController;

-(id)initWithJSONData:(NSData*)jsonData andDelegate:(id<czzArticleProtocol>)del;
-(void)processJSONData:(NSData*)jsonData;
-(id)initWithJSONDictonary:(NSDictionary*)jsonDict;
//replace the temporary [IMAGE] anchor in the content to an <img> tag with local inage
-(void)notifyImageDownloaded:(NSString*)imgURL saveTo:(NSString*)savePath;
-(void)stop;
@end

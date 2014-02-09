//
//  czzArticle.h
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzAcUser.h"

@interface czzArticle : NSObject
@property NSInteger acId;
@property NSString *name;
@property NSString *desc;
@property NSString *previewUrl;
@property NSInteger viewCount;
@property NSInteger favouriteCount;
@property NSInteger commentCount;
@property NSDate *createTime;
@property czzAcUser *creator; //TODO: user class
@property BOOL isOriginal;
@property NSArray *tags;
@property NSString *category;
@property NSString *htmlBody;

@property NSArray *articleFragments;

-(id)initWithJSONData:(NSData*)jsonData;
-(id)initWithJSONDictonary:(NSDictionary*)jsonDict;
@end

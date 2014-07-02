//
//  czzComment.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 12/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzAcUser.h"

@interface czzComment : NSObject
@property NSString *content;
@property czzAcUser *user;
@property NSDate *postTime;
@property NSInteger commentID;
@property NSInteger floorIndex;
@property NSArray *refCommentFlow;
@property NSAttributedString *renderedContent;

-(id)initWithJSONDictionary:(NSDictionary*)dict;
-(id)initWithJSONData:(NSData*)data;
-(BOOL)referredToComment:(czzComment*)comment;
@end

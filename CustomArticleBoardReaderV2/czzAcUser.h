//
//  czzAcUser.h
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzAcUser : NSObject
@property NSInteger userID;
@property NSString *name;
@property NSString *avatar;
@property NSString *bio;
@property NSInteger gender;
@property NSString *location;
@property NSString *qq;
@property NSString *phone;

-(id)initWithJSON:(NSDictionary*)dataDict;
@end

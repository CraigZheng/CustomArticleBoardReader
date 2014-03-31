//
//  czzMySelf.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 18/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzAcUser.h"

@interface czzMySelf : czzAcUser
@property NSDate *access_token_expiry_date;
@property NSString *access_token;
@property (nonatomic) NSString *loginStatus;
-(id)initWithAcUser:(czzAcUser*)user access_token:(NSString*)access_token expiry_date:(NSDate*)expiry_date;
@end

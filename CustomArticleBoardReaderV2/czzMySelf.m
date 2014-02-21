//
//  czzMySelf.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 18/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzMySelf.h"

@implementation czzMySelf

-(id)initWithAcUser:(czzAcUser *)user access_token:(NSString *)access_token expiry_date:(NSDate *)expiry_date{
    self = [super init];
    if (self) {
        self.userID = user.userID;
        self.name = user.name;
        self.avatar = user.avatar;
        self.bio = user.bio;
        self.gender = user.gender;
        self.location = user.location;
        self.qq = user.qq;
        self.phone = user.phone;
        self.access_token_expiry_date = expiry_date;
        self.access_token = access_token;
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder{
    [coder encodeInteger:self.userID forKey:@"userID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.avatar forKey:@"avatar"];
    [coder encodeObject:self.bio forKey:@"bio"];
    [coder encodeInteger:self.gender forKey:@"gender"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.qq forKey:@"qq"];
    [coder encodeObject:self.phone forKey:@"phone"];
    [coder encodeObject:self.access_token forKey:@"access_token"];
    [coder encodeObject:self.access_token_expiry_date forKey:@"access_token_expiry_date"];
}

-(id)initWithCoder:(NSCoder*)coder{
    self = [super init];
    if (self){
        self.userID = [coder decodeIntegerForKey:@"userID"];
        self.name = [coder decodeObjectForKey:@"name"];
        self.avatar = [coder decodeObjectForKey:@"avatar"];
        self.bio = [coder decodeObjectForKey:@"bio"];
        self.gender = [coder decodeIntegerForKey:@"gender"];
        self.location = [coder decodeObjectForKey:@"location"];
        self.qq = [coder decodeObjectForKey:@"qq"];
        self.phone = [coder decodeObjectForKey:@"phone"];
        self.access_token_expiry_date = [coder decodeObjectForKey:@"access_token_expiry_date"];
        self.access_token = [coder decodeObjectForKey:@"access_token"];
    }
    return self;
}
@end

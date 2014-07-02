//
//  czzAcUser.m
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzAcUser.h"

@implementation czzAcUser

-(id)init {
    self = [super init];
    if (self) {
        self.userID = -1;
        self.name = @"";
        self.avatar = @"";
        self.bio = @"";
        self.gender = -1;
        self.location = @"";
        self.qq = @"";
        self.phone = @"";
    }
    return self;
}

-(id)initWithJSONDictionary:(NSDictionary *)dataDict{
    self = [super init];
    NSError *error;
    //NSMutableDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error){
        NSLog(@"%@", error);
        return nil;
    }
    if (self){
        self.userID = [[dataDict objectForKey:@"id"] integerValue];
        self.name = [dataDict objectForKey:@"name"];
        self.avatar = [dataDict objectForKey:@"avatar"];
        self.gender = [[dataDict objectForKey:@"gender"] integerValue];
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
    }
    return self;
}
@end

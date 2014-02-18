//
//  czzAcUser.m
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzAcUser.h"

@implementation czzAcUser

-(id)initWithJSONDictionary:(NSDictionary *)dataDict{
    self = [super init];
    NSError *error;
    //NSMutableDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error){
        NSLog(@"%@", error);
        return nil;
    }
    if (self){
        for (NSString *key in dataDict.allKeys) {
            if ([key isEqualToString:@"id"]){
                self.userID = [[dataDict objectForKey:key] integerValue];
            }
            if ([key isEqualToString:@"name"]){
                self.name = [dataDict objectForKey:key];
            }
            if ([key isEqualToString:@"avatar"]){
                self.avatar = [dataDict objectForKey:key];
            }
            if ([key isEqualToString:@"gender"]){
                self.gender = [[dataDict objectForKey:key] integerValue];
            }
        }
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

//
//  czzAcUser.m
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzAcUser.h"

@implementation czzAcUser

-(id)initWithJSON:(NSDictionary *)dataDict{
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
        }
    }

    return self;
}
@end

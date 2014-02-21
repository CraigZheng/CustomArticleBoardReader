//
//  czzComment.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 12/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzComment.h"

@implementation czzComment

-(id)initWithJSONDictionary:(NSDictionary*)dict{
    self = [super init];
    if (self){
        [self assignPropertiesWithJSONDictionary:dict];
    }
    return self;
}

-(id)initWithJSONData:(NSData*)data{
    self = [super init];
    if (self){
        NSError *error;
        NSMutableDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error){
            NSLog(@"%@", error);
            return nil;
        }
        [self assignPropertiesWithJSONDictionary:dataDict];
    }
    return self;
}

-(void)assignPropertiesWithJSONDictionary:(NSDictionary*)dict{
    /*
    for (NSString *key in dict.allKeys) {
        if ([key isEqualToString:@"content"]) {
            self.content = [dict objectForKey:key];
            self.content = [self.content stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
        }
        if ([key isEqualToString:@"user"]){
            czzAcUser *user = [[czzAcUser alloc] initWithJSONDictionary:[dict objectForKey:key]];
            self.user = user;
        }
        if ([key isEqualToString:@"time"]){
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = @"MMM d,yyyy h:m:ss tt";
            self.postTime = [dateFormatter dateFromString:[dict objectForKey:key]];
        }
        if ([key isEqualToString:@"id"]){
            self.commentID = [[dict objectForKey:key] integerValue];
        }
        if ([key isEqualToString:@"floorindex"]){
            self.floorIndex = [[dict objectForKey:key] integerValue];
        }
        if ([key isEqualToString:@"refcommentflow"]){
            NSError *error;
            id refComment = [dict objectForKey:key];
            //id refComment = [NSJSONSerialization JSONObjectWithData:[dict objectForKey:key] options:NSJSONReadingMutableContainers error:&error];
            if (error)
                continue;
            if ([refComment isKindOfClass:[NSArray class]]){
                refComment = (NSArray*)refComment;
                NSMutableArray *tempCommentArray = [NSMutableArray new];
                for (NSDictionary *dict in refComment) {
                    czzComment *refComment = [[czzComment alloc] initWithJSONDictionary:dict];
                    [tempCommentArray addObject:refComment];
                }
                self.refCommentFlow = tempCommentArray;
            } else if ([refComment isKindOfClass:[NSDictionary class]]){
                czzComment *comment = [[czzComment alloc] initWithJSONDictionary:(NSDictionary*)refComment];
                self.refCommentFlow = [NSArray arrayWithObject:comment];
            }
        }
    }
     */
    self.content = [dict objectForKey:@"content"];
    if (self.content)
        self.content = [self.content stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
    self.user = [[czzAcUser alloc] initWithJSONDictionary:[dict objectForKey:@"user"]];
    //post time
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"MMM d,yyyy h:m:ss tt";
    self.postTime = [dateFormatter dateFromString:[dict objectForKey:@"time"]];
    self.commentID = [[dict objectForKey:@"id"] integerValue];
    self.floorIndex = [[dict objectForKey:@"floorindex"] integerValue];
    //ref comment flow
    id refComment = [dict objectForKey:@"refcommentflow"];
    if ([refComment isKindOfClass:[NSArray class]]){
        refComment = (NSArray*)refComment;
        NSMutableArray *tempCommentArray = [NSMutableArray new];
        for (NSDictionary *dict in refComment) {
            czzComment *refComment = [[czzComment alloc] initWithJSONDictionary:dict];
            [tempCommentArray addObject:refComment];
        }
        self.refCommentFlow = tempCommentArray;
    } else if ([refComment isKindOfClass:[NSDictionary class]]){
        czzComment *comment = [[czzComment alloc] initWithJSONDictionary:(NSDictionary*)refComment];
        self.refCommentFlow = [NSArray arrayWithObject:comment];
    }
}
@end

//
//  czzArticle.m
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticle.h"

@implementation czzArticle

-(id)init{
    self = [super init];
    if (self){
        self.tags = [NSArray new];
    }
    return self;
}

-(id)initWithJSONData:(NSData *)jsonData{
    self = [self init];
    NSError *error;
    NSMutableDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error){
        NSLog(@"%@", error);
        return nil;
    }
    [self assignPropertyWithJSONDictonary:dataDict];
    return self;
}

-(id)initWithJSONDictonary:(NSDictionary *)jsonDict{
    self = [self init];
    [self assignPropertyWithJSONDictonary:jsonDict];
    return self;
}

-(void)assignPropertyWithJSONDictonary:(NSDictionary*)dataDict{
    for (NSString *key in dataDict.allKeys) {
        if ([key isEqualToString:@"acId"]){
            self.acId = [[dataDict objectForKey:key] integerValue];
        }
        if ([key isEqualToString:@"name"]){
            self.name = [dataDict objectForKey:key];
        }
        if ([key isEqualToString:@"desc"]){
            self.desc = [dataDict objectForKey:key];
        }
        if ([key isEqualToString:@"previewurl"]){
            self.previewUrl = [dataDict objectForKey:key];
        }
        if ([key isEqualToString:@"viewernum"]){
            self.viewCount = [[dataDict objectForKey:key] integerValue];
        }
        if ([key isEqualToString:@"collectnum"]){
            self.favouriteCount = [[dataDict objectForKey:key] integerValue];
        }
        if ([key isEqualToString:@"commentnuminvideo"]){
            self.commentCount = [[dataDict objectForKey:key] integerValue];
        }
        if ([key isEqualToString:@"createtime"]){
            self.createTime = [NSDate dateWithTimeIntervalSince1970:1366965794000];
        }
        if ([key isEqualToString:@"creator"]){
            self.creator = [[czzAcUser alloc] initWithJSON:[dataDict objectForKey:key]];
        }
        if ([key isEqualToString:@"isoriginal"]){
            self.isOriginal = [[dataDict objectForKey:key] boolValue];
        }
        if ([key isEqualToString:@"tags"]){
            self.tags = [dataDict objectForKey:key];
        }
        if ([key isEqualToString:@"category"]){
            self.category = [dataDict objectForKey:key];
        }
        if ([key isEqualToString:@"txt"]){
            self.htmlBody = [dataDict objectForKey:key];
            self.htmlBody = [self extractImgTags:self.htmlBody];
        }
    }
}

-(NSString*)extractImgTags:(NSString*)htmlBody{
    /*
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [linkDetector matchesInString:htmlBody
                                             options:0
                                               range:NSMakeRange(0, htmlBody.length)];
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [match URL];
            if ([url.absoluteString hasSuffix:@"jpg"] || [url.absoluteString hasSuffix:@"jpeg"] || [url.absoluteString hasSuffix:@"gif"] || [url.absoluteString hasSuffix:@"png"]){
                NSLog(@"%@", url.absoluteString);
            }
        }
    }
    NSRange imgTagBegin = [htmlBody rangeOfString:@"<img" options:NSCaseInsensitiveSearch];
    while (imgTagBegin.location != NSNotFound) {
        NSRange imgTagEnd = [htmlBody rangeOfString:@"/>" options:NSCaseInsensitiveSearch range:NSMakeRange(imgTagBegin.location, htmlBody.length - imgTagBegin.location)];
        if (imgTagEnd.location != NSNotFound) {
            NSLog(@"%@", [htmlBody substringWithRange:NSMakeRange(imgTagBegin.location, imgTagEnd.location + imgTagEnd.length)]);
            [htmlBody stringByReplacingCharactersInRange:NSMakeRange(imgTagBegin.location, imgTagEnd.location + imgTagEnd.length) withString:@"%^$&*(&"];
        }
        //next image tag begin
        imgTagBegin = [htmlBody rangeOfString:@"<img" options:NSCaseInsensitiveSearch];
    }
    
    return htmlBody;
     */
    
    NSMutableArray *level3Fragments = [NSMutableArray new];
    NSArray *level1Fragments = [htmlBody componentsSeparatedByString:@"<img"];
    for (NSString *l1fragment in level1Fragments) {
        NSArray *level2fragments = [l1fragment componentsSeparatedByString:@"/>"];
        for (NSString *l2fragment in level2fragments) {
            NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
            NSArray *matches = [linkDetector matchesInString:l2fragment
                                                     options:0
                                                       range:NSMakeRange(0, l2fragment.length)];

            if (matches.count <= 0)
                [level3Fragments addObject:l2fragment];
            else {
                for (NSTextCheckingResult *match in matches) {
                    if ([match resultType] == NSTextCheckingTypeLink) {
                        NSURL *url = [match URL];
                        if ([url.absoluteString hasSuffix:@"jpg"] || [url.absoluteString hasSuffix:@"jpeg"] || [url.absoluteString hasSuffix:@"gif"] || [url.absoluteString hasSuffix:@"png"]){
                            //change URL scheme to custom action
                            NSString *newAction = [@"action:" stringByAppendingString:url.absoluteString];
                            newAction = [self embedURLIntoAnchor:newAction];
                            [level3Fragments addObject:newAction];

                        }
                    }
                }
                
            }
        }
    }
    /*
    NSMutableString *newHtmlBody = [NSMutableString new];
    NSInteger i = 0;
    if ([htmlBody hasPrefix:@"<img"])
        i = 1;
    for (NSString *l3fragment in level3Fragments) {
        if (i % 2 == 0)
            [newHtmlBody appendString:l3fragment];
        i++;
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *matches = [linkDetector matchesInString:l3fragment
                                                 options:0
                                                   range:NSMakeRange(0, l3fragment.length)];
        for (NSTextCheckingResult *match in matches) {
            if ([match resultType] == NSTextCheckingTypeLink) {
                NSURL *url = [match URL];
                if ([url.absoluteString hasSuffix:@"jpg"] || [url.absoluteString hasSuffix:@"jpeg"] || [url.absoluteString hasSuffix:@"gif"] || [url.absoluteString hasSuffix:@"png"]){
                    NSLog(@"%@", url.absoluteString);
                }
            }
        }
     
    }
    
    return newHtmlBody;
     */
    NSMutableString *newHtmlBody = [NSMutableString new];
    for (NSString *l3Fragment in level3Fragments) {
        [newHtmlBody appendString:l3Fragment];
    }
    self.articleFragments = level3Fragments;
    return newHtmlBody;
}

-(NSString*)embedURLIntoAnchor:(NSString*)url{
    NSString *aString = [NSString stringWithFormat:@"</p><a href=%@ >[IMAGE]</a><br>", url];
    return aString;
}
@end

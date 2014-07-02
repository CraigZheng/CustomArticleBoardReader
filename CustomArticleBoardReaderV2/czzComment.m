//
//  czzComment.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 12/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzComment.h"
#import "NSAttributedString+HTML.h"
#import "czzAppDelegate.h"

@implementation czzComment

-(id)init {
    self = [super init];
    
    if (self) {
        self.user = [czzAcUser new];
        self.content = @"";
        self.renderedContent = [[NSAttributedString alloc] initWithString:@""];
        self.floorIndex = -1;
        self.refCommentFlow = nil;
        self.commentID = -1;
        self.postTime = [NSDate new];
    }
    return self;
}

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
    self.content = [dict objectForKey:@"content"];
    if (self.content) {
        self.content = [self.content stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
        self.renderedContent = [self renderHTMLTags:self.content :[czzAppDelegate sharedAppDelegate].emotionDictionary :[UIFont systemFontOfSize:14]];
    }
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

#pragma mark - render image tags, font color etc.
- (NSAttributedString*)renderHTMLTags:(NSString *)originalText :(NSDictionary*)emoDict :(UIFont*)font{
    
    NSDictionary *emotions = emoDict;
    NSString *text = [originalText mutableCopy];
    
    NSString *replaced;
    NSMutableString *formatedResponse = [NSMutableString string];
    
    NSScanner *emotionScanner = [NSScanner scannerWithString:text];
    [emotionScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    while ([emotionScanner isAtEnd] == NO) {
        
        if([emotionScanner scanUpToString:@"[" intoString:&replaced]) {
            [formatedResponse appendString:replaced];
        }
        if(![emotionScanner isAtEnd]) {
            [emotionScanner scanString:@"[" intoString:nil];
            replaced = @"";
            [emotionScanner scanUpToString:@"]" intoString:&replaced];
            NSString *em = [emotions valueForKey:replaced];
            if (em) {
                [formatedResponse appendFormat:@"<img src='%@' />", em];
            } else {
                //remove [] tags
                [formatedResponse appendString:@""];
//                [formatedResponse appendFormat:@"[%@]", replaced];
            }
            
            [emotionScanner scanString:@"]" intoString:nil];
        }
    }
    
    //render emotion tags
    [formatedResponse replaceOccurrencesOfString:@"\n" withString:@"<br />" options:0 range:NSMakeRange(0, formatedResponse.length)];
    NSString *stringWithEmotionTags = [NSString stringWithFormat:@"<p style='font-size:%fpt'>%@</p>", font.pointSize, formatedResponse];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:/*CGSizeMake(_font.lineHeight, _font.lineHeight)*/CGSizeMake(50, 50)], DTMaxImageSize, @"System", DTDefaultFontFamily, nil];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithHTML:[stringWithEmotionTags dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
    if (string.length <= 0) {
        string = [[NSMutableAttributedString alloc] initWithString:self.content];
    }
    return string;
}

-(BOOL)referredToComment:(czzComment *)comment {
    BOOL reffered = NO;
    for (czzComment *refComment in self.refCommentFlow) {
        if (refComment.commentID == comment.commentID) {
            reffered = YES;
            break;
        }
    }
    return reffered;
}

@end

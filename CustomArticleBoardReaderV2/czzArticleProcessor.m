//
//  czzArticleProcessor.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 22/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticleProcessor.h"
#import "NSString+HTML.h"

@interface czzArticleProcessor()
@property NSString *htmlBody;
@property NSMutableArray *htmlFragments;
@end

@implementation czzArticleProcessor
@synthesize article;
@synthesize delegate;
@synthesize htmlBody;
@synthesize htmlFragments;

-(id)initWithArticle:(czzArticle *)arty andHTMLBody:(NSString *)html andDelegate:(id<czzArticleProcessorDelegate>)del{
    self = [super init];
    if (self) {
        delegate = del;
        htmlBody = html;
        article = arty;
        htmlFragments = [NSMutableArray new];
        article.htmlFragments = htmlFragments;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDate *startTime = [NSDate new];
            [self prepareHTMLForFragments:htmlBody];
            NSLog(@"Total process time: %fsecond", [[NSDate new] timeIntervalSinceDate:startTime]);
        });
    }
    return self;
}


-(NSArray*)prepareHTMLForFragments:(NSString*)htmlString{
    NSRange r;
    //remove everything between < and >
//    htmlFragments = [NSMutableArray new];
    while ((r = [htmlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        @autoreleasepool {
            NSString *subString = [htmlString substringWithRange:r];
            NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
            NSArray *matches = [linkDetector matchesInString:subString
                                                     options:0
                                                       range:NSMakeRange(0, subString.length)];
            NSString *matchedParagraph;
            if (matches.count > 0){
                for (NSTextCheckingResult *match in matches) {
                    if ([match resultType] == NSTextCheckingTypeLink) {
                        NSURL *url = [match URL];
                        if ([url.absoluteString.lastPathComponent rangeOfString:@"jpg" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                            [url.absoluteString.lastPathComponent rangeOfString:@"jpeg" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                            [url.absoluteString.lastPathComponent rangeOfString:@"gif" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                            [url.absoluteString.lastPathComponent rangeOfString:@"png"options:NSCaseInsensitiveSearch].location != NSNotFound){
                            BOOL inserted = NO;
                            for (NSInteger i = 0; i < htmlFragments.count; i++) {
                                id fragment = [htmlFragments objectAtIndex:i];
                                if ([fragment isKindOfClass:[NSURL class]] && [[(NSURL*)fragment absoluteString].lastPathComponent isEqualToString:url.absoluteString.lastPathComponent]){
                                    [htmlFragments replaceObjectAtIndex:[htmlFragments indexOfObject:fragment] withObject:url];
                                    inserted = YES;
                                    break;
                                }
                            }
                            if (!inserted)
                                [htmlFragments addObject:url];
                        }
                    }
                }
            } else if ([subString hasPrefix:@"<img"]){
                NSString *emoconURL = [self extractString:subString toLookFor:@"\"" skipForwardX:1 toStopBefore:@"\""];
                emoconURL = [emoconURL stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                if (emoconURL.length > 0 && [emoconURL rangeOfString:@"emotion"].location != NSNotFound)
                {
                    NSString *emoURLString = [NSString stringWithFormat:@"http://www.acfun.tv%@", emoconURL];
                    NSURL *emoURL = [NSURL URLWithString:emoURLString];
                    if (emoURL)
                        [htmlFragments addObject:emoURL];
                }
                
            }
            if ([subString rangeOfString:@"<p"].location != NSNotFound ||
                [subString rangeOfString:@"</p"].location != NSNotFound ||
                [subString rangeOfString:@"<br"].location != NSNotFound)
            {
                matchedParagraph = [htmlString substringToIndex:r.location];
                NSString *processedParagraph = [[matchedParagraph stringByDecodingHTMLEntities] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (processedParagraph.length > 0)
                {
                    [htmlFragments addObject:processedParagraph];
                }
            }
            htmlString = [htmlString stringByReplacingCharactersInRange:r withString:@""];
            if (matchedParagraph.length > 0){
                htmlString = [htmlString stringByReplacingOccurrencesOfString:matchedParagraph withString:@""];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(articleUpdated:isFinished:)]) {
                [self.delegate articleUpdated:article isFinished:NO];
            }
        }
    }
    NSString *processedString = htmlString = [[htmlString stringByDecodingHTMLEntities] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (processedString.length > 0){
        [htmlFragments addObject:processedString];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(articleUpdated:isFinished:)]) {
        [self.delegate articleUpdated:article isFinished:YES];
    }

    return htmlFragments;
}


- (NSString*)extractString:(NSString *)fullString toLookFor:(NSString *)lookFor skipForwardX:(NSInteger)skipForward toStopBefore:(NSString *)stopBefore
{
    NSRange firstRange = [fullString rangeOfString:lookFor];
    if (firstRange.location != NSNotFound) {
        NSRange secondRange = [[fullString substringFromIndex:firstRange.location + skipForward] rangeOfString:stopBefore];
        if (secondRange.location != NSNotFound) {
            NSRange finalRange = NSMakeRange(firstRange.location + skipForward, secondRange.location + [stopBefore length]);
            return [fullString substringWithRange:finalRange];
        }
    }
    return nil;
}


@end

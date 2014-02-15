//
//  czzArticle.m
//  CustomArticleBoardReader
//
//  Created by Craig on 24/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticle.h"
#import "czzAppDelegate.h"

#define RANDOM_STRING @"%$^&^$%2$%^&%7#!@#^%#&#*"

@interface czzArticle()
@property NSMutableArray *paragraphTags;
@property NSMutableArray *imageTags;
@end

@implementation czzArticle
@synthesize paragraphTags;
@synthesize imageTags;

-(id)init{
    self = [super init];
    if (self){
        self.tags = [NSArray new];
        self.imageSrc = [NSMutableArray new];
        self.name = @"无题";
        self.desc = @"无简介";
        paragraphTags = [NSMutableArray new];
        imageTags = [NSMutableArray new];
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
            self.desc = [self.desc stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
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
        if ([key isEqualToString:@"commentnum"]){
            self.commentCount = [[dataDict objectForKey:key] integerValue];
        }
        if ([key isEqualToString:@"createtime"]){
            self.createTime = [NSDate dateWithTimeIntervalSince1970:[[dataDict objectForKey:key] longValue]];
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
            self.htmlBody = [self prepareHTMLForBetterVisual:self.htmlBody];
        }
    }
}

#pragma mark - prepareHTMLForBetterVisual will remove the old formatting, and re-apply some simple html format for better visual on a mobile device
/*
 this function will remove everything between < > except </p> and <img>
 <p> and <img> will be preseved for better formatting and image broswing
 */
-(NSString*)prepareHTMLForBetterVisual:(NSString*)oldHTML{
    oldHTML = [self replaceParagraphyTagsAndBrTags:oldHTML];
    oldHTML = [self extractImgTags:oldHTML];
    oldHTML = [self stringByApplyingSimpleHTMLFormat:oldHTML];
    oldHTML = [self repopulateParagraphyTagsAndImageTags:oldHTML];
    return oldHTML;
}

-(NSString *)stringByApplyingSimpleHTMLFormat:(NSString*)htmlString {
    NSRange r;
    //remove everything between < and >
    while ((r = [htmlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        htmlString = [htmlString stringByReplacingCharactersInRange:r withString:@""];
    NSString *newHTMLString = [NSString stringWithFormat:@"<html> \n"
                                   "<head> \n"
                                   "<style type=\"text/css\"> \n"
                                   "body {font-family: \"%@\"; font-size: %@; width:100%% ;padding:0px; margin:0px;}\n"
                                   "</style> \n"
                                   "</head> \n"
                                   "<body>%@</body> \n"
                                   "</html>", @"helvetica", [NSNumber numberWithInt:16], htmlString];

    return newHTMLString;
}

-(NSString*)replaceParagraphyTagsAndBrTags:(NSString*)htmlBody{
    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"</p>" withString:[self embedString:@"PARAGRAPH TAG" withString:RANDOM_STRING]];
    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"<br/>" withString:[self embedString:@"BR TAG" withString:RANDOM_STRING]];
    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"<br />" withString:[self embedString:@"BR TAG" withString:RANDOM_STRING]];
    return htmlBody;
}

-(NSString*)extractImgTags:(NSString*)htmlBody{
    //NSString *tempString = [self stringBetweenString:@"<img" andString:@"/>" withstring:htmlBody];
    NSString *imgTag = [self extractString:htmlBody toLookFor:@"<img" skipForwardX:0 toStopBefore:@"/>"];
    NSInteger maximumTry = 999;
    while (imgTag != nil && maximumTry >0) {
        //to avoid loop lock
        maximumTry--;
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *matches = [linkDetector matchesInString:imgTag
                                                 options:0
                                                   range:NSMakeRange(0, imgTag.length)];
        if (matches.count > 0){
            for (NSTextCheckingResult *match in matches) {
                if ([match resultType] == NSTextCheckingTypeLink) {
                    NSURL *url = [match URL];
                    if ([url.absoluteString.lastPathComponent rangeOfString:@"jpg" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                        [url.absoluteString.lastPathComponent rangeOfString:@"jpeg" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                        [url.absoluteString.lastPathComponent rangeOfString:@"gif" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                        [url.absoluteString.lastPathComponent rangeOfString:@"png"options:NSCaseInsensitiveSearch].location != NSNotFound){
                        //change URL scheme to mark string for later process
                        //NSString *imgInTag = [self embedURLIntoAnchor:url.absoluteString];
                        NSString *imgMark = [self embedString:url.absoluteString withString:RANDOM_STRING];
                        [self.imageSrc addObject:url.absoluteString];
                        htmlBody = [htmlBody stringByReplacingOccurrencesOfString:imgTag withString:imgMark];
                    }
                }
            }
        } else {
            
            NSString *emoconURL = [self extractString:imgTag toLookFor:@"\"" skipForwardX:1 toStopBefore:@"\""];
            if (emoconURL.length > 0 && [emoconURL rangeOfString:@"emotion"].location != NSNotFound)
            {
                htmlBody = [htmlBody stringByReplacingOccurrencesOfString:emoconURL withString:[NSString stringWithFormat:@"\"http://www.acfun.tv%@", emoconURL]];
            }
        }
        imgTag = [self extractString:htmlBody toLookFor:@"<img" skipForwardX:0 toStopBefore:@"/>"];
    }
    return htmlBody;
}

-(NSString*)embedString:(NSString*)originalString withString:(NSString*)string
{
    originalString = [string stringByAppendingString:originalString];
    originalString = [originalString stringByAppendingString:string];
    return originalString;
}

//use this function at last to repopulate marked p tags and image tags
-(NSString*)repopulateParagraphyTagsAndImageTags:(NSString*)htmlString{
    //p tags
    NSString *markedPTags = [self embedString:@"PARAGRAPH TAG" withString:RANDOM_STRING];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:markedPTags withString:@"</p>"];
    //br tags
    htmlString = [htmlString stringByReplacingOccurrencesOfString:[self embedString:@"BR TAG" withString:RANDOM_STRING] withString:@"<br/>"];
    //img tags
    for (NSString *imgURLString in self.imageSrc) {
        NSString *markedImgURLString = [self embedString:imgURLString withString:RANDOM_STRING];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:markedImgURLString withString:[self embedURLIntoAnchor:imgURLString]];
    }
    return htmlString;
}

-(NSString*)embedURLIntoAnchor:(NSString*)url{
    NSString *imgSrc = [@"action:" stringByAppendingString:url];
    NSString *aString = [NSString stringWithFormat:@"</p><a href=%@ >[[点我下载图片]]</a><br>", imgSrc];
    return aString;
}

-(void)notifyImageDownloaded:(NSString *)imgURL saveTo:(NSString *)savePath{
    NSString *imgTagInBody = [self embedURLIntoAnchor:imgURL];
    NSString *localImageInImgTag = [self readyLocalImageForUIWebView:savePath];
    if (localImageInImgTag.length > 0){
        self.htmlBody = [self.htmlBody stringByReplacingOccurrencesOfString:imgTagInBody withString:localImageInImgTag];
    }
}

-(NSString*)readyLocalImageForUIWebView:(NSString*)localImagePath {
    //example : <img src="smiley.gif" height="42" width="42">
    UIImage *image = [UIImage imageWithContentsOfFile:localImagePath];
    if (!image)
        return nil;
    //shrink the image accordingly
    NSInteger width = image.size.width;
    NSInteger heigth = image.size.height;
    if (image.size.width > [czzAppDelegate sharedAppDelegate].window.frame.size.width)
    {
        width = [czzAppDelegate sharedAppDelegate].window.frame.size.width;
        heigth = width / image.size.width * heigth;
    }
    NSString *imgTagString = [NSString stringWithFormat:@"<a href=\"openfile:%@\" ><img src=\"file://%@\" width=\"%ld\" height=\"%ld\" align=\"left\" /></a></p>", localImagePath, localImagePath, (long)width, (long)heigth];
    //NSString *imgTagString = [NSString stringWithFormat:@"<img src=\"file:/%@\" width=\"280\" height=\"320\" />", localImagePath];
    return imgTagString;
}

- (NSString *)extractString:(NSString *)fullString toLookFor:(NSString *)lookFor skipForwardX:(NSInteger)skipForward toStopBefore:(NSString *)stopBefore
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

#pragma mark - encoder and decoder - for storing this object into the storage
- (void) encodeWithCoder: (NSCoder *) coder
{
    [coder encodeInteger:self.acId forKey:@"acId"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.desc forKey:@"desc"];
    [coder encodeObject:self.previewUrl forKey:@"previewUrl"];
    [coder encodeInteger:self.viewCount forKey:@"viewCount"];
    [coder encodeInteger:self.favouriteCount forKey:@"favouriteCount"];
    [coder encodeInteger:self.commentCount forKey:@"commentCount"];
    [coder encodeObject:self.createTime forKey:@"createTime"];
    [coder encodeObject:self.creator forKey:@"creator"];
    [coder encodeBool:self.isOriginal forKey:@"isOriginal"];
    [coder encodeObject:self.tags forKey:@"tags"];
    [coder encodeObject:self.category forKey:@"category"];
    [coder encodeObject:self.htmlBody forKey:@"htmlBody"];
    [coder encodeObject:self.imageSrc forKey:@"imageSrc"];
}

- (id) initWithCoder: (NSCoder *) coder
{
    self = [self init];
    if (self){
        self.acId = [coder decodeIntegerForKey:@"acId"];
        self.name = [coder decodeObjectForKey:@"name"];
        self.desc = [coder decodeObjectForKey:@"desc"];
        self.previewUrl = [coder decodeObjectForKey:@"previewUrl"];
        self.viewCount = [coder decodeIntegerForKey:@"viewCount"];
        self.favouriteCount = [coder decodeIntegerForKey:@"favouriteCount"];
        self.commentCount = [coder decodeIntegerForKey:@"commentCount"];
        self.createTime = [coder decodeObjectForKey:@"createTime"];
        self.creator = [coder decodeObjectForKey:@"creator"];
        self.isOriginal = [coder decodeBoolForKey:@"isOriginal"];
        self.tags = [coder decodeObjectForKey:@"tags"];
        self.category = [coder decodeObjectForKey:@"category"];
        self.htmlBody = [coder decodeObjectForKey:@"htmlBody"];
        self.imageSrc = [coder decodeObjectForKey:@"imageSrc"];
    }
    return self;
}

@end

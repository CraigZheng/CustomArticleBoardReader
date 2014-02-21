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
@synthesize htmlFragments;

-(id)init{
    self = [super init];
    if (self){
        self.tags = [NSArray new];
        self.imageSrc = [NSMutableArray new];
        self.name = @"无题";
        self.desc = @"无简介";
        paragraphTags = [NSMutableArray new];
        imageTags = [NSMutableArray new];
        htmlFragments = [NSMutableArray new];
        
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

    self.acId = [[dataDict objectForKey:@"acId"] integerValue];
    self.name = [dataDict objectForKey:@"name"];
    self.desc = [dataDict objectForKey:@"desc"];
    if (self.desc)
        self.desc = [self.desc stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    self.previewUrl = [dataDict objectForKey:@"previewurl"];
    self.viewCount = [[dataDict objectForKey:@"viewernum"] integerValue];
    self.favouriteCount = [[dataDict objectForKey:@"collectnum"] integerValue];
    self.commentCount = [[dataDict objectForKey:@"commentnum"] integerValue];
    self.createTime = [NSDate dateWithTimeIntervalSince1970:[[dataDict objectForKey:@"createtime"] doubleValue] / 1000];
    self.creator = [[czzAcUser alloc] initWithJSONDictionary:[dataDict objectForKey:@"creator"]];
    self.isOriginal = [[dataDict objectForKey:@"isOriginal"] boolValue];
    self.tags = [dataDict objectForKey:@"tags"];
    self.category = [dataDict objectForKey:@"category"];
    self.htmlBody = [dataDict objectForKey:@"txt"];
    if (self.htmlBody){
        self.htmlBody = [self prepareHTMLForBetterVisual:self.htmlBody];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUseExperimentalBrowser"]) {
            NSArray *fragments = [self prepareHTMLForFragments:[dataDict objectForKey:@"txt"]];
            [self.htmlFragments addObjectsFromArray:fragments];
        }
    }
}

#pragma mark - prepareHTMLForBetterVisual will remove the old formatting, and re-apply some simple html format for better visual on a mobile device
/*
 this function will remove everything between < > except </p> and <img>
 <p> and <img> will be preseved for better formatting and image broswing
 */
-(NSString*)prepareHTMLForBetterVisual:(NSString*)oldHTML{
    oldHTML = [self markFormattingTags:oldHTML];
    oldHTML = [self extractImgTags:oldHTML];
    oldHTML = [self stringByApplyingSimpleHTMLFormat:oldHTML];
    oldHTML = [self repopulateFormattingTagsAndImageTags:oldHTML];
    return oldHTML;
}

-(NSMutableArray*)prepareHTMLForFragments:(NSString*)oldHtml{
    NSMutableArray *fragments = [NSMutableArray new];
    oldHtml = [self markFormattingTags:oldHtml];
    //--- IMG TAG
    NSString *imgTag = [self extractString:oldHtml toLookFor:@"<img" skipForwardX:0 toStopBefore:@">"];
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
                        //NSString *imgMark = [self embedString:url.absoluteString withString:RANDOM_STRING];
                        oldHtml = [oldHtml stringByReplacingOccurrencesOfString:imgTag withString:url.absoluteString];
                    }
                }
            }
        } else {
            
            NSString *emoconURL = [self extractString:imgTag toLookFor:@"\"" skipForwardX:1 toStopBefore:@"\""];
            if (emoconURL.length > 0 && [emoconURL rangeOfString:@"emotion"].location != NSNotFound)
            {
                oldHtml = [oldHtml stringByReplacingOccurrencesOfString:emoconURL withString:[NSString stringWithFormat:@"\"http://www.acfun.tv%@", emoconURL]];
            }
        }
        imgTag = [self extractString:oldHtml toLookFor:@"<img" skipForwardX:0 toStopBefore:@">"];
    }
    //--- END IMG TAG
    NSRange r;
    //remove everything between < and >
    while ((r = [oldHtml rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        oldHtml = [oldHtml stringByReplacingCharactersInRange:r withString:@""];
    NSArray *pass1 = [oldHtml componentsSeparatedByString:[self embedString:@"PARAGRAPH TAG" withString:RANDOM_STRING]];
    NSMutableArray *pass2 = [NSMutableArray new];
    for (NSString *p1Frag in pass1) {
        NSArray *tempP2 = [p1Frag componentsSeparatedByString:[self embedString:@"BR TAG" withString:RANDOM_STRING]];
        [pass2 addObjectsFromArray:tempP2];
    }
    NSMutableOrderedSet *pass3 = [NSMutableOrderedSet new];
    for (NSString *imgSrc in self.imageSrc){
        for (NSString* p2Frag in pass2){
            NSArray *tempP3 = [p2Frag componentsSeparatedByString:imgSrc];
            if (tempP3.count > 1){
                //it doesn't contain the given image mark, add itself
                [pass3 addObject:p2Frag];
                for (NSString *tempString in tempP3) {
                    if (tempString.length == 0)
                        [pass3 addObject:imgSrc];
                    else
                        [pass3 addObject:tempString];
                }
            } else {
                [pass3 addObject:tempP3[0]];
            }
        }
    }
    for (NSString* fragment in pass3.array) {
        if (fragment.length != 0) {
            [fragments addObject:[fragment stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
        }
    }
    return fragments;
}

-(NSString *)stringByApplyingSimpleHTMLFormat:(NSString*)htmlString {
    NSRange r;
    //remove everything between < and >
    while ((r = [htmlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        htmlString = [htmlString stringByReplacingCharactersInRange:r withString:@""];
    NSString *newHTMLString = [NSString stringWithFormat:@"<html> \n"
                                   "<head> \n"
                                   "<style type=\"text/css\"> \n"
                                   "body {font-family: \"%@\"; font-size: %@; width:100%% ;padding:0px; margin:0px; word-wrap: break-word;}\n"
                                   "</style> \n"
                                   "</head> \n"
                                   "<body>%@</body> \n"
                                   "</html>", @"helvetica", [NSNumber numberWithInt:16], htmlString];

    return newHTMLString;
}

-(NSString*)markFormattingTags:(NSString*)htmlBody{
    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"</p>" withString:[self embedString:@"PARAGRAPH TAG" withString:RANDOM_STRING]];
    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"<br" withString:[[self embedString:@"BR TAG" withString:RANDOM_STRING] stringByAppendingString:@"<+"]];
    htmlBody = [htmlBody stringByReplacingOccurrencesOfString:@"<div" withString:[[self embedString:@"BR TAG" withString:RANDOM_STRING] stringByAppendingString:@"<+"]];
    return htmlBody;
}

-(NSString*)extractImgTags:(NSString*)htmlBody{
    NSString *imgTag = [self extractString:htmlBody toLookFor:@"<img" skipForwardX:0 toStopBefore:@">"];
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
        imgTag = [self extractString:htmlBody toLookFor:@"<img" skipForwardX:0 toStopBefore:@">"];
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
-(NSString*)repopulateFormattingTagsAndImageTags:(NSString*)htmlString{
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
    //change scheme of URL to action in order to allow webview to catch it
    NSString *imgSrc = [@"action:" stringByAppendingString:url];
    NSString *aString = [NSString stringWithFormat:@"<br><a href=%@>[[点我下载图片]]</a>", imgSrc];
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
    CGFloat widthOfWindow = self.parentViewController.view.frame.size.width;
    if (image.size.width > widthOfWindow)
    {
        width = widthOfWindow;
        heigth = width / image.size.width * heigth;
    }
    NSString *imgTagString = [NSString stringWithFormat:@"<br><a href=\"openfile:%@\" ><img src=\"file://%@\" width=\"%ld\" height=\"%ld\" align=\"center\" /></a>", localImagePath, localImagePath, (long)width, (long)heigth];
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

#pragma mark - getter for getting the htmlBodyWithouImage
-(NSString *)htmlBodyWithouImage{
    NSString *newHtmlBody = [NSString stringWithString:self.htmlBody];
    if (newHtmlBody){
        newHtmlBody = [self markFormattingTags:newHtmlBody];
        newHtmlBody = [self stringByApplyingSimpleHTMLFormat:newHtmlBody];
        newHtmlBody = [self repopulateFormattingTagsAndImageTags:newHtmlBody];
    }
    return newHtmlBody;
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

//
//  EmotionLabel.m
//  Jacky <newbdez33@gmail.com>
//
//  Created by Jacky on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EmotionLabel.h"

@implementation EmotionLabel

@synthesize orignText = _orignText;
@synthesize text = _text;
@synthesize font = _font;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
    }
    return self;
}

- (NSDictionary *)getEmotions {
    static NSDictionary *ems;
    if (!ems) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"emotions" ofType:@"plist"];
        ems = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    }
    
    return ems;
    
}

- (void)setText:(NSString *)text {
    
    emotions = [self getEmotions];
    //NSLog(@"emotions: %@", emotions);
    
    _orignText = text;
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
            //TODOif replace contains '[' then reset scanner location to this newer '[' and scan again.
//            UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", replaced]];
//            if (img) {
//                NSString *base64Image = [UIImagePNGRepresentation(img) base64String];
//                [formatedResponse appendFormat:@"<img src='data:image/png;base64,%@' />", base64Image];
            NSString *em = [emotions valueForKey:replaced];
            if (em) {
                [formatedResponse appendFormat:@"<img src='%@' />", em];
            }else {
                [formatedResponse appendFormat:@"[%@]", replaced];
            }

            [emotionScanner scanString:@"]" intoString:nil];
        }
        
    }
    
    //NSLog(@"formatedResponse: %@", formatedResponse);
    [formatedResponse replaceOccurrencesOfString:@"\n" withString:@"<br />" options:0 range:NSMakeRange(0, formatedResponse.length)];
    NSData *data = [[NSString stringWithFormat:@"<p style='font-size:%fpt'>%@</p>", _font.pointSize, formatedResponse] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:CGSizeMake(_font.lineHeight, _font.lineHeight)], DTMaxImageSize, @"System", DTDefaultFontFamily, nil];
    NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL];
    self.attributedString = string;

}

@end

//
//  EmotionLabel.h
//  Jacky <newbdez33@gmail.com>
//
//  Created by Jacky on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTAttributedTextContentView.h"

@interface EmotionLabel : DTAttributedTextContentView {
    NSDictionary *emotions;
}

@property (nonatomic ,strong) NSString *text;
@property (nonatomic ,strong) NSString *orignText;
@property (nonatomic ,strong) UIFont *font;

@end

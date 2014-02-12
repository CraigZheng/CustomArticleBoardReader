//
//  czzAdTableViewCell.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADBannerView.h"

@interface czzAdTableViewCell : UITableViewCell
@property GADBannerView *bannerView_;
@property (nonatomic) UIViewController *parentViewController;
@end

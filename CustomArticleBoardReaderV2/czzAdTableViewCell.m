//
//  czzAdTableViewCell.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzAdTableViewCell.h"

@implementation czzAdTableViewCell
@synthesize bannerView_;
@synthesize parentViewController;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        //admob module
        bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        bannerView_.adUnitID = @"a151ef285f8e0dd";

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setParentViewController:(UIViewController *)parent{
    parentViewController = parent;
    bannerView_.rootViewController = self.parentViewController;
    [bannerView_ setFrame:CGRectMake(0, self.bounds.size.height, bannerView_.bounds.size.width,
                                     bannerView_.bounds.size.height)];
    //[bannerView_ loadRequest:[GADRequest request]];
}

@end

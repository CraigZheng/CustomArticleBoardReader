//
//  czzArticleDescriptionViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 16/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticleDescriptionViewController.h"

@interface czzArticleDescriptionViewController ()

@end

@implementation czzArticleDescriptionViewController
@synthesize myArticle;
@synthesize infoLabel;
@synthesize descLabel;
@synthesize titleLabel;
@synthesize parentViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //info: author, date and category
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy MMM-dd, hh:mm";
    NSString *dateString = [dateFormatter stringFromDate:myArticle.createTime];
    NSString *infoString = [NSString stringWithFormat:@"By %@, 评论：%d 点击：%d, %@", myArticle.creator.name, myArticle.commentCount, myArticle.viewCount, dateString];
    infoLabel.text = infoString;
    descLabel.text = myArticle.desc;
    titleLabel.text = myArticle.name;
    [self recalculateFrame:self.interfaceOrientation];
}

-(void)recalculateFrame:(UIInterfaceOrientation)interfaceOrientation{
    //calculate frame
    CGRect frame = CGRectMake(0, 0, parentViewController.view.frame.size.width, 1);
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        frame = CGRectMake(0, 0, parentViewController.view.frame.size.height, 1);
    }
    CGFloat height1 = titleLabel.frame.origin.y + titleLabel.intrinsicContentSize.height;
    CGFloat height2 = infoLabel.frame.origin.y + infoLabel.intrinsicContentSize.height;
    CGFloat height3 = descLabel.frame.origin.y + descLabel.intrinsicContentSize.height;
    frame.size.height = height1 + height2 + height3 - (parentViewController.navigationController.navigationBar.frame.size.height + parentViewController.navigationController.navigationBar.frame.origin.y);
    self.view.frame = frame;
}

@end

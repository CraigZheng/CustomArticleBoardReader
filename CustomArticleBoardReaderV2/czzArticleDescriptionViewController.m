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
    NSString *infoString = [NSString stringWithFormat:@"By %@, 评论：%ld 点击：%ld, %@", myArticle.creator.name, (long)myArticle.commentCount, (long)myArticle.viewCount, dateString];
    infoLabel.text = infoString;
    descLabel.text = myArticle.desc;
    titleLabel.text = myArticle.name;
    [self layoutTextViewsForInterfaceOrientation:self.interfaceOrientation];
}

//layout the views according to interface orientation
-(void)layoutTextViewsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    //calculate frame
    CGRect frame;;
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, 1);
    } else
        frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1);
    titleLabel.preferredMaxLayoutWidth = frame.size.width;
    CGFloat height1 = titleLabel.frame.origin.y + titleLabel.intrinsicContentSize.height;
    infoLabel.preferredMaxLayoutWidth = frame.size.width;
    CGFloat height2 = infoLabel.frame.origin.y + infoLabel.intrinsicContentSize.height;
    descLabel.preferredMaxLayoutWidth = frame.size.width;
    CGFloat height3 = descLabel.frame.origin.y + descLabel.intrinsicContentSize.height;
    CGFloat height4 = (UIInterfaceOrientationIsLandscape(interfaceOrientation) ? 44 : 64);//parentViewController.navigationController.navigationBar.frame.size.height + parentViewController.navigationController.navigationBar.frame.origin.y;
    frame.size.height = height1 + height2 + height3 - height4;
    self.view.frame = frame;
//    NSLog(@"height 1 %f, height 2 %f, height 3 %f, height 4 %f", height1, height2, height3, height4);
//    NSLog(@"calculate height for description view: %f", frame.size.height);
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self layoutTextViewsForInterfaceOrientation:toInterfaceOrientation];
}
@end

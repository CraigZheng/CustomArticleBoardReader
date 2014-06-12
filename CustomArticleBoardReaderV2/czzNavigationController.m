//
//  czzNavigationController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig Zheng on 13/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNavigationController.h"

@interface czzNavigationController ()

@end

@implementation czzNavigationController
@synthesize shouldRotateViewController;


-(BOOL)shouldAutorotate {
    return shouldRotateViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    shouldRotateViewController = YES;

}

- (NSUInteger)supportedInterfaceOrientations{
    if (!shouldRotateViewController)
        return UIInterfaceOrientationMaskPortrait;
    return UIInterfaceOrientationMaskAll;
}

@end

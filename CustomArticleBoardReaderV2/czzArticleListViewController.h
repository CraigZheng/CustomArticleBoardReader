//
//  czzArticleListViewController.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzArticleListViewController : UITableViewController

@property NSInteger lastContentOffsetY;
@property (strong, nonatomic) IBOutlet UISegmentedControl *categorySegmentControl;
typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

- (void)loadMoreAction;
- (IBAction)categorySelectedAction:(id)sender;
@end

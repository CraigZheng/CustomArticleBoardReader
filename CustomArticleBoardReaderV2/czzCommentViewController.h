//
//  czzCommentViewController.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 12/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface czzCommentViewController : UITableViewController
@property NSInteger articleID;

- (void)loadMoreAction;
@end

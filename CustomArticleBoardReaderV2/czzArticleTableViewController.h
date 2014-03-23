//
//  czzArticleTableViewController.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 21/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzArticle.h"

@interface czzArticleTableViewController : UITableViewController
@property (nonatomic) czzArticle *myArticle;
- (IBAction)favouriteAction:(id)sender;
@end

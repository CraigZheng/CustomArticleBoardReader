//
//  czzArticlelViewController.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 10/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzArticle.h"
#import "czzArticleListViewController.h"

@interface czzArticlelViewController : UIViewController
@property NSInteger lastContentOffsetY;
@property (strong, nonatomic) IBOutlet UIWebView *articleWebView;
@property (nonatomic) czzArticle *myArticle;

- (IBAction)loadAllImages:(id)sender;
- (IBAction)shareAction:(id)sender;
- (IBAction)favirouteAction:(id)sender;
@end

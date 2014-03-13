//
//  czzArticleDescriptionViewController.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 16/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzArticle.h"
#import "czzArticlelViewController.h"

@interface czzArticleDescriptionViewController : UIViewController
@property (nonatomic) czzArticle *myArticle;

@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descLabel;
@property (nonatomic) UIViewController *parentViewController;
@end

//
//  czzPostCommentViewController.h
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 20/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzPostCommentViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextView *postTextView;
@property NSInteger videoID;
@property NSInteger refFloor;
- (IBAction)postAction:(id)sender;
@end

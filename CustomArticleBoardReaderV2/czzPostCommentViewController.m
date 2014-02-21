//
//  czzPostCommentViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 20/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzPostCommentViewController.h"
#import "czzCommentUploader.h"
#import "czzComment.h"
#import "czzAcUser.h"
#import "czzMySelf.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "Toast+UIView.h"

@interface czzPostCommentViewController ()<czzCommentUploaderDelegate, UIAlertViewDelegate>
@property czzCommentUploader *commentUploader;

@end

@implementation czzPostCommentViewController
@synthesize postTextView;
@synthesize commentUploader;
@synthesize videoID;
@synthesize refFloor;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // observe keyboard hide and show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [self performSelectorInBackground:@selector(checkLogin) withObject:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)checkLogin{
    //check the current date against the expiry of currently login user
    czzMySelf *currentLoginUser = [[czzAppDelegate sharedAppDelegate] currentLoginUser];
    if (!currentLoginUser || [currentLoginUser.access_token_expiry_date compare:[NSDate new]] == NSOrderedAscending){
        //not login or access token expired
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"登录" message:@"你还没有登录ACFun，你想现在登入吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
    }
}

#pragma mark - UIAlertVIew delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"登录"] && [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"确定"]){
        [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"login_view_controller"] animated:YES];
    }
}
#pragma mark Keyboard actions
-(void)keyboardWillShow:(NSNotification*)notification{
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's
    // coordinate system. The bottom of the text view's frame should align with the top
    // of the keyboard's final position.
    //
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y/* + self.navigationController.navigationBar.frame.size.height*/, self.view.bounds.size.width, self.view.bounds.size.height);
    newTextViewFrame.size.height = keyboardTop - self.navigationController.navigationBar.frame.size.height - self.view.bounds.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    postTextView.frame = newTextViewFrame;
    
    [UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification*)notification{
    NSDictionary *userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    postTextView.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y/* + self.navigationController.navigationBar.frame.size.height*/, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [UIView commitAnimations];
}

- (IBAction)postAction:(id)sender {
    commentUploader = [[czzCommentUploader alloc] init];
    commentUploader.delegate = self;
    if (videoID) {
        [postTextView resignFirstResponder];
        czzComment *comment = [[czzComment alloc] init];
        comment.content = postTextView.text;
        if (refFloor){
            comment.floorIndex = refFloor;
        }
        [commentUploader sendComment:comment toVideo:videoID];

    }
}

#pragma mark - czzCommentUploaderDelegate
-(void)sendComment:(czzComment *)comment toVideo:(NSInteger)videoID success:(BOOL)success{
    
    if (success){
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"评论发表成功"];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"评论发表不出来我浑身难受！这部分正在紧张有序的开发中"];
    }
}
@end

//
//  czzArticleTableViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 21/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzArticleTableViewController.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "czzArticleDescriptionViewController.h"
#import "czzAcUser.h"
#import "czzArticleDownloader.h"
#import "czzImageDownloader.h"
#import "czzCommentViewController.h"
#import "czzArticleListViewController.h"


@interface czzArticleTableViewController ()<UINavigationControllerDelegate, czzArticleDownloaderDelegate>
@property czzArticleDownloader *articleDownloader;
@property BOOL shouldAutomaticallyLoadImage;
@end

@implementation czzArticleTableViewController
@synthesize myArticle;
@synthesize articleDownloader;
@synthesize shouldAutomaticallyLoadImage;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.delegate = self;
    shouldAutomaticallyLoadImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
    if (myArticle){
        if (myArticle.htmlBody == nil)
            [self startDownloadingArticle];
        else {
            NSLog(@"article nil");
        }
    }
}

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if ([viewController isKindOfClass:[czzArticleListViewController class]]){
        if (articleDownloader)
            [articleDownloader stop];
    }
}

-(void)startDownloadingArticle{
    articleDownloader = [[czzArticleDownloader alloc] initWithArticleID:myArticle.acId delegate:self startImmediately:YES];
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return myArticle.htmlFragments;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

#pragma mark - myArticle setter, also load the given html body if presented
-(void)setMyArticle:(czzArticle *)article{
    myArticle = article;
    myArticle.parentViewController = self;
    if (myArticle.htmlBody){

    }
    if (shouldAutomaticallyLoadImage){
        
    }
}

@end

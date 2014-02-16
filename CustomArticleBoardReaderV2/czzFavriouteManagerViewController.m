//
//  czzFavriouteManagerViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 16/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzFavriouteManagerViewController.h"
#import "czzArticlelViewController.h"
#import "czzArticle.h"

@interface czzFavriouteManagerViewController ()
@property NSMutableArray *favArticles;
@property NSIndexPath *selectedIndexPath;
@property BOOL editing;
@end

@implementation czzFavriouteManagerViewController
@synthesize favArticles;
@synthesize selectedIndexPath;
@synthesize editing;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    editing = NO;
    favArticles = [NSMutableArray new];
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* favirouteFolder = [basePath stringByAppendingPathComponent:@"Faviroutes"];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:favirouteFolder error:nil];
    for (NSString *file in files) {
        NSString *filePath = [favirouteFolder stringByAppendingPathComponent:file];
        czzArticle *article = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        [favArticles addObject:article];
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return favArticles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"article_desc_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell){
        UILabel *title = (UILabel*)[cell viewWithTag:1];
        UILabel *info = (UILabel*)[cell viewWithTag:2];
        UILabel *desc = (UILabel*)[cell viewWithTag:3];
        czzArticle *article = [favArticles objectAtIndex:indexPath.row];
        //info strip
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"MM-dd, HH:mm";
        NSString *dateString = [dateFormatter stringFromDate:article.createTime];
        title.text = article.name;
        NSString *infoString = [NSString stringWithFormat:@"%@, 评论：%d, 点击：%d", dateString, article.commentCount, article.viewCount];
        info.text = infoString;
        desc.text = article.desc;
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat preferHeight = 0;
    UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    newHiddenTextView.hidden = YES;
    newHiddenTextView.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:newHiddenTextView];
    czzArticle *article = [favArticles objectAtIndex:indexPath.row];
    newHiddenTextView.text = article.desc;
    preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 20 + 16;
    [newHiddenTextView removeFromSuperview];
    return MAX(tableView.rowHeight, preferHeight);
}

#pragma mark - UITableview delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndexPath = indexPath;
    [self performSegueWithIdentifier:@"go_article_view_controller_identifier" sender:self];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //delete the archived article from the disk
        czzArticle *articleToDelete = [favArticles objectAtIndex:indexPath.row];
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* favirouteFolder = [basePath stringByAppendingPathComponent:@"Faviroutes"];
        NSString* filePath = [favirouteFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.fav", (long)articleToDelete.acId]];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        [favArticles removeObjectAtIndex:indexPath.row];

        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    if ([segue.identifier isEqualToString:@"go_article_view_controller_identifier"]){
        czzArticlelViewController *articleViewController = (czzArticlelViewController*)segue.destinationViewController;
        articleViewController.myArticle = [favArticles objectAtIndex:selectedIndexPath.row];
    }
}

- (IBAction)manageAction:(id)sender {
    editing = !editing;
    [self.tableView setEditing:editing animated:YES];
}
@end

//
//  czzSettingsViewController.m
//  CustomArticleBoardReaderV2
//
//  Created by Craig on 16/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzSettingsViewController.h"
#import "czzArticleListDownloader.h"
#import "Toast+UIView.h"

@interface czzSettingsViewController ()<UIActionSheetDelegate>
@property NSMutableArray *commands;
@end

@implementation czzSettingsViewController
@synthesize commands;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    commands = [[NSMutableArray alloc] initWithObjects:@"自动下载图片", @"文章排列顺序", @"清除图片缓存", nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return commands.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"command_cell_identifier";
    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *command = [commands objectAtIndex:indexPath.row];
    // Configure the cell...
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"command_cell_with_switch_identifier" forIndexPath:indexPath];
        UISwitch *switchView = (UISwitch*)[cell viewWithTag:2];
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:1];
        commandLabel.text = command;
        switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
    }
    if (indexPath.row >= 1){
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:1];
        commandLabel.text = command;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //文章排列顺序
    if (indexPath.row == 1){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"文章排列顺序" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"最新发布", @"今日热点", @"本周热点", @"最多回复", @"最新回复", nil];
        [actionSheet showInView:self.view];
    } else if (indexPath.row == 2){
        //清除图片缓存
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        //save to thumbnail folder or fullsize folder
        basePath = [basePath
                    stringByAppendingPathComponent:@"Images"];
        NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:nil];
        for (NSString *file in files) {
            NSString *filePath = [basePath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [self.view makeToast:@"缓存已清空"];
    }
}

- (IBAction)switchValueChangedAction:(id)sender {
    UISwitch *switchView = (UISwitch*)sender;
    UIView *cell = switchView;
    do {
        cell = cell.superview;
    } while (![cell isKindOfClass:[UITableViewCell class]]);
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForCell:(UITableViewCell*)cell];
    //自动下载图片
    if (selectedIndexPath.row == 0)
        [self setShouldAutomaticallyLoadImage:switchView.isOn];
}

-(void)setShouldAutomaticallyLoadImage:(BOOL)should{
    [[NSUserDefaults standardUserDefaults] setBool:should forKey:@"shouldAutomaticallyLoadImage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if ([actionSheet.title isEqualToString:@"文章排列顺序"] && buttonIndex != actionSheet.cancelButtonIndex){
        [[NSUserDefaults standardUserDefaults] setInteger:buttonIndex forKey:@"articleOrdering"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
@end

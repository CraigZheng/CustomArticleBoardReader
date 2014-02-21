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
#import "czzLoginViewController.h"

@interface czzSettingsViewController ()<UIActionSheetDelegate>
@property NSMutableArray *commands;
@end

@implementation czzSettingsViewController
@synthesize commands;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    commands = [[NSMutableArray alloc] initWithObjects:@"自动下载图片", @"使用实验性的浏览器", @"文章排列顺序", @"清除图片缓存", @"登陆", nil];
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
    if ([command isEqualToString:@"自动下载图片"] || [command isEqualToString:@"使用实验性的浏览器"]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"command_cell_with_switch_identifier" forIndexPath:indexPath];
        UISwitch *switchView = (UISwitch*)[cell viewWithTag:2];
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:1];
        commandLabel.text = command;
        if ([command isEqualToString:@"自动下载图片"])
            switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutomaticallyLoadImage"];
        else if ([command isEqualToString:@"使用实验性的浏览器"] )
            switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUseExperimentalBrowser"];
    }
    if (indexPath.row > 1){
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:1];
        commandLabel.text = command;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *command = [commands objectAtIndex:indexPath.row];
    //文章排列顺序
    if ([command hasPrefix:@"文章排列顺序"]){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"文章排列顺序" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"最新发布", @"今日热点", @"本周热点", @"最多回复", @"最新回复", nil];
        [actionSheet showInView:self.view];
    } else if ([command isEqualToString:@"清除图片缓存"]){
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
    } else if ([command isEqualToString:@"登陆"]){
        //登陆
        czzLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"login_view_controller"];
        [self.navigationController pushViewController:loginViewController animated:YES];
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
    if ([[commands objectAtIndex:selectedIndexPath.row] isEqualToString:@"自动下载图片"])
        [self setShouldAutomaticallyLoadImage:switchView.isOn];
    //使用实验性的浏览器
    else if ([[commands objectAtIndex:selectedIndexPath.row] isEqualToString:@"使用实验性的浏览器"]){
        [self setShouldUseExperimentalBrowser:switchView.isOn];
    }
}

-(void)setShouldAutomaticallyLoadImage:(BOOL)should{
    [[NSUserDefaults standardUserDefaults] setBool:should forKey:@"shouldAutomaticallyLoadImage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setShouldUseExperimentalBrowser:(BOOL)should{
    [[NSUserDefaults standardUserDefaults] setBool:should forKey:@"shouldUseExperimentalBrowser"];
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

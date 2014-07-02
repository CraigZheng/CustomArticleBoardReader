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
#import "czzMySelf.h"
#import "czzAppDelegate.h"

@interface czzSettingsViewController ()<UIActionSheetDelegate, UIAlertViewDelegate>
@property NSMutableArray *commands;
@property NSString *libraryFolder;
@end

@implementation czzSettingsViewController
@synthesize commands;
@synthesize libraryFolder;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    libraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadCommand];
}

-(void)reloadCommand{
    NSInteger ordering = [[NSUserDefaults standardUserDefaults] integerForKey:@"articleOrdering"];
    NSDictionary *orderingDict = [NSDictionary dictionaryWithObjects:@[@"最新发布",
                                                            @"今日热点",
                                                            @"本周热点",
                                                            @"最多回复",
                                                            @"最新回复"]
                                                  forKeys:@[[NSNumber numberWithInteger:DEFAULT_ORDER],
                                                            [NSNumber numberWithInteger:MOST_CLICKED_DAILY],
                                                            [NSNumber numberWithInteger:MOST_CLICKED_WEEKLY],
                                                            [NSNumber numberWithInteger:MOST_COMMENTED_DAILY],
                                                            [NSNumber numberWithInteger:NEWEST_RESPONDED]]];

    NSString *articleOrderingCommand = [NSString stringWithFormat:@"文章排列顺序: %@", [orderingDict objectForKey:[NSNumber numberWithInteger:ordering]]];
    
    NSString *loginStatus = @"登陆";
    czzMySelf *currentLoginUser = [[czzAppDelegate sharedAppDelegate] currentLoginUser];
    if (currentLoginUser) {
        loginStatus = [NSString stringWithFormat:@"%@ - %@", currentLoginUser.name, currentLoginUser.loginStatus];
    }
    commands = [[NSMutableArray alloc] initWithObjects:@"自动下载图片", /*@"使用实验性的浏览器",*/
                articleOrderingCommand,
                @"图片缓存", @"清空图片缓存", @"清空文章缓存", [NSString stringWithFormat:@"版本号: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], /*loginStatus, */nil];
    [self.tableView reloadData];
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
        return cell;
    }
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UILabel *commandLabel = (UILabel*)[cell viewWithTag:1];
    commandLabel.text = command;

    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *command = [commands objectAtIndex:indexPath.row];
    //文章排列顺序
    if ([command hasPrefix:@"文章排列顺序"]){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"文章排列顺序" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"最新发布", @"今日热点", @"本周热点", @"最多回复", @"最新回复", nil];
        [actionSheet showInView:self.view];
    } else if ([command isEqualToString:@"清空图片缓存"]){
        //清除图片缓存
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清空图片缓存" message:@"此操作不可逆，请确定" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
        
    } else if ([command isEqualToString:@"登陆"]){
        //登陆
        czzLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"login_view_controller"];
        [self.navigationController pushViewController:loginViewController animated:YES];
        return;
    } else if ([command isEqualToString:@"清空文章缓存"]){
        //清空文章缓存
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清空文章缓存" message:@"此操作不可逆，请确定" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
    } else if ([command isEqualToString:@"图片缓存"]){
        [self performSegueWithIdentifier:@"go_image_manager_view_controller_segue" sender:nil];
    } else if (indexPath.row == commands.count - 1) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"退出登陆？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
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
    if ([actionSheet.title hasPrefix:@"文章排列顺序"] && buttonIndex != actionSheet.cancelButtonIndex){
        [[NSUserDefaults standardUserDefaults] setInteger:buttonIndex forKey:@"articleOrdering"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reloadCommand];
    }
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex)
        return;
    if ([alertView.title isEqualToString:@"清空文章缓存"]){
        NSString *cacheFolder = [libraryFolder stringByAppendingPathComponent:@"Cache"];
        NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheFolder error:nil];
        for (NSString *file in files) {
            NSString *filePath = [cacheFolder stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"缓存已清空"];
    } else if ([alertView.title isEqualToString:@"清空图片缓存"]){
        NSString* imageFolder = [libraryFolder
                    stringByAppendingPathComponent:@"Images"];
        NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageFolder error:nil];
        for (NSString *file in files) {
            NSString *filePath = [imageFolder stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"缓存已清空"];
    } else if ([alertView.title isEqualToString:@"退出登陆？"]) {
        NSString *userFile = [libraryFolder stringByAppendingPathComponent:@"currentLoginUser.dat"];
        [[NSFileManager defaultManager] removeItemAtPath:userFile error:nil];
        [[czzAppDelegate sharedAppDelegate] setCurrentLoginUser:nil];
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"已退出登陆"];
        [self reloadCommand];
    }
}
@end

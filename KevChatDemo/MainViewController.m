//
//  MainViewController.m
//  KevChatDemo
//
//  Created by Kevin Manase on 1/28/16.
//  Copyright © 2016 KEV. All rights reserved.
//

#import "MainViewController.h"
#import "ServicesManager.h"
#import "UsersDataSource.h"

@interface MainViewController ()
@property (strong, nonatomic) IBOutlet UIButton *chatActionButton;

@end

@implementation MainViewController
static NSString *const kTestUsersDefaultPassword = @"12345678";


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.chatActionButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:true];
    [SVProgressHUD showWithStatus:@"Logging in..." maskType:SVProgressHUDMaskTypeClear];
    
    QBUUser *selectedUser = [QBUUser user];
    selectedUser.login = @"kevin";
    selectedUser.password = kTestUsersDefaultPassword;
    
    __weak __typeof(self)weakSelf = self;
    // Logging in to Quickblox REST API and chat.
    [ServicesManager.instance logInWithUser:selectedUser completion:^(BOOL success, NSString *errorMessage) {
        if (success) {
            [SVProgressHUD showSuccessWithStatus:@"Logged in"];
            [weakSelf registerForRemoteNotifications];
            self.chatActionButton.enabled = YES;
        } else {
            [SVProgressHUD showErrorWithStatus:@"Can not login"];
        }
    }];
}

#pragma mark - Push Notifications

- (void)registerForRemoteNotifications{
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

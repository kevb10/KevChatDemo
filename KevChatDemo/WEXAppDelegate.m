//
//  AppDelegate.m
//  Wildcat Exchange
//
//  Created by Kevin Manase on 6/23/14.
//  Copyright (c) 2014 Kevin Manase. All rights reserved.
//

#import "WEXAppDelegate.h"
#import "ServicesManager.h"
#import "ChatViewController.h"

const NSUInteger kApplicationID = 33477;
NSString *const kAuthKey        = @"d8xbnqvaJJBweut";
NSString *const kAuthSecret     = @"smumqOeb5m2fy6W";
NSString *const kAcconuntKey    = @"8mryPjSHqee8mAx2DsyU";

@interface WEXAppDelegate () <NotificationServiceDelegate>
@end

@implementation WEXAppDelegate
            
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize initialStoryBoard = _initialStoryBoard;

- (id) init
{
    return [super init];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    // Quickblox
    [self initializeQuickBloxWithLaunchOptions:launchOptions];
    
    _initialStoryBoard = self.window.rootViewController.storyboard;


    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Logout from chat
    //
    [ServicesManager.instance.chatService disconnectWithCompletionBlock:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // Login to QuickBlox Chat
    //
    [ServicesManager.instance.chatService connectWithCompletionBlock:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}


#pragma mark - Reset app
- (void)resetWindowToInitialView
{
    for (UIView* view in self.window.subviews)
    {
        [view removeFromSuperview];
    }
    
    UIViewController* initialScene = [_initialStoryBoard instantiateInitialViewController];
    self.window.rootViewController = initialScene;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark = Quickblox
- (void)initializeQuickBloxWithLaunchOptions:(NSDictionary *)launchOptions {
    // Set QuickBlox credentials (You must create application in admin.quickblox.com)
    [QBSettings setApplicationID:kApplicationID];
    [QBSettings setAuthKey:kAuthKey];
    [QBSettings setAuthSecret:kAuthSecret];
    [QBSettings setAccountKey:kAcconuntKey];
    
    // Enables Quickblox REST API calls debug console output
    [QBSettings setLogLevel:QBLogLevelDebug];
    
    // Enables detailed XMPP logging in console output
    [QBSettings enableXMPPLogging];
    
    // app was launched from push notification, handling it
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        ServicesManager.instance.notificationService.pushDialogID = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey][kPushNotificationDialogIdentifierKey];
    }
}

#pragma mark - Push notification
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // subscribing for push notifications
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNS;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = deviceToken;
    
    [QBRequest createSubscription:subscription successBlock:^(QBResponse *response, NSArray *objects) {
        //
    } errorBlock:^(QBResponse *response) {
        //
    }];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // failed to register push
    NSLog(@"Push failed to register with error: %@", error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ([application applicationState] == UIApplicationStateInactive)
    {
        NSString *dialogID = userInfo[kPushNotificationDialogIdentifierKey];
        if (dialogID != nil) {
            NSString *dialogWithIDWasEntered = [ServicesManager instance].currentDialogID;
            if ([dialogWithIDWasEntered isEqualToString:dialogID]) return;
            
            ServicesManager.instance.notificationService.pushDialogID = dialogID;
            [ServicesManager.instance.notificationService handlePushNotificationWithDelegate:self];
        }
    }
}

#pragma mark - NotificationServiceDelegate protocol

- (void)notificationServiceDidSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    
    ChatViewController *chatController = (ChatViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatViewController"];
    chatController.dialog = chatDialog;
    
    NSString *dialogWithIDWasEntered = [ServicesManager instance].currentDialogID;
    if (dialogWithIDWasEntered != nil) {
        // some chat already opened, return to dialogs view controller first
        [navigationController popViewControllerAnimated:NO];
    }
    
    [navigationController pushViewController:chatController animated:NO];
}




@end

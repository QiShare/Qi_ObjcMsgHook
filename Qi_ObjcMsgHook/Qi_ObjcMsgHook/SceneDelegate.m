#import "SceneDelegate.h"
#import "QiRootViewController.h"
#import "QiCallTrace.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    
    if (@available(iOS 13.0, *)) {
        
        [QiCallTrace start];
        
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [self.window setWindowScene:windowScene];
        [self.window setBackgroundColor:UIColor.whiteColor];
        
        QiRootViewController *rootVC = [[QiRootViewController alloc] init];
        UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController: rootVC];
        self.window.rootViewController = homeNav;
        [self.window makeKeyAndVisible];
        
        [self test1_1];
        [self test2_1];
        [self test3_1];
        
        [self test1_1];
        [self test2_1];
        [self test3_1];
        
        [QiCallTrace stop];
        [QiCallTrace save];
    }
}


- (void)test1_1 {
    usleep(11 * 1000);
    [self test1_2];
    [self test1_3];
}

- (void)test1_2 {
    usleep(12 * 1000);
}

- (void)test1_3 {
    usleep(13 * 1000);
}

- (void)test2_1 {
    usleep(21 * 1000);
    [self test2_2];
    [self test2_3];
}

- (void)test2_2 {
    usleep(22 * 1000);
}

- (void)test2_3 {
    usleep(23 * 1000);
}


- (void)test3_1 {
    usleep(31 * 1000);
    [self test3_2];
    [self test3_3];
}

- (void)test3_2 {
    usleep(32 * 1000);
}

- (void)test3_3 {
    usleep(33 * 1000);
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end

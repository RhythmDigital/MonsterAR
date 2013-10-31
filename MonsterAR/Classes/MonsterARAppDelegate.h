/**
 *  MonsterARAppDelegate.h
 *  MonsterAR
 *
 *  Created by Jamie White on 31/10/2013.
 *  Copyright Rhythm Digital Ltd 2013. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "CC3UIViewController.h"

@interface MonsterARAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow* _window;
	CC3DeviceCameraOverlayUIViewController* _viewController;
}
@end

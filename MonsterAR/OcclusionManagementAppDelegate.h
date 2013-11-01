/*==============================================================================
Copyright (c) 2011-2013 QUALCOMM Austria Research Center GmbH .
All Rights Reserved.
Qualcomm Confidential and Proprietary
==============================================================================*/


#import <UIKit/UIKit.h>
#import "EAGLView.h"

@class ARParentViewController;

@interface OcclusionManagementAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ARParentViewController *arParentViewController;
    UIImageView *splashV;
}

@end

/*==============================================================================
            Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
            All Rights Reserved.
            Qualcomm Confidential and Proprietary
==============================================================================*/

#import "ImageTargetsQCARutils.h"

@implementation ImageTargetsQCARutils
@synthesize deviceOrientationLock;

// return QCARutils singleton, initing if necessary
+ (ImageTargetsQCARutils *) getInstance
{
    if (qUtils == nil)
    {
        qUtils = [[ImageTargetsQCARutils alloc] init];
    }
    
    return (ImageTargetsQCARutils *)qUtils;
}

// iOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    BOOL retVal = NO;
    
    if (self.deviceOrientationLock == DeviceOrientationLockAuto)
    {
        //  Automatic orientation is enabled, rotate
        retVal = YES;
    }
    else if (self.deviceOrientationLock == DeviceOrientationLockPortrait)
    {
        
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
        {
            retVal = YES;
        }
        
    }
    else if (self.deviceOrientationLock == DeviceOrientationLockLandscape)
    {
        
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
        {
            retVal = YES;
        }
    }
    
    return retVal;
}

//  iOS 6
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
// UIInterfaceOrientationMask defined in UIApplication.h (iOS 6 SDK)
enum iOS6OrientationMask {
    UIInterfaceOrientationMaskPortrait = (1 << UIInterfaceOrientationPortrait),
    UIInterfaceOrientationMaskLandscapeLeft = (1 << UIInterfaceOrientationLandscapeLeft),
    UIInterfaceOrientationMaskLandscapeRight = (1 << UIInterfaceOrientationLandscapeRight),
    UIInterfaceOrientationMaskPortraitUpsideDown = (1 << UIInterfaceOrientationPortraitUpsideDown),
    UIInterfaceOrientationMaskLandscape = (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight),
    UIInterfaceOrientationMaskAll = (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown),
    UIInterfaceOrientationMaskAllButUpsideDown = (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight),
};
#endif

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger retVal = UIInterfaceOrientationMaskPortrait;
    
    if (self.deviceOrientationLock == DeviceOrientationLockAuto)
    {
        retVal = UIInterfaceOrientationMaskAll;
    }
    else if (self.deviceOrientationLock == DeviceOrientationLockPortrait)
    {
        retVal = UIInterfaceOrientationMaskPortrait;
    }
    else if (self.deviceOrientationLock == DeviceOrientationLockLandscape)
    {
        retVal = UIInterfaceOrientationMaskLandscape;
    }
    
    return retVal;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end

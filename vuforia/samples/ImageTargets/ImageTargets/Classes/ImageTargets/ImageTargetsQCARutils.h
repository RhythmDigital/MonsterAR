/*==============================================================================
            Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
            All Rights Reserved.
            Qualcomm Confidential and Proprietary
==============================================================================*/

#import "QCARutils.h"

typedef enum {
    DeviceOrientationLockPortrait,
    DeviceOrientationLockLandscape,
    DeviceOrientationLockAuto
} DeviceOrientationLock;

@interface ImageTargetsQCARutils : QCARutils
{
    DeviceOrientationLock deviceOrientationLock;
}

@property (assign) DeviceOrientationLock deviceOrientationLock;

+ (ImageTargetsQCARutils *) getInstance;

//  Autorotation
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (NSUInteger) supportedInterfaceOrientations;
- (BOOL) shouldAutorotate;
@end

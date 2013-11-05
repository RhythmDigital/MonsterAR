/*==============================================================================
            Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
            All Rights Reserved.
            Qualcomm Confidential and Proprietary
==============================================================================*/

#import "ImageTargetsParentViewController.h"
#import "ImageTargetsQCARutils.h"
#import "ImageTargetsOverlayViewController.h"
#import "ARViewController.h"
#import "AboutViewController.h"

@implementation ImageTargetsParentViewController

- (void)loadView
{
    NSLog(@"ImageTargetsParentViewController: creating");
    [self createParentViewAndSplashContinuation];
    
    // Add the EAGLView and the overlay view to the window
    arViewController = [[ARViewController alloc] init];
    
    // need to set size here to setup camera image size for AR
    arViewController.arViewSize = arViewRect.size;
    [parentView addSubview:arViewController.view];
    
    // Hide the AR view so the parent view can be seen during start-up (the
    // parent view contains the splash continuation image on iPad and is empty
    // on iPhone and iPod)
    [arViewController.view setHidden:YES];
    
    // Create an auto-rotating overlay view and its view controller (used for
    // displaying UI objects, such as the camera control menu)
    overlayViewController = [[ImageTargetsOverlayViewController alloc] init];
    [parentView addSubview: overlayViewController.view];
    
    self.view = parentView;
}

//  Deprecated on iOS 6. Use the 2 methods below to control autorotation
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    BOOL retVal = [[ImageTargetsQCARutils getInstance] shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    return retVal;
}

- (BOOL)shouldAutorotate
{
    BOOL retVal = [[ImageTargetsQCARutils getInstance] shouldAutorotate];
    return retVal;
}

- (NSUInteger) supportedInterfaceOrientations
{
    NSUInteger retVal = [[ImageTargetsQCARutils getInstance] supportedInterfaceOrientations];
    return retVal;
}

#pragma mark -
#pragma mark Splash screen control
- (void)endSplash:(NSTimer*)theTimer
{
    // Poll to see if the camera video stream has started and if so remove the
    // splash screen
    [super endSplash:theTimer];
    
    if ([QCARutils getInstance].videoStreamStarted == YES)
    {
        // Create and show the about view
        AboutViewController *aboutViewController = [[[AboutViewController alloc] init] autorelease];
        aboutViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        // Animate the modal only if it's an iPad
        BOOL shouldAnimateTransition = NO;
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            shouldAnimateTransition = YES;
        }
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [self presentModalViewController:aboutViewController animated:shouldAnimateTransition];
        });
    }
}

@end

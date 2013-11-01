/**
 *  MonsterARLayer.m
 *  MonsterAR
 *
 *  Created by Jamie White on 31/10/2013.
 *  Copyright Rhythm Digital Ltd 2013. All rights reserved.
 */

#import "MonsterARLayer.h"
#import "MonsterARScene.h"
#import "QCARutils.h"
#import "CCSprite.h"
#import "CCTexture2D.h"

@implementation CCSprite(Resize)

-(void)resizeTo:(CGSize) theSize
{
    CGFloat newWidth = theSize.width;
    CGFloat newHeight = theSize.height;
    
    
    float startWidth = self.contentSize.width;
    float startHeight = self.contentSize.height;
    
    float newScaleX = newWidth/startWidth;
    float newScaleY = newHeight/startHeight;
    
    self.scaleX = newScaleX;
    self.scaleY = newScaleY;
    
}

@end

@implementation MonsterARLayer

-(void) dealloc {
    [super dealloc];
}




/**
 * Override to set up your 2D controls and other initial state, and to initialize update processing.
 *
 * For more info, read the notes of this method on CC3Layer.
 */
-(void) initializeControls {
	[self scheduleUpdate];
}

-(void) updateCameraWithImage:(UIImage *)newBackground {
    if (cameraview == nil) {
        if (newBackground != nil) {
            backgroundImage = newBackground;
            cameraview = [[CCSprite alloc] initWithTexture:[[[CCTexture2D alloc] initWithImage: backgroundImage] autorelease] rect:CGRectMake(0, 0, 640, 480)];
            
            cameraview.position = CGPointMake(self.contentSize.width/2, self.contentSize.height/2);
            
            [cameraview resizeTo:CGSizeMake(1024, 768)];
            
            [self.cc3Scene setZOrder: 10];
            [self reorderChild:cameraview z:-10];
            [self addChild:cameraview];
        }
    } else {
        if (newBackground != nil) {
            backgroundImage = newBackground;
            [cameraview setTexture: [[[CCTexture2D alloc] initWithImage: backgroundImage] autorelease]];
        }
    }
}


#pragma mark Updating layer


/**
 * Override to perform set-up activity prior to the scene being opened
 * on the view, such as adding gesture recognizers.
 *
 * For more info, read the notes of this method on CC3Layer.
 */
-(void) onOpenCC3Layer {}

/**
 * Override to perform tear-down activity prior to the scene disappearing.
 *
 * For more info, read the notes of this method on CC3Layer.
 */
-(void) onCloseCC3Layer {}

/**
 * The ccTouchMoved:withEvent: method is optional for the <CCTouchDelegateProtocol>.
 * The event dispatcher will not dispatch events for which there is no method
 * implementation. Since the touch-move events are both voluminous and seldom used,
 * the implementation of ccTouchMoved:withEvent: has been left out of the default
 * CC3Layer implementation. To receive and handle touch-move events for object
 * picking, uncomment the following method implementation.
 */
/*
-(void) ccTouchMoved: (UITouch *)touch withEvent: (UIEvent *)event {
	[self handleTouch: touch ofType: kCCTouchMoved];
}
 */

@end

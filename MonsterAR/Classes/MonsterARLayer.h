/**
 *  MonsterARLayer.h
 *  MonsterAR
 *
 *  Created by Jamie White on 31/10/2013.
 *  Copyright Rhythm Digital Ltd 2013. All rights reserved.
 */


#import "CC3Layer.h"


/** A sample application-specific CC3Layer subclass. */
@interface MonsterARLayer : CC3Layer {
    CCSprite *cameraview;
    UIImage *backgroundImage;
    CCTexture2D *cameraTex;
    BOOL even;
}


@property (nonatomic, retain) UIImage *backgroundImage;
@property (nonatomic, retain) CCTexture2D *cameraTex;

-(void) updateCameraWithImage:(UIImage *)newBackground;

@end

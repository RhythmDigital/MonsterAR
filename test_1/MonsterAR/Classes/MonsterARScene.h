/**
 *  MonsterARScene.h
 *  MonsterAR
 *
 *  Created by Jamie White on 31/10/2013.
 *  Copyright Rhythm Digital Ltd 2013. All rights reserved.
 */


#import "CC3Scene.h"
#import "QCARutils.h"
#import "CCSprite.h"
#import "CC3UtilityMeshNodes.h"

/** A sample application-specific CC3Scene subclass.*/
@interface MonsterARScene : CC3Scene {
    QCARutils *qUtils;
    UIImage *backgroundImage;
    CCSprite *backGroundNode;
    CC3Node* rootNode;
    CC3Node* outerNode;
    CC3PlaneNode* planeA;
}

@property (nonatomic, retain) UIImage *backgroundImage;

-(void) drawLineFrom:(CC3Vector)from To:(CC3Vector)to withColor:(ccColor3B)color andName:(NSString *)linename;
-(ccResolutionType) resolutionType;

@end

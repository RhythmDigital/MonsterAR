/*==============================================================================
 Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
 All Rights Reserved.
 Qualcomm Confidential and Proprietary
 ==============================================================================*/

#import <UIKit/UIKit.h>
@class EAGLView, QCARutils;

@interface ARViewController : UIViewController {
@public
    IBOutlet EAGLView *arView;  // the Augmented Reality view
    CGSize arViewSize;          // required view size

@protected
    QCARutils *qUtils;          // QCAR utils singleton class
@private
    UIView *parentView;         // Avoids unwanted interactions between UIViewController and EAGLView
    NSMutableArray* textures;   // Teapot textures
    BOOL arVisible;             // State of visibility of the view
}

@property (nonatomic, retain) IBOutlet EAGLView *arView;
@property (nonatomic) CGSize arViewSize;
           
- (void) handleARViewRotation:(UIInterfaceOrientation)interfaceOrientation;
- (void)freeOpenGLESResources;

@end

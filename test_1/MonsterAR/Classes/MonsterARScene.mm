/**
 *  MonsterARScene.m
 *  MonsterAR
 *
 *  Created by Jamie White on 31/10/2013.
 *  Copyright Rhythm Digital Ltd 2013. All rights reserved.
 */

#import "MonsterARScene.h"
#import "MonsterARLayer.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"

#import "CC3ActionInterval.h"
#import "CC3VertexArrayMeshModel.h"
#import "CC3IOSExtensions.h"
#import "CC3Billboard.h"
#import "CC3ModelSampleFactory.h"
#import "CCLabelTTF.h"
#import "CGPointExtension.h"
#import "CCTouchDispatcher.h"
#import "CCParticleExamples.h"
#import "CC3PODNode.h"
#import "CC3BoundingVolumes.h"
#import "CC3ParametricMeshNodes.h"
#import "CC3PointParticleSamples.h"
#import "CC3VertexSkinning.h"
#import "CC3ShadowVolumes.h"
#import "CC3Math.h"
#import <QCAR/QCAR.h>
#import <QCAR/State.h>
#import <QCAR/Renderer.h>
#import <QCAR/Image.h>
#import <QCAR/Tracker.h>
#import <QCAR/CameraDevice.h>
#import "QCARutils.h"
#import "EAGLView.h"
#import "ShaderUtils.h"
//#import "SampleMath.h"
#import "CC3GLMatrix.h"
#import "math.h"
#import "GLKit/GLKMath.h"

#define _USE_MATH_DEFINES

/*

@interface EAGLView (QCAR)
- (void)renderFrameQCAR;
@end

@implementation EAGLView (QCAR)

- (void)renderFrameQCAR
{
    NSLog(@"am being called by QCARooo...");
}

@end
*/


@implementation MonsterARScene

@synthesize backgroundImage;

-(void) dealloc {
	[super dealloc];
}

/**
 * Constructs the 3D scene prior to the scene being displayed.
 *
 * Adds 3D objects to the scene, loading a 3D 'hello, world' message
 * from a POD file, and creating the camera and light programatically.
 *
 * When adapting this template to your application, remove all of the content
 * of this method, and add your own to construct your 3D model scene.
 *
 * You can also load scene content asynchronously while the scene is being displayed by
 * loading on a background thread. The
 *
 * NOTES:
 *
 * 1) To help you find your scene content once it is loaded, the onOpen method below contains
 *    code to automatically move the camera so that it frames the scene. You can remove that
 *    code once you know where you want to place your camera.
 *
 * 2) The POD file used for the 'hello, world' message model is fairly large, because converting a
 *    font to a mesh results in a LOT of triangles. When adapting this template project for your own
 *    application, REMOVE the POD file 'hello-world.pod' from the Resources folder of your project.
 */
-(void) initializeScene {
    
    //init QCAR
    qUtils = [QCARutils getInstance];
    
    
	// Create the camera, place it back a bit, and add it to the scene
	CC3Camera* cam = [CC3Camera nodeWithName: @"Camera"];
	cam.location = cc3v( 0.0, 0.0, 0.0 );
    CC3Vector camrot = cam.rotation;
    cam.rotation = camrot;
    //cam.fieldOfView = 75.000;
    NSLog(@"Field of View: %f", cam.fieldOfView);
	[self addChild: cam];

	// Create a light, place it back and to the left at a specific
	// position (not just directional lighting), and add it to the scene
	CC3Light* lamp = [CC3Light nodeWithName: @"Lamp"];
	lamp.location = cc3v( -2.0, 0.0, 0.0 );
	lamp.isDirectionalOnly = NO;
	[cam addChild: lamp];

	// This is the simplest way to load a POD resource file and add the
	// nodes to the CC3Scene, if no customized resource subclass is needed.
	[self addContentFromPODFile: @"hello-world.pod" withName:@"ground"];
	
    
    
    ccColor4F col = {255,255,0,255};
    planeA = [CC3PlaneNode nodeWithName:@"PLane 1"];
    [planeA setDiffuseColor: col];
    [planeA setLocation:cc3v( 1.0, 0.0, 2.0 )];
    [planeA setRotation:cc3v(0.0,0.0,0.0)];
    [planeA setBlendFunc:(ccBlendFunc){GL_ZERO, GL_ONE_MINUS_SRC_ALPHA}];
    //    [planeA po
    
    
    
    
    
	// Create OpenGL buffers for the vertex arrays to keep things fast and efficient, and to
	// save memory, release the vertex content in main memory because it is now redundant.
	[self createGLBuffers];
	[self releaseRedundantContent];
	
	// Select an appropriate shader program for each mesh node in this scene now. If this step
	// is omitted, a shader program will be selected for each mesh node the first time that mesh
	// node is drawn. Doing it now adds some additional time up front, but avoids potential pauses
	// as each shader program is loaded as needed the first time it is needed during drawing.
	[self selectShaderPrograms];

	// With complex scenes, the drawing of objects that are not within view of the camera will
	// consume GPU resources unnecessarily, and potentially degrading app performance. We can
	// avoid drawing objects that are not within view of the camera by assigning a bounding
	// volume to each mesh node. Once assigned, the bounding volume is automatically checked
	// to see if it intersects the camera's frustum before the mesh node is drawn. If the node's
	// bounding volume intersects the camera frustum, the node will be drawn. If the bounding
	// volume does not intersect the camera's frustum, the node will not be visible to the camera,
	// and the node will not be drawn. Bounding volumes can also be used for collision detection
	// between nodes. You can create bounding volumes automatically for most rigid (non-skinned)
	// objects by using the createBoundingVolumes on a node. This will create bounding volumes
	// for all decendant rigid mesh nodes of that node. Invoking the method on your scene will
	// create bounding volumes for all rigid mesh nodes in the scene. Bounding volumes are not
	// automatically created for skinned meshes that modify vertices using bones. Because the
	// vertices can be moved arbitrarily by the bones, you must create and assign bounding
	// volumes to skinned mesh nodes yourself, by determining the extent of the bounding
	// volume you need, and creating a bounding volume that matches it. Finally, checking
	// bounding volumes involves a small computation cost. For objects that you know will be
	// in front of the camera at all times, you can skip creating a bounding volume for that
	// node, letting it be drawn on each frame.
	[self createBoundingVolumes];

	
	// ------------------------------------------
	
	// That's it! The scene is now constructed and is good to go.
	
	// To help you find your scene content once it is loaded, the onOpen method below contains
	// code to automatically move the camera so that it frames the scene. You can remove that
	// code once you know where you want to place your camera.
	
	// If you encounter problems displaying your models, you can uncomment one or more of the
	// following lines to help you troubleshoot. You can also use these features on a single node,
	// or a structure of nodes. See the CC3Node notes for more explanation of these properties.
	// Also, the onOpen method below contains additional troubleshooting code you can comment
	// out to move the camera so that it will display the entire scene automatically.
	
	// Displays short descriptive text for each node (including class, node name & tag).
	// The text is displayed centered on the pivot point (origin) of the node.
//	self.shouldDrawAllDescriptors = YES;
	
	// Displays bounding boxes around those nodes with local content (eg- meshes).
//	self.shouldDrawAllLocalContentWireframeBoxes = YES;
	
	// Displays bounding boxes around all nodes. The bounding box for each node
	// will encompass its child nodes.
//	self.shouldDrawAllWireframeBoxes = YES;
	
	// If you encounter issues creating and adding nodes, or loading models from
	// files, the following line is used to log the full structure of the scene.
	LogInfo(@"The structure of this scene is: %@", [self structureDescription]);
	
	// ------------------------------------------

    
    
    outerNode = [[CC3Node alloc] init];;
    [self addChild:outerNode];
    
    rootNode = [[CC3Node alloc] init];
    [outerNode addChild:rootNode];
    
    rootNode.rotation = cc3v(90.0,0,0);
    
    
    
	CC3MeshNode* ground = (CC3MeshNode*)[self getNodeNamed: @"ground"];
    ground.uniformScale = 50.0;
	[ground setLocation:cc3v(0.0, 0.0, 0.0)];
    
    //we add all our elements to the root node as this is the node that gets manipulated with respect to the camera
    [rootNode addChild:ground];
    
    [rootNode addChild:planeA];
    
    
    GLfloat tintTime = 8.0f;
	ccColor3B startColor = ground.color;
	ccColor3B endColor = { 50, 0, 200 };
	CCActionInterval* tintDown = [CCTintTo actionWithDuration: tintTime
														  red: endColor.r
														green: endColor.g
														 blue: endColor.b];
	CCActionInterval* tintUp = [CCTintTo actionWithDuration: tintTime
														red: startColor.r
													  green: startColor.g
													   blue: startColor.b];
    CCActionInterval* tintCycle = [CCSequence actionOne: tintDown two: tintUp];
	[ground runAction: [CCRepeatForever actionWithAction: tintCycle]];
    
}


-(void) drawLineFrom:(CC3Vector)from To:(CC3Vector)to withColor:(ccColor3B)color andName:(NSString *)linename
{
    /*
     //ccColor3B predefined colors
     //! White color (255,255,255)
     static const ccColor3B ccWHITE = {255,255,255};
     //! Yellow color (255,255,0)
     static const ccColor3B ccYELLOW = {255,255,0};
     //! Blue color (0,0,255)
     static const ccColor3B ccBLUE = {0,0,255};
     //! Green Color (0,255,0)
     static const ccColor3B ccGREEN = {0,255,0};
     //! Red Color (255,0,0,)
     static const ccColor3B ccRED = {255,0,0};
     //! Magenta Color (255,0,255)
     static const ccColor3B ccMAGENTA = {255,0,255};
     //! Black Color (0,0,0)
     static const ccColor3B ccBLACK = {0,0,0};
     //! Orange Color (255,127,0)
     static const ccColor3B ccORANGE = {255,127,0};
     //! Gray Color (166,166,166)
     static const ccColor3B ccGRAY = {166,166,166};
     */
    
    CC3VertexLocations* axisZVertices = [[[CC3VertexLocations alloc] init] autorelease];
    axisZVertices.drawingMode = GL_LINES;
    [axisZVertices allocateElements:2];
    [axisZVertices setLocation:from at:0];
    [axisZVertices setLocation:to at:1];
    
    CC3VertexArrayMeshModel* axisZMeshModel = [[[CC3VertexArrayMeshModel alloc] init] autorelease];
    axisZMeshModel.vertexLocations = axisZVertices;
    
    CC3Material* axisZMaterial = [[[CC3Material alloc] init] autorelease];
    axisZMaterial.diffuseColor = ccc4FFromccc3B(color);
    axisZMaterial.ambientColor = ccc4FFromccc3B(color);
    
    CC3LineNode* axisZ = [CC3LineNode nodeWithName:linename];
    axisZ.meshModel = axisZMeshModel;
    axisZ.material = axisZMaterial;
    
    [rootNode addChild:axisZ];
}

#pragma mark Updating custom activity


-(CC3Vector4)multiplyQuaternion:(CC3Vector4)q2 onAxis:(CC3Vector4)axis byDegress:(float)degrees{
    
    CC3Vector4 q1;
    
    q1.x = axis.x;
    q1.y = axis.y;
    q1.z = axis.z;
    
    // Converts the angle in degrees to radians.
    float radians = CC_DEGREES_TO_RADIANS(degrees);
    
    // Finds the sin and cosine for the half angle.
    float sin = sinf(radians * 0.5);
    float cos = cosf(radians * 0.5);
    
    // Formula to construct a new Quaternion based on direction and angle.
    q1.w = cos;
    q1.x = q1.x * sin;
    q1.y = q1.y * sin;
    q1.z = q1.z * sin;
    
    // Multiply quaternion, q1 x q2 is not equal to q2 x q1
    
    CC3Vector4 newQ;
    newQ.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
    newQ.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
    newQ.y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x;
    newQ.z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w;
    
    return  newQ;
}


/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities before
 * any changes are applied to the transformMatrix of the 3D nodes in the scene.
 *
 * For more info, read the notes of this method on CC3Node.
 */

-(void) updateBeforeTransform: (CC3NodeUpdatingVisitor*) visitor {
    
    //NSLog(@"in update transform");
    if (qUtils.videoStreamStarted)
    {
        //NSLog(@"video stream is started");
        QCAR::setFrameFormat(QCAR::RGB888, true); //part of that is needed later when extracting the image,
        //image recognition works without it
        QCAR::State state = QCAR::Renderer::getInstance().begin();
        //NSLog(@"Active trackables: %i", state.getNumActiveTrackables());
        
        QCAR::Renderer::getInstance().setARProjection(kCC3DefaultNearClippingDistance, kCC3DefaultFarClippingDistance);
        
        for (int i = 0; i < state.getNumTrackableResults(); ++i)
		{
            
 			// Get the trackable
            
            //NSLog(@"Testing... %s", trackable->getName());
            
            
            const QCAR::TrackableResult *trackableResult = state.getTrackableResult(i);
            //QCAR::Trackable trackable = trackableResult->getTrackable();
            
         //   const QCAR::Trackable *trackable = trackableResult.
            
			QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(trackableResult->getPose()); //this is the model view matrix
            QCAR::Matrix34F poseMatrix = trackableResult->getPose();
            // take the inverse of the modelview matrix to find the camera orientation in relation to a target at the origin
            //QCAR::Matrix44F inverseModelView = SampleMath::Matrix44FTranspose(SampleMath::Matrix44FInverse(modelViewMatrix));
            //QCAR::Matrix44F nontransposedModelView = SampleMath::Matrix44FInverse(modelViewMatrix);
            //QCAR::Matrix44F noninverseModelView = SampleMath::Matrix44FTranspose(modelViewMatrix);
            
			if (!strcmp(trackableResult->getTrackable().getName(), "tarmac"))
			{
                CC3Matrix* newMatrix = [CC3GLMatrix matrixFromGLMatrix: poseMatrix.data];
                CC3Vector4 quart = [newMatrix extractQuaternion];
                
                CC3Vector4    camQuaternion;
                camQuaternion.w =  quart.w;
                camQuaternion.x = -quart.x;
                camQuaternion.y = quart.y;
                camQuaternion.z = quart.z;
                camQuaternion   = [self multiplyQuaternion:camQuaternion onAxis:CC3Vector4Make(1, 0, 0, 0) byDegress:90];
                outerNode.quaternion = camQuaternion;
                
                
                
                float x = modelViewMatrix.data[12];
                float y = modelViewMatrix.data[13];
                float z = modelViewMatrix.data[14];
                
                x = poseMatrix.data[3];
                y = poseMatrix.data[7];
                z = poseMatrix.data[11];
                
                
                outerNode.location = cc3v(x,-y,-z);
                
            }
        }
        
        // Skip the first few frames
        static int frameCount = 0;
        if (frameCount < 5) {
            frameCount++;
            return;
        }
    
    

        QCAR::Frame frame = state.getFrame();
        for (int i = 0; i < frame.getNumImages(); i++)
        {
            const QCAR::Image *qcarImage = frame.getImage(i);
            if (qcarImage->getFormat() == QCAR::RGB888)
            {
                UIImage *backImage = [self createUIImage:qcarImage];
                
                //big performance hit on this operation, fps drops by more than half 60->23, I dont really know the resolution of backImage, it might be 640x480
                [(MonsterARLayer*)[self cc3Layer] updateCameraWithImage:backImage];
               // [(QCARExperimentLayer*)[self cc3Layer] updateCameraWithImage:backImage];
                
                [backImage release];
            }
        }
        
        QCAR::Renderer::getInstance().end();

    }
}

void releasePixels(void *info, const void *data, size_t size)
{
    // do nothing
}


/**
 * By populating this method, you can add add additional scene content dynamically and
 * asynchronously after the scene is open.
 *
 * This method is invoked from a code block defined in the onOpen method, that is run on a
 * background thread by the CC3GLBackgrounder available through the backgrounder property of
 * the viewSurfaceManager. It adds content dynamically and asynchronously while rendering is
 * running on the main rendering thread.
 *
 * You can add content on the background thread at any time while your scene is running, by
 * defining a code block and running it on the backgrounder of the viewSurfaceManager. The
 * example provided in the onOpen method is a template for how to do this, but it does not
 * need to be invoked only from the onOpen method.
 *
 * Certain assets, notably shader programs, will cause short, but unavoidable, delays in the
 * rendering of the scene, because certain finalization steps from shader compilation occur on
 * the main thread. Shaders and certain other critical assets should be pre-loaded in the
 * initializeScene method prior to the opening of this scene.
 */
-(void) addSceneContentAsynchronously {}


#pragma mark Updating custom activity


/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities after
 * the transformMatrix of the 3D nodes in the scen have been recalculated.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateAfterTransform: (CC3NodeUpdatingVisitor*) visitor {}

- (UIImage *)createUIImage:(const QCAR::Image *)qcarImage
{
    int width = qcarImage->getWidth();
    int height = qcarImage->getHeight();
    int bitsPerComponent = 8;
    int bitsPerPixel = QCAR::getBitsPerPixel(QCAR::RGB888);
    int bytesPerRow = qcarImage->getBufferWidth() * bitsPerPixel / bitsPerComponent;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, qcarImage->getPixels(), QCAR::getBufferSize(width, height, QCAR::RGB888), releasePixels);
    
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    UIImage *image = [[UIImage imageWithCGImage:imageRef] retain];
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    
    return image;
}

#pragma mark Scene opening and closing

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene is first displayed.
 *
 * This method is a good place to invoke one of CC3Camera moveToShowAllOf:... family
 * of methods, used to cause the camera to automatically focus on and frame a particular
 * node, or the entire scene.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onOpen {
	
	// Add additional scene content dynamically and asynchronously on a background thread
	// after the scene is open and rendering has begun on the rendering thread. We use the
	// GL backgrounder provided by the viewSurfaceManager to accomplish this. Asynchronous
	// loading must be initiated after the scene has been attached to the view. It cannot
	// be started in the initializeScene method. However, you do not need to start it only
	// in this onOpen method. You can use the code here as a template for use whenever your
	// app requires background content loading.
	[self.viewSurfaceManager.backgrounder runBlock: ^{
		[self addSceneContentAsynchronously];
	}];

	// Move the camera to frame the scene. The resulting configuration of the camera is output as
	// a [debug] log message, so you know where the camera needs to be in order to view your scene.
	[self.activeCamera moveWithDuration: 3.0 toShowAllOf: self withPadding: 0.5f];

	// Uncomment this line to draw the bounding box of the scene.
//	self.shouldDrawWireframeBox = YES;
}

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene has been removed from display.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onClose {}


#pragma mark Drawing

/**
 * Template method that draws the content of the scene.
 *
 * This method is invoked automatically by the drawScene method, once the 3D environment has
 * been established. Once this method is complete, the 2D rendering environment will be
 * re-established automatically, and any 2D billboard overlays will be rendered. This method
 * does not need to take care of any of this set-up and tear-down.
 *
 * This implementation turns on the lighting contained within the scene, and performs a single
 * rendering pass of the nodes in the scene by invoking the visit: method on the specified
 * visitor, with this scene as the argument.
 *
 * You can override this method to customize the scene rendering flow, such as performing
 * multiple rendering passes on different surfaces, or adding post-processing effects, using
 * the template methods mentioned above.
 *
 * Rendering output is directed to the render surface held in the renderSurface property of
 * the visitor. By default, that is set to the render surface held in the viewSurface property
 * of this scene. If you override this method, you can set the renderSurface property of the
 * visitor to another surface, and then invoke this superclass implementation, to render this
 * scene to a texture for later processing.
 *
 * When overriding the drawSceneContentWithVisitor: method with your own specialized rendering,
 * steps, be careful to avoid recursive loops when rendering to textures and environment maps.
 * For example, you might typically override drawSceneContentWithVisitor: to include steps to
 * render environment maps for reflections, etc. In that case, you should also override the
 * drawSceneContentForEnvironmentMapWithVisitor: to render the scene without those additional
 * steps, to avoid the inadvertenly invoking an infinite recursive rendering of a scene to a
 * texture while the scene is already being rendered to that texture.
 *
 * To maintain performance, by default, the depth buffer of the surface is not specifically
 * cleared when 3D drawing begins. If this scene is drawing to a surface that already has
 * depth information rendered, you can override this method and clear the depth buffer before
 * continuing with 3D drawing, by invoking clearDepthContent on the renderSurface of the visitor,
 * and then invoking this superclass implementation, or continuing with your own drawing logic.
 *
 * Examples of when the depth buffer should be cleared are when this scene is being drawn
 * on top of other 3D content (as in a sub-window), or when any 2D content that is rendered
 * behind the scene makes use of depth drawing. See also the closeDepthTestWithVisitor:
 * method for more info about managing the depth buffer.
 */
-(void) drawSceneContentWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	[self illuminateWithVisitor: visitor];		// Light up your world!
	//[visitor visit: self.backdrop];				// Draw the backdrop if it exists
	[visitor visit: self];						// Draw the scene components
	[self drawShadows];							// Shadows are drawn with a different visitor
}


#pragma mark Handling touch events 

/**
 * This method is invoked from the CC3Layer whenever a touch event occurs, if that layer
 * has indicated that it is interested in receiving touch events, and is handling them.
 *
 * Override this method to handle touch events, or remove this method to make use of
 * the superclass behaviour of selecting 3D nodes on each touch-down event.
 *
 * This method is not invoked when gestures are used for user interaction. Your custom
 * CC3Layer processes gestures and invokes higher-level application-defined behaviour
 * on this customized CC3Scene subclass.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) touchEvent: (uint) touchType at: (CGPoint) touchPoint {}

/**
 * This callback template method is invoked automatically when a node has been picked
 * by the invocation of the pickNodeFromTapAt: or pickNodeFromTouchEvent:at: methods,
 * as a result of a touch event or tap gesture.
 *
 * Override this method to perform activities on 3D nodes that have been picked by the user.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) nodeSelected: (CC3Node*) aNode byTouchEvent: (uint) touchType at: (CGPoint) touchPoint {}

@end


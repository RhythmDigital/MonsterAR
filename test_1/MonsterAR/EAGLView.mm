/*==============================================================================
 Copyright (c) 2011-2013 QUALCOMM Austria Research Center GmbH .
 All Rights Reserved.
 Qualcomm Confidential and Proprietary
 ==============================================================================*/


#import "EAGLView.h"
#import "Cube.h"
#import "Teapot.h"
#include <sys/time.h>

#import "QCARutils.h"
#import "Texture.h"
#import <QCAR/Renderer.h>
#import <QCAR/MultiTarget.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/VideoBackgroundTextureInfo.h>
#import <QCAR/VideoBackgroundConfig.h>

#import "ShaderUtils.h"
#import "Shaders/CubeShaders.h"
#import "Shaders/Shaders.h"


namespace {
    // Texture filenames
    const char* textureFilenames[] = {
        "background.png", // 0
        "teapot.png",  // 1
        "mask.png", // 2
    };
    
    float vbOrthoQuadVertices[] =
    {
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 0.0f,
        1.0f,  1.0f, 0.0f,
        -1.0f,  1.0f, 0.0f
    };
    
    float vbOrthoQuadTexCoords[] =
    {
        0.0,    1.0,
        1.0,    1.0,
        1.0,    0.0,
        0.0,    0.0
    };
    
    GLbyte vbOrthoQuadIndices[]=
    {
        0, 1, 2, 2, 3, 0
    };
    
    float   vbOrthoProjMatrix[16];
    
    unsigned int vbShaderProgramOcclusionID     = 0;
    GLint vbVertexPositionOcclusionHandle      = 0;
    GLint vbVertexTexCoordOcclusionHandle      = 0;
    GLint vbTexSamplerVideoOcclusionHandle     = 0;
    GLint vbProjectionMatrixOcclusionHandle    = 0;
    GLint vbTexSamplerMaskOcclusionHandle      = 0;
    GLint vbViewportOriginHandle               = 0;
    GLint vbViewportSizeHandle                 = 0;
    GLint vbTextureRatioHandle                 = 0;
    
    unsigned int vbShaderProgramOcclusionReflectID  = 0;
    GLint vbVertexPositionOcclusionReflectHandle   = 0;
    GLint vbVertexTexCoordOcclusionReflectHandle   = 0;
    GLint vbTexSamplerVideoOcclusionReflectHandle  = 0;
    GLint vbProjectionMatrixOcclusionReflectHandle = 0;
    GLint vbTexSamplerMaskOcclusionReflectHandle   = 0;
    GLint vbViewportOriginReflectHandle            = 0;
    GLint vbViewportSizeReflectHandle              = 0;
    GLint vbTextureRatioReflectHandle              = 0;
    
    unsigned int vbShaderProgramID              = 0;
    GLint vbVertexPositionHandle               = 0;
    GLint vbVertexTexCoordHandle               = 0;
    GLint vbTexSamplerVideoHandle              = 0;
    GLint vbProjectionMatrixHandle             = 0;
    
    // Constants:
    const float kCubeScaleX = 120.0f * 0.75f / 2.0f;
    const float kCubeScaleY = 120.0f * 1.00f / 2.0f;
    const float kCubeScaleZ = 120.0f * 0.50f / 2.0f;
    
    static const float kTeapotScaleX            = 120.0f * 0.015f;
    static const float kTeapotScaleY            = 120.0f * 0.015f;
    static const float kTeapotScaleZ            = 120.0f * 0.015f;
}


@implementation EAGLView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
	if (self)
    {
        qUtils = [QCARutils getInstance];
        
        // create list of textures we want loading - ARViewController will do this for us
        int nTextures = sizeof(textureFilenames) / sizeof(textureFilenames[0]);
        for (int i = 0; i < nTextures; ++i)
            [textureList addObject: [NSString stringWithUTF8String:textureFilenames[i]]];
    }
    return self;
}


// called after QCAR is initialised but before the camera starts
- (void) postInitQCAR
{
    // Here we could make a QCAR::setHint call to set the maximum
    // number of simultaneous targets
    // QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 2);
}

////////////////////////////////////////////////////////////////////////////////
// Initialise OpenGL 2.x shaders
- (void)initShaders
{
    shaderProgramID                     = ShaderUtils::createProgramFromBuffer(cubeMeshVertexShader, cubeFragmentShader);
    vertexHandle                        =
    glGetAttribLocation(shaderProgramID, "vertexPosition");
    normalHandle                        =
    glGetAttribLocation(shaderProgramID, "vertexNormal");
    textureCoordHandle                  =
    glGetAttribLocation(shaderProgramID, "vertexTexCoord");
    mvpMatrixHandle                     =
    glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
    
    
    vbShaderProgramID                   = ShaderUtils::createProgramFromBuffer(passThroughVertexShader, passThroughFragmentShader);
    vbVertexPositionHandle              =
    glGetAttribLocation(vbShaderProgramID, "vertexPosition");
    vbVertexTexCoordHandle              =
    glGetAttribLocation(vbShaderProgramID, "vertexTexCoord");
    vbProjectionMatrixHandle            =
    glGetUniformLocation(vbShaderProgramID, "modelViewProjectionMatrix");
    vbTexSamplerVideoHandle             =
    glGetUniformLocation(vbShaderProgramID, "texSamplerVideo");
    ShaderUtils::setOrthoMatrix(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0,
                                vbOrthoProjMatrix);
    
    vbShaderProgramOcclusionID          = ShaderUtils::createProgramFromBuffer(passThroughVertexShader, occlusionFragmentShader);
    vbVertexPositionOcclusionHandle     =
    glGetAttribLocation(vbShaderProgramOcclusionID, "vertexPosition");
    vbVertexTexCoordOcclusionHandle     =
    glGetAttribLocation(vbShaderProgramOcclusionID, "vertexTexCoord");
    vbProjectionMatrixOcclusionHandle   =
    glGetUniformLocation(vbShaderProgramOcclusionID,
                         "modelViewProjectionMatrix");
    vbViewportOriginHandle              =
    glGetUniformLocation(vbShaderProgramOcclusionID, "viewportOrigin");
    vbViewportSizeHandle                =
    glGetUniformLocation(vbShaderProgramOcclusionID, "viewportSize");
    vbTextureRatioHandle                =
    glGetUniformLocation(vbShaderProgramOcclusionID, "textureRatio");
    vbTexSamplerVideoOcclusionHandle       =
    glGetUniformLocation(vbShaderProgramOcclusionID, "texSamplerVideo");
    vbTexSamplerMaskOcclusionHandle     =
    glGetUniformLocation(vbShaderProgramOcclusionID, "texSamplerMask");
    
    
    vbShaderProgramOcclusionReflectID       =  ShaderUtils::createProgramFromBuffer(passThroughVertexShader, occlusionFragmentShader,
                                                                                    NULL,                 // No preprocessor defs for vertex shader
                                                                                    "#define REFLECT\n"); // Define reflection for the fragment shader
    vbVertexPositionOcclusionReflectHandle  =
    glGetAttribLocation(vbShaderProgramOcclusionReflectID, "vertexPosition");
    vbVertexTexCoordOcclusionReflectHandle  =
    glGetAttribLocation(vbShaderProgramOcclusionReflectID, "vertexTexCoord");
    vbTexSamplerVideoOcclusionReflectHandle =
    glGetUniformLocation(vbShaderProgramOcclusionReflectID, "texSamplerVideo");
    vbProjectionMatrixOcclusionReflectHandle=
    glGetUniformLocation(vbShaderProgramOcclusionReflectID,
                         "modelViewProjectionMatrix");
    vbTexSamplerMaskOcclusionReflectHandle  =
    glGetUniformLocation(vbShaderProgramOcclusionReflectID, "texSamplerMask");
    vbViewportOriginReflectHandle           =
    glGetUniformLocation(vbShaderProgramOcclusionReflectID, "viewportOrigin");
    vbViewportSizeReflectHandle             =
    glGetUniformLocation(vbShaderProgramOcclusionReflectID, "viewportSize");
    vbTextureRatioReflectHandle             =
    glGetUniformLocation(vbShaderProgramOcclusionReflectID, "textureRatio");
}



////////////////////////////////////////////////////////////////////////////////
// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method on a background thread ***

- (void)renderFrameQCAR
{
    [super setFramebuffer];
    
    ShaderUtils::checkGlError("Check gl errors prior render Frame");
    
    // Clear color and depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // Render video background:
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    
    const QCAR::VIDEO_BACKGROUND_REFLECTION reflection = QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection;
    
    const QCAR::VideoBackgroundTextureInfo texInfo =
    QCAR::Renderer::getInstance().getVideoBackgroundTextureInfo();
    float uRatio =
    ((float)texInfo.mImageSize.data[0]/(float)texInfo.mTextureSize.data[0]);
    float vRatio =
    ((float)texInfo.mImageSize.data[1]/(float)texInfo.mTextureSize.data[1]);
    
    // Y coords for the video texture remain const
    vbOrthoQuadTexCoords[1] = vRatio;
    vbOrthoQuadTexCoords[3] = vRatio;
    
    // If we detect a reflection, invert the x coords for the video background texture
    if(reflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
    {
        vbOrthoQuadTexCoords[0] = uRatio;
        vbOrthoQuadTexCoords[2] = 0;
        vbOrthoQuadTexCoords[4] = 0;
        vbOrthoQuadTexCoords[6] = uRatio;
    }
    else // otherwise reset them
    {
        vbOrthoQuadTexCoords[0] = 0;
        vbOrthoQuadTexCoords[2] = uRatio;
        vbOrthoQuadTexCoords[4] = uRatio;
        vbOrthoQuadTexCoords[6] = 0;
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // This section renders the video background with a
    // custom shader defined in Shaders.h
    
    const GLuint vbVideoTextureUnit = 0;
    const GLuint vbMaskTextureUnit = 1;
    if (!QCAR::Renderer::getInstance().bindVideoBackground(vbVideoTextureUnit))
    {
        // No video frame available, take no further action
        QCAR::Renderer::getInstance().end();
        return;
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    // Load the shader and upload the vertex/texcoord/index data
    
    glViewport(qUtils.viewport.posX, qUtils.viewport.posY,
               qUtils.viewport.sizeX, qUtils.viewport.sizeY);
    
    glUseProgram(vbShaderProgramID);
    glVertexAttribPointer(vbVertexPositionHandle, 3, GL_FLOAT, GL_FALSE, 0,
                          vbOrthoQuadVertices);
    glVertexAttribPointer(vbVertexTexCoordHandle, 2, GL_FLOAT, GL_FALSE, 0,
                          vbOrthoQuadTexCoords);
    glUniform1i(vbTexSamplerVideoHandle, vbVideoTextureUnit);
    glUniformMatrix4fv(vbProjectionMatrixHandle, 1, GL_FALSE,
                       &vbOrthoProjMatrix[0]);
    
    // Render the video background with the custom shader
    glEnableVertexAttribArray(vbVertexPositionHandle);
    glEnableVertexAttribArray(vbVertexTexCoordHandle);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, vbOrthoQuadIndices);
    glDisableVertexAttribArray(vbVertexPositionHandle);
    glDisableVertexAttribArray(vbVertexTexCoordHandle);
    
    // Wrap up this rendering
    glUseProgram(0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    ShaderUtils::checkGlError("Rendering of the video background");
    //
    ////////////////////////////////////////////////////////////////////////////
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Did we find any trackables this frame?
    if (state.getNumTrackableResults())
    {
        // Get the trackable:
        const QCAR::TrackableResult* result=NULL;
        int numResults=state.getNumTrackableResults();
        
        // Browse results searching for the MultiTarget
        for (int j=0;j<numResults;j++)
        {
            result = state.getTrackableResult(j);
            if (result->getType() == QCAR::TrackableResult::MULTI_TARGET_RESULT) break;
            result=NULL;
        }
        
        // If it was not found exit
        if (result==NULL)
        {
            // Clean up and leave
            glDisable(GL_BLEND);
            glDisable(GL_DEPTH_TEST);
            
            QCAR::Renderer::getInstance().end();
            return;
        }
        
        
        QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        QCAR::Matrix44F modelViewProjectionCube;
        QCAR::Matrix44F modelViewProjectionTeapot;
        
        ShaderUtils::scalePoseMatrix(kCubeScaleX, kCubeScaleY, kCubeScaleZ,
                                     &modelViewMatrix.data[0]);
        ShaderUtils::multiplyMatrix(&qUtils.projectionMatrix.data[0],
                                    &modelViewMatrix.data[0],
                                    &modelViewProjectionCube.data[0]);
        
        ////////////////////////////////////////////////////////////////////////
        // First, we render the faces that serve as a "background" to the teapot
        // This helps the user to have a visually constrained space
        // (otherwise the teapot looks floating in space)
        
        glEnable(GL_CULL_FACE);
        glCullFace(GL_FRONT);
        
        if(reflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
            glFrontFace(GL_CW);  //Front camera
        else
            glFrontFace(GL_CCW);   //Back camera
        
        glUseProgram(shaderProgramID);
        
        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &cubeVertices[0]);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &cubeNormals[0]);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &cubeTexCoords[0]);
        glEnableVertexAttribArray(vertexHandle);
        glEnableVertexAttribArray(normalHandle);
        glEnableVertexAttribArray(textureCoordHandle);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, [[textures objectAtIndex:0] textureID]);
        glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE,
                           (GLfloat*)&modelViewProjectionCube.data[0] );
        glDrawElements(GL_TRIANGLES, NUM_CUBE_INDEX, GL_UNSIGNED_SHORT,
                       (const GLvoid*) &cubeIndices[0]);
        
        glCullFace(GL_BACK);
        
        ShaderUtils::checkGlError("Back faces of the box");
        //
        ////////////////////////////////////////////////////////////////////////
        
        
        ////////////////////////////////////////////////////////////////////////
        // Then, we render the actual teapot
        
        modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        ShaderUtils::translatePoseMatrix(0.0f*120.0f, -0.0f*120.0f,
                                         -0.17f*120.0f, &modelViewMatrix.data[0]);
        ShaderUtils::rotatePoseMatrix(90.0f, 0.0f, 0, 1,
                                      &modelViewMatrix.data[0]);
        ShaderUtils::scalePoseMatrix(kTeapotScaleX, kTeapotScaleY, kTeapotScaleZ,
                                     &modelViewMatrix.data[0]);
        ShaderUtils::multiplyMatrix(&qUtils.projectionMatrix.data[0],
                                    &modelViewMatrix.data[0],
                                    &modelViewProjectionTeapot.data[0]);
        glUseProgram(shaderProgramID);
        glEnableVertexAttribArray(vertexHandle);
        glEnableVertexAttribArray(normalHandle);
        glEnableVertexAttribArray(textureCoordHandle);
        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &teapotVertices[0]);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &teapotNormals[0]);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &teapotTexCoords[0]);
        glBindTexture(GL_TEXTURE_2D, ((Texture *)[textures objectAtIndex:1]).textureID);
        glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE,
                           (GLfloat*)&modelViewProjectionTeapot.data[0] );
        glDrawElements(GL_TRIANGLES, NUM_TEAPOT_OBJECT_INDEX, GL_UNSIGNED_SHORT,
                       (const GLvoid*) &teapotIndices[0]);
        glBindTexture(GL_TEXTURE_2D, 0);
        ////////////////////////////////////////////////////////////////////////
        
        ////////////////////////////////////////////////////////////////////////
        // Finally, we render the top layer based on the video image
        // this is the layer that actually gives the "transparent look"
        // notice that we use the mask.png (textures[2]->mTextureID)
        // to define how the transparency looks
        
        glDepthFunc(GL_LEQUAL);
        glActiveTexture(GL_TEXTURE0);
        QCAR::Renderer::getInstance().bindVideoBackground(vbVideoTextureUnit);
        glActiveTexture(GL_TEXTURE0 + vbMaskTextureUnit);
        glBindTexture(GL_TEXTURE_2D, ((Texture *)[textures objectAtIndex:2]).textureID);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
        
        glViewport(qUtils.viewport.posX, qUtils.viewport.posY,
                   qUtils.viewport.sizeX, qUtils.viewport.sizeY);
        
        // use the precompiled shader with reflection enabled
        if(reflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
        {
            glUseProgram(vbShaderProgramOcclusionReflectID);
            glVertexAttribPointer(vbVertexPositionOcclusionReflectHandle, 3, GL_FLOAT,
                                  GL_FALSE, 0, (const GLvoid*) &cubeVertices[0]);
            glVertexAttribPointer(vbVertexTexCoordOcclusionReflectHandle, 2, GL_FLOAT,
                                  GL_FALSE, 0, (const GLvoid*) &cubeTexCoords[0]);
            glEnableVertexAttribArray(vbVertexPositionOcclusionReflectHandle);
            glEnableVertexAttribArray(vbVertexTexCoordOcclusionReflectHandle);
            
            glUniform2f(vbViewportOriginReflectHandle,
                        qUtils.viewport.posX, qUtils.viewport.posY);
            glUniform2f(vbViewportSizeReflectHandle, qUtils.viewport.sizeX, qUtils.viewport.sizeY);
            glUniform2f(vbTextureRatioReflectHandle, uRatio, vRatio);
            
            glUniform1i(vbTexSamplerVideoOcclusionReflectHandle, vbVideoTextureUnit);
            glUniform1i(vbTexSamplerMaskOcclusionReflectHandle, vbMaskTextureUnit);
            glUniformMatrix4fv(vbProjectionMatrixOcclusionReflectHandle, 1, GL_FALSE,
                               (GLfloat*)&modelViewProjectionCube.data[0] );
            glDrawElements(GL_TRIANGLES, NUM_CUBE_INDEX, GL_UNSIGNED_SHORT,
                           (const GLvoid*) &cubeIndices[0]);
            glDisableVertexAttribArray(vbVertexPositionOcclusionReflectHandle);
            glDisableVertexAttribArray(vbVertexTexCoordOcclusionReflectHandle);
            glUseProgram(0);
        }
        else // use the precompiled shader with reflection disabled
        {
            glUseProgram(vbShaderProgramOcclusionID);
            glVertexAttribPointer(vbVertexPositionOcclusionHandle, 3, GL_FLOAT,
                                  GL_FALSE, 0, (const GLvoid*) &cubeVertices[0]);
            glVertexAttribPointer(vbVertexTexCoordOcclusionHandle, 2, GL_FLOAT,
                                  GL_FALSE, 0, (const GLvoid*) &cubeTexCoords[0]);
            glEnableVertexAttribArray(vbVertexPositionOcclusionHandle);
            glEnableVertexAttribArray(vbVertexTexCoordOcclusionHandle);
            
            glUniform2f(vbViewportOriginHandle,
                        qUtils.viewport.posX, qUtils.viewport.posY);
            glUniform2f(vbViewportSizeHandle, qUtils.viewport.sizeX, qUtils.viewport.sizeY);
            glUniform2f(vbTextureRatioHandle, uRatio, vRatio);
            
            glUniform1i(vbTexSamplerVideoOcclusionHandle, vbVideoTextureUnit);
            glUniform1i(vbTexSamplerMaskOcclusionHandle, vbMaskTextureUnit);
            glUniformMatrix4fv(vbProjectionMatrixOcclusionHandle, 1, GL_FALSE,
                               (GLfloat*)&modelViewProjectionCube.data[0] );
            glDrawElements(GL_TRIANGLES, NUM_CUBE_INDEX, GL_UNSIGNED_SHORT,
                           (const GLvoid*) &cubeIndices[0]);
            glDisableVertexAttribArray(vbVertexPositionOcclusionHandle);
            glDisableVertexAttribArray(vbVertexTexCoordOcclusionHandle);
            glUseProgram(0);
        }
        glDepthFunc(GL_LESS);
        ShaderUtils::checkGlError("Transparency layer");
        //
        ////////////////////////////////////////////////////////////////////////
    }
    
    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);
    
    glDisableVertexAttribArray(vertexHandle);
    glDisableVertexAttribArray(normalHandle);
    glDisableVertexAttribArray(textureCoordHandle);
    
    QCAR::Renderer::getInstance().end();
    [super presentFramebuffer];
}


@end

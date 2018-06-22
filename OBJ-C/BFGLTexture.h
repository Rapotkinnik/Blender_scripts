//
//  BFGLTexture.h
//  TestProject
//
//  Created by Рапоткин Николай on 21.05.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

#import "BFFinaly.h"

@interface BFGLTexture : NSObject
{
    GLenum m_target;
    GLuint m_texture;
    
    BOOL   m_selfCreated;
}

-(id)initWithTarget:(GLenum)target;
-(id)initWithTarget:(GLenum)target Texture:(GLuint)texture;

-(BFFinaly *)bind;
-(BFFinaly *)bindToUnit:(GLuint)unit;

@property(nonatomic, readonly) GLenum target;
@property(nonatomic, readonly) GLuint texture;
@property(nonatomic, readonly) BOOL   selfCreated;

@end  // BFGLTexture

@interface BFGLTexture2D : BFGLTexture
{
    CGSize m_size;
    GLenum m_pixelType;
    GLenum m_pixelFormat;
}

-(id)initWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat;

+(instancetype)shadowMapWithSize:(CGSize)size;
+(instancetype)emptyCanvasToDrawWithSize:(CGSize)size;
+(instancetype)texture2DWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat Data:(const void *)data;

-(void)setData:(const GLvoid *)data;
-(void)setData:(const GLvoid *)data WithOffset:(CGPoint)offset Size:(CGSize)size;

-(void)setMinifyingFuction:(GLenum)fun;
-(void)setMagnificationFunction:(GLenum)fun;
-(void)setWrapFunction:(GLenum)fun ForCoordinate:(GLenum)coord;

@property(nonatomic, readonly) CGSize size;
@property(nonatomic, readonly) GLenum pixelType;
@property(nonatomic, readonly) GLenum pixelFormat;

@end  // BFGLTexture2D

@interface BFGLTextureCubeMap : BFGLTexture
{
    CGSize m_size;
    GLenum m_pixelType;
    GLenum m_pixelFormat;
}

-(id)initWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat;

+(instancetype)shadowCubeMapWithSize:(CGSize)size;
+(instancetype)emptyCanvasToDrawWithSize:(CGSize)size;
+(instancetype)cubeMapWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat Data:(const void *)data;

-(void)setData:(const GLvoid *)data;
-(void)setData:(const GLvoid *)data ForFace:(GLenum)face;
-(void)setData:(const GLvoid *)data WithOffset:(CGPoint)offset Size:(CGSize)size ForFace:(GLenum)face;

-(void)setMinifyingFuction:(GLenum)fun;
-(void)setMagnificationFunction:(GLenum)fun;
-(void)setWrapFunction:(GLenum)fun ForCoordinate:(GLenum)coord;

@property(nonatomic, readonly) CGSize size;
@property(nonatomic, readonly) GLenum pixelType;
@property(nonatomic, readonly) GLenum pixelFormat;

@end  // BFGLTextureCubeMap

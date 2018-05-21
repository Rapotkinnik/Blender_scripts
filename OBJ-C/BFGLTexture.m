//
//  BFGLTexture.m
//  TestProject
//
//  Created by Рапоткин Николай on 21.05.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import "BFGLTexture.h"

@implementation BFGLTexture

-(id)initWithTarget:(GLenum)target
{
    self = [super init];
    if (self)
    {
        m_target = target;
        m_selfCreated = YES;
        
        glGenTextures(1, &m_texture);
    }
    
    return self;
}

-(id)initWithTarget:(GLenum)target Texture:(GLuint)texture
{
    self = [super init];
    if (self)
    {
        m_target = target;
        m_selfCreated = NO;
    }
    
    return self;
}

-(void)dealloc
{
    if (m_selfCreated)
        glDeleteTextures(1, &m_texture);
}

@synthesize target = m_target, texture = m_texture, selfCreated = m_selfCreated;

@end  // BFGLTexture

@implementation BFGLTexture2D

-(id)initWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat
{
    self = [super initWithTarget:GL_TEXTURE_2D];
    if (self)
    {
        GLint maxTextureSize;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        if (MAX(size.height, size.width) > maxTextureSize)
        {
            NSLog(@"This device doesn't support texture with %fx%f size", size.width, size.height);
            
            return nil;
        }
        
        GLint lastTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);
        
        glBindTexture(GL_TEXTURE_2D, [super texture]);
        
        glTexImage2D(GL_TEXTURE_2D, 0, pixelFormat, size.width, size.height, 0, pixelFormat, pixelType, NULL);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glBindTexture(GL_TEXTURE_2D, lastTexture);
    }
    
    return self;
}

+(instancetype)shadowMapWithSize:(CGSize)size
{
    return [[[self class] alloc] initWithSize:size PixelType:GL_FLOAT PixelFormat:GL_DEPTH_COMPONENT];
}

+(instancetype)emptyCanvasToDrawWithSize:(CGSize)size;
{
    return [[[self class] alloc] initWithSize:size PixelType:GL_UNSIGNED_SHORT_5_6_5 PixelFormat:GL_RGB];
}

+(instancetype)texture2DWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat Data:(const void *)data
{
    BFGLTexture2D *texture = [[[self class] alloc] initWithSize:size PixelType:pixelType PixelFormat:pixelFormat];
    if (texture)
        [texture setData:data];
    
    return texture;
}

-(void)setMinifyingFuction:(GLenum)fun
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);
    
    glBindTexture(GL_TEXTURE_2D, [super texture]);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, fun);
    
    glBindTexture(GL_TEXTURE_2D, lastTexture);
}

-(void)setMagnificationFunction:(GLenum)fun
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);
    
    glBindTexture(GL_TEXTURE_2D, [super texture]);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, fun);
    
    glBindTexture(GL_TEXTURE_2D, lastTexture);
}

-(void)setWrapFunction:(GLenum)fun ForCoordinate:(GLenum)coord
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);
    
    glBindTexture(GL_TEXTURE_2D, [super texture]);
    
    glTexParameteri(GL_TEXTURE_2D, coord, fun);
    
    glBindTexture(GL_TEXTURE_2D, lastTexture);
}

-(void)setData:(const GLvoid *)data
{
    [self setData:data WithOffset:CGPointMake(0.0, 0.0) Size:m_size];
}

-(void)setData:(const GLvoid *)data WithOffset:(CGPoint)offset Size:(CGSize)size
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);
    
    glBindTexture(GL_TEXTURE_2D, [super texture]);
    
    glTexSubImage2D(GL_TEXTURE_2D, 0, offset.x, offset.y, size.width, size.height, m_pixelFormat, m_pixelType, data);
    
    glBindTexture(GL_TEXTURE_2D, lastTexture);
}

@synthesize size = m_size, pixelType = m_pixelType, pixelFormat = m_pixelFormat;

@end  // BFGLTexture2D

@implementation BFGLTextureCubeMap

-(id)initWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat
{
    self = [super initWithTarget:GL_TEXTURE_CUBE_MAP];
    if (self)
    {
        GLint maxTextureSize;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        if (MAX(size.height, size.width) > maxTextureSize)
        {
            NSLog(@"This device doesn't support texture with %fx%f size", size.width, size.height);
            
            return nil;
        }
        
        GLint lastTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &lastTexture);
        
        glBindTexture(GL_TEXTURE_CUBE_MAP, [super texture]);
        
        for (uint i = 0; i < 6; ++i)
            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, pixelFormat, size.width, size.height, 0, pixelFormat, pixelType, NULL);
        
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
// ?    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
        
        glBindTexture(GL_TEXTURE_CUBE_MAP, lastTexture);
    }
    
    return self;
}

+(instancetype)shadowCubeMapWithSize:(CGSize)size
{
    return [[[self class] alloc] initWithSize:size PixelType:GL_FLOAT PixelFormat:GL_DEPTH_COMPONENT];
}

+(instancetype)emptyCanvasToDrawWithSize:(CGSize)size;
{
    return [[[self class] alloc] initWithSize:size PixelType:GL_UNSIGNED_SHORT_5_6_5 PixelFormat:GL_RGB];
}

+(instancetype)cubeMapWithSize:(CGSize)size PixelType:(GLenum)pixelType PixelFormat:(GLenum)pixelFormat Data:(const void *)data
{
    BFGLTextureCubeMap *texture = [[[self class] alloc] initWithSize:size PixelType:pixelType PixelFormat:pixelFormat];
    if (texture)
        [texture setData:data];
    
    return texture;
}

-(void)setMinifyingFuction:(GLenum)fun
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &lastTexture);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, [super texture]);
    
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, fun);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, lastTexture);
}

-(void)setMagnificationFunction:(GLenum)fun
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &lastTexture);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, [super texture]);
    
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, fun);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, lastTexture);
}

-(void)setWrapFunction:(GLenum)fun ForCoordinate:(GLenum)coord
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &lastTexture);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, [super texture]);
    
    glTexParameteri(GL_TEXTURE_CUBE_MAP, coord, fun);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, lastTexture);
}

-(void)setData:(const GLvoid *)data
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &lastTexture);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, [super texture]);
    
    GLuint offset = m_size.width * m_size.height * sizeof(GLuint);
    for (uint i = 0; i < 6; ++i)
        glTexSubImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, m_size.width, m_size.height, m_pixelFormat, m_pixelType, (char *)data + offset * i);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, lastTexture);
}

-(void)setData:(const GLvoid *)data ForFace:(GLenum)face;
{
    [self setData:data WithOffset:CGPointMake(0.0, 0.0) Size:m_size ForFace:face];
}

-(void)setData:(const GLvoid *)data WithOffset:(CGPoint)offset Size:(CGSize)size ForFace:(GLenum)face;
{
    GLint lastTexture;
    glGetIntegerv(GL_TEXTURE_BINDING_CUBE_MAP, &lastTexture);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, [super texture]);
    
    glTexSubImage2D(face, 0, offset.x, offset.y, size.width, size.height, m_pixelFormat, m_pixelType, data);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, lastTexture);
}

@synthesize size = m_size, pixelType = m_pixelType, pixelFormat = m_pixelFormat;

@end  // BFGLTextureCubeMap

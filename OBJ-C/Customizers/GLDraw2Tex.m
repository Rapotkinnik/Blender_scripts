//
//  GLUtils.m
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//

#import "GLDraw2Tex.h"

@implementation BFGLDraw2Texture

-(instancetype)initWithView:(CGRect)view
{
    self = [super init];
    if (self)
    {
        GLint maxRenderbufferSize;
        glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderbufferSize);
        if (maxRenderbufferSize <= view.size.width ||
            maxRenderbufferSize <= view.size.height)
        {
            @throw [NSException exceptionWithName:@"TextureIsToBigException"
                                           reason:@"This device doesn't support texture pixsels"
                                         userInfo:nil];
        }
        
        m_view = view;
        m_buffer = NULL;
        
        glGenTextures(1, &m_selfTexture);
        glGenFramebuffers(1, &m_framebuffer);
        
        [self setTexture:m_selfTexture];
    }
    
    return self;
}

+(instancetype)draw2TextureWithView:(CGRect)view
{
    return [[[self class] alloc] initWithView:view];
}

-(void)bindBuffer:(GLvoid *)buffer
{
    m_buffer = buffer;
}

-(void)setTexture:(GLuint)texture
{
    m_texture = (texture == 0)?m_selfTexture:texture;
    
    glBindTexture(GL_TEXTURE_2D, m_texture);
    glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, m_view.size.width, m_view.size.height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_texture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        @throw [NSException exceptionWithName:@"FramebufferCompilationException"
                                       reason:@"Framebuffer compilation error"
                                     userInfo:nil];
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

-(void)setProgram:(BFGLProgram *)programm
{
    m_program = programm;
}

-(void)preparation
{

}

-(void)cleanup
{
    glDeleteTextures(1, &m_selfTexture);
    glDeleteFramebuffers(1, &m_framebuffer);
}

-(void)beforeDraw
{
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &m_lastTextre);
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &m_lastFramebuffer);
    glGetIntegerv(GL_VIEWPORT, m_lastViewPort);
    glViewport(m_view.origin.x, m_view.origin.y,
               m_view.size.width, m_view.size.height);
    
    glBindTexture(GL_TEXTURE_2D, m_texture);
    glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
}

-(void)afterDraw
{
    if (m_buffer)
        glReadPixels(m_view.origin.x, m_view.origin.y,
                     m_view.size.width, m_view.size.height,
                     GL_RGB, GL_UNSIGNED_SHORT_5_6_5, m_buffer);
    
    glBindTexture(GL_TEXTURE_2D, m_lastTextre);
    glBindFramebuffer(GL_FRAMEBUFFER, m_lastFramebuffer);
    
    glViewport(m_lastViewPort[0], m_lastViewPort[1],
               m_lastViewPort[2], m_lastViewPort[3]);
}

@synthesize view = m_view, texture = m_texture;

@end  // BFGLToTextureDrawer
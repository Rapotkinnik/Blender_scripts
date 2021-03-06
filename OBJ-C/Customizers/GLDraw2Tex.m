//
//  GLUtils.m
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//

#import "BFFinaly.h"
#import "GLDraw2Tex.h"

@implementation BFGLDraw2Texture

-(instancetype)initWithView:(CGRect)view Attachments:(const GLenum *)attachments
{
    self = [super init];
    if (self)
    {
        m_view = view;
        
        GLint maxRenderbufferSize;
        glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderbufferSize);
        if (MAX(view.size.width, view.size.height) > maxRenderbufferSize)
            @throw [NSException exceptionWithName:@"TextureIsToBigException"
                                           reason:@"This device doesn't support texture pixsels"
                                         userInfo:nil];
        
        glGenFramebuffers(1, &m_framebuffer);
        
        @autoreleasepool
        {
            [self bindCurrentFrameBuffer];
            
            for (;*attachments != 0; attachments++)
            {
                BFGLTexture *texture = nil;
                switch (*attachments) {
                    case GL_DEPTH_ATTACHMENT:
                        texture = [BFGLTexture2D shadowMapWithSize:view.size];
                        break;
                    case GL_STENCIL_ATTACHMENT:
                        break;
                    default:
                        texture = [BFGLTexture2D emptyCanvasToDrawWithSize:view.size];
                }
            
                if (!texture)
                    continue;
            
                glFramebufferTexture2D(GL_FRAMEBUFFER, *attachments, GL_TEXTURE_2D, [texture texture], 0);
                if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
                    @throw [NSException exceptionWithName:@"FramebufferCompilationException"
                                                   reason:@"Framebuffer compilation error"
                                                 userInfo:nil];
            }
        }
    }
    
    return self;
}

+(instancetype)draw2TextureWithView:(CGRect)view Attachments:(const GLenum *)attachments
{
    return [[[self class] alloc] initWithView:view Attachments:attachments];
}

-(BFFinaly *)bindCurrentFrameBuffer
{
    GLint lastFramebuffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &lastFramebuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
    
    return [BFFinaly finalyWithFunctor:^(){ glBindFramebuffer(GL_FRAMEBUFFER, lastFramebuffer); }];
}

-(GLint)getTextureForAttachment:(GLenum)attachment
{
    @autoreleasepool
    {
        [self bindCurrentFrameBuffer];
        
        GLint objectType, objectName;
    
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE, &objectType);
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, &objectName);

        if (objectType == GL_TEXTURE_2D)
            return objectName;
    
        return -1;
    }
}

-(void)setTexture:(GLuint)texture WithTarget:(GLenum)target ForAttachment:(GLuint)attachment
{
    @autoreleasepool
    {
        [self bindCurrentFrameBuffer];
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, target, texture, 0);
    
        GLenum checkin = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (checkin != GL_FRAMEBUFFER_COMPLETE)
            @throw [NSException exceptionWithName:@"FramebufferCompilationException"
                                           reason:[NSString stringWithFormat:@"Framebuffer compilation error %d", checkin] userInfo:nil];
    }
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
    glDeleteFramebuffers(1, &m_framebuffer);
}

-(void)beforeDraw
{
    glGetIntegerv(GL_VIEWPORT, m_lastViewPort);
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &m_lastFramebuffer);
    
    glViewport(m_view.origin.x, m_view.origin.y,
               m_view.size.width, m_view.size.height);
    
    glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
}

-(void)afterDraw
{
    glBindFramebuffer(GL_FRAMEBUFFER, m_lastFramebuffer);
    
    glViewport(m_lastViewPort[0], m_lastViewPort[1],
               m_lastViewPort[2], m_lastViewPort[3]);
}

@synthesize view = m_view;

@end  // BFGLToTextureDrawer
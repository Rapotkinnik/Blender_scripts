//
//  GLUtils.m
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//

#import "GLDraw2Tex.h"

@interface TextureHolder : NSObject

-(id)initWith:(GLenum)pixelFormat DataType:(GLenum)type Rect:(CGRect)rect;
-(id)initWithTexture:(GLuint)texture Buffer:(void*)buffer;

+(instancetype)textureHolderWith:(GLenum)pixelFormat DataType:(GLenum)type Rect:(CGRect)rect;
+(instancetype)textureHolderWithTexture:(GLuint)texture Buffer:(void*)buffer;

@property (nonatomic, assign) void *buffer;
@property (nonatomic, assign) BOOL isCreated;
@property (nonatomic, assign) GLuint texture;

@end

@implementation TextureHolder

-(id)initWith:(GLenum)pixelFormat DataType:(GLenum)type Rect:(CGRect)rect
{
    self = [super init];
    if (self)
    {
        GLint maxTextureSize = 0;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        if (MAX(rect.size.height, rect.size.width) > maxTextureSize)
            @throw [NSException exceptionWithName:@"TextureTooLarge"
                                           reason:@"This device doesn't support texture with that size"
                                         userInfo:nil];
        GLuint texture;
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);

        glTexImage2D(GL_TEXTURE_2D, 0, pixelFormat, rect.size.width, rect.size.height, 0, pixelFormat, type, NULL);
        
        GLenum error = GL_NO_ERROR;
        if ((error = glGetError()) != GL_NO_ERROR)
            @throw [NSException exceptionWithName:@"WrongTextureParams"
                                           reason:@"Wrang texture params were passed to"
                                         userInfo:nil];
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        glBindTexture(GL_TEXTURE_2D, 0);
        
        [self setIsCreated:YES];
        [self setTexture:texture];
    }
    
    return self;
}

-(id)initWithTexture:(GLuint)texture Buffer:(void*)buffer
{
    self = [super init];
    if (self)
    {
        [self setBuffer:buffer];
        [self setTexture:texture];
        [self setIsCreated:NO];
    }
    
    return self;
}

+(instancetype)textureHolderWith:(GLenum)pixelFormat DataType:(GLenum)type Rect:(CGRect)rect
{
    return [[[self class] alloc] initWith:pixelFormat DataType:type Rect:rect];
}

+(instancetype)textureHolderWithTexture:(GLuint)texture Buffer:(void*)buffer
{
    return [[[self class] alloc] initWithTexture:texture Buffer:buffer];
}

-(void)dealloc
{
    GLuint texture = [self texture];
    if ([self isCreated])
        glDeleteTextures(1, &texture);
}

@end


@implementation BFGLDraw2Texture

-(instancetype)initWithView:(CGRect)view Attachments:(const GLenum *)attachments
{
    self = [super init];
    if (self)
    {
        m_view = view;
        m_attachments = [NSMutableDictionary dictionary];
        
        GLint maxRenderbufferSize;
        glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderbufferSize);
        if (MAX(view.size.width, view.size.height) > maxRenderbufferSize)
            @throw [NSException exceptionWithName:@"TextureIsToBigException"
                                           reason:@"This device doesn't support texture pixsels"
                                         userInfo:nil];
        
        glGenFramebuffers(1, &m_framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
        
        for (;*attachments != 0; attachments++)
        {
            TextureHolder *textureHolder = nil;
            switch (*attachments) {
                case GL_DEPTH_ATTACHMENT:
                    textureHolder = [TextureHolder textureHolderWith:GL_DEPTH_COMPONENT DataType:GL_UNSIGNED_SHORT Rect:m_view];
                    break;
                case GL_STENCIL_ATTACHMENT:
                    break;
                default:
                    textureHolder = [TextureHolder textureHolderWith:GL_RGB DataType:GL_UNSIGNED_SHORT_5_6_5 Rect:m_view];
            }
            
            if (!textureHolder)
                continue;
            
            [m_attachments setObject:textureHolder
                              forKey:[[NSNumber numberWithUnsignedInt:*attachments] stringValue]];
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, *attachments, GL_TEXTURE_2D, [textureHolder texture], 0);
            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            {
                @throw [NSException exceptionWithName:@"FramebufferCompilationException"
                                               reason:@"Framebuffer compilation error"
                                             userInfo:nil];
            }
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    
    return self;
}

+(instancetype)draw2TextureWithView:(CGRect)view Attachments:(const GLenum *)attachments
{
    return [[[self class] alloc] initWithView:view Attachments:attachments];
}

-(GLuint)getTextureForAttachment:(GLuint)attachment
{
    TextureHolder *textureHolder = [m_attachments objectForKey:[[NSNumber numberWithUnsignedInt:attachment] stringValue]];
    if (textureHolder)
        return [textureHolder texture];
    
    return 0;
}

-(void)setTexture:(GLuint)texture ForAttachment:(GLenum)attachment
{
    
    NSString *attachment_key = [[NSNumber numberWithUnsignedInt:attachment] stringValue];
    TextureHolder *textureHolder = [m_attachments objectForKey:attachment_key];
    
    if (texture == 0)
        return [m_attachments removeObjectForKey:attachment_key];
    
    if (textureHolder && ![textureHolder isCreated])
        [textureHolder setTexture:texture];
    else
        [m_attachments setObject:[TextureHolder textureHolderWithTexture:texture Buffer:0] forKey:attachment_key];
    
    glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, texture, 0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        @throw [NSException exceptionWithName:@"FramebufferCompilationException"
                                       reason:@"Framebuffer compilation error"
                                     userInfo:nil];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

-(void)setBuffer:(void *)buffer ForAttachment:(GLenum)attachment
{
    TextureHolder *textureHolder = [m_attachments objectForKey:[[NSNumber numberWithUnsignedInt:attachment] stringValue]];
    if (textureHolder)
        [textureHolder setBuffer:buffer];
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
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &m_lastFramebuffer);
    glGetIntegerv(GL_VIEWPORT, m_lastViewPort);
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
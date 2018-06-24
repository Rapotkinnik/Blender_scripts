//
//  GLUtils.h
//  Snowflackes
//
//  Created by Рапоткин Никалай on 23.08.2017.
//

#import "GLProgram.h"
#import "BFGLTexture.h"

@interface BFGLDraw2Texture : NSObject <BFGLCustomizer>
{
    CGRect m_view;
    GLuint m_framebuffer;
    
    GLint  m_lastFramebuffer;
    GLint  m_lastViewPort[4];
    
    BFGLProgram *m_program;
}

@property (nonatomic, readonly) CGRect view;

-(instancetype)initWithView:(CGRect)view Attachments:(const GLenum *)attachments;  // Список буферов с запирающим 0
+(instancetype)draw2TextureWithView:(CGRect)view Attachments:(const GLenum *)attachments;

-(GLint)getTextureForAttachment:(GLenum)attachment;
-(void)setTexture:(GLuint)texture WithTarget:(GLenum)target ForAttachment:(GLuint)attachment;

@end  // BFGLDraw2Texture
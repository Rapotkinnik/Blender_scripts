//
//  GLUtils.h
//  Snowflackes
//
//  Created by Рапоткин Никалай on 23.08.2017.
//

#import "GLProgram.h"

@interface BFGLDraw2Texture : NSObject <BFGLCustomizer>
{
    CGRect m_view;
    GLuint m_texture;
    GLuint m_selfTexture;
    GLuint m_framebuffer;
    
    GLint  m_lastTextre;
    GLint  m_lastFramebuffer;
    GLint  m_lastViewPort[4];

    GLvoid *m_buffer;
    BFGLProgram *m_program;
}

@property (nonatomic, readonly) CGRect view;
@property (nonatomic, readwrite) GLuint texture;

-(instancetype)initWithView:(CGRect)view;
+(instancetype)draw2TextureWithView:(CGRect)view;

-(void)bindBuffer:(GLvoid *)buffer;

@end  // BFGLDraw2Texture
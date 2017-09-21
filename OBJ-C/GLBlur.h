//
//  GLUtils.h
//  Snowflackes
//
//  Created by Рапоткин Никалай on 23.08.2017.
//

#import "GLUtils.h"

typedef struct {
    GLfloat vertical;
    GLfloat horizontal;
} BlureAmount;

@interface BFGLBlur : NSObject <BFGLCustomizer>
{
    GLuint m_texture;
    BlureAmount m_blurAmount;
    
    GLint m_positionIndex;
    GLint m_texCoordIndex;
    GLint m_blurAmountIndex;
    GLint m_screemTextureIndex;
    
    BFGLProgram *m_blurProgram;
}

@property (nonatomic) GLuint texture;
@property (nonatomic) BlureAmount blurAmount;

-(instancetype)initWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount;
+(instancetype)blurWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount;
-(instancetype)initWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount Customizers:(NSArray *)customizers;
+(instancetype)blurWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount Customizers:(NSArray *)customizers;

-(NSArray *)customizers;
-(void)addCustomizer:(NSObject<BFGLCustomizer> *)customizer;
-(void)removeCustomizer:(NSObject<BFGLCustomizer> *)customizer;

@end  // BFGLBlur

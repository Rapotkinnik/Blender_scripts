//
//  GLUtils.m
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//

#import "GLBlur.h"

NSString *kVertexShader = @""
"attribute lowp vec2 position;\n"
"attribute lowp vec2 texCoord;\n"
"varying lowp vec2 outTexCoord;\n"
"\n"
"void main()\n"
"{\n"
"    outTexCoord = texCoord;\n"
"    gl_Position = vec4(position, 0.0, 0.0);\n"
"}";

NSString *kFragmentShader = @""
"uniform sampler2D screenTexture;  // offscreen texture, witch was created on previous render step\n"
"uniform mediump vec2 blurAmount;  // Amount of blur at x, y\n"
"\n"
"varying lowp vec2 outTexCoord;\n"
"\n"
"lowp float blurSizeH = blurAmount.x / 300.0;\n"
"lowp float blurSizeV = blurAmount.y / 200.0;\n"
"\n"
"void main()\n"
"{\n"
"    lowp vec4 sum = vec4(0.0);\n"
"    for (int x = -4; x <= 4; x + 2)\n"
"        for (int y = -4; y <= 4; y + 2)\n"
"            sum += texture2D(screenTexture,\n"
"                             vec2(outTexCoord.x + float(x) * blurSizeH,\n"
"                                  outTexCoord.y + float(y) * blurSizeV)) / 16.0;\n"
"    gl_FragColor = sum;\n"
"}";

const GLfloat kFigure[] = {-1.0, -1.0, 0.0, 0.0,
                           -1.0,  1.0, 1.0, 0.0,
                            1.0,  1.0, 1.0, 1.0,
                            1.0, -1.0, 0.1, 1.0};

const GLubyte kIndices[] = {0, 1, 2, 2, 3, 0};

@implementation BFGLBlur

-(instancetype)initWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount
{
    return [self initWithTexture:texure BlurAmount:blurAmount Customizers:nil];
}

-(instancetype)initWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount Customizers:(NSArray *)customizers
{
    self = [super init];
    if (self)
    {
        m_texture = texure;
        m_blurAmount = blurAmount;
        m_blurProgram = [BFGLProgram glProgramWithVertexShader:kVertexShader
                                                FragmentShader:kFragmentShader
                                                   Customizers:customizers];
        
        m_positionIndex = [m_blurProgram attribute:@"position"];
        m_texCoordIndex = [m_blurProgram attribute:@"texCoord"];
        m_blurAmountIndex = [m_blurProgram uniform:@"blurAmount"];
        m_screemTextureIndex = [m_blurProgram uniform:@"screenTexture"];
    }
    
    return self;
}

+(instancetype)blurWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount
{
    return [[[self class] alloc] initWithTexture:texure BlurAmount:blurAmount];
}

+(instancetype)blurWithTexture:(GLuint)texure BlurAmount:(BlureAmount)blurAmount Customizers:(NSArray *)customizers
{
    return [[[self class] alloc] initWithTexture:texure BlurAmount:blurAmount Customizers:customizers];
}

-(NSArray *)customizers
{
    return [m_blurProgram customizers];
}

-(void)addCustomizer:(NSObject<BFGLCustomizer> *)customizer
{
    [m_blurProgram addCustomizer:customizer];
}

-(void)removeCustomizer:(NSObject<BFGLCustomizer> *)customizer
{
    [m_blurProgram removeCustomizer:customizer];
}

-(void)setProgram:(BFGLProgram *)programm
{
    m_program = programm;
}

-(void)afterDraw
{
    [m_blurProgram drawFunctor:^(BFGLProgram *program){
        glEnableVertexAttribArray(m_positionIndex);
        glEnableVertexAttribArray(m_texCoordIndex);

        GLint prevTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTexture);

        glBindTexture(GL_TEXTURE_2D, m_texture);

        glUniform1i(m_screemTextureIndex, 0);
        glUniform2f(m_blurAmountIndex, m_blurAmount.horizontal, m_blurAmount.vertical);

        glVertexAttribPointer(m_positionIndex, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GL_FLOAT), kFigure);
        glVertexAttribPointer(m_texCoordIndex, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GL_FLOAT), &kFigure[2]);

        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, kIndices);

        glBindTexture(GL_TEXTURE_2D, 0);
    }];
}

-(void)preparation {}
-(void)cleanup {}
-(void)beforeDraw {}

@synthesize texture = m_texture, blurAmount = m_blurAmount;

@end  // BFGLBlur
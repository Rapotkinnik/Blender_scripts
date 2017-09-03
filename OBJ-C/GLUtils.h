//
//  GLUtils.h
//  Snowflackes
//
//  Created by Рапоткин Никалай on 23.08.2017.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

//// Uniform index.
//enum
//{
//    UNIFORM_MODELVIEWPROJECTION_MATRIX,
//    UNIFORM_NORMAL_MATRIX,
//    NUM_UNIFORMS
//};
//
//// Attribute index.
//enum
//{
//    ATTRIB_VERTEX,
//    ATTRIB_COLOR,
//    ATTRIB_NORMAL,
//    ATTRIB_TEX_CO,
//    NUM_ATTRIBUTES
//};

@class BFGLProgram;

typedef void(BFGLFunction)(BFGLProgram *program);
typedef void(^BFGLFunctor)(BFGLProgram *program);

@protocol BFGLCustomizer <NSObject>

-(void)setProgram:(BFGLProgram *)programm;
-(void)preparation;
-(void)cleanup;
-(void)beforeDraw;
-(void)afterDraw;
-(void)draw;

@end

@interface BFGLToTextureDrawer : NSObject <BFGLCustomizer>
{
    CGRect m_view;
    GLuint m_texture;
    GLuint m_selfTexture;
    GLuint m_framebuffer;
    GLint  m_lastViewPort[4];

    GLvoid *m_buffer;
    BFGLProgram *m_programm;
}

@property (nonatomic, readonly) CGRect view;
@property (nonatomic, readwrite) GLuint texture;

-(instancetype)initWithView:(CGRect)view;
+(instancetype)textureDrawerWithView:(CGRect)view;

-(void)bindBuffer:(GLvoid *)buffer;

@end

@interface BFGLVBODrawer : NSObject <BFGLCustomizer>
{
    
}

@end

@interface BFGLProgram : NSObject
{
    GLuint m_program;
    GLuint m_vertexArray;
    GLuint m_vertexBuffer;
    NSMutableArray *m_customizers;
    NSMutableDictionary *m_attribs;
    NSMutableDictionary *m_uniforms;
}

@property (readonly) GLuint program;
@property (readonly) NSArray *customizers;
@property (readonly) NSDictionary *attribs;
@property (readonly) NSDictionary *uniforms;

-(instancetype)initWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader Customizers:(NSArray *) customizers;
-(instancetype)initWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath Customizers:(NSArray *) customizers;
+(instancetype)glProgramWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader;
+(instancetype)glProgramWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath;
+(instancetype)glProgramWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader Customizers:(NSArray *) customizers;
+(instancetype)glProgramWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath Customizers:(NSArray *) customizers;

-(void)addCustomizer:(NSObject<BFGLCustomizer> *)customizer;
-(void)removeCustomizer:(NSObject<BFGLCustomizer> *)customizer;
-(void)draw:(BFGLFunctor)functor;

@end  // BFGLProgram
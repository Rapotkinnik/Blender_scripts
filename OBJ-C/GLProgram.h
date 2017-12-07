//
//  GLUtils.h
//  Snowflackes
//
//  Created by Рапоткин Никалай on 23.08.2017.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

@class BFGLProgram;

typedef void(^BFGLFunctor)(BFGLProgram *program);

@protocol BFGLDrawable <NSObject>

-(void)beforeDraw:(BFGLProgram *)program;
-(void)afterDraw:(BFGLProgram *)program;
-(void)draw:(BFGLProgram *)program;

@end

@protocol BFGLCustomizer <NSObject>

-(void)setProgram:(BFGLProgram *)programm;
-(void)preparation;
-(void)cleanup;
-(void)beforeDraw;
-(void)afterDraw;

@end

@interface BFGLFunctorWrapper : NSObject <BFGLDrawable>
{
    BFGLFunctor m_functorDraw;
    BFGLFunctor m_functorBefor;
    BFGLFunctor m_functorAfter;
}

-(instancetype)initWithFunctorDraw:(BFGLFunctor)functor;
-(instancetype)initWithFunctorBeforDraw:(BFGLFunctor)functor;
-(instancetype)initWithFunctorAfterDraw:(BFGLFunctor)functor;
-(instancetype)initWithFunctorDraw:(BFGLFunctor)drawFunctor BeforDraw:(BFGLFunctor)beforFunctor AfterDraw:(BFGLFunctor)afterFunctor;
+(instancetype)functorWrapperWithFunctorDraw:(BFGLFunctor)functor;
+(instancetype)functorWrapperWithFunctorBeforDraw:(BFGLFunctor)functor;
+(instancetype)functorWrapperWithFunctorAfterDraw:(BFGLFunctor)functor;
+(instancetype)functorWrapperWithFunctorDraw:(BFGLFunctor)drawFunctor BeforDraw:(BFGLFunctor)beforFunctor AfterDraw:(BFGLFunctor)afterFunctor;
    
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

@property (nonatomic, readonly) GLuint program;
@property (nonatomic, readonly) NSArray *customizers;

-(instancetype)initWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader Customizers:(NSArray *) customizers;
-(instancetype)initWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath Customizers:(NSArray *) customizers;
+(instancetype)glProgramWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader;
+(instancetype)glProgramWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath;
+(instancetype)glProgramWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader Customizers:(NSArray *) customizers;
+(instancetype)glProgramWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath Customizers:(NSArray *) customizers;

-(void)addCustomizer:(NSObject<BFGLCustomizer> *)customizer;
-(void)removeCustomizer:(NSObject<BFGLCustomizer> *)customizer;
-(void)drawFunctor:(BFGLFunctor)functor;
-(void)drawFunctors:(NSArray *)functors;
-(void)drawObjects:(NSArray *)objects;
-(GLint)attribute:(NSString *)name;
-(GLint)uniform:(NSString *)name;

@end  // BFGLProgram
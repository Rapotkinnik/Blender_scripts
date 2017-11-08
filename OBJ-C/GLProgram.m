//
//  GLUtils.m
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//

#import "GLProgram.h"

const NSString *TYPES_PATTERN = @"int|flaot|bool|b?vec[2-4]|mat[2-4]|sampler(1D|2D|Cube)";

@implementation BFGLFunctorWrapper

-(instancetype)initWithFunctor:(BFGLFunctor)functor
{
    self = [super init];
    if (self)
    {
        m_functor = functor;
    }
    
    return self;
}

+(instancetype)functorWrapperWithFunctor:(BFGLFunctor)functor
{
    return [[[self class] alloc] initWithFunctor:functor];
}

-(void)beforeDraw:(BFGLProgram *)program {}
-(void)afterDraw:(BFGLProgram *)program {}
-(void)draw:(BFGLProgram *)program
{
    m_functor(program);
}

@end  // BFGLFunctorWrapper

@implementation BFGLProgram

-(instancetype)initWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader Customizers:(NSArray *) customizers
{
    self = [super init];
    if (self)
    {
        GLuint vertShaderId;
        GLuint fragShaderId;
        
        m_attribs = [NSMutableDictionary dictionary];
        m_uniforms = [NSMutableDictionary dictionary];
        m_customizers = [NSMutableArray arrayWithArray:customizers];
        
        for (NSObject *customizer in customizers)
            if (![[customizer class] conformsToProtocol:@protocol(BFGLCustomizer)])
            {
                @throw [NSException exceptionWithName:@"NotConformingProtocolException"
                                               reason:@"Customizer doesn't conform protocol BFGLCustomizer"
                                             userInfo:nil];
            }
        
        NSError *error = nil;
        NSString *mainPattern = @"void\\s+main\\s*\\(\\s*\\)";
        NSString *structPattern = @"(?<=struct\\s{1,10})\\w+(?=\\s{0,5}\\{{0,1})";
        NSString *allTypesPattern = @"int|flaot|bool|b?vec[2-4]|mat[2-4]|sampler(1D|2D|Cube)";
        NSRegularExpression *mainRegExpr = [NSRegularExpression regularExpressionWithPattern:mainPattern options:0 error:&error];
        NSRegularExpression *structRegExpr = [NSRegularExpression regularExpressionWithPattern:structPattern options:0 error:&error];
        
        NSString *line = nil;
        NSTextCheckingResult *match = nil;
        NSEnumerator *vertexShaderEnumerator = [[vertShader componentsSeparatedByString:@"\n"] objectEnumerator];
        while ((line = [vertexShaderEnumerator nextObject]) &&
               !(match = [mainRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
        {
            if ((match = [structRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
                allTypesPattern = [allTypesPattern stringByAppendingFormat: @"|%@", [line substringWithRange:[match range]]];
        }
        
        NSEnumerator *fragmentShaderEnumerator = [[fragShader componentsSeparatedByString:@"\n"] objectEnumerator];
        while ((line = [fragmentShaderEnumerator nextObject]) &&
               !(match = [mainRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
        {
            if ((match = [structRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
                allTypesPattern = [allTypesPattern stringByAppendingFormat: @"|%@", [line substringWithRange:[match range]]];
        }
        
        NSString *attribPattern = [NSString stringWithFormat:@"(?<=attribute\\s{0,5}(lowp|mediump|highp)?\\s{1,5}(%@)\\s{1,10})\\w+(?=;|\\[)", allTypesPattern];
        NSString *uniformPattern = [NSString stringWithFormat:@"(?<=uniform\\s{0,5}(lowp|mediump|highp)?\\s{1,5}(%@)\\s{1,10})\\w+(?=;|\\[)", allTypesPattern];
        NSRegularExpression *attribRegExpr = [NSRegularExpression regularExpressionWithPattern:attribPattern options:0 error:&error];
        NSRegularExpression *uniformRegExpr = [NSRegularExpression regularExpressionWithPattern:uniformPattern options:0 error:&error];
        
        vertexShaderEnumerator = [[vertShader componentsSeparatedByString:@"\n"] objectEnumerator];
        while ((line = [vertexShaderEnumerator nextObject]) &&
              !(match = [mainRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
        {
            if ((match = [attribRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
                [m_attribs setObject:[NSNull null] forKey:[line substringWithRange:[match range]]];
            
            if ((match = [uniformRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
                [m_uniforms setObject:[NSNull null] forKey:[line substringWithRange:[match range]]];
        }

        fragmentShaderEnumerator = [[fragShader componentsSeparatedByString:@"\n"] objectEnumerator];
        while ((line = [fragmentShaderEnumerator nextObject]) &&
               !(match = [mainRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
        {
            if ((match = [uniformRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
                [m_uniforms setObject:[NSNull null] forKey:[line substringWithRange:[match range]]];
        }
        
        
        if (![self compileShader:&vertShaderId WithType:GL_VERTEX_SHADER WithSource:vertShader] ||
            ![self compileShader:&fragShaderId WithType:GL_FRAGMENT_SHADER WithSource:fragShader])
        {
            @throw [NSException exceptionWithName:@"LoadingShadersException"
                                           reason:@""
                                         userInfo:nil];
        }
        
        m_program = glCreateProgram();
        
        // Attach vertex and fragment shaders to program.
        glAttachShader(m_program, vertShaderId);
        glAttachShader(m_program, fragShaderId);
        
        // Link program.
        if (![self linkProgram:m_program]) {
            NSLog(@"Failed to link program: %d", m_program);
            
            if (vertShader) {
                glDeleteShader(vertShaderId);
                vertShader = 0;
            }
            if (fragShader) {
                glDeleteShader(fragShaderId);
                fragShader = 0;
            }
            if (m_program) {
                glDeleteProgram(m_program);
                m_program = 0;
            }
            
            NSLog(@"Failed to load vertex shader");
            @throw [NSException exceptionWithName:@"LoadingShadersException"
                                           reason:@""
                                         userInfo:nil];
        }
        
        // Release vertex and fragment shaders.
        if (vertShader) {
            glDetachShader(m_program, vertShaderId);
            glDeleteShader(vertShaderId);
        }
        if (fragShader) {
            glDetachShader(m_program, fragShaderId);
            glDeleteShader(fragShaderId);
        }
        
        NSArray *attribKeys = [m_attribs allKeys];
        for (NSString *key in attribKeys)
            [m_attribs setObject:[NSNumber numberWithInt:glGetAttribLocation(m_program, [key UTF8String])] forKey:key];
        
        NSArray *uniformKeys = [m_uniforms allKeys];
        for (NSString *key in uniformKeys)
            [m_uniforms setObject:[NSNumber numberWithInt:glGetUniformLocation(m_program, [key UTF8String])] forKey:key];
        
        for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        {
            [customizer setProgram:self];
            [customizer preparation];
        }
    }
    
    return self;
}

-(instancetype)initWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath Customizers:(NSArray *) customizers
{
    NSError *error = nil;
    NSString *vertShader = [NSString stringWithContentsOfFile:vertShaderPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (!vertShader || error) {
        NSString * reason = [NSString stringWithFormat:@"t must be in [0 .. 1], not %f;", 0.1];
        
        NSLog(@"Failed to load vertex shader");
        @throw [NSException exceptionWithName:@"LoadingShadersException"
                                       reason:reason
                                     userInfo:nil];
    }
    
    NSString *fragShader = [NSString stringWithContentsOfFile:fragShaderPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (!vertShader || error) {
        NSString * reason = [NSString stringWithFormat:@"t must be in [0 .. 1], not %f;", 0.1];
        
        NSLog(@"Failed to load vertex shader");
        @throw [NSException exceptionWithName:@"LoadingShadersException"
                                       reason:reason
                                     userInfo:nil];
    }
    
    return [self initWithVertexShader:vertShader FragmentShader:fragShader Customizers:customizers];
}

+(instancetype)glProgramWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader
{
    return [[[self class] alloc] initWithVertexShader:vertShader FragmentShader:fragShader Customizers:nil];
}

+(instancetype)glProgramWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath
{
    return [[[self class] alloc] initWithVertexShaderPath:vertShaderPath FragmentShaderPath:fragShaderPath Customizers:nil];
}

+(instancetype)glProgramWithVertexShader:(NSString *)vertShader FragmentShader:(NSString *)fragShader Customizers:(NSArray *) customizers
{
    return [[[self class] alloc] initWithVertexShader:vertShader FragmentShader:fragShader Customizers:customizers];
}

+(instancetype)glProgramWithVertexShaderPath:(NSString *)vertShaderPath FragmentShaderPath:(NSString *)fragShaderPath Customizers:(NSArray *) customizers
{
    return [[[self class] alloc] initWithVertexShaderPath:vertShaderPath FragmentShaderPath:fragShaderPath Customizers:customizers];
}

-(void)dealloc
{
    if (m_program) {
        glUseProgram(m_program);
        
        for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        {
            [customizer cleanup];
            [customizer setProgram:nil];
        }
        
        glUseProgram(0);
        glDeleteProgram(m_program);
        m_program = 0;
    }
}

-(void)addCustomizer:(NSObject<BFGLCustomizer> *)customizer
{
    [customizer setProgram:self];
    [m_customizers addObject:customizer];
}

-(void)removeCustomizer:(NSObject<BFGLCustomizer> *)customizer
{
    [customizer setProgram:nil];
    [m_customizers removeObject:customizer];
}

-(void)drawFunctor:(BFGLFunctor)functor
{
    GLint prev_program;
    glGetIntegerv(GL_CURRENT_PROGRAM, &prev_program);
    
    glUseProgram(m_program);
    
    for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        [customizer beforeDraw];
    
    functor(self);
    
    for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        [customizer afterDraw];
    
    NSNumber *value;
    NSEnumerator *attribEnumerator = [m_attribs objectEnumerator];
    while(value = [attribEnumerator nextObject])
        glDisableVertexAttribArray([value integerValue]);

    glUseProgram(prev_program);
}

-(void)drawFunctors:(NSArray *)functors
{
    GLint prev_program;
    glGetIntegerv(GL_CURRENT_PROGRAM, &prev_program);
    
    glUseProgram(m_program);
    
    for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        [customizer beforeDraw];
    
    for (BFGLFunctor functor in functors)
        functor(self);
    
    for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        [customizer afterDraw];
    
    NSNumber *value;
    NSEnumerator *attribEnumerator = [m_attribs objectEnumerator];
    while(value = [attribEnumerator nextObject])
        glDisableVertexAttribArray([value integerValue]);
    
    glUseProgram(prev_program);
}

-(void)drawObjects:(NSArray *)objects
{
    GLint prev_program;
    glGetIntegerv(GL_CURRENT_PROGRAM, &prev_program);
    
    glUseProgram(m_program);
    
    for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        [customizer beforeDraw];
    
    for (NSObject<BFGLDrawable> *object in objects)
        [object beforeDraw:self];
    
    for (NSObject<BFGLDrawable> *object in objects)
        [object draw:self];
    
    for (NSObject<BFGLDrawable> *object in objects)
        [object afterDraw:self];
    
    for (NSObject<BFGLCustomizer> *customizer in m_customizers)
        [customizer afterDraw];
    
    NSNumber *value;
    NSEnumerator *attribEnumerator = [m_attribs objectEnumerator];
    while(value = [attribEnumerator nextObject])
        glDisableVertexAttribArray([value integerValue]);
    
    glUseProgram(prev_program);
}

-(GLint)attribute:(NSString *)name
{
    NSNumber *value = [m_attribs objectForKey:name];
    if (value)
        return (GLint)[value integerValue];
    
    @throw [NSException exceptionWithName:@"NotExistAttributeException"
                                   reason:[NSString stringWithFormat:@"There is no attribute with the name \"%@\"", name]
                                 userInfo:nil];
}

-(GLint)uniform:(NSString *)name
{
    NSNumber *value = [m_uniforms objectForKey:name];
    if (value)
        return (GLint)[value integerValue];
    
    @throw [NSException exceptionWithName:@"NotExistUniformException"
                                   reason:[NSString stringWithFormat:@"There is no uniform with the name \"%@\"", name]
                                 userInfo:nil];
}

-(BOOL)compileShader:(GLuint *)shaderID WithType:(GLenum)type WithSource:(NSString *)shader
{
    GLint status;
    const GLchar *source = (GLchar *)[shader UTF8String];
    
    *shaderID = glCreateShader(type);
    glShaderSource(*shaderID, 1, &source, NULL);
    glCompileShader(*shaderID);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shaderID, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shaderID, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shaderID, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shaderID);
        return NO;
    }
    
    return YES;
}

-(BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

-(BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@synthesize program = m_program, customizers = m_customizers;

@end  // BFGLProgram
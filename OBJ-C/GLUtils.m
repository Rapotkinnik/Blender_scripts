//
//  GLUtils.m
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//

#import "GLUtils.h"

@implementation BFGLToTextureDrawer

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
        
        GLenum error = glGetError();
        
        glGenTextures(1, &m_selfTexture);
        glGenFramebuffers(1, &m_framebuffer);
        
        error = glGetError();
        
        [self setTexture:m_selfTexture];
        
        error = glGetError();
    }
    
    return self;
}

+(instancetype)textureDrawerWithView:(CGRect)view
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

@implementation BFGLBuffCleaner

-(instancetype)initWithColor:(CIColor *)color Mask:(GLbitfield)mask
{
    self = [super init];
    if (self)
    {
        m_color = color;
        m_mask = mask;
    }
    
    return self;
}

+(instancetype)buffCleanerWithColor:(CIColor *)color Mask:(GLbitfield)mask
{
    return [[[self class] alloc] initWithColor:(CIColor *)color Mask:(GLbitfield)mask];
}

-(void)afterDraw:(BFGLProgram *)program {}
-(void)beforeDraw:(BFGLProgram *)program {}
-(void)draw:(BFGLProgram *)program
{
    glClearColor([m_color red], [m_color green], [m_color blue], [m_color alpha]);
    glClear(m_mask);
}

@synthesize color = m_color, mask = m_mask;

@end  // BFGLBuffCleaner

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
        NSString *mainPattern = @"void\\s+main\\s*\(\\s*\)";
        NSString *attribPattern = @"(?<=attribute\\s{1,10}(lowp|mediump|highp)?\\s{0,10}(int|flaot|vec2|vec3|vec4|mat2|mat3|mat4|sampler1D|sampler2D){1}\\s{1,10})\\S+(?=;)";
        NSString *uniformPattern = @"(?<=uniform\\s{1,10}(lowp|mediump|highp)?\\s{0,10}(int|flaot|vec2|vec3|vec4|mat2|mat3|mat4|sampler1D|sampler2D){1}\\s{1,10})\\S+(?=;)";
        NSRegularExpression *mainRegExpr = [NSRegularExpression regularExpressionWithPattern:mainPattern options:0 error:&error];
        NSRegularExpression *attribRegExpr = [NSRegularExpression regularExpressionWithPattern:attribPattern options:0 error:&error];
        NSRegularExpression *uniformRegExpr = [NSRegularExpression regularExpressionWithPattern:uniformPattern options:0 error:&error];
        
        NSString *line = nil;
        NSTextCheckingResult *match;
        NSEnumerator   *vertexShaderEnumerator = [[vertShader componentsSeparatedByString:@"\n"] objectEnumerator];
        while ((line = [vertexShaderEnumerator nextObject]) &&
              !(match = [mainRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
        {
            if ((match = [attribRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
                [m_attribs setObject:[NSNull null] forKey:[line substringWithRange:[match range]]];
            
            if ((match = [uniformRegExpr firstMatchInString:line options:0 range:NSMakeRange(0, [line length])]))
                [m_uniforms setObject:[NSNull null] forKey:[line substringWithRange:[match range]]];
        }

        NSEnumerator   *fragmentShaderEnumerator = [[fragShader componentsSeparatedByString:@"\n"] objectEnumerator];
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
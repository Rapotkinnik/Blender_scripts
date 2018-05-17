//
//  BFCandleFlame.m
//  TestProject
//
//  Created by Рапоткин Николай on 01.04.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import "BFCandleFlame.h"

static NSTimeInterval kFrameDuration = 1.0 / 30.0;  // Время одного кадра при 15 кадрах в секунду

@implementation LinearCircularStrategy

-(id)initWithFrameDuration:(NSTimeInterval)duration
{
    self = [super init];
    if (self)
    {
        m_frameDuration = duration;
    }
    
    return self;
}

+(instancetype)linearCircularStrategyWithFrameDuration:(NSTimeInterval)duration
{
    return [[[self class] alloc] initWithFrameDuration:duration];
}

-(UInt32)activeTextureOn:(NSTimeInterval)timeSinceLastDraw In:(UInt32)textureCount
{
    
    NSTimeInterval duration = textureCount * m_frameDuration;
    m_drawTime += timeSinceLastDraw;
    if (m_drawTime >= duration)
        m_drawTime -= duration;
    
    return textureCount * m_drawTime / duration;
}

@end

@implementation SpriteSheetHolder

-(id)initWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    self = [super init];
    if (self)
    {
        NSError *error;
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:GLKTextureLoaderOriginBottomLeft, [NSNumber numberWithBool:YES], nil];
        GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfData:data options:options error:&error];
        if (!texture)
            @throw [NSException exceptionWithName:@"TextureLoadingException"
                                           reason:[NSString stringWithFormat:@"Can't load texture from data with error code :%d", [error code]]
                                         userInfo:nil];
        
        m_texture = [texture name];
        m_rowCount = row;
        m_columnCount = column;
        m_duration = kFrameDuration * row * column;
    }
    
    return self;
}

-(id)initWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    self = [super init];
    if (self)
    {
        NSError *error;
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:GLKTextureLoaderOriginBottomLeft, [NSNumber numberWithBool:YES], nil];
        GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
        if (!texture)
            @throw [NSException exceptionWithName:@"TextureLoadingException"
                                           reason:[NSString stringWithFormat:@"Can't load texture from file %@ with error code :%d", path, [error code]]
                                         userInfo:nil];
        
        m_texture = [texture name];
        m_rowCount = row;
        m_columnCount = column;
        m_duration = kFrameDuration * row * column;
    }
    
    return self;
}

+(instancetype)spritesheetHolderWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    return [[[self class] alloc] initWithContentsOfFile:path RowCount:row ColumnCount:column];
}

+(instancetype)spritesheetHolderWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    return [[[self class] alloc] initWithContentsOfData:data RowCount:row ColumnCount:column];
}

-(void)dealloc
{
    glDeleteTextures(1, &m_texture);
}

@synthesize texture = m_texture, rowCount = m_rowCount, columnCount = m_columnCount, duration = m_duration;

@end


@implementation BFCandleFlame

-(id)init
{
    const GLubyte kIndices[] = {0, 1, 2, 2, 3, 0};
    const GLfloat kVertixes[] = {
        -1.0, -1.0, 0.0,
        -1.0,  1.0, 0.0,
         1.0,  1.0, 0.0,
         1.0, -1.0, 0.0
    };
    
    return [self initWithVertexes:kVertixes Indices:kIndices];
}

-(id)initWithVertexes:(const GLfloat[12])vertexes Indices:(const GLubyte[6])indices
{
    self = [super init];
    if (self)
    {
        m_sets = [NSMutableDictionary dictionary];
        m_modelMatrix = GLKMatrix4Identity;
        m_strategy = [LinearCircularStrategy linearCircularStrategyWithFrameDuration:kFrameDuration];
        
        memcpy(m_indices, indices, sizeof(m_indices));
        memcpy(m_vertexes, vertexes, sizeof(m_vertexes));
    }
    
    return self;
}

-(GLuint)getTextureFor:(TextureSets)set
{
    SpriteSheetHolder *holder = [m_sets objectForKey:[[NSNumber numberWithInt:set] stringValue]];
    if (!holder)
        return 0;
    
    return [holder texture];
}

-(UInt32)getTextureCountFor:(TextureSets)set
{
    SpriteSheetHolder *holder = [m_sets objectForKey:[[NSNumber numberWithInt:set] stringValue]];
    if (!holder)
        return 0;
    
    return [holder rowCount] * [holder columnCount];
}

-(void)setTexture:(SpriteSheetHolder *)holder For:(TextureSets)set
{
    [m_sets setObject:holder forKey:[[NSNumber numberWithInt:set] stringValue]];
}

-(GLuint)getActiveTexture:(NSTimeInterval)sinceLastDraw
{
    SpriteSheetHolder *holder = [m_sets objectForKey:[[NSNumber numberWithInt:m_activeSet] stringValue]];
    if (!holder)
        return 0;
    
    UInt32 activeTexture = [m_strategy activeTextureOn:sinceLastDraw In:[holder rowCount] * [holder columnCount]];
    
    GLfloat rowStep = 1.0 / [holder rowCount];
    GLfloat columnStep = 1.0 / [holder columnCount];
    
    UInt16 row = activeTexture / [holder columnCount];
    UInt16 column = activeTexture - row * [holder columnCount];
    
    m_uvCoord[0] = (BFPointUV){columnStep * (column + 1), rowStep * (row + 1)};
    m_uvCoord[1] = (BFPointUV){columnStep * (column + 1), rowStep * (row + 0)};
    m_uvCoord[2] = (BFPointUV){columnStep * (column + 0), rowStep * (row + 0)};
    m_uvCoord[3] = (BFPointUV){columnStep * (column + 0), rowStep * (row + 1)};
    
    return [holder texture];
}

-(void)beforeDraw:(BFGLProgram *)program
{
}

-(void)afterDraw:(BFGLProgram *)program
{
}

-(void)draw:(BFGLProgram *)program
{
    if ([self activeTextureSet] == NotDrawing)
        return;
    
    GLuint texture = [self getActiveTexture:[program timeSinceLastDraw]];
    if (!texture)
        return;
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    GLint positionAttr = [program attribute:@"position"];
    GLint uvCoordAttr = [program attribute:@"texCoord"];
    
    GLint textureUniform = [program uniform:@"objTexture"];
    GLint useTextureUniform = [program uniform:@"useTexture"];
    GLint modelMatrixUniform = [program uniform:@"modelMatrix"];
    
    glEnableVertexAttribArray(positionAttr);
	glEnableVertexAttribArray(uvCoordAttr);
    
    glUniform1i(textureUniform, 0);
    glUniform1i(useTextureUniform, 1);
    glUniformMatrix4fv(modelMatrixUniform, 1, 0, [self modelMatrix].m);
    
    glVertexAttribPointer(positionAttr, 3, GL_FLOAT, GL_FALSE, 0, m_vertexes);
    glVertexAttribPointer(uvCoordAttr, 2, GL_FLOAT, GL_FALSE, 0, m_uvCoord);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, m_indices);
    
    glUniform1i(useTextureUniform, 0);
    glDisableVertexAttribArray(positionAttr);
	glDisableVertexAttribArray(uvCoordAttr);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

@synthesize modelMatrix = m_modelMatrix, activeTextureSet = m_activeSet, activeStrategy = m_strategy;

@end

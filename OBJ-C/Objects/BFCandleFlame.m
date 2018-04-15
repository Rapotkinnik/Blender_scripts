//
//  BFCandleFlame.m
//  TestProject
//
//  Created by Рапоткин Николай on 01.04.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import "BFCandleFlame.h"

@implementation TextureHolder

-(id)initWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    self = [super init];
    if (self)
    {
        NSError *error;
        GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfData:data options:nil error:&error];
        if (!texture)
            @throw [NSException exceptionWithName:@"TextureLoadingException"
                                           reason:[NSString stringWithFormat:@"Can't load texture from data with error code :%d", [error code]]
                                         userInfo:nil];
        
        m_texture = [texture name];
        m_rowCount = row;
        m_columnCount = column;
    }
    
    return self;
}

-(id)initWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    self = [super init];
    if (self)
    {
        NSError *error;
        GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfFile:path options:nil error:&error];
        if (!texture)
            @throw [NSException exceptionWithName:@"TextureLoadingException"
                                           reason:[NSString stringWithFormat:@"Can't load texture from file %@ with error code :%d", path, [error code]]
                                         userInfo:nil];
        
        m_texture = [texture name];
        m_rowCount = row;
        m_columnCount = column;
    }
    
    return self;
}

+(instancetype)textureHolderWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    return [[[self class] alloc] initWithContentsOfFile:path RowCount:row ColumnCount:column];
}

+(instancetype)textureHolderWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column
{
    return [[[self class] alloc] initWithContentsOfData:data RowCount:row ColumnCount:column];
}

-(void)dealloc
{
    glDeleteTextures(1, &m_texture);
}

@synthesize texture = m_texture, rowCount = m_rowCount, columnCount = m_columnCount;

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
        
        memcpy(m_indices, indices, sizeof(m_indices));
        memcpy(m_vertexes, vertexes, sizeof(m_vertexes));
    }
    
    return self;
}

-(GLuint)getTextureFor:(TextureSets)set
{
    TextureHolder *holder = [m_sets objectForKey:[[NSNumber numberWithInt:set] stringValue]];
    if (!holder)
        return 0;
    
    return [holder texture];
}

-(UInt32)getTextureCountFor:(TextureSets)set
{
    TextureHolder *holder = [m_sets objectForKey:[[NSNumber numberWithInt:set] stringValue]];
    if (!holder)
        return 0;
    
    return [holder rowCount] * [holder columnCount];
}

-(void)setTexture:(TextureHolder *)holder For:(TextureSets)set
{
    [m_sets setObject:holder forKey:[[NSNumber numberWithInt:set] stringValue]];
}

-(void)setActiveTexture:(UInt32)activeTexture
{
    TextureHolder *holder = [m_sets objectForKey:[[NSNumber numberWithInt:m_activeSet] stringValue]];
    if (!holder)
        return;
    
    if (activeTexture > [holder rowCount] * [holder columnCount])
        return;
    
    m_activeTexture = activeTexture;
    
    GLfloat rowStep = 1.0 / [holder rowCount];
    GLfloat columnStep = 1.0 / [holder columnCount];
    
    UInt16 row = m_activeTexture / [holder columnCount];
    UInt16 column = m_activeTexture - row * [holder columnCount];
    
    m_uvCoord[0] = (BFPointUV){rowStep * (row + 0), columnStep * (column + 0)};
    m_uvCoord[1] = (BFPointUV){rowStep * (row + 1), columnStep * (column + 0)};
    m_uvCoord[2] = (BFPointUV){rowStep * (row + 1), columnStep * (column + 1)};
    m_uvCoord[3] = (BFPointUV){rowStep * (row + 0), columnStep * (column + 1)};
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
    
    GLuint texture = [self getTextureFor:[self activeTextureSet]];
    if (!texture)
        return;
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    GLint positionAttr = [program attribute:@"position"];
    GLint uvCoordAttr = [program attribute:@"texCoord"];
    
    GLint textureUniform = [program uniform:@"texture"];
    GLint modelMatrixUniform = [program uniform:@"modelMatrix"];
    
    glUniform1i(textureUniform, 0);
    glUniformMatrix4fv(modelMatrixUniform, 1, 0, [self modelMatrix].m);
    
    glVertexAttribPointer(positionAttr, 3, GL_FLOAT, GL_FALSE, 0, m_vertexes);
    glVertexAttribPointer(uvCoordAttr, 2, GL_FLOAT, GL_FALSE, 0, m_uvCoord);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, m_indices);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

@synthesize activeTexture = m_activeTexture, activeTextureSet = m_activeSet;

@end

//
//  BFCandleFlame.h
//  TestProject
//
//  Created by Рапоткин Николай on 01.04.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

#import "Math.h"
#import "GLProgram.h"

typedef enum
{
    NotDrawing = 0,
    CalmBurning,
    LeftBlowBurning,
    RightBlowBurning,
    CalmSmoldering,
    LeftBlowSmoldering,
    RightBlowSmoldering,
    SetsCount
} TextureSets;

@interface TextureHolder : NSObject
{
    GLuint m_texture;
    UInt16 m_rowCount;
    UInt16 m_columnCount;
    NSTimeInterval m_duration;
}

-(id)initWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column Duration:(NSTimeInterval)duration;
-(id)initWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column Duration:(NSTimeInterval)duration;
+(instancetype)textureHolderWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column Duration:(NSTimeInterval)duration;
+(instancetype)textureHolderWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column Duration:(NSTimeInterval)duration;

@property(nonatomic, readonly) GLuint texture;
@property(nonatomic, readonly) UInt16 rowCount;
@property(nonatomic, readonly) UInt16 columnCount;
@property(nonatomic, readonly) NSTimeInterval duration;

@end

@interface BFCandleFlame : NSObject <BFGLDrawable>
{
    GLubyte m_indices[6];
    BFPointUV m_uvCoord[4];
    BFPoint3D m_vertexes[4];
    TextureSets m_activeSet;
    GLKMatrix4 m_modelMatrix;
    NSTimeInterval m_drawTime;
    
    NSMutableDictionary *m_sets;
}

-(id)initWithVertexes:(const GLfloat[12])vertexes Indices:(const GLubyte[6])indices;

-(GLuint)getTextureFor:(TextureSets)set;
-(UInt32)getTextureCountFor:(TextureSets)set;
-(void)setTexture:(TextureHolder *)holder For:(TextureSets)set;

@property(nonatomic) GLKMatrix4 modelMatrix;
@property(nonatomic) TextureSets activeTextureSet;

@end

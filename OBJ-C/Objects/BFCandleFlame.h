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

@protocol ChangeTextureStrategy <NSObject>

-(UInt32)activeTextureOn:(NSTimeInterval)timeSinceLastDraw In:(UInt32)textureCount;

@end

@interface LinearCircularStrategy : NSObject <ChangeTextureStrategy>
{
    NSTimeInterval m_drawTime;
    NSTimeInterval m_frameDuration;
}

-(id)initWithFrameDuration:(NSTimeInterval)duration;
+(instancetype)linearCircularStrategyWithFrameDuration:(NSTimeInterval)duration;

@end

// TODO: Добавить стратегии для изменения активной текстуры : циклическая, туда-сюдак, туда и колебание около послденй, сюда + колебание около первой

@interface SpriteSheetHolder : NSObject
{
    GLuint m_texture;
    UInt16 m_rowCount;
    UInt16 m_columnCount;
    NSTimeInterval m_duration;
}

-(id)initWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column;
-(id)initWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column;
+(instancetype)spritesheetHolderWithContentsOfData:(NSData *)data RowCount:(UInt16)row ColumnCount:(UInt16)column;
+(instancetype)spritesheetHolderWithContentsOfFile:(NSString *)path RowCount:(UInt16)row ColumnCount:(UInt16)column;

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
    
    NSMutableDictionary *m_sets;
    id<ChangeTextureStrategy> m_strategy;
}

-(id)initWithVertexes:(const GLfloat[12])vertexes Indices:(const GLubyte[6])indices;

-(GLuint)getTextureFor:(TextureSets)set;
-(UInt32)getTextureCountFor:(TextureSets)set;
-(void)setTexture:(SpriteSheetHolder *)holder For:(TextureSets)set;

@property(nonatomic) GLKMatrix4 modelMatrix;
@property(nonatomic) TextureSets activeTextureSet;
@property(nonatomic) id<ChangeTextureStrategy> activeStrategy;

@end

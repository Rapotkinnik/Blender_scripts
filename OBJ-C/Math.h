#import <GLKit/GLKit.h>

typedef struct
{
    float x;
    float y;
} BFPoint2D;

typedef struct
{
    float u;
    float v;
} BFPointUV;

typedef struct
{
    float x;
    float y;
    float z;
} BFPoint3D;

typedef struct
{
    float r;
    float g;
    float b;
} BFColorRGB;

typedef struct
{
    float r;
    float g;
    float b;
    float alpha;
} BFColorRGBA;

typedef struct
{
    BFPoint3D    coord;
    BFPoint3D    normal;
    BFPointUV    textureCoord;
} BFVertex;

typedef struct
{
    BFPoint3D    coord;
    BFColorRGBA  color;
    BFPoint3D    normal;
    BFPointUV    textureCoord;
} BFVertexColor;

typedef BFPoint2D * BFPoint2DRef;
typedef BFPointUV * BFPointUVRef;
typedef BFPoint3D * BFPoint3DRef;
typedef BFVertex * BFVertexRef;

typedef struct {
    float ambient[3];
    float diffuse[3];
    float specular[3];
    float shininess;
} BFMaterial;

typedef struct {
    float ambient[3];
    float diffuse[3];
    float specular[3];
} BFLightProperties;

@interface BFValue : NSObject
{
    void * m_data;
    size_t m_size;
    NSMutableDictionary *m_metaData;
}

-(instancetype)initWithData:(void *)data MetaData:(NSDictionary *)metaData;
-(void)dealloc;

-(void *)getValue;

-(id)getMetaData:(NSString *)name;
-(void)addMetaData:(id)value WithName:(NSString *)name;

@end

@interface BFValue (BFPoint3D)

+(BFValue *)valueWithBFPoint3D:(BFPoint3D)value;
+(NSValue *)valueWithBFPoint3DRef:(BFPoint3DRef)value;
+(NSValue *)valueWithBFPoint3D:(BFPoint3D)value MetaData:(NSDictionary *)dict;
+(NSValue *)valueWithBFPoint3DRef:(BFPoint3DRef)value MetaData:(NSDictionary *)dict;

-(BFPoint3D)BFPoint3D;
-(BFPoint3DRef)BFPoint3DRef;

@end

@interface NSValue (BFPointUV)

+ (NSValue *) valueWithBFPointUV: (BFPointUV) value;

@property (readonly) BFPointUV BFPointUV;

@end

@interface NSValue (BFVertex)

+ (NSValue *) valueWithBFVertex: (BFVertex) value;

@property (readonly) BFVertex BFVertex;

@end

typedef enum
{
    TouchFirst,
    TouchSecond,
    Intersection,
    UnIntersection
} LineIntersection;

@interface BFLine: NSObject
{
    float m_a, m_b, m_c;
    union {
        BFPointUV pointsUV[2];
        BFPoint2D points2D[2];
    } m_points;
}

- (id) initWithPointsUV:(BFPointUV)a :(BFPointUV)b;
- (id) initWithPoints2D:(BFPoint2D)a :(BFPoint2D)b;
+ (id) lineWithPointsUV:(BFPointUV)a :(BFPointUV)b;
+ (id) lineWithPoints2D:(BFPoint2D)a :(BFPoint2D)b;

- (float) leftTurnWithPoint2D:(BFPoint2D) point;
- (float) leftTurnWithpointUV:(BFPointUV) point;
- (LineIntersection) isIntersectedBy:(BFLine *) line;
- (BFPointUV) getIntersectionPointUVWith:(BFLine *) line;
- (BFPoint2D) getIntersectionPoint2DWith:(BFLine *) line;

- (float) vFromU:(float) u;
- (float) uFromV:(float) v;
- (float) yFromX:(float) x;
- (float) xFromY:(float) y;

@property (readonly) float a;
@property (readonly) float b;
@property (readonly) float c;

@end

float LinearBezierCurve1D(const float values[2], float t);
float QuadraticBezierCurve1D(const float values[3], float t);
float CubicBezierCurve1D(const float values[4], float t);
float QuadricBezierCurve1D(const float values[5], float t);
float QuinticBezierCurve1D(const float values[6], float t);

float getPointOnCurve(const float *values, int size, int order, float t);

BFPoint3D MakeNormal(BFPoint3D *point);

BFPoint3D LinearBezierCurve(const BFPoint3D points[2], float t);
BFPoint3D QuadraticBezierCurve(const BFPoint3D points[3], float t);
BFPoint3D CubicBezierCurve(const BFPoint3D points[4], float t);
BFPoint3D QuadricBezierCurve(const BFPoint3D points[5], float t);
BFPoint3D QuinticBezierCurve(const BFPoint3D points[6], float t);

BFPoint3D NormalToLinearBezierCurve(const BFPoint3D points[2], float t);
BFPoint3D NormalToQuadraticBezierCurve(const BFPoint3D points[3], float t);
BFPoint3D NormalToCubicBezierCurve(const BFPoint3D points[4], float t);
BFPoint3D NormalToQuadricBezierCurve(const BFPoint3D points[5], float t);
BFPoint3D NormalToQuinticBezierCurve(const BFPoint3D points[6], float t);

typedef BFPointUV(^BFGetPointUVFromValue)(id value, BOOL *isOK);
//typedef BOOL(^BFGetPointUVFromValue)(id value, BFPointUV *point);

NSArray *BFTriangulate(NSEnumerator *poly); // return NSArray<NSNumber>
NSArray *BFTriangulateWithGetPointUVFunc(NSArray *poly, BFGetPointUVFromValue block);

@interface BFObject: NSObject
-(GLKMatrix4)getModelMatrix;
@end

// Источник света
@protocol BFLighting
- (BFPoint3D)        getPosition;
- (BFLigthProperies) getLigthProperies;
@end

// Меш
@protocol BFMesh
- (GLuint)     getGLPrimitive;
- (GLuint)     getDataCount;
- (GLuint)     getIndicesCount;
- (GLuint *)   getIndices;
- (BFVertex *) getData;
- (BFMaterial) getMaterial;
@end

// Кривая
@protocol BFCurve
- (BFPoint3D) getPointAt: (float)t;
- (BFPoint3D) getPointAt: (float)t OnSpline:(int)spline;
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithSegments:(int)   count;                      // return BFPoint3D[]
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithMinAngle:(float) angle;                      // return BFPoint3D[]
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithSegments:(int)   count OnSpline:(int)spline; // return BFPoint3D[]
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithMinAngle:(float) angle OnSpline:(int)spline; // return BFPoint3D[]
@end

// Поверхность
@protocol BFSurface
- (BFVertex)           getPointAt:         (BFPointUV)point;
- (BFVertex)           getPointAt:         (BFPointUV)point  OnSpline:    (int)  spline;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithSegments:(int)  count;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithMinAngle:(float)angle;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithSegments:(int)  count;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithMinAngle:(float)angle;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithSegments:(int)  count OnSpline:(int)spline;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithMinAngle:(float)angle OnSpline:(int)spline;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithSegments:(int)  count OnSpline:(int)spline;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithMinAngle:(float)angle OnSpline:(int)spline;

- (BFObject<BFMesh> *) getWholeSurfaceWithSegments:(int)count;
- (BFObject<BFMesh> *) getWholeSurfaceWithMinAngle:(float)angle;

- (id<BFSurface>) getSurfaceWithGetPointUVFunc: (BFGetPointUVFromValue) block;
@end

typedef void(^BFPerPointBlock)(BFPoint3D *point, float t);

@interface BFSpline : NSObject
{
    NSMutableArray *m_points;
    unsigned int m_order;
}

- (id) initWithPoints: (NSArray *) points Order: (unsigned int) order; // NSArray<NSVAlue<BFPoint3D>>
- (id) initWithPoints: (BFPoint3D *) points Count: (unsigned int) count Order: (unsigned int) order;

- (BFPoint3D) getPointAt: (float)t;
- (BFPoint3D) getNormalAt:(float)t;
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithSegments:(int)   count;
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithMinAngle:(float) angle;

@property (retain) NSMutableArray *points;

@end

@interface BFSurfaceSpline : NSObject
{
    NSArray *m_splines;  // NSArray<BFSpline>
    unsigned int m_order;
}

- (id) initWithSplines: (NSArray *)   splines Order: (unsigned int) order; // NSArray<BFSpline>
- (id) initWithPoints:  (BFPoint3D *) points CountU: (unsigned int) count_u CountV: (unsigned int) count_v
                                             OrderU: (unsigned int) order_u OrderV: (unsigned int) order_v;

- (BFVertex)  getPointAt:         (BFPointUV) point;
- (NSArray *) getLineByPoints:    (NSArray *) points WithSegments: (int)   count;
- (NSArray *) getLineByPoints:    (NSArray *) points WithMinAngle: (float) angle;
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithSegments: (int)   count;
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle;

@property (retain) NSArray *splines;

@end

@interface BFExtrudedSpline : NSObject
{
    BFSpline *m_spline;
    unsigned int m_extrude;
}

- (instancetype)initWithSpline:(BFSpline *)spline Extrude:(unsigned int)extrude;

- (BFVertex)  getPointAt:         (BFPointUV) point;
- (NSArray *) getLineByPoints:    (NSArray *) points WithSegments: (int)   count;
- (NSArray *) getLineByPoints:    (NSArray *) points WithMinAngle: (float) angle;
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithSegments: (int)   count;  // Все такие возвращаются треугольники...
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle;  // 

- (NSArray *) getWholeSurface:(NSMutableArray *)indices WithSegments:(int)count;
- (NSArray *) getWholeSurface:(NSMutableArray *)indices WithMinAngle:(float)angle;

@property (retain) BFSpline *spline;

@end

@interface BFDefaultMesh : BFObtject <BFMesh>

-(id)initWithData:(NSArray *)data GLPrimitive:(GLuint)primitive Matrix:(GLKMatrix4)matrix;
-(id)initWithData:(NSArray *)data Indices:(NSArray *)indices GLPrimitive:(GLuint)primitive Matrix:(GLKMatrix4)matrix;

@property (readonly, getter = getData) BFVertex * m_data;
@property (readonly, getter = getIndices) GLuint * m_indices;
@property (readonly, getter = getDataCount) GLuint m_dataCount;
@property (readonly, getter = getIndicesCount) GLuint m_indicesCount;
@property (readonly, getter = getGLPrimitive) GLuint m_primitive;
@property (readonly, getter = getModelMatrix) GLKMatrix4 m_modelMatrix;

@end
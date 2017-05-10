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

BFPoint3D addPoint3D(BFPoint3D rv,BFPoint3D lv);
BFPoint3D divPoint3D(BFPoint3D rv,BFPoint3D lv);
BFPoint3D multPoint3D(BFPoint3D rv,BFPoint3D lv);

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
} BFVertext;

typedef struct
{
    BFPoint3D    coord;
    BFColorRGBA  color;
    BFPoint3D    normal;
    BFPointUV    textureCoord;
} BFVertextColor;

@interface NSValue (BFPoint3D)

+ (NSValue *) valueWithBFPoint3D:(BFPoint3D) value;
+ (NSValue *) valueWithBFPoint3D:(BFPoint3D) value MetaData:(NSDictionary *)dict;

- (id) getMetaData:(NSString *)name;
- (void) addMetaData:(NSString *)name WithValue:(id) value;

@property (readonly) BFPoint3D BFPoint3D;
@property (readonly) NSMutableDictionary *MetaData;

@end

@interface NSValue (BFPointUV)

+ (NSValue *) valueWithBFPointUV: (BFPointUV) value;

@property (readonly) BFPointUV BFPointUV;

@end

@interface NSValue (BFVertext)

+ (NSValue *) valueWithBFVertext: (BFVertext) value;

@property (readonly) BFVertext BFVertext;

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
- (id) lineWithPointsUV:(BFPointUV)a :(BFPointUV)b;
- (id) lineWithPoints2D:(BFPoint2D)a :(BFPoint2D)b;

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
NSArray *BFTriangulateWithGetPointFunc(NSEnumerator *poly, BFGetPointUVFromValue block);

float absf(float value);

@interface BFObject: NSObject
- (GLKMatrix4) getModelMatrix;
@end

// Меш
@protocol BFMesh
- (GLuint)      getGLPrimitive;
- (GLuint)      getDataCount;
- (GLuint)      getIndicesCount;
- (GLuint *)    getIndices;
- (BFVertext *) getData;
@end

// Кривая
@protocol BFCurve
- (BFPoint3D) getPointAt: (float)t;
- (BFPoint3D) getPointAt: (float)t OnSpline:(int)spline;
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithSegments:(int)   count;                        // return BFPoint3D[]
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithMinAngle:(float) angle;                        // return BFPoint3D[]
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithSegments:(int)   count OnSpline:(int)spline; // return BFPoint3D[]
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithMinAngle:(float) angle OnSpline:(int)spline; // return BFPoint3D[]
@end

// Поверхность
@protocol BFSurface
- (BFVertext)          getPointAt:         (BFPointUV)point;
- (BFVertext)          getPointAt:         (BFPointUV)point  OnSpline:    (int)  spline;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithSegments:(int)  count;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithMinAngle:(float)angle;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithSegments:(int)  count;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithMinAngle:(float)angle;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithSegments:(int)  count OnSpline:(int)spline;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *)points WithMinAngle:(float)angle OnSpline:(int)spline;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithSegments:(int)  count OnSpline:(int)spline;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *)points WithMinAngle:(float)angle OnSpline:(int)spline;

- (BFObject<BFMesh> *) getWholeSurface;

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
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithSegments:(int)   count;
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithMinAngle:(float) angle;
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithSegments:(int)   count WithBlock:(BFPerPointBlock)block;
- (NSArray *) getLineFrom:(float)t_start To:(float)t_end WithMinAngle:(float) angle WithBlock:(BFPerPointBlock)block;

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

- (BFPoint3D) getPointAt:         (BFPointUV) point;
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

- (id) initWithSpline:(BFSpline *) spline Extrude:(unsigned int) extrude;

- (BFVertext)          getPointAt:         (BFPointUV) point;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *) points WithSegments: (int)   count;
- (BFObject<BFMesh> *) getLineByPoints:    (NSArray *) points WithMinAngle: (float) angle;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *) points WithSegments: (int)   count;
- (BFObject<BFMesh> *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle;

- (BFObject<BFMesh> *) getWholeSurface;

@property (retain) BFSpline *spline;

@end
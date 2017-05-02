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
+ (void) addMetaData:(NSString *) name Data:(id) data;

@property (readonly) BFPoint3D BFPoint3D;

@end

@interface NSValue (BFPointUV)

+ (NSValue *) valueWithBFPointUV: (BFPointUV) value;

@property (readonly) BFPointUV BFPointUV;

@end

@interface BFCoordExchanger : NSObject
{
    float m_points[3]; // a, b, c
}

- (id) initWithPoints:(BFPointUV)a And:(BFPointUV)b;
- (id) coordExchangerWithPoints :(BFPointUV)a And:(BFPointUV)b;

- (float) vfromu:(float) u;
- (float) ufromv:(float) v;

@end

BFPoint3D LinearBezierCurve(const BFPoint3D points[2], float t);
BFPoint3D QuadraticBezierCurve(const BFPoint3D points[3], float t);
BFPoint3D CubicBezierCurve(const BFPoint3D points[4], float t);
BFPoint3D QuadricBezierCurve(const BFPoint3D points[5], float t);
BFPoint3D QuinticBezierCurve(const BFPoint3D points[6], float t);

float absf(float value);

@interface BFObject: NSObject
- (GLKMatrix4) getModelMatrix;
@end

// Меш
@protocol BFMesh
- (int) getGLPrimitive;
- (GLint *) getIndices;
- (BFVertext *) getData;
@end

// Кривая
@protocol BFCurve
- (BFPoint3D) getPointAt:  (float) t;
- (BFPoint3D) getPointAt:  (float) t OnSpline: (int)   spline;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count;                        // return BFPoint3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle;                        // return BFPoint3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count OnSpline: (int) spline; // return BFPoint3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle OnSpline: (int) spline; // return BFPoint3D[]
@end

// Поверхность
@protocol BFSurface
- (BFPoint3D) getPointAt:         (BFPointUV) point;
- (BFPoint3D) getPointAt:         (BFPointUV) point  OnSpline:     (int)   spline;
- (NSArray *) getLineByPoints:    (NSArray *) points WithSegments: (int)   count;                        // return BFPoint3D[]
- (NSArray *) getLineByPoints:    (NSArray *) points WithMinAngle: (float) angle;                        // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithSegments: (int)   count;                        // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle;                        // return BFPoint3D[]
- (NSArray *) getLineByPoints:    (NSArray *) points WithSegments: (int)   count OnSpline: (int) spline; // return BFPoint3D[]
- (NSArray *) getLineByPoints:    (NSArray *) points WithMinAngle: (float) angle OnSpline: (int) spline; // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithSegments: (int)   count OnSpline: (int) spline; // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle OnSpline: (int) spline; // return BFPoint3D[]
@end

typedef void(^BFPerPointBlock)(BFPoint3D *point, float t);

@interface BFSpline : NSObject
{
    NSMutableArray *m_points;
    unsigned int m_order;
}

- (id) initWithPoints: (NSArray *) points Order: (unsigned int) order; // NSArray<NSVAlue<BFPoint3D>>
- (id) initWithPoints: (BFPoint3D *) points Count: (unsigned int) count Order: (unsigned int) order;
- (void) dealloc;

- (BFPoint3D) getPointAt:  (float) t;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count WithBlock: (BFPerPointBlock) block;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle WithBlock: (BFPerPointBlock) block;

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
- (void) dealloc;

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

- (id) initWithPoints: (BFSpline *) spline Extrude: (unsigned int) extrude;
- (void) dealloc;

- (BFPoint3D) getPointAt:         (BFPointUV) point;
- (NSArray *) getLineByPoints:    (NSArray *) points WithSegments: (int)   count; // NSArray<NSValue<BFPointUV>>
- (NSArray *) getLineByPoints:    (NSArray *) points WithMinAngle: (float) angle; // NSArray<NSValue<BFPointUV>>
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithSegments: (int)   count; // NSArray<NSValue<BFPointUV>>
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle; // NSArray<NSValue<BFPointUV>>

@property (retain) BFSpline *spline;

@end
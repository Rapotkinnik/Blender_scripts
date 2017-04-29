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

+ (NSValue *) valueWithBFPoint3D: (BFPoint3D) value;

@property (readonly) BFPoint3D BFPoint3D;

@end

@interface NSValue (BFPointUV)

+ (NSValue *) valueWithBFPointUV: (BFPointUV) value;

@property (readonly) BFPointUV BFPointUV;

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
- (BFPoint3D) getPointAt:         (BFPointUV)   point;
- (BFPoint3D) getPointAt:         (BFPointUV)   point  OnSpline:     (int)   spline;
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithSegments: (int)   count;                        // return BFPoint3D[]
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithMinAngle: (float) angle;                        // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithSegments: (int)   count;                        // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithMinAngle: (float) angle;                        // return BFPoint3D[]
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithSegments: (int)   count OnSpline: (int) spline; // return BFPoint3D[]
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithMinAngle: (float) angle OnSpline: (int) spline; // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithSegments: (int)   count OnSpline: (int) spline; // return BFPoint3D[]
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithMinAngle: (float) angle OnSpline: (int) spline; // return BFPoint3D[]
@end

@interface BFSpline : NSObject
{
    BFPoint3D *m_points;
    unsigned int m_order;
    unsigned int m_count;
}

- (id) initWithPoints: (NSArray *) points Order: (unsigned int) order; // NSArray<BFPoint3D>
- (id) initWithPoints: (BFPoint3D *) points Count: (unsigned int) count Order: (unsigned int) order;
- (void) dealloc;

- (BFPoint3D) getPointAt:  (float) t;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle;

@property (assign) NSArray *points;

@end

@interface BFSurfaceSpline : NSObject
{
    NSArray *m_splines;  // NSArray<BFSpline>
    unsigned int m_order;
}

- (id) initWithPoints: (NSArray *) splines Order: (unsigned int) order; // NSArray<BFSpline>
- (id) initWithPoints: (BFPoint3D *) points CountU: (unsigned int) count_u CountV: (unsigned int) count_v
                                            OrderU: (unsigned int) order_u OrderV: (unsigned int) order_v;
- (void) dealloc;

- (BFPoint3D) getPointAt:         (BFPointUV)   point;
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithSegments: (int)   count;
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithMinAngle: (float) angle;
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithSegments: (int)   count;
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithMinAngle: (float) angle;

@end

@interface BFExtrudedSpline : NSObject
{
    BFSpline *m_spline;
    unsigned int m_extrude;
}

- (id) initWithPoints: (BFSpline *) spline Extrude: (unsigned int) extrude;
- (void) dealloc;

- (BFPoint3D) getPointAt:         (BFPointUV)   point;
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithSegments: (int)   count;
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithMinAngle: (float) angle;
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithSegments: (int)   count;
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithMinAngle: (float) angle;

@property (assign) BFSpline *spline;

@end
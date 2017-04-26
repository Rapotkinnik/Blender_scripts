#import <GLKit/GLKit.h>

typedef struct
{
    float x;
    float y;
} FBPoint2D;

typedef struct
{
    float u;
    float v;
} FBPointUV;

typedef struct
{
    float x;
    float y;
    float z;
} FBPoint3D;

FBPoint3D addPoint3D(FBPoint3D rv,FBPoint3D lv);
FBPoint3D divPoint3D(FBPoint3D rv,FBPoint3D lv);
FBPoint3D multPoint3D(FBPoint3D rv,FBPoint3D lv);

typedef struct
{
    float r;
    float g;
    float b;
} FBColorRGB;

typedef struct
{
    float r;
    float g;
    float b;
    float alpha;
} FBColorRGBA;

typedef struct
{
    FBPoint3D    coord;
    FBPoint3D    normal;
    FBPointUV    textureCoord;
} FBVertext;

typedef struct
{
    FBPoint3D    coord;
    FBColorRGBA  color;
    FBPoint3D    normal;
    FBPointUV    textureCoord;
} FBVertextColor;

@interface NSValue (FBPoint3D)

+ (NSValue *) valueWithFBPoint3D: (FBPoint3D) value;

@property (readonly) FBPoint3D FBPoint3D;

@end

FBPoint3D LinearBezierCurve(const FBPoint3D points[2], float t);
FBPoint3D QuadraticBezierCurve(const FBPoint3D points[3], float t);
FBPoint3D CubicBezierCurve(const FBPoint3D points[4], float t);
FBPoint3D QuadricBezierCurve(const FBPoint3D points[5], float t);
FBPoint3D QuinticBezierCurve(const FBPoint3D points[6], float t);

float absf(float value);

@interface BFObject: NSObject
- (GLKMatrix4) getModelMatrix;
@end

// Кривая
@protocol FBCurve
- (FBPoint3D) getPointAt:  (float) t;
- (FBPoint3D) getPointAt:  (float) t OnSpline: (int)   spline;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count;                        // return FBPoint3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle;                        // return FBPoint3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count OnSpline: (int) spline; // return FBPoint3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle OnSpline: (int) spline; // return FBPoint3D[]
@end


// Поверхность
@protocol FBSurface
- (FBPoint3D) getPointAt:         (FBPointUV)   point;
- (FBPoint3D) getPointAt:         (FBPointUV)   point  OnSpline:     (int)   spline;
- (NSArray *) getLineByPoints:    (FBPointUV *) points WithSegments: (int)   count;                        // return FBPoint3D[]
- (NSArray *) getLineByPoints:    (FBPointUV *) points WithMinAngle: (float) angle;                        // return FBPoint3D[]
- (NSArray *) getSurfaceByPoints: (FBPointUV *) points WithSegments: (int)   count;                        // return FBPoint3D[]
- (NSArray *) getSurfaceByPoints: (FBPointUV *) points WithMinAngle: (float) angle;                        // return FBPoint3D[]
- (NSArray *) getLineByPoints:    (FBPointUV *) points WithSegments: (int)   count OnSpline: (int) spline; // return FBPoint3D[]
- (NSArray *) getLineByPoints:    (FBPointUV *) points WithMinAngle: (float) angle OnSpline: (int) spline; // return FBPoint3D[]
- (NSArray *) getSurfaceByPoints: (FBPointUV *) points WithSegments: (int)   count OnSpline: (int) spline; // return FBPoint3D[]
- (NSArray *) getSurfaceByPoints: (FBPointUV *) points WithMinAngle: (float) angle OnSpline: (int) spline; // return FBPoint3D[]
@end

@interface FBSpline : NSObject
{
    FBPoint3D *m_points;
    unsigned int m_order;
    unsigned int m_count;
}

- (id) initWithPoints: (FBPoint3D *) points Count: (unsigned int) count Order: (unsigned int) order;
- (void) dealloc;

- (FBPoint3D) getPointAt:  (float) t;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int)   count;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle;

@end
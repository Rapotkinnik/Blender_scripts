#import <GLKit/GLKit.h>
#import <CoreFoundation/CFArray.h>

typedef struct
{
    float x;
    float y;
} Point2D;

typedef struct
{
    float u;
    float v;
} PointUV;

typedef struct
{
    float x;
    float y;
    float z;
} Point3D;

Point3D addPoint3D(Point3D rv, Point3D lv);
Point3D divPoint3D(Point3D rv, Point3D lv);
Point3D multPoint3D(Point3D rv, Point3D lv);

typedef struct
{
    float r;
    float g;
    float b;
} ColorRGB;

typedef struct
{
    float r;
    float g;
    float b;
    float alpha;
} ColorRGBA;

typedef struct
{
    Point3D    coord;
    ColorRGBA  color;
    Point3D    normal;
    PointUV    textureCoord;
} Vertext;

@interface NSValue (Point3D)

+ (NSValue *) valueWithPoint3D: (Point3D) value;

@property (readonly) Point3D point3Dvalue;

@end

Point3D LinearBezierCurve(const Point3D points[2], float t);
Point3D QuadraticBezierCurve(const Point3D points[3], float t);
Point3D CubicBezierCurve(const Point3D points[4], float t);
Point3D QuadricBezierCurve(const Point3D points[5], float t);
Point3D QuinticBezierCurve(const Point3D points[6], float t);

float absf(float value);


// Кривая
@interface Curve : NSObject

- (int)        getPointsCount;
- (Point3D)    getPointAt: (float) t;
- (GLKMatrix4) getModelMatrix;

// return Point3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end withSegments: (unsigned int) count;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end withMinAngle: (float) angle;

- (void) getLineRecursive: (NSMutableArray *) result From: (float) t_start To: (float) t_end withMinAngle: (float) angle;

@end


// Поверхность
@interface Surface: NSObject

- (Point3D)    getPointAtUV: (PointUV) point;
- (GLKMatrix4) getModelMatrix;

- (id) getSurface: (PointUV *) points ;

@end
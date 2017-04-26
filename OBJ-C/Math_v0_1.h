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

+ (instancetype) valueWithPoint3D: (Point3D) value;

@property (readonly) Point3D value;

@end

Point3D LinearBezierCurve(const Point3D points[2], float t);
Point3D QuadraticBezierCurve(const Point3D points[3], float t);
Point3D CubicBezierCurve(const Point3D points[4], float t);
Point3D QuadricBezierCurve(const Point3D points[5], float t);
Point3D QuinticBezierCurve(const Point3D points[6], float t);


// Кривая
@interface Curve : NSObject
{
    
int        * m_knots;  // int[]
Point3D    * m_points; // Point3D[]
    
unsigned int m_knots_count;
unsigned int m_points_count;

unsigned int m_order;
GLKMatrix4   m_model_matrix;
}

- (Point3D) getPointAt: (float) t;

// return Point3D[]
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end withSegments: (unsigned int) count;
- (NSArray *) getLineFrom: (float) t_start To: (float) t_end withMinAngle: (float) angle;

@property (readonly, getter = getOrder)       unsigned int order;
@property (readonly, getter = getModelMatrix) GLKMatrix4   model_matrix;

@end


// Поверхность
@interface Surface: NSObject
{
CFArrayRef   points_;

unsigned int m_order_u;
unsigned int m_order_v;
GLKMatrix4   m_model_matrix;
}

- (Point3D) getPointAt: (float) u And: (float) v;
- (Point3D) getPointAtUV: (PointUV) point;

- () getSurface;

@property (readonly, getter = getOrderU)      unsigned int order_u;
@property (readonly, getter = getOrderV)      unsigned int order_v;
@property (readonly, getter = getModelMatrix) GLKMatrix4   model_matrix;

@end
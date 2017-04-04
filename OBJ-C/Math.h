typedef struct
{
    float x;
    float y;
} Point2D;

Point2D & operator+(const Point2D &point, float t);
Point2D & operator-(const Point2D &point, float t);
Point2D & operator*(const Point2D &point, float t);
Point2D & operator/(const Point2D &point, float t);

typedef struct
{
    float u;
    float v;
} PointUV;

typedef struct
{
    float x;
    float y;
    float z
} Point3D;

Point2Dtypedef struct
{
    float r;
    float g;
    float b;
    float alpha;
} ColorRGBA;

typedef struct
{
    Point3D    coord;
    ColorRGBA color;
    Point3D    normal;
    PointUV    textureCoord;
} Vertext;

// Кривая
@interface Curve : NSObject

@protected
@property unsigned int   order_;
@property int[]             knots_;
@property Point3D[]      points_;
@property GLKMatrix4x4 model_matrix_;

- (void) set_order: (unsigned int) order;
- (void) use_control_points: (bool) use;

- (GLKMatrix4x4) get_model_matrix;

- (Point3D) get_point_at_t: (float) t;

- (Point3D[]) get_line_from: (float) t_start to: (float) t_end with_segments: (unsigned int) count;
- (Point3D[]) get_line_from: (float) t_start to: (float) t_end with_min_angle: (float) angle;

@end

// Поверхность
@interface Surface: NSObject

@protected
@property unsigned int  order_u_;
@property unsigned int  order_v_;
@property Point3D[]      points_;
@property GLKMatrix4x4 model_matrix_;

- (void) set_order: (unsigned int) order;
- (void) use_control_points: (bool) use;

- (GLKMatrix4x4) get_model_matrix;

- (Point3D) get_point_at_u: (float) u and_v: (float) v;
- (Point3D) get_point_at_uv: (PointUV) point;

- () get_surface

@end
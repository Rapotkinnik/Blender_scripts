#import "Math.h"

@implementation NSValue (Point3D)

+ (instancetype) valueWithPoint3D: (Point3D) value
{
    return [self valueWithBytes:&value objCType:@encode(Point3D)];
}

- (Point3D) value
{
    Point3D value;
    [self getValue: &value];
    return value;
}

@end

Point3D LinearBezierCurve(const Point3D points[2], float t)
{
    Point3D result;
    result.x = (1 - t) * points[0].x + t * points[1].x;
    result.y = (1 - t) * points[0].y + t * points[1].y;
    result.z = (1 - t) * points[0].z + t * points[1].z;
    return result;
};

Point3D QuadraticBezierCurve(const Point3D points[3], float t)
{
    Point3D result;
    result.x = pow(1 - t, 2) * points[0].x + 2 * t * (1 - t) * points[1].x + 2 * t * t * points[2].x;
    result.y = pow(1 - t, 2) * points[0].y + 2 * t * (1 - t) * points[1].y + 2 * t * t * points[2].y;
    result.z = pow(1 - t, 2) * points[0].z + 2 * t * (1 - t) * points[1].z + 2 * t * t * points[2].z;
    return result;
};

Point3D CubicBezierCurve(const Point3D points[4], float t)
{
    Point3D result;
    result.x = pow(1 - t, 3) * points[0].x + 3 * pow(1 - t, 2) * t * points[1].x + 3 * (1 - t) * t * t * points[2].x + pow(t, 3) * points[3].x;
    result.y = pow(1 - t, 3) * points[0].y + 3 * pow(1 - t, 2) * t * points[1].y + 3 * (1 - t) * t * t * points[2].y + pow(t, 3) * points[3].y;
    result.z = pow(1 - t, 3) * points[0].z + 3 * pow(1 - t, 2) * t * points[1].z + 3 * (1 - t) * t * t * points[2].z + pow(t, 3) * points[3].z;
    return result;
};

Point3D QuadricBezierCurve(const Point3D points[5], float t)
{
    Point3D result;
    result.x = pow(1 - t, 4) * points[0].x + 4 * pow(1 - t, 3) * t * points[1].x + 6 * pow(1 - t, 2) * t * t * points[2].x + 4 * pow(t, 3) * (1 - t) * points[3].x + pow(t, 4) * points[4].x;
    result.y = pow(1 - t, 4) * points[0].y + 4 * pow(1 - t, 3) * t * points[1].y + 6 * pow(1 - t, 2) * t * t * points[2].y + 4 * pow(t, 3) * (1 - t) * points[3].y + pow(t, 4) * points[4].y;
    result.z = pow(1 - t, 4) * points[0].z + 4 * pow(1 - t, 3) * t * points[1].z + 6 * pow(1 - t, 2) * t * t * points[2].z + 4 * pow(t, 3) * (1 - t) * points[3].z + pow(t, 4) * points[4].z;
    return result;
};


@implementation Curve

- (Point3D) getPointAt: (float) t
{
    if (t < 0 || t > 1)
    {
        NSException* wrong_t = [NSException
                                exceptionWithName:@"WrongTValueException"
                                reason:[[NSString alloc] initWithFormat:@"t must be betwine 0 and 1, not %f!", t]
                                userInfo:nil];
        @throw wrong_t;
    }
    
    unsigned int segment_count = m_points_count - m_order - 1;
    unsigned int segment       = (unsigned int) ceilf(t * segment_count);
    
    float segment_t = t * segment_count / segment;
    
    if (m_order == 2)
        return LinearBezierCurve(&m_points[segment - 1], segment_t);
    
    
    Point3D bezier_points[m_order];
    
    if (m_order == 3)
    {
        bezier_points[0] = ((m_knots[index + 3] - knots[index + 2]) * bezier_points[index].co[:] +
              (knots[index + 2] - knots[index + 1]) * bezier_points[index + 1].co[:]) / (knots[index + 3] - knots[index + 1])
        bezier_points[1] = bezier_points[index + 1].co[:]
        bezier_points[2] = ((knots[(index + 1) + 3] - knots[(index + 1) + 2]) * bezier_points[(index + 1)].co[:] +
              (knots[(index + 1) + 2] - knots[(index + 1) + 1]) * bezier_points[(index + 1) + 1].co[:]) / \
        (knots[(index + 1) + 3] - knots[(index + 1) + 1])
        
        
        return QuadraticBezierCurve(bezier_points, segment_t);
    }
    
    if (m_order == 3)
    {
        
        return CubicBezierCurve(bezier_points, segment_t);
    }
    
    if (m_order == 4)
    {
        
        return QuadraticBezierCurve(bezier_points, segment_t);
    }

    
    NSException* unsupported_order = [NSException
                                      exceptionWithName:@"UnSupportedOrderException"
                                      reason:[[NSString alloc] initWithFormat:@"This order=%d is unsupported!", m_order]
                                      userInfo:nil];
    @throw unsupported_order;
    
    Point3D result;
    return result;
}

- (Point3D[]) get_line_from: (float) t_start to: (float) t_end with_segments: (unsigned int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    float delta = (t_end - t_start) / count;
    for (int segment = 0; segment < count; segment++)
        [result addObject: [NSValue valueWithPoint3D: [self getPointAt: t_start + segment*delta]]];
    
    return result;
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end withMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    int points_count = [self getPointsCount];
    float delta = (t_end - t_start) / points_count;
    
    [result addObject: [NSValue valueWithPoint3D: [self getPointAt: t_start]]];
    for (int index = 0; index < points_count; index++)
        [self getLineRecursive:result From:t_start + delta * index To:t_start + delta * (index + 1) withMinAngle:angle];
    
    [result addObject: [NSValue valueWithPoint3D: [self getPointAt: t_end]]];
    
    return result;
}

- (void) getLineRecursive: (NSMutableArray *) result From: (float) t_start To: (float) t_end withMinAngle: (float) angle
{
    if (absf(t_end - t_start) <=  MIN_DELTA_T)
        return;
    
    float t_middle = (t_start - t_end) / 2;
    
    FBPoint3D start_point  = [[result lastObject] point3Dvalue];
    FBPoint3D end_point    = [self getPointAt:t_end];
    FBPoint3D middle_point = [self getPointAt:t_middle];
    
    FBPoint3D vector_me = { end_point.x - middle_point.x,
        end_point.y - middle_point.y,
        end_point.z - middle_point.z };
    
    FBPoint3D vector_ms = { start_point.x - middle_point.x,
        start_point.y - middle_point.y,
        start_point.z - middle_point.z };
    
    float angle_between_points = (vector_me.x*vector_ms.x + vector_me.y*vector_ms.z + vector_me.x*vector_ms.z) /
    (sqrtf(powf(vector_me.x, 2) + powf(vector_me.y, 2) + powf(vector_me.z, 2) *
           sqrtf(powf(vector_ms.x, 2) + powf(vector_ms.y, 2) + powf(vector_ms.z, 2))));
    
    if (absf(angle_between_points) > cosf(angle))
    {
        [self getLineRecursive: result From: t_start To: t_middle WithMinAngle: angle];
        
        [result addObject: [NSValue valueWithPoint3D: middle_point]];
        [self getLineRecursive: result From: t_middle To: t_end WithMinAngle: angle];
    }
    else
        [result addObject: [NSValue valueWithPoint3D: middle_point]];
}

@end

@synthesize order = m_order;
@synthesize model_matrix = m_model_matrix;

@end


@implementation Surface


@synthesize order_u = m_order_u;
@synthesize order_v = m_order_v;
@synthesize model_matrix = m_model_matrix;

@end
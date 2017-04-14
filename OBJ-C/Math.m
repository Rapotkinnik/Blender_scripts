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

- (int) getPointsCount
{
    return 0;
}

- (Point3D) getPointAt: (float) t
{
        NSException* pure_method = [NSException
                                    exceptionWithName:@"PureVirtualMethodException"
                                    reason:@"You mustn't call this method directly from the superclass!"
                                    userInfo:nil];
        @throw pure_method;
}

- (GLKMatrix4) getModelMatrix
{
    return GLKMatrix4Identity;
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end withSegments: (unsigned int) count
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
    float half_delta = delta/2;
    
    [result addObject: [NSValue valueWithPoint3D: [self getPointAt: t_start]]];
    
    for (int index = 0; index < points_count; index++)
    {
        float tmp_delta = delta * index;
        Point3D start_point =  [self getPointAt:t_start + tmp_delta];
        Point3D end_point =    [self getPointAt:t_start + tmp_delta + delta];
        Point3D middle_point = [self getPointAt:t_start + tmp_delta + half_delta];
        
        if (getAngleBetween() > angle)
            continue;
        
        {
            [result addObject: [NSValue valueWithPoint3D: start_point]];
        }
    }
    
    
    [result addObject: [NSValue valueWithPoint3D: [self getPointAt: t_start]]];

    
    float t_middle = (t_end - t_start) / 2;
    
    
    
    [result addObject: [NSValue valueWithPoint3D: [self getPointAt: t_end]]];
    
    return result;
}

- (void) _getLineRecursive: (NSArray *) resylt From: (float) t_start To: (float) t_end withMinAngle: (float) angle
{
    
}

@end


// Поверхность
@implementation Surface

- (Point3D) getPointAtUV: (PointUV) point
{
    NSException* pure_method = [NSException
                                exceptionWithName:@"PureVirtualMethodException"
                                reason:@"You mustn't call this method directly from the superclass!"
                                userInfo:nil];
    @throw pure_method;
}

- (GLKMatrix4) getModelMatrix
{
    return GLKMatrix4Identity;
}

@end

#import "Math.h"

static const float MIN_DELTA_T = .000001f;

@implementation NSValue (BFPoint3D)

+ (NSValue *) valueWithBFPoint3D: (BFPoint3D) value
{
    return [self valueWithBytes:&value objCType:@encode(BFPoint3D)];
}

- (BFPoint3D) BFPoint3D
{
    BFPoint3D value;
    [self getValue: &value];
    return value;
}

@end

BFPoint3D LinearBezierCurve(const BFPoint3D points[2], float t)
{
    BFPoint3D result;
    result.x = (1 - t) * points[0].x + t * points[1].x;
    result.y = (1 - t) * points[0].y + t * points[1].y;
    result.z = (1 - t) * points[0].z + t * points[1].z;
    return result;
};

BFPoint3D QuadraticBezierCurve(const BFPoint3D points[3], float t)
{
    BFPoint3D result;
    result.x = pow(1 - t, 2) * points[0].x + 2 * t * (1 - t) * points[1].x + 2 * t * t * points[2].x;
    result.y = pow(1 - t, 2) * points[0].y + 2 * t * (1 - t) * points[1].y + 2 * t * t * points[2].y;
    result.z = pow(1 - t, 2) * points[0].z + 2 * t * (1 - t) * points[1].z + 2 * t * t * points[2].z;
    return result;
};

BFPoint3D CubicBezierCurve(const BFPoint3D points[4], float t)
{
    BFPoint3D result;
    result.x = pow(1 - t, 3) * points[0].x + 3 * pow(1 - t, 2) * t * points[1].x + 3 * (1 - t) * t * t * points[2].x + pow(t, 3) * points[3].x;
    result.y = pow(1 - t, 3) * points[0].y + 3 * pow(1 - t, 2) * t * points[1].y + 3 * (1 - t) * t * t * points[2].y + pow(t, 3) * points[3].y;
    result.z = pow(1 - t, 3) * points[0].z + 3 * pow(1 - t, 2) * t * points[1].z + 3 * (1 - t) * t * t * points[2].z + pow(t, 3) * points[3].z;
    return result;
};

BFPoint3D QuadricBezierCurve(const BFPoint3D points[5], float t)
{
    BFPoint3D result;
    result.x = pow(1 - t, 4) * points[0].x + 4 * pow(1 - t, 3) * t * points[1].x + 6 * pow(1 - t, 2) * t * t * points[2].x + 4 * pow(t, 3) * (1 - t) * points[3].x + pow(t, 4) * points[4].x;
    result.y = pow(1 - t, 4) * points[0].y + 4 * pow(1 - t, 3) * t * points[1].y + 6 * pow(1 - t, 2) * t * t * points[2].y + 4 * pow(t, 3) * (1 - t) * points[3].y + pow(t, 4) * points[4].y;
    result.z = pow(1 - t, 4) * points[0].z + 4 * pow(1 - t, 3) * t * points[1].z + 6 * pow(1 - t, 2) * t * t * points[2].z + 4 * pow(t, 3) * (1 - t) * points[3].z + pow(t, 4) * points[4].z;
    return result;
};

BFPoint3D QuinticBezierCurve(const BFPoint3D points[6], float t)
{
    BFPoint3D result;
    return result;
}

float absf(float value)
{
    if (value >= 0)
        return value;
    
    return -1 * value;
}


@implementation BFSpline

- (id) initWithPoints: (BFPoint3D *) points Count: (unsigned int) count Order: (unsigned int) order
{
    self = [super init];
    if (self)
    {
        memccpy(m_points, points, count, sizeof(BFPoint3D));
        m_count = count;
        m_order = order;
    }
    
    return self;
}

- (void) dealloc
{
    free(m_points);
}

- (BFPoint3D) getPointAt: (float) t
{
    unsigned int segment_count = m_count - m_order - 1;
    unsigned int segment       = (unsigned int) ceilf(t * segment_count);
    
    float segment_t = t * segment_count / segment;
    
    switch (m_order) {
        case 2:
            return LinearBezierCurve(&m_points[segment - 1], segment_t);
        case 3:
            return QuadraticBezierCurve(&m_points[segment - 1], segment_t);
        case 4:
            return CubicBezierCurve(&m_points[segment - 1], segment_t);
        case 5:
            return QuadricBezierCurve(&m_points[segment - 1], segment_t);
        case 6:
            return QuinticBezierCurve(&m_points[segment - 1], segment_t);
        default:
            break;
    }
    
    NSException* unsupported_order = [NSException
                                      exceptionWithName:@"UnSupportedOrderException"
                                      reason:[[NSString alloc] initWithFormat:@"This order=%d is unsupported!", m_order]
                                      userInfo:nil];
    @throw unsupported_order;
    
    BFPoint3D result;
    return    result;
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int) count
{
    int point_count = count * m_count - 2;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    float delta = (t_end - t_start) / point_count;
    for (int segment = 0; segment < point_count; segment++)
        [result addObject: [NSValue valueWithBFPoint3D: [self getPointAt: t_start + segment*delta]]];
    
    return result;
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle;
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    float delta = (t_end - t_start) / m_count;
    
    [result addObject: [NSValue valueWithBFPoint3D: [self getPointAt: t_start]]];
    for (int index = 0; index < m_count; index++)
        [self getLineRecursive:result From:t_start + delta * index To:t_start + delta * (index + 1) withMinAngle:angle];
    
    [result addObject: [NSValue valueWithBFPoint3D: [self getPointAt: t_end]]];
    
    return result;
}

- (void) getLineRecursive: (NSMutableArray *) result From: (float) t_start To: (float) t_end withMinAngle: (float) angle
{
    if (absf(t_end - t_start) <=  MIN_DELTA_T)
        return;
    
    float t_middle = (t_start - t_end) / 2;
    
    BFPoint3D start_point  = [[result lastObject] BFPoint3D];
    BFPoint3D end_point    = [self getPointAt:t_end];
    BFPoint3D middle_point = [self getPointAt:t_middle];
    
    BFPoint3D vector_me = { end_point.x - middle_point.x,
                            end_point.y - middle_point.y,
                            end_point.z - middle_point.z };
    
    BFPoint3D vector_ms = { start_point.x - middle_point.x,
                            start_point.y - middle_point.y,
                            start_point.z - middle_point.z };
    
    float angle_between_points = (vector_me.x*vector_ms.x + vector_me.y*vector_ms.z + vector_me.x*vector_ms.z) /
    (sqrtf(powf(vector_me.x, 2) + powf(vector_me.y, 2) + powf(vector_me.z, 2) *
           sqrtf(powf(vector_ms.x, 2) + powf(vector_ms.y, 2) + powf(vector_ms.z, 2))));
    
    if (absf(angle_between_points) > cosf(angle))
    {
        [self getLineRecursive: result From: t_start To: t_middle WithMinAngle: angle];
        
        [result addObject: [NSValue valueWithBFPoint3D: middle_point]];
        [self getLineRecursive: result From: t_middle To: t_end WithMinAngle: angle];
    }
    else
        [result addObject: [NSValue valueWithBFPoint3D: middle_point]];
}

@synthesize points = m_points;

@end


@implementation BFSurfaceSpline

- (id) initWithPoints: (NSArray *) splines Order: (unsigned int) order; // NSArray<BFSpline>
- (id) initWithPoints: (BFPoint3D *) points CountU: (unsigned int) count_u CountV: (unsigned int) count_v
                                            OrderU: (unsigned int) order_u OrderV: (unsigned int) order_v;
- (void) dealloc
{

}

- (BFPoint3D) getPointAt:         (BFPointUV)   point;
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithSegments: (int)   count;
- (NSArray *) getLineByPoints:    (BFPointUV *) points WithMinAngle: (float) angle;
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithSegments: (int)   count;
- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithMinAngle: (float) angle;

@end

@implementation BFExtrudedSpline

- (id) initWithPoints: (BFSpline *) spline Extrude: (unsigned int) extrude
{
    self = [super init];
    if (self)
    {
        [self setSpline: spline]
         m_extrude = extrude;
    }

    return self;
}

- (void) dealloc
{
    [self setSpline: NULL];
}

- (BFPoint3D) getPointAt: (BFPointUV) point;
{
    BFPoint3D result = [m_spline getPointAt: point.u];
    result.z += (point.v - 0.5) * m_extrude;

    return result;
}

- (NSArray *) getLineByPoints: (BFPointUV *) points WithSegments: (int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;

     for (int i = 0; i < len(points) - 1; i++)
     {
        NSArray *segment = [m_spline getLineFrom: points[i].u To: points[i + 1].u WithSegments: count];

        int delta_v = points[i + 1].v - points[i].v
        for (NSValue *value in segment)
        {
            [value ]
        }
     }

    return result;
}

- (NSArray *) getLineByPoints: (BFPointUV *) points WithMinAngle: (float) angle
{

}

- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithSegments: (int) count
{

}

- (NSArray *) getSurfaceByPoints: (BFPointUV *) points WithMinAngle: (float) angle
{

}

@property (assigned) BFSpline *spline;

@end
#import "Math.h"

static const float MIN_DELTA_T = .000001f;
static const float MACHINE_EPSILON = 2e-54;

@implementation NSValue (BFPoint3D)

+ (NSValue *) valueWithBFPoint3D: (BFPoint3D) value
{
    return [self valueWithBytes:&value objCType:@encode(BFPoint3D)];
}

+ (NSValue *) valueWithBFPoint3D:(BFPoint3D) value MetaData:(NSDictionary *)dict;
{
    NSValue *result = [self valueWithBytes:&value objCType:@encode(BFPoint3D)];
    [[result MetaData] setValuesForKeysWithDictionary:dict];
    
    return result;
}

- (id) getMetaData:(NSString *)name
{
    return [[self MetaData] valueForKey:name];
}
- (void) addMetaData:(NSString *)name WithValue:(id) value
{
    [[self MetaData] setValue:value forKey:name];
}

- (BFPoint3D) BFPoint3D
{
    BFPoint3D value;
    [self getValue: &value];
    return value;
}

@dynamic MetaData;

@end

@implementation NSValue (BFPointUV)

+ (NSValue *) valueWithBFPointUV: (BFPointUV) value
{
    return [self valueWithBytes:&value objCType:@encode(BFPointUV)];
}

- (BFPointUV) BFPointUV
{
    BFPointUV value;
    [self getValue: &value];
    return value;
}

@end

@implementation NSValue (BFVertext)

+ (NSValue *) valueWithBFVertext: (BFVertext) value
{
    return [self valueWithBytes:&value objCType:@encode(BFVertext)];
}

- (BFVertext) BFVertext
{
    BFVertext value;
    [self getValue: &value];
    return value;
}

@end

@implementation BFLine

- (id) initWithPointsUV:(BFPointUV)a :(BFPointUV)b
{
    self = [super init];
    if (self)
    {
        m_points.pointsUV[0] = a;
        m_points.pointsUV[1] = b;
        m_a = b.v - a.v;
        m_b = a.u - b.u;
        m_c = - a.u * m_a - a.v * m_b;
    }
    
    return self;
}

- (id) initWithPoints2D:(BFPoint2D)a :(BFPoint2D)b
{
    self = [super init];
    if (self)
    {
        m_points.points2D[0] = a;
        m_points.points2D[1] = b;
        m_a = b.y - a.y;
        m_b = a.x - b.x;
        m_c = - a.x * m_a - a.y * m_b;
    }
    
    return self;
}

- (id) lineWithPointsUV:(BFPointUV)a :(BFPointUV)b
{
#ifdef OBJC_ARC_UNAVAILABLE
    //    return [[[BFCoordExchanger alloc] initWithPoints:a And:b] autorelease];
#endif
    return [[BFLine alloc] initWithPointsUV:a :b];
}

- (id) lineWithPoints2D:(BFPoint2D)a :(BFPoint2D)b
{
    return [[BFLine alloc] initWithPoints2D:a :b];
}

- (float) leftTurnWithPoint2D:(BFPoint2D) point
{
    return (m_points.points2D[1].y - m_points.points2D[0].y) * (point.x - m_points.points2D[0].x) -
           (m_points.points2D[1].x - m_points.points2D[0].x) * (point.y - m_points.points2D[0].y);
}

- (float) leftTurnWithpointUV:(BFPointUV) point
{
    return (m_points.pointsUV[1].v - m_points.pointsUV[0].v) * (point.u - m_points.pointsUV[0].u) -
           (m_points.pointsUV[1].u - m_points.pointsUV[0].u) * (point.v - m_points.pointsUV[0].v);
}

- (LineIntersection) isIntersectedBy:(BFLine *) line
{
    float first  = [self leftTurnWithPoint2D:line->m_points.points2D[0]];
    float second = [self leftTurnWithPoint2D:line->m_points.points2D[1]];
    
    if (fabs(first) < MACHINE_EPSILON)
        return TouchFirst;
    if (fabs(second) < MACHINE_EPSILON)
        return TouchSecond;
    if (first * second < 0)
        return Intersection;
    
    return UnIntersection;
}

@synthesize a = m_a, b = m_b, c = m_c;

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

BOOL IsConvex(id curValue, id<NSFastEnumeration> *poly, BFGetPointUVFromValue block)
{
    BFPointUV point = block(curValue, NULL);
    
    /*    if ((cur == NULL) || (figure.getSize() <= 0))
     return false;
     
     float a, b, c;
     
     QPointF *pointA = cur->getContent();
     QPointF *pointB = cur->getNext()->getContent();
     QPointF *pointC = cur->getPrev()->getContent();
     QPointF *point = NULL;
     
     if (((pointB->x() - pointA->x())*(pointC->y() - pointA->y()) -
     (pointB->y() - pointA->y())*(pointC->x() - pointA->x())) <= 0)
     return false;
     
     figure.goBOList();
     do
     {
     point = figure.getCur()->getContent();
     if ((point != pointA) && (point != pointB) && (point != pointC))
     {
     a = (pointA->x() - point->x()) * (pointB->y() - pointA->y()) -
     (pointB->x() - pointA->x()) * (pointA->y() - point->y());
     b = (pointB->x() - point->x()) * (pointC->y() - pointB->y()) -
     (pointC->x() - pointB->x()) * (pointB->y() - point->y());
     c = (pointC->x() - point->x()) * (pointA->y() - pointC->y()) -
     (pointA->x() - pointC->x()) * (pointC->y() - point->y());
     if (((a < 0 && b < 0 && c < 0) || (a > 0 && b > 0 && c > 0)))
     return false;
     }
     
     figure.goNext();
     
     }while(!figure.isBOList());*/
    
    return YES;
}

NSArray *BFTriangulate(NSEnumerator *poly)
{
    return BFTriangulateWithGetPointFunc(poly, ^BFPointUV(id value, BOOL *isOK) {
        *isOK = YES;
        return [value BFPointUV];
    });
}

NSArray *BFTriangulateWithGetPointFunc(NSEnumerator *poly, BFGetPointUVFromValue block)
{
    NSMutableArray *result = [NSMutableArray array];
    if (!result)
        return result;
    
    while ([poly count] > 3)
    {
        if (IsConvex(, , BLOCK))
        {
            
        }
    }
    
    /*
    QList<QList<QPointF *> > triangles;
    figure.goBOList();
    //    float aX, aY, bX, bY;
    int i = 0;
    while((figure.getSize() > 3) && (i < figure.getSize()))
    {
        
        //        aX = figure.getCur()->getContent()->x() - figure.getPrev()->getContent()->x();
        //        aY = figure.getCur()->getContent()->y() - figure.getPrev()->getContent()->y();
        //        bX = figure.getNext()->getContent()->x() - figure.getCur()->getContent()->x();
        //        bY = figure.getNext()->getContent()->y() - figure.getCur()->getContent()->y();
        
        //        qDebug()<<(aX*bX + aX*bY)/sqrt((aX*aX + aY*aY)*(bX*bX + bY*bY));
        
        if (isEar(figure.getCur(), figure))
        {
            QList<QPointF *> list;
            list.append(new QPointF(*figure.getPrev()->getContent()));
            list.append(new QPointF(*figure.getCur()->getContent()));
            list.append(new QPointF(*figure.getNext()->getContent()));
            figure.removeCur();
            //            figure.goPrev();
            
            i = 0;
            triangles.append(list);
            //            updateGL();
        }
        
        i++;
        figure.goNext();
    }
    
    QList<QPointF *> list;
    list.append(new QPointF(*figure.getPrev()->getContent()));
    list.append(new QPointF(*figure.getCur()->getContent()));
    list.append(new QPointF(*figure.getNext()->getContent()));
    
    triangles.append(list); */
    
    return result;
}

float absf(float value)
{
    if (value >= 0)
        return value;
    
    return -1 * value;
}

@interface BFCurveMesh : BFObject <BFMesh>

@end

@implementation BFCurveMesh

@end

@interface BFSurfaceMesh : BFObject <BFMesh>

@end

@implementation BFSurfaceMesh

@end

@implementation BFSpline

- (id) initWithPoints: (NSArray *) points Order: (unsigned int) order
{
    self = [super init];
    if (self)
    {
        m_order = order;
        m_points = [NSMutableArray arrayWithArray:points];
    }
    
    return self;
}

- (id) initWithPoints: (BFPoint3D *) points Count: (unsigned int) count Order: (unsigned int) order
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < count; i++)
        [array addObject:[NSValue valueWithBFPoint3D:points[i]]];
    
    return [self initWithPoints:array Order:order];
}

- (void) dealloc
{
    [self setPoints:NULL];
}

- (BFPoint3D) getPointAt: (float) t
{
    BFPoint3D points[m_order];
    unsigned int segment_count = [m_points count] - m_order - 1;
    unsigned int segment       = (unsigned int) ceilf(t * segment_count);
    
    float segment_t = t * segment_count / segment;
    for (int i = 0; i < m_order; i++)
        points[i] = [[m_points objectAtIndex:segment + i - 1] BFPoint3D];
    
    switch (m_order) {
        case 2:
            return LinearBezierCurve(points, segment_t);
        case 3:
            return QuadraticBezierCurve(points, segment_t);
        case 4:
            return CubicBezierCurve(points, segment_t);
        case 5:
            return QuadricBezierCurve(points, segment_t);
        case 6:
            return QuinticBezierCurve(points, segment_t);
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
    return [self getLineFrom:t_start To:t_end WithSegments:count WithBlock:NULL];
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle
{
    return [self getLineFrom:t_start To:t_end WithMinAngle:angle WithBlock:NULL];
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int) count WithBlock:(BFPerPointBlock) block
{
    int point_count = count * [m_points count] - 2;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    float delta = (t_end - t_start) / point_count;
    for (int segment = 0; segment < point_count; segment++)
    {
        float t = t_start + segment*delta;
        BFPoint3D point = [self getPointAt: t];
        [result addObject: [NSValue valueWithBFPoint3D: point
                                              MetaData: @{@"t": [NSNumber numberWithFloat:t]}]];
    }
    
    return result;
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle WithBlock:(BFPerPointBlock) block
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    float delta = (t_end - t_start) / [m_points count];
    
    [result addObject: [NSValue valueWithBFPoint3D: [self getPointAt: t_start]]];
    for (int index = 0; index < [m_points count]; index++)
        [self getLineRecursive:result From:t_start + delta * index To:t_start + delta * (index + 1) WithMinAngle:angle];
    
    [result addObject: [NSValue valueWithBFPoint3D: [self getPointAt: t_end]]];
    
    return result;
}

- (void) getLineRecursive: (NSMutableArray *) result From: (float) t_start To: (float) t_end WithMinAngle: (float) angle
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
    
    float angle_between_points = (vector_me.x * vector_ms.x + vector_me.y * vector_ms.z + vector_me.x * vector_ms.z) /
                                 (sqrtf(powf(vector_me.x, 2) + powf(vector_me.y, 2) + powf(vector_me.z, 2) *
                                  sqrtf(powf(vector_ms.x, 2) + powf(vector_ms.y, 2) + powf(vector_ms.z, 2))));
    
    if (absf(angle_between_points) > cosf(angle))
    {
        [self getLineRecursive:result From:t_start To:t_middle WithMinAngle:angle];
        [result addObject: [NSValue valueWithBFPoint3D: middle_point]];
        [self getLineRecursive:result From:t_middle To:t_end WithMinAngle:angle];
    }
    else
        [result addObject: [NSValue valueWithBFPoint3D: middle_point]];
}

@synthesize points = m_points;

@end


@implementation BFSurfaceSpline

- (id) initWithSplines: (NSArray *) splines Order: (unsigned int) order
{
    self = [super init];
    if (self)
    {
        [self setSplines:splines];
        m_order = order;
    }
    
    return self;
}

- (id) initWithPoints: (BFPoint3D *) points CountU: (unsigned int) count_u CountV: (unsigned int) count_v
                                            OrderU: (unsigned int) order_u OrderV: (unsigned int) order_v
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < count_v; i++)
        [array addObject:[[BFSpline alloc] initWithPoints:(points + i * count_u) Count:count_u Order:order_u]];
    
    return [self initWithSplines:array Order:order_v];
}

- (void) dealloc
{
    [self setSplines:NULL];
}

- (BFPoint3D) getPointAt: (BFPointUV) point
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (BFSpline *spline in m_splines)
        [array addObject:[NSValue valueWithBFPoint3D:[spline getPointAt:point.u]]];
    
    BFSpline *v_spline = [[BFSpline alloc] initWithPoints:array Order:m_order];  // TODO: Ну скорее всего это утечка памяти!=(
    
    return [v_spline getPointAt:point.v];
}

- (NSArray *) getLineByPoints: (NSArray *) points WithSegments: (int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    return result;
}

- (NSArray *) getLineByPoints: (NSArray *) points WithMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    return result;
}

- (NSArray *) getSurfaceByPoints: (NSArray *) points WithSegments: (int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    return result;
}

- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    return result;
}

@synthesize splines = m_splines;

@end


@implementation BFExtrudedSpline

- (id) initWithPoints:(BFSpline *) spline Extrude:(unsigned int) extrude
{
    return [self initWithSpline:spline Extrude:extrude Matrix:GLKMatrix4Identity];
}

- (id) initWithSplines: (BFSpline *) spline Extrude: (unsigned int) extrude WithMatrix:(GLKMatrix4) matrix
{
    self = [super init];
    if (self)
    {
        [self setSpline:spline];
        m_extrude = extrude;
    }
    
    return self;
}

- (void) dealloc
{
    [self setSpline:NULL];
}

- (BFVertext) getPointAt: (BFPointUV) point;
{
    BFPoint3D point3D = [m_spline getPointAt: point.u];
    point3D.z += (point.v - 0.5) * m_extrude;
    
    BFVertext result;
    result.coord = point3D;
    result.textureCoord = point;

    return result;
}

- (id<BFMesh>) getLineByPoints: (NSArray *) points WithSegments: (int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;

    for (int i = 0; i < [points count] - 1; i++)
    {
        BFCoordExchanger *exchenger = [[BFCoordExchanger alloc] initWithPoints:[points[i] BFPointUV]
                                                                           And:[points[i + 1] BFPointUV]];
        
        NSMutableArray *segment_result =  [NSMutableArray arrayWithArray: [m_spline getLineFrom:[points[i] BFPointUV].u
                                                                                             To:[points[i + 1] BFPointUV].u
                                                                                   WithSegments:count WithBlock:^(BFPoint3D *point, float t) {
                                                                                        point->z += ([exchenger vfromu:t] - 0.5) * m_extrude;
                                                                                   }]];
        
        for (int i = 0; i < [segment_result count]; i++)
        {
            NSValue *value = [segment_result objectAtIndex:i];
            BFPoint3D point = [value BFPoint3D];
            point.z += ([exchenger vfromu:[[value getMetaData:@"t"] floatValue]] - 0.5) * m_extrude;
            [segment_result replaceObjectAtIndex:i withObject:[NSValue valueWithBFPoint3D:point]];
        }
        
        [result addObjectsFromArray: segment_result];
        
    }

    return result;
}

- (id<BFMesh>) getLineByPoints: (NSArray *) points WithMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    return result;
}

- (id<BFMesh>) getSurfaceByPoints: (NSArray *) points WithSegments: (int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    NSArray *outlinePoints = [self getLineByPoints:points WithSegments:count];
    NSArray *outlineIndices = BFTriangulate([outlinePoints objectEnumerator]);
    
    for (int i = 0; i < [outlineIndices count]; i = i+3)
    {
        
    }
    for (NSNumber *index in outlineIndices)
    
    return result;
}

- (id<BFMesh>) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    NSArray *segment =
    
    return result;
}

- (GLKMatrix4) getModelMatrix
{
    return m_matrix;
}

@synthesize spline = m_spline;

@end
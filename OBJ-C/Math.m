#import "Math.h"
#import "BFUtils.h"

static const float MIN_DELTA_T = 1e-10;
static const float MACHINE_EPSILON = 2e-54;

@implementation BFValue

-(instancetype)initWithData:(void *)data MetaData:(NSDictionary *)metaData
{
    self = [super init];
    if (self)
    {
        m_data = data;
        m_metaData = [NSMutableDictionary dictionaryWithDictionary:metaData];
    }
    
    return self;
}

-(void)dealloc
{
    free(m_data);
}

-(void *)getValue
{
    return m_data;
}

-(id)getMetaData:(NSString *)name
{
    if (m_metaData)
        return [m_metaData objectForKey:name];
    
    return NULL;
}

-(void)addMetaData:(id)value WithName:(NSString *)name
{
    if (!m_metaData)
        m_metaData = [NSMutableDictionary dictionary];
    
    [m_metaData setObject:value forKey:name];
}

@end

@implementation BFValue (BFPoint3D)

+(BFValue *)valueWithBFPoint3D:(BFPoint3D)value
{
    BFPoint3D *data = (BFPoint3D *)malloc(sizeof(BFPoint3D));  *data = value;
    return [[BFValue alloc] initWithData:data MetaData:NULL];
}

+(BFValue *)valueWithBFPoint3DRef:(BFPoint3DRef)value
{
    return [[BFValue alloc] initWithData:value MetaData:NULL];
}

+(BFValue *)valueWithBFPoint3D:(BFPoint3D)value MetaData:(NSDictionary *)dict
{
    BFPoint3D *data = (BFPoint3D *)malloc(sizeof(BFPoint3D));  *data = value;
    return [[BFValue alloc] initWithData:data MetaData:dict];
}
+(BFValue *)valueWithBFPoint3DRef:(BFPoint3DRef)value MetaData:(NSDictionary *)dict
{
    return [[BFValue alloc] initWithData:value MetaData:dict];
}

-(BFPoint3D)BFPoint3D
{
    return *(BFPoint3D *)[self getValue];
    
}
-(BFPoint3DRef)BFPoint3DRef
{
    return (BFPoint3DRef)[self getValue];
}

@end

@implementation BFValue (BFVertex)

+(BFValue *)valueWithBFVertex:(BFVertex)value
{
    BFVertex *data = (BFVertex *)malloc(sizeof(BFVertex));  *data = value;
    return [[BFValue alloc] initWithData:data MetaData:NULL];
}

+(BFValue *)valueWithBFVertexRef:(BFVertexRef)value
{
    return [[BFValue alloc] initWithData:value MetaData:NULL];
}

+(BFValue *)valueWithBFVertex:(BFVertex)value MetaData:(NSDictionary *)dict
{
    BFVertex *data = (BFVertex *)malloc(sizeof(BFVertex));  *data = value;
    return [[BFValue alloc] initWithData:data MetaData:dict];
}
+(BFValue *)valueWithBFVertexRef:(BFVertexRef)value MetaData:(NSDictionary *)dict
{
    return [[BFValue alloc] initWithData:value MetaData:dict];
}

-(BFVertex)BFVertex
{
    return *(BFVertex *)[self getValue];
    
}
-(BFVertexRef)BFVertexRef
{
    return (BFVertexRef)[self getValue];
}

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

@implementation NSValue (BFVertex)

+ (NSValue *) valueWithBFVertex: (BFVertex) value
{
    return [self valueWithBytes:&value objCType:@encode(BFVertex)];
}

- (BFVertex) BFVertex
{
    BFVertex value;
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

+ (id) lineWithPointsUV:(BFPointUV)a :(BFPointUV)b
{
#ifdef OBJC_ARC_UNAVAILABLE
    //    return [[[BFCoordExchanger alloc] initWithPoints:a And:b] autorelease];
#endif
    return [[BFLine alloc] initWithPointsUV:a :b];
}

+ (id) lineWithPoints2D:(BFPoint2D)a :(BFPoint2D)b
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

- (BFPointUV) getIntersectionPointUVWith:(BFLine *) line
{
    BFPointUV result;
    
    return result;
}

- (BFPoint2D) getIntersectionPoint2DWith:(BFLine *) line
{
    BFPoint2D result;
    
    return result;
}

- (float) vFromU:(float) u
{
    if (m_b)
        return - (m_c + m_a * u) / m_b;
    
    return 0.0;
}
- (float) uFromV:(float) v
{
    if (m_a)
        return - (m_c + m_b * v) / m_a;
    
    return 0.0;
}
- (float) yFromX:(float) x
{
    if (m_b)
        return - (m_c + m_a * x) / m_b;

    return 0.0;
}
- (float) xFromY:(float) y
{
    if (m_a)
        return - (m_c + m_b * y) / m_a;
    
    return 0.0;
}

@synthesize a = m_a, b = m_b, c = m_c;

@end

float LinearBezierCurve1D(const float values[2], float t)
{
    return (1 - t) * values[0] + t * values[1];
}

float QuadraticBezierCurve1D(const float values[3], float t)
{
    return pow(1 - t, 2) * values[0] + 2 * t * (1 - t) * values[1] + t * t * values[2];
}

float CubicBezierCurve1D(const float values[4], float t)
{
    return pow(1 - t, 3) * values[0] + 3 * pow(1 - t, 2) * t * values[1] + 3 * (1 - t) * t * t * values[2] + pow(t, 3) * values[3];
}

float QuadricBezierCurve1D(const float values[5], float t)
{
    return pow(1 - t, 4) * values[0] + 4 * pow(1 - t, 3) * t * values[1] + 6 * pow(1 - t, 2) * t * t * values[2] + 4 * pow(t, 3) * (1 - t) * values[3] + pow(t, 4) * values[4];
}

float QuinticBezierCurve1D(const float values[6], float t)
{
    return 0.0;
}

float getPointOnCurve(const float *values, int size, int order, const float t)
{
    unsigned int degree        = order - 1;
    unsigned int segment_count = (unsigned int) size / degree;
    unsigned int segment       = (unsigned int) (t == 1)?segment_count - 1:floor(t * segment_count);

    float segment_t = t * segment_count - segment;

    switch (order) {
        case 2:
            return LinearBezierCurve1D(values + segment * degree, segment_t);
        case 3:
            return QuadraticBezierCurve1D(values + segment * degree, segment_t);
        case 4:
            return CubicBezierCurve1D(values + segment * degree, segment_t);
        case 5:
            return QuadricBezierCurve1D(values + segment * degree, segment_t);
        case 6:
            return QuinticBezierCurve1D(values + segment * degree, segment_t);
        default:
            break;
    }

    return 0.0;
}

BFPoint3D MakeNormal(BFPoint3D * const point)
{
    BFPoint3D result;
    float length = sqrt(pow(point->x, 2) + pow(point->y, 2) + pow(point->z, 2));

    result.x = -point->y / length;
    result.y =  point->x / length;
    result.z =  point->z / length;

    return result;
}

BFPoint3D LinearBezierCurve(const BFPoint3D points[2], float t)
{
    BFPoint3D result;
    result.x = (1 - t) * points[0].x + t * points[1].x; // = LinearBezierCurve1D((float[2]){points[0].x, points[1].x}, t)
    result.y = (1 - t) * points[0].y + t * points[1].y;
    result.z = (1 - t) * points[0].z + t * points[1].z;
    return result;
};

BFPoint3D QuadraticBezierCurve(const BFPoint3D points[3], float t)
{
    BFPoint3D result;
    result.x = pow(1 - t, 2) * points[0].x + 2 * t * (1 - t) * points[1].x + t * t * points[2].x;
    result.y = pow(1 - t, 2) * points[0].y + 2 * t * (1 - t) * points[1].y + t * t * points[2].y;
    result.z = pow(1 - t, 2) * points[0].z + 2 * t * (1 - t) * points[1].z + t * t * points[2].z;
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

BFPoint3D NormalToLinearBezierCurve(const BFPoint3D points[2], float t)
{
    BFPoint3D result;
    // Касательная к кривой в точке t
    result.x = points[1].x - points[0].x;
    result.y = points[1].y - points[0].y;
    result.z = points[1].z - points[0].z;

    // Преобразуем касательную в нормализованную нормаль к кривой в точке t
    return MakeNormal(&result);
}

BFPoint3D NormalToQuadraticBezierCurve(const BFPoint3D points[3], float t)
{
    BFPoint3D result;
    result.x = 2 * (1 - t) * (points[1].x - points[0].x) + 2 * t * (points[2].x - points[1].x);
    result.y = 2 * (1 - t) * (points[1].y - points[0].y) + 2 * t * (points[2].y - points[1].y);
    result.z = 2 * (1 - t) * (points[1].z - points[0].z) + 2 * t * (points[2].z - points[1].z);

    return MakeNormal(&result);
}

BFPoint3D NormalToCubicBezierCurve(const BFPoint3D points[4], float t)
{
    BFPoint3D result;
    result.x = 3 * pow((1 - t), 2) * (points[1].x - points[0].x) + 6 * (1 - t) * t * (points[2].x - points[1].x) + 3 * pow(t, 2) * (points[3].x - points[2].x);
    result.y = 3 * pow((1 - t), 2) * (points[1].y - points[0].y) + 6 * (1 - t) * t * (points[2].y - points[1].y) + 3 * pow(t, 2) * (points[3].y - points[2].y);
    result.z = 3 * pow((1 - t), 2) * (points[1].z - points[0].z) + 6 * (1 - t) * t * (points[2].z - points[1].z) + 3 * pow(t, 2) * (points[3].z - points[2].z);

    return MakeNormal(&result);
}

BFPoint3D NormalToQuadricBezierCurve(const BFPoint3D points[5], float t)
{
    BFPoint3D result;
    result.x = 4 * pow((1 - t), 3) * (points[1].x - points[0].x) + 12 * pow((1 - t), 2) * t * (points[2].x - points[1].x) + 12 * (1 - t) * pow(t, 2) * (points[3].x - points[2].x) + 4 * pow(t, 3) * (points[4].x - points[3].x);
    result.y = 4 * pow((1 - t), 3) * (points[1].y - points[0].y) + 12 * pow((1 - t), 2) * t * (points[2].y - points[1].y) + 12 * (1 - t) * pow(t, 2) * (points[3].y - points[2].y) + 4 * pow(t, 3) * (points[4].y - points[3].y);
    result.z = 4 * pow((1 - t), 3) * (points[1].z - points[0].z) + 12 * pow((1 - t), 2) * t * (points[2].z - points[1].z) + 12 * (1 - t) * pow(t, 2) * (points[3].z - points[2].z) + 4 * pow(t, 3) * (points[4].z - points[3].z);

    return MakeNormal(&result);
}

BFPoint3D NormalToQuinticBezierCurve(const BFPoint3D points[6], float t)
{
    BFPoint3D result;
    return result;
}

BOOL IsConvex(BFListElem *curElem, BFCircularList *poly, BFGetPointUVFromValue block)
{
    if (!curElem || [poly getSize] < 3)
        return NO;
    
    if ([poly getSize] == 3)
        return YES;
    
    BOOL isOkFirst, isOkLast;
    BFLine *line = [BFLine lineWithPointsUV:block([[curElem getNext] getValue], &isOkFirst)
                                           :block([[curElem getPrev] getValue], &isOkLast)];
    
    if (isOkFirst && isOkLast)
    {
        //for (BFListElem *elem in poly)
        BFListElem * cur = [poly getCur];
        while ([poly getCur] != cur) {
            BFListElem * elem = [poly getCur];
            if ([line isIntersectedBy:[BFLine lineWithPointsUV:block([elem getValue], &isOkFirst)
                                                              :block([[elem getNext] getValue], &isOkLast)]] == Intersection && isOkFirst && isOkLast)
                return NO;
            
            [poly goNext];
        }
    }
    
    return YES;
}

/*
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
     
     }while(!figure.isBOList());
*/

/*NSArray<NSMutableArray<NSValue>> массив треугольникв*/
 NSArray *BFTriangulateWithGetPointUVFunc(NSArray *poly, BFGetPointUVFromValue block)
 {
     NSMutableArray *result = [NSMutableArray array];
     if (!result)
         return result;
     
     BFCircularList *list = [BFCircularList circularListWithArray:poly];
     
     while ([list getSize] >= 3)
     {
         if (IsConvex([list getCur], list, block))
         {
             BFListElem *curElem = [list getCur];
             [result addObject:[curElem getValue]];
             [result addObject:[[curElem getNext] getValue]];
             [result addObject:[[curElem getPrev] getValue]];

             [list removeCur];
         }
         else
             [list goNext];
     }
     
     return result;
 }

/*NSArray<NSArray<NSValue>> массив треугольникв
NSArray *BFTriangulateWithGetPointUVFunc(NSArray *poly, BFGetPointUVFromValue block)
{
    NSMutableArray *result = [NSMutableArray array];
    if (!result)
        return result;
    
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
    
    triangles.append(list);
    
    return result;
}
*/

@implementation BFObject
- (GLKMatrix4) getModelMatrix
{
    return GLKMatrix4Identity;
}
@end

//@interface BFCurveMesh : BFObject <BFMesh>
//
//@end
//
//@implementation BFCurveMesh
//
//- (GLuint)getGLPrimitive
//{
//    return GL_LINE_STRIP;
//}
//
//@end

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
        [array addObject:[BFValue valueWithBFPoint3D:points[i]]];
    
    return [self initWithPoints:array Order:order];
}

- (void) dealloc
{
    [self setPoints:NULL];
}

- (BFPoint3D) getPointAt: (float) t
{
    if (t < 0 || t > 1) {
        NSException* wrong_t = [NSException exceptionWithName:@"WrongTValueException"
                                                       reason:[[NSString alloc] initWithFormat:@"t must be in [0 .. 1], not %f;", t]
                                                     userInfo:nil];
        @throw wrong_t;
    }
    
    BFPoint3D points[m_order];
    unsigned int degree        = m_order - 1;
    unsigned int segment_count = (unsigned int) [m_points count] / degree;
    unsigned int segment       = (unsigned int) (t == 1)?segment_count - 1:floor(t * segment_count);
    
    float segment_t = t * segment_count - segment;
    for (int i = 0; i < m_order; i++)
        points[i] = [[m_points objectAtIndex:segment * degree + i] BFPoint3D];
    
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
    
    NSException* unsupported_order = [NSException exceptionWithName:@"UnSupportedOrderException"
                                                             reason:[[NSString alloc] initWithFormat:@"This order=%d is unsupported!", m_order]
                                                           userInfo:nil];
    @throw unsupported_order;
    
    return (BFPoint3D) {};
}

- (BFPoint3D) getNormalAt: (float) t
{
    if (t < 0 || t > 1) {
        NSException* wrong_t = [NSException exceptionWithName:@"WrongTValueException"
                                                       reason:[[NSString alloc] initWithFormat:@"t must be in [0 .. 1], not %f;", t]
                                                     userInfo:nil];
        @throw wrong_t;
    }
    
    BFPoint3D points[m_order];
    unsigned int degree        = m_order - 1;
    unsigned int segment_count = (unsigned int) [m_points count] / degree;
    unsigned int segment       = (unsigned int) (t == 1)?segment_count - 1:floor(t * segment_count);
    
    float segment_t = t * segment_count - segment;
    for (int i = 0; i < m_order; i++)
        points[i] = [[m_points objectAtIndex:segment * degree + i] BFPoint3D];
    
    switch (m_order) {
        case 2:
            return NormalToLinearBezierCurve(points, segment_t);
        case 3:
            return NormalToQuadraticBezierCurve(points, segment_t);
        case 4:
            return NormalToCubicBezierCurve(points, segment_t);
        case 5:
            return NormalToQuadricBezierCurve(points, segment_t);
        case 6:
            return NormalToQuinticBezierCurve(points, segment_t);
        default:
            break;
    }
    
    NSException* unsupported_order = [NSException exceptionWithName:@"UnSupportedOrderException"
                                                             reason:[[NSString alloc] initWithFormat:@"This order=%d is unsupported!", m_order]
                                                           userInfo:nil];
    @throw unsupported_order;
    
    return (BFPoint3D) {};
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int) count
{
    int point_count = count * [m_points count] - 2;
    NSMutableArray *result = [NSMutableArray array];
    
    float delta = (t_end - t_start) / point_count;
    for (int segment = 0; segment < point_count; segment++)
    {
        float t = t_start + segment*delta;
        BFPoint3D point = [self getPointAt: t];
        [result addObject: [BFValue valueWithBFPoint3D: point
                                              MetaData: @{@"t": [NSNumber numberWithFloat:t]}]];
    }
    
    return result;
}

- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle
{
    NSMutableArray *result = [NSMutableArray array];
    
    float t_max = MIN(t_start, t_end);
    float t_min = MAX(t_start, t_end);
    
    NSInteger point_count = [m_points count];
    NSMutableArray *segments = [NSMutableArray arrayWithObject:[NSNumber numberWithFloat:t_start]];
    for (int i = 0; i < point_count; i = i + m_order - 1)
    {
        float edge_point_t = 1.0 * i / (point_count - 1);
        if (t_max < edge_point_t && edge_point_t < t_min)  // Возможно стоит использовать fabsf(t_start - edge_point_t) < MIN_DELTA_T
            [segments addObject:[NSNumber numberWithFloat:edge_point_t]];
    }
    
    [segments addObject:[NSNumber numberWithFloat:t_end]];
    
    [result addObject:[BFValue valueWithBFPoint3D:[self getPointAt:t_start]
                                         MetaData:@{@"t":[NSNumber numberWithFloat:t_start]}]];
    
    for (int i = 0; i < [segments count] - 1; i++)
    {
        float end_t    = [segments[i + 1] floatValue];
        float start_t  = [segments[i    ] floatValue];
        float middle_t = start_t + (end_t - start_t) / 2;
        
        [self getLineRecursive:result From:start_t  To:middle_t WithMinAngle:angle];
        [self getLineRecursive:result From:middle_t To:end_t    WithMinAngle:angle];
    }
    
    /*
    float delta = (t_end - t_start) / [m_points count];
    
    [result addObject: [BFValue valueWithBFPoint3D:[self getPointAt:t_start]
                                          MetaData:@{@"t":[NSNumber numberWithFloat:t_start]}]];
    for (int index = 0; index < [m_points count]; index++)
        [self getLineRecursive:result From:t_start + delta * index To:t_start + delta * (index + 1) WithMinAngle:angle];
    
    [result addObject: [BFValue valueWithBFPoint3D:[self getPointAt: t_end]
                                          MetaData:@{@"t": [NSNumber numberWithFloat:t_end]}]];
     */
    return result;
}

- (void) getLineRecursive: (NSMutableArray *) result From: (float) t_start To: (float) t_end WithMinAngle: (float) angle
{
    if (fabsf(t_end - t_start) <=  MIN_DELTA_T)
        return;
    
    float t_middle = t_start + (t_end - t_start) / 2;
    
    BFPoint3D start_point  = [[result lastObject] BFPoint3D];
    BFPoint3D end_point    = [self getPointAt:t_end];
    BFPoint3D middle_point = [self getPointAt:t_middle];
    
    BFPoint3D vector_me = { end_point.x - middle_point.x,
                            end_point.y - middle_point.y,
                            end_point.z - middle_point.z };
    
    BFPoint3D vector_ms = { start_point.x - middle_point.x,
                            start_point.y - middle_point.y,
                            start_point.z - middle_point.z };
    
    float angle_between_points = (vector_me.x * vector_ms.x + vector_me.y * vector_ms.y + vector_me.z * vector_ms.z) /
                                 (sqrtf(powf(vector_me.x, 2) + powf(vector_me.y, 2) + powf(vector_me.z, 2)) *
                                  sqrtf(powf(vector_ms.x, 2) + powf(vector_ms.y, 2) + powf(vector_ms.z, 2)));
    
    if (angle_between_points > cosf(M_PI * (180 - angle) / 180))
    {
        [self getLineRecursive:result From:t_start To:t_middle WithMinAngle:angle];
        [result addObject: [BFValue valueWithBFPoint3D: middle_point MetaData:@{@"t": [NSNumber numberWithFloat:t_middle]}]];
        [self getLineRecursive:result From:t_middle To:t_end WithMinAngle:angle];
    }
    else
        [result addObject: [BFValue valueWithBFPoint3D: middle_point MetaData:@{@"t": [NSNumber numberWithFloat:t_middle]}]];
    
    [result addObject: [BFValue valueWithBFPoint3D: end_point MetaData:@{@"t": [NSNumber numberWithFloat:t_end]}]];
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

- (BFVertex) getPointAt: (BFPointUV) point
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (BFSpline *spline in m_splines)
        [array addObject:[BFValue valueWithBFPoint3D:[spline getPointAt:point.u]]];
    
    BFSpline *v_spline = [[BFSpline alloc] initWithPoints:array Order:m_order];  // TODO: Все ОК только в случае ARC
    
    BFVertex result;
    result.coord = [v_spline getPointAt:point.v];
    result.normal = [v_spline getNormalAt:point.v];
    result.textureCoord = point;
    
    return result;
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

- (instancetype) initWithSpline:(BFSpline *)spline Extrude:(unsigned int)extrude
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

- (BFVertex) getPointAt: (BFPointUV) point;
{
    BFPoint3D point3D = [m_spline getPointAt: point.u];
    point3D.z += (point.v - 0.5) * m_extrude;
    
    BFVertex result;
    result.coord = point3D;
    result.normal = [m_spline getNormalAt: point.u];
    result.textureCoord = point;

    return result;
}

- (NSArray *) getLineByPoints:(BFPointUV *)first :(BFPointUV *)last WithMinAngle:(float)angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    if (fabsf(first->u - last->u) >= MIN_DELTA_T)
    {
        BFLine *line = [[BFLine alloc] initWithPointsUV:*first :*last];
        NSArray *array = [m_spline getLineFrom:first->u To:last->u WithMinAngle:angle];
        
        for (BFValue *value in array)
        {
            BFVertex vertex;
            float t = [[value getMetaData:@"t"] floatValue];
            vertex.coord = [value BFPoint3D];
            vertex.coord.z += ([line vFromU:t] - 0.5) * m_extrude;
            vertex.normal = [m_spline getNormalAt:t];
            vertex.textureCoord = (BFPointUV) {t, [line vFromU:t]};
            
            [result addObject:[BFValue valueWithBFVertex:vertex]];
        }
    }
    else
    {
        BFVertex firstVertex, lastVertex;
        firstVertex.coord = lastVertex.coord = [m_spline getPointAt:first->u];
        firstVertex.coord.z += (first->v - 0.5) * m_extrude;
        lastVertex.coord.z += (last->v - 0.5) * m_extrude;
        firstVertex.normal = lastVertex.normal = [m_spline getNormalAt:first->u];
        firstVertex.textureCoord = *first;
        lastVertex.textureCoord = *last;
        
        [result addObject:[BFValue valueWithBFVertex:firstVertex]];
        [result addObject:[BFValue valueWithBFVertex:lastVertex]];
    }
    
    return result;
}

- (NSArray *) getLineByPoints: (NSArray *) points WithSegments: (int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;

    for (int i = 0; i < [points count] - 1; i++)
    {
//        BFCoordExchanger *exchenger = [[BFCoordExchanger alloc] initWithPoints:[points[i] BFPointUV]
//                                                                           And:[points[i + 1] BFPointUV]];
//        
//        NSMutableArray *segment_result =  [NSMutableArray arrayWithArray: [m_spline getLineFrom:[points[i] BFPointUV].u
//                                                                                             To:[points[i + 1] BFPointUV].u
//                                                                                   WithSegments:count WithBlock:^(BFPoint3D *point, float t) {
//                                                                                        point->z += ([exchenger vfromu:t] - 0.5) * m_extrude;
//                                                                                   }]];
        BFPointUV firstPoint = [points[i] BFPointUV];
        BFPointUV secondPoint = [points[i + 1] BFPointUV];
        if (fabs(firstPoint.u - secondPoint.u) >= MIN_DELTA_T)
        {
            NSArray *segment_result =  [m_spline getLineFrom:firstPoint.u
                                                          To:secondPoint.u WithSegments:count];
        
            BFLine *segment_line = [[BFLine alloc] initWithPointsUV:firstPoint :secondPoint];
        
            for (int j = 0; j < [segment_result count]; j++)
            {
                if (i > 0 && j == 0)  // Это чтобы не было дублирования точек - конча и начала сегментов
                    continue;
                
                BFValue *value = [segment_result objectAtIndex:j];

                BFVertex vertex;
                float t = [[value getMetaData:@"t"] floatValue];
                vertex.coord = [value BFPoint3D];
                vertex.coord.z += ([segment_line vFromU:t] - 0.5) * m_extrude;
                vertex.normal = [m_spline getNormalAt:t];
                vertex.textureCoord = (BFPointUV) {t, [segment_line vFromU:t]};
            
                [result addObject:[BFValue valueWithBFVertex:vertex]];
            }
        }
        else
        {
            BFVertex fistVertex, secondVertex;
            fistVertex.coord = secondVertex.coord = [m_spline getPointAt:firstPoint.u];
            fistVertex.coord.z += (firstPoint.v - 0.5) * m_extrude;
            secondVertex.coord.z += (secondPoint.v - 0.5) * m_extrude;
            fistVertex.normal = secondVertex.normal = [m_spline getNormalAt:firstPoint.u];
            fistVertex.textureCoord = secondVertex.textureCoord = firstPoint;
            
            if (i == 0)
                [result addObject:[BFValue valueWithBFVertex:fistVertex]];
            
            [result addObject:[BFValue valueWithBFVertex:secondVertex]];
        }
    }

    return result;
}

- (NSArray *) getLineByPoints: (NSArray *) points WithMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    for (int i = 0; i < [points count] - 1; i++)
    {
        BFPointUV firstPoint = [points[i] BFPointUV];
        BFPointUV secondPoint = [points[i + 1] BFPointUV];
        if (fabsf(firstPoint.u - secondPoint.u) >= MIN_DELTA_T)
        {
            NSArray *segment_result = [m_spline getLineFrom:firstPoint.u
                                                         To:secondPoint.u WithMinAngle:angle];
            
            BFLine *segment_line = [[BFLine alloc] initWithPointsUV:firstPoint :secondPoint];
            
            for (int j = 0; j < [segment_result count]; j++)
            {
                if (i > 0 && j == 0)  // Это чтобы не было дублирования точек - конча и начала сегментов
                    continue;
                
                BFValue *value = [segment_result objectAtIndex:j];
                
                BFVertex vertex;
                float t = [[value getMetaData:@"t"] floatValue];
                vertex.coord = [value BFPoint3D];
                vertex.coord.z += ([segment_line vFromU:t] - 0.5) * m_extrude;
                vertex.normal = [m_spline getNormalAt:t];
                vertex.textureCoord = (BFPointUV) {t, [segment_line vFromU:t]};
                
                [result addObject:[BFValue valueWithBFVertex:vertex]];
            }
        }
        else
        {
            BFVertex fistVertex, secondVertex;
            fistVertex.coord = secondVertex.coord = [m_spline getPointAt:firstPoint.u];
            fistVertex.coord.z += (firstPoint.v - 0.5) * m_extrude;
            secondVertex.coord.z += (secondPoint.v - 0.5) * m_extrude;
            fistVertex.normal = secondVertex.normal = [m_spline getNormalAt:firstPoint.u];
            fistVertex.textureCoord = secondVertex.textureCoord = firstPoint;
            
            if (i == 0)
                [result addObject:[BFValue valueWithBFVertex:fistVertex]];
            
            [result addObject:[BFValue valueWithBFVertex:secondVertex]];
        }
    }
    
    return result;
}

- (NSArray *) getSurfaceByPoints: (NSArray *) points WithSegments: (int) count
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    
    /*
    NSMutableArray *outlinePoints = [NSMutableArray array];
    [outlinePoints addObjectsFromArray:[self getLineByPoints:points WithSegments:count]];  // NSArray<BFvertex>
    [outlinePoints removeLastObject];
    
    [outlinePoints addObjectsFromArray:[self getLineByPoints:[NSArray arrayWithObjects:[points lastObject], [points firstObject], nil] WithSegments:count]];
    [outlinePoints removeLastObject];
    
    NSArray *triangles = BFTriangulate([outlinePoints objectEnumerator]);  // Допусть тут возвращается массив треугольников
    
    for (int i = 0; i < [triangles count]; i = i + 3)
    {
        NSArray *triangle = [NSArray arrayWithObjects:[triangles objectAtIndex:i    ],
                                                      [triangles objectAtIndex:i + 1],
                                                      [triangles objectAtIndex:i + 2], nil];
        
        [result addObjectsFromArray:[self getSurfaceByPoints:triangle WithSegments:count]];
    }*/
    
    return result;
}

- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    NSMutableArray *loop_points = [NSMutableArray arrayWithArray:points];
    [loop_points addObject:[points firstObject]];
    
    NSMutableArray *outlinePoints = [NSMutableArray arrayWithArray:[self getLineByPoints:loop_points WithMinAngle:angle]];  // NSArray<BFvertex>
    [outlinePoints removeLastObject];
    
    NSArray *triangles = BFTriangulateWithGetPointUVFunc(outlinePoints, ^BFPointUV(id value, BOOL *isOK) {
                                                                             *isOK = YES;
                                                                             return [value BFVertexRef]->textureCoord;
                                                                         });  // Тут возвращается массив точек по три (треугольников)
    
    if ([outlinePoints count] <= 6)  // Функция getLineByPoints для треугольника вернет минимум 6 точек!
        return outlinePoints;
    
    for (int i = 0; i < [triangles count]; i = i + 3)
    {
        NSMutableArray *pointsUV = [NSMutableArray array];
        [pointsUV addObject:[NSValue valueWithBFPointUV:[triangles[i    ] BFVertexRef]->textureCoord]];
        [pointsUV addObject:[NSValue valueWithBFPointUV:[triangles[i + 1] BFVertexRef]->textureCoord]];
        [pointsUV addObject:[NSValue valueWithBFPointUV:[triangles[i + 2] BFVertexRef]->textureCoord]];
        
        [result addObjectsFromArray:[self getSurfaceByPoints:pointsUV WithMinAngle:angle]];
    }
    
    return result;
}

/*
- (NSArray *) getSurfaceByPoints: (NSArray *) points WithMinAngle: (float) angle
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (!result)
        return result;
    
    NSMutableArray *loop_points = [NSMutableArray arrayWithArray:points];
    [loop_points addObject:[points firstObject]];
    
    NSArray *outlinePoints = [self getLineByPoints:loop_points WithMinAngle:angle];  // NSArray<BFvertex>
    if ([outlinePoints count] <= 6)  // Функция getLineByPoints никогда не вернет 3 точки!
        return outlinePoints;
    
    NSArray *outlineIndices = BFTriangulate([outlinePoints objectEnumerator]);  // Допусть тут возвращается массив индексов
    
    for (int i = 0; i < [outlineIndices count] - 1; i = i + 3)  // count - 1 - потому что первая и последняя точка совпадают и их не исключить
    {
        NSMutableArray *pointsUV = [NSMutableArray array];
        int indices[3] = {[[outlineIndices objectAtIndex:i    ] intValue],
                          [[outlineIndices objectAtIndex:i + 1] intValue],
                          [[outlineIndices objectAtIndex:i + 2] intValue]};
        
        BFVertexRef pointsRef[3] = {[[outlinePoints objectAtIndex:indices[0]] BFVertexRef],
                                    [[outlinePoints objectAtIndex:indices[1]] BFVertexRef],
                                    [[outlinePoints objectAtIndex:indices[2]] BFVertexRef]};
        
        [pointsUV addObject:[NSValue valueWithBFPointUV:pointsRef[0]->textureCoord]];
        [pointsUV addObject:[NSValue valueWithBFPointUV:pointsRef[1]->textureCoord]];
        [pointsUV addObject:[NSValue valueWithBFPointUV:pointsRef[2]->textureCoord]];
        
        [result addObjectsFromArray:[self getSurfaceByPoints:pointsUV WithMinAngle:angle]];
    }
    
    return result;
}
*/

- (NSArray *) getWholeSurface:(NSMutableArray *)indices WithSegments:(int)count
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *splinePoints = [m_spline getLineFrom:0.0 To:1.0 WithSegments:count];
    
    for (int i = 0; i < 2 * [splinePoints count] - 2; i++)
    {
        [indices addObject:[NSNumber numberWithInt:i    ]];
        [indices addObject:[NSNumber numberWithInt:i + 1]];
        [indices addObject:[NSNumber numberWithInt:i + 2]];
    }
    
    for (BFValue *point in splinePoints)
    {
        float t = [[point getMetaData:@"t"] floatValue];
        BFPoint3D point3D = [point BFPoint3D];
        
        BFVertex farPoint, nearPoint;
        farPoint.coord = nearPoint.coord = point3D;
        farPoint.coord.z -= 0.5 * m_extrude;
        nearPoint.coord.z += 0.5 * m_extrude;
        
        farPoint.textureCoord = (BFPointUV) {t, 1.0};
        nearPoint.textureCoord = (BFPointUV) {t, 0.0};
        
        farPoint.normal = nearPoint.normal = [m_spline getNormalAt:t];
        
        [result addObject:[NSValue valueWithBFVertex:nearPoint]];
        [result addObject:[NSValue valueWithBFVertex:farPoint]];
        
        //        if (!indices)
        //        TODO: Для этого нужно обрабатывать сразу 2 точки
    }
    
    return result;
}

- (NSArray *) getWholeSurface:(NSMutableArray *)indices WithMinAngle:(float)angle;
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *splinePoints = [m_spline getLineFrom:0.0 To:1.0 WithMinAngle:angle];
    
    for (int i = 0; i < 2 * [splinePoints count] - 2; i++)
    {
        [indices addObject:[NSNumber numberWithInt:i    ]];
        [indices addObject:[NSNumber numberWithInt:i + 1]];
        [indices addObject:[NSNumber numberWithInt:i + 2]];
    }
    
    for (BFValue *point in splinePoints)
    {
        float t = [[point getMetaData:@"t"] floatValue];
        BFPoint3D point3D = [point BFPoint3D];
        
        BFVertex farPoint, nearPoint;
        farPoint.coord = nearPoint.coord = point3D;
        farPoint.coord.z -= 0.5 * m_extrude;
        nearPoint.coord.z += 0.5 * m_extrude;
        
        farPoint.textureCoord = (BFPointUV) {t, 1.0};
        nearPoint.textureCoord = (BFPointUV) {t, 0.0};
        
        farPoint.normal = nearPoint.normal = [m_spline getNormalAt:t];
        
        [result addObject:[NSValue valueWithBFVertex:nearPoint]];
        [result addObject:[NSValue valueWithBFVertex:farPoint]];
        
//        if (!indices)
//        TODO: Для этого нужно обрабатывать сразу 2 точки
    }
    
    return result;
}

@synthesize spline = m_spline;

@end


@implementation BFDefaultMesh

-(id)initWithData:(NSArray *)data GLPrimitive:(GLuint)primitive Matrix:(GLKMatrix4)matrix
{
    if (primitive == GL_POINTS)
        return [self initWithData:data Indices:[NSArray array] GLPrimitive:primitive Matrix:matrix];  // TODO: Нужно подумать, как обрабатывать пустой массив индексов

    NSMutableArray *indices = [NSMutableArray array];
    NSMutableArray *dictionary = [NSMutableArray array];

    int index = 0;
    for (BFValue *point in data)
    {
        NSUInteger number;
        if ((number = [dictionary indexOfObjectIdenticalTo:point]) == NSNotFound)
        {
            [dictionary addObject:point];
            [indices addObject:[NSNumber numberWithInt:index]];

            index++;
        }
        else
            [indices addObject:[NSNumber numberWithUnsignedInt:number]];
    }

    return [self initWithData:dictionary Indices:indices GLPrimitive:primitive Matrix:matrix];
}

-(id)initWithData:(NSArray *)data Indices:(NSArray *)indices GLPrimitive:(GLuint)primitive Matrix:(GLKMatrix4)matrix
{
    self = [super init];
    if (self)
    {
        m_dataCount = [data count];
        m_indicesCount = [indices count];
        m_data = (BFVertex *)malloc(m_dataCount * sizeof(BFVertex));
        m_indices = (GLuint *)malloc(m_indicesCount * sizeof(GLuint));

        for (int i = 0; i < m_dataCount; i++)
            m_data[i] = [[data objectAtIndex:i] BFVertex];

        for (int i = 0; i < m_indicesCount; i++)
            m_indices[i] = [[indices objectAtIndex:i] intValue];

        m_primitive = primitive;
        m_modelMatrix = matrix;
    }

    return self;
}

-(void)dealloc
{
    if (m_data)
        free(m_data);

    if (m_indices)
        free(m_indices);
}

@synthesize m_data, m_indices, m_dataCount, m_indicesCount, m_primitive, m_modelMatrix;

@end  // BFDefaultMesh
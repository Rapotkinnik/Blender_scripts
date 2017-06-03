//
//  SNFCircularList.m
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//
//

#import "BFUtils.h"

@implementation BFListElem

-(instancetype)initWithValue:(id)value
{
    self = [super init];
    if (self)
    {
        [self setPrev:nil];
        [self setNext:nil];
        [self setValue:value];
    }
    
    return self;
}

+(instancetype)listElemWithValue:(id)value
{
    return [[[self class] alloc] initWithValue:value];
}

- (void) dealloc
{
    [self setPrev:nil];
    [self setNext:nil];
    [self setValue:nil];
}

-(id)copyWithZone:(NSZone *)zone
{
    BFListElem *newElem = [[[self class] allocWithZone: zone] init];
    if (newElem)
    {
        [newElem setPrev:m_prev];
        [newElem setNext:m_next];
        [newElem setValue:m_value];
    }
                            
    return  newElem;
}

-(BOOL)isEqual:(id)object
{
    return (m_next == [object getNext] &&
            m_prev == [object getPrev] && [m_value isEqual:[object getValue]]);
}

@synthesize next = m_next, prev = m_prev, value = m_value;

@end //BFListElem


@implementation BFCircularListEnumerator

-(id)initWithCircularList:(BFCircularList *)aList
{
    self = [super init];
    
    if (self)
    {
        m_list = aList;
        m_isEnumerationAtFirstElem = YES;
        
        [m_list goBOList];
    }
    
    return self;
}

-(id)nextObject
{
    if (m_list)
    {
        if (m_isEnumerationAtFirstElem)
        {
            m_isEnumerationAtFirstElem = NO;
            return [[m_list getCur] getValue];
        }
        
        [m_list goNext];
        
        if ([m_list isBOList])
            return nil;
        
        return [[m_list getCur] getValue];
    }
    else
        return nil;
}

@synthesize list = m_list;

@end //BFCircularListEnumerator


@implementation BFCircularList

-(instancetype)init
{
    return [self initWithArray:nil];
}

-(instancetype)initWithArray:(NSArray *)array
{
    self = [super init];
    if (self)
    {
        m_first = nil;
        m_cur = nil;
        m_size = 0;
    }
    
    if (array)
        [self appendValuesFrom:array withDirection:Forward];
    
    return self;
}

+(instancetype)circularList
{
    return [[[self class] alloc] init];
}

+(instancetype)circularListWithArray:(NSArray *)array
{
    return [[[self class] alloc] initWithArray:array];
}

// NSCoding protocol implementation
-(id)initWithCoder:(NSCoder *)coder
{
    if (self = [self init])
    {
        
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    for (id value in self)
        [value encodeWithCoder: aCoder];
}

-(void)dealloc {
    [self clear];
}

// NSCopying protocol implementation
-(id)copyWithZone:(NSZone *)zone
{
    BFCircularList *newList = [[[self class] allocWithZone:zone] init];
    
    if (newList)
        for (id value in self)
            [newList appendValue:value];
    
    return newList;
}

-(BOOL)isEmty
{
    return (m_cur == nil) && (m_first == nil) && (m_size == 0);
}

-(BOOL)isBOList
{
    return ![self isEmty] && m_cur == m_first;
}

-(BOOL)isEOList
{
    return ![self isEmty] && m_cur == [m_first getPrev];
}

-(void)clear
{
    while (![self isEmty])
        [self removeCur];
}

-(void)goBOList
{
    if (![self isEmty])
        m_cur = m_first;
}

-(void)goEOList
{
    if (![self isEmty])
        m_cur = [m_first getPrev];
}

-(void)goNext
{
    m_cur = [m_cur getNext];
}

-(void)goPrev
{
    m_cur = [m_cur getPrev];
}

-(BOOL)goAtItem:(BFListElem *)item
{
    if (item)
    {
        [self goBOList];
        do
        {
            if ([self getCur] == item)
                return YES;
        
            [self goNext];
        
        } while (![self isBOList]);
    }
    
    return NO;
}

-(BOOL)goAtItemWithValue:(id)value
{
    [self goBOList];
    do
    {
        if ([[[self getCur] getValue] isEqual: value])
            return YES;
        
        [self goNext];
        
    } while (![self isBOList]);
    
    return NO;
}

-(BOOL)isContainValue:(id)value
{
    for (id elem in self)
        if ([[[elem getCur] getValue] isEqual: value])
            return YES;
    
    return NO;
}

-(void)removeCur
{
    if (![self isEmty])
    {
        BFListElem *elem = m_cur;
        
        if (m_size == 1)
        {
            m_cur = nil;
            m_first = nil;
        }
        else
        {
            [[m_cur getPrev] setNext:[m_cur getNext]];
            [[m_cur getNext] setPrev:[m_cur getPrev]];
            m_cur = [m_cur getNext];
            
            if (m_first == elem)
                m_first = m_cur;
        }

        m_size--;
    }
}

-(void)appendValue:(id)value
{
    // Это не написанно так: [self goEOList]; [self insertValueAfterCurrent:value];
    // Потому что добавление элемента в конец не должно менять положение положение текущего элемента
    BFListElem *elem = [BFListElem listElemWithValue:value];
    if ([self isEmty])
    {
        m_first = elem;
        [m_first setNext:elem];
        [m_first setPrev:elem];
        m_cur = m_first;
    }
    else
    {
        [elem setNext:m_first];
        [elem setPrev:[m_first getPrev]];
        [[m_first getPrev] setNext:elem];
        [m_first setPrev:elem];
    }
    
    m_size++;
}

-(void)appendValuesFrom:(NSArray *)array withDirection:(Direction)direction
{
    NSEnumerator *enumerator = (direction == Forward)?[array objectEnumerator]:[array reverseObjectEnumerator];
    
    id object;
    while (object = [enumerator nextObject])
        [self appendValue:object];
}

-(void)insertValueAfterCurrent:(id)value
{
    BFListElem *elem = [BFListElem listElemWithValue:value];
    
    if ([self isEmty])
    {
        m_first = elem;
        [m_first setNext:elem];
        [m_first setPrev:elem];
        m_cur = m_first;
    }
    else
    {
        [[m_cur getNext] setPrev:elem];
        [elem setNext:[m_cur getNext]];
        [elem setPrev:m_cur];
        [m_cur setNext:elem];
    }
    
    m_size++;
}

-(BFCircularListEnumerator *)getEnumerator
{
    return [[BFCircularListEnumerator alloc] initWithCircularList: self];
}

//Implementation of NSFustEnumeration protocol
//- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)len
//{
//    if (state->state == 0)
//    {
//        [self goBOList];
//        
//        state->mutationsPtr = (unsigned long *)self;
//        state->state = 1;
//        
//        if ([self getSize] == 0)
//            return 0;
//        
//        id obj = [self getCurValue];
//        state->itemsPtr = &obj;
//        
//        [self goNext];
//        
//        return 1;
//    }
//    
//    if ([self isBOList])
//        return 0;
//    
//    id obj = [self getCurValue];
//    state->itemsPtr = &obj;
//    
//    [self goNext];
//
//    return 1;
//}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)buffer count:(NSUInteger)len
{
    if (state->state == 0)
    {
        state->mutationsPtr = (unsigned long *)(__bridge void *)self;
        state->state = 1;
        state->extra[0] = (unsigned long)[m_first getNext];
        
        if ([self getSize] == 0)
            return 0;
        
        id __unsafe_unretained obj = [m_first getValue];
        state->itemsPtr = &obj;
        
        return 1;
    }
    
    BFListElem *elem = (__bridge BFListElem *)(void *)state->extra[0];
    if (elem == m_first)
        return 0;
    
    id __unsafe_unretained obj = [elem getValue];
    state->itemsPtr = &obj;
    
    state->extra[0] = (unsigned long)[elem getNext];
    
    return 1;
}

@synthesize size = m_size, cur = m_cur, first = m_first;

@end //BFCircularList


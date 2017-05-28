//
//  SNFCircularList.h
//  Snoflackes
//
//  Created by Рапоткин Никалай on 11.09.14.
//
//

#import <Foundation/Foundation.h>

@interface BFListElem : NSObject <NSCopying>
{
    id m_value;
    BFListElem *m_next;
    BFListElem *m_prev;
}

-(instancetype)initWithValue:(id)value;
+(instancetype)listElemWithValue:(id)value;

@property (nonatomic, strong, getter = getNext) BFListElem *next;
@property (nonatomic, strong, getter = getPrev) BFListElem *prev;
@property (nonatomic, strong, getter = getValue) id value;

@end //BFListElem

typedef enum
{
    Forward = 0,
    Reverse
} Direction;

@interface BFCircularListEnumerator : NSEnumerator
{
@private SNFCircularList *m_list;
@private BOOL m_isEnumerationAtFirstElem;
}

-(id)initWithCircularList:(BFCircularList *)aList;
-(id)nextObject;

@property (readonly, getter = allObjects) BFCircularList *list;

@end //BFCircularListEnumerator

@interface BFCircularList : NSObject <NSCopying, NSCoding, NSFastEnumeration>
{
    int m_size;
    BFListElem *m_cur;
    BFListElem *m_first;
}

-(instancetype)init;
-(instancetype)initWithArray:(NSArray *)array;
+(instancetype)circularList;
+(instancetype)circularListWithArray:(NSArray *)array;

-(BOOL)isEmty;
-(BOOL)isEOList;
-(BOOL)isBOList;

-(void)clear;
-(void)goBOList;
-(void)goEOList;
-(void)goNext;
-(void)goPrev;
-(BOOL)goAtItem:(BFListElem *)item;
-(BOOL)goAtItemWithValue:(id)value;
-(BOOL)isContainValue:(id)value;

-(void)removeCur;
-(void)appendValue:(id)value;
-(void)appendValuesFrom:(NSArray *)array withDirection:(Direction)direction;
-(void)insertValueAfterCurrent:(id)value;

-(BFCircularListEnumerator *)getEnumerator;

@property (readonly, getter = getCur) BFListElem *cur;
@property (readonly, getter = getFirst) BFListElem *first;
@property (readonly, getter = getSize) int size;

@end //BFCircularList



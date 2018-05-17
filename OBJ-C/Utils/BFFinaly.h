//
//  BFFinaly.h
//  TestProject
//
//  Created by Рапоткин Николай on 03.05.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^FinalyFunctor)();

@interface BFFinaly : NSObject
{
    FinalyFunctor m_functor;
}

-(id)initWithFunctor:(FinalyFunctor)functor;
+(instancetype)finalyWithFunctor:(FinalyFunctor)functor;

@end

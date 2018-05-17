//
//  BFFinaly.m
//  TestProject
//
//  Created by Рапоткин Николай on 03.05.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import "BFFinaly.h"

@implementation BFFinaly

-(id)initWithFunctor:(FinalyFunctor)functor
{
    self = [super init];
    if (self)
        m_functor = functor;
    
    return self;
}

+(instancetype)finalyWithFunctor:(FinalyFunctor)functor
{
    return [[[self class] alloc] initWithFunctor:functor];
}

-(void)dealloc
{
    m_functor();
}

@end

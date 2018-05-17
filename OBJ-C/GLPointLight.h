//
//  GLPointLight.h
//  TestProject
//
//  Created by Рапоткин Николай on 05.02.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import "Math.h"
#import "GLProgram.h"

@interface BFGLPointLight : NSObject <BFGLDrawable>
{
    int m_lightID;
    BOOL m_isLightOn;
	float m_lightEnergy;
    GLKVector3 m_position;
    GLKVector3 m_ambientColor;
    GLKVector3 m_diffuseColor;
    GLKVector3 m_specularColor;
    GLKVector3 m_lightAttenuation;
}

-(instancetype)pointLightWithPosition:(GLKVector3)position
                              Ambient:(GLKVector3)ambient
                              Diffuse:(GLKVector3)diffuse
                             Specular:(GLKVector3)specular
                          Attenuation:(GLKVector3)attenuation;

@property (nonatomic, assign) int lightID;
@property (nonatomic, assign) BOOL isLightOn;
@property (nonatomic, assign) float lightEnergy;
@property (nonatomic, assign) GLKVector3 position;
@property (nonatomic, assign) GLKVector3 ambientColor;
@property (nonatomic, assign) GLKVector3 diffuseColor;
@property (nonatomic, assign) GLKVector3 specularColor;
@property (nonatomic, assign) GLKVector3 lightAttenuation;

@end

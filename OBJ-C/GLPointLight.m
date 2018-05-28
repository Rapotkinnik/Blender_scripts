//
//  GLPointLight.m
//  TestProject
//
//  Created by Рапоткин Николай on 05.02.18.
//  Copyright (c) 2018 Rapotkin. All rights reserved.
//

#import "GLPointLight.h"

@implementation BFGLPointLight

static int ObjectCount = 0;

-(id)init
{
	self = [super init];
	if (self)
	{
        m_lightID = ObjectCount++;
        m_isLightOn = YES;
		m_lightEnergy = 1.0;
	}
    
	return self;
}

-(instancetype)pointLightWithPosition:(GLKVector3)position
                              Ambient:(GLKVector3)ambient
                              Diffuse:(GLKVector3)diffuse
                             Specular:(GLKVector3)specular
                          Attenuation:(GLKVector3)attenuation
{
    BFGLPointLight *light = [[[self class] alloc] init];
    [light setPosition:position];
    [light setAmbientColor:ambient];
    [light setDiffuseColor:diffuse];
    [light setSpecularColor:specular];
    [light setLightAttenuation:attenuation];
    
    return light;
}

-(void)dealloc
{
}

-(void)beforeDraw:(BFGLProgram *)program
{
    @try
    {
        GLint isOn        = [program uniform:[NSString stringWithFormat:@"pointLights[%d].isOn",          m_lightID]];
        GLint position    = [program uniform:[NSString stringWithFormat:@"pointLights[%d].position",      m_lightID]];
        GLint ambient     = [program uniform:[NSString stringWithFormat:@"pointLights[%d].ambientColor",  m_lightID]];
        GLint diffuse     = [program uniform:[NSString stringWithFormat:@"pointLights[%d].diffuseColor",  m_lightID]];
        GLint specular    = [program uniform:[NSString stringWithFormat:@"pointLights[%d].specularColor", m_lightID]];
        GLint attenuation = [program uniform:[NSString stringWithFormat:@"pointLights[%d].attenuation",   m_lightID]];

        glUniform1i(isOn, m_isLightOn ? 1 : 0);
        glUniform3fv(position,    1, m_position.v);
        glUniform3fv(ambient,     1, m_ambientColor.v);
        glUniform3fv(diffuse,     1, m_diffuseColor.v);
        glUniform3fv(specular,    1, m_specularColor.v);
        glUniform3fv(attenuation, 1, m_lightAttenuation.v);
    }
    @catch(NSException *){}
}

-(void)afterDraw:(BFGLProgram *)program
{
//    @try
//    {
//        GLint isOn = [program uniform:[NSString stringWithFormat:@"pointLights[%d].isOn", m_lightID]];
//        glUniform1i(isOn, 0);
//    }
//    @catch(NSException *){}
}

-(void)draw:(BFGLProgram *)program
{
}

@synthesize lightID = m_lightID,
            isLightOn = m_isLightOn,
            lightEnergy = m_lightEnergy,
            position = m_position,
            ambientColor = m_ambientColor,
            diffuseColor = m_diffuseColor,
            specularColor = m_specularColor,
            lightAttenuation = m_lightAttenuation;
@end

#ifndef CURVE_H
#define CURVE_H

#include "mathutils.h"

class Curve
{
    void getCurveRecursive(float t_start, float t_end,
                           float max_angle, Blender::Vector3D &buff);
public:
    Curve();

    Blender::Point3D getCurvePoint(float t);
    Blender::Vector3D getCurve(float t_start, float t_end, float max_angle);
};

#endif // CURVE_H

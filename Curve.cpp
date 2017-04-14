#include "Curve.h"

Curve::Curve()
{

}

Blender::Vector3D Curve::getCurve(float t_start, float t_end, float max_angle)
{
    Blender::Vector3D result;
    t_start = std::min(t_start, t_end);
    t_end   = std::max(t_start, t_end);
    getCurveRecursive(std::min(t_start, 0.5), , max_angle, result);
    getCurveRecursive(std::min(t_start, 0.5), , max_angle, result);

    return result;
}


#ifndef MATHUTILS
#define MATHUTILS

namespace Blender
{
    struct Point3D
    {
        float x, y, z;
    };

    struct PointUV
    {
        float u, v;
    };

    using Vector3D = std::vector<Point3D>;

} // Blender

#endif // MATHUTILS


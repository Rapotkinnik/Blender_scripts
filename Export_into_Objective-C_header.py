bl_info = {
    'name': 'Objective-C header',
    'author': 'Nikolay Rapotkin',
    'version': (0, 0, 4),
    'blender': (2, 74, 0),
    'location': 'File > Export',
    'description': 'Export meshes into Objective-C header for OpenGL ES drawing',
    'warning': '',
    'wiki_url': '',
    'tracker_url': '',
    'support': 'COMMUNITY',
    'category': 'Import-Export'}
    
import os
import bpy
import math
import shutil
import mathutils
import bpy_extras.io_utils

from bpy.props           import BoolProperty, FloatProperty, StringProperty, EnumProperty
from progress_report     import ProgressReport, ProgressReportSubstep
from bpy_extras.io_utils import ExportHelper, orientation_helper_factory, path_reference_mode, axis_conversion

IOOBJOrientationHelper = orientation_helper_factory("IOOBJOrientationHelper", axis_forward='-Z', axis_up='Y')


def matrix_to_string(matrix, str_prefix, with_first=True):
    matrix_str = ''
    for vector in matrix:
        matrix_str += str_prefix + ', '.join(('%.6f' % co for co in vector)) + ',\n'

    return matrix_str[:-2] if with_first else matrix_str[len(str_prefix):-2]


def struct_to_string(struct, str_prefix):
    matrix_str = ''
    for sub in struct:
        try:
            matrix_str += str_prefix + '{' + ', '.join(('%.6f' % co for co in sub)) + '},\n'
        except TypeError:
            matrix_str += str_prefix + '%.6f' % sub + ',\n'

    return matrix_str[:-2]


def class_name(name):
    if name is None:
        return 'None'
    else:
        c_name = name.replace(' ', '').replace('.', '')
        return 'BF' + c_name[0].upper() + c_name[1:]


def member_name(name):
    if name is None:
        return 'None'
    else:
        m_name = name.replace(' ', '').replace('.', '')
        return m_name[0].lower() + m_name[1:]


def mesh_triangulate(mesh):
    import bmesh
    bm = bmesh.new()

    bm.from_mesh(mesh)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()


def bezier_interpolation(points):
    bezier_points = []
    for p_index in range(len(points) - 1):
        if points[p_index] != points[p_index + 1]:
            break
    else:
        return bezier_points  # if all points are equal return empty list

    if len(points) == 2:
        bezier_points.append(points[0])
        bezier_points.append((2 * points[0] + points[1]) / 3)
        bezier_points.append(2 * bezier_points[-1] - points[0])
        bezier_points.append(points[1])
        return bezier_points

    '''
    right_side_handles = [points[0] + 2 * points[1]]
    for p_index in range(1, len(points) - 2):
        right_side_handles.append(4 * points[p_index] + 2 * points[p_index + 1])
    right_side_handles.append(4 * points[-2] + points[-1] / 2) # or 8 * points[-2] + points[-1] wtf?
    '''

    tmp_c = [2]
    tmp_f = [points[0] + 2 * points[1]]
    for p_index in range(1, len(points) - 1):
        tmp_f.append(4 * points[p_index] - 2 * points[p_index + 1] - tmp_f[-1] / tmp_c[-1])
        tmp_c.append(4 - 1 / tmp_c[-1])
    tmp_f.append(8 * points[-2] + points[-1] - 2 * tmp_f[-1] / tmp_c[-1])
    tmp_c.append(7 - 2 / tmp_c[-1])

    first_control_points = [tmp_f[-1] / tmp_c[-1]]
    for p_index in range(len(points) - 1, 0, -1):
        first_control_points.insert(0, (tmp_f[p_index] - first_control_points[0]) / tmp_c[p_index])

    for p_index in range(len(points) - 1):
        bezier_points.append(points[p_index])  # P0
        bezier_points.append(first_control_points[p_index])  # P1
        bezier_points.append(2 * points[p_index + 1] - first_control_points[p_index + 1])  # P2

    bezier_points[-1] = 0.5 * (points[-1] + bezier_points[-2])  # P2 for last segment
    bezier_points.append(points[-1])
    return bezier_points


def bezier_points_for_bezier_spline(spline):
    bezier_points = []
    points = list(spline.bezier_points)
    if spline.use_cyclic_u:
        points.append(spline.bezier_points[0])

    for i in range(len(points) - 1):
        bezier_points.append(points[i].co)
        bezier_points.append(points[i].handle_right)
        bezier_points.append(points[i + 1].handle_left)
    else:
        bezier_points.append(points[-1].co)  # has been i

    return bezier_points


def bezier_points_for_NURB_spline(spline):
    bezier_points = []
    points = list(spline.points)
    if spline.use_cyclic_u:
        points.append(spline.points[0])

    if spline.order_u == 2:
        bezier_points.extend(points)
        return bezier_points

    knots = [0]
    for i, point in enumerate(points):
        knots.append(knots[i] + point.weight)

    if spline.order_u == 3:
        for i in range(len(points) - spline.order_u + 1):
            v = ((knots[i + 3] - knots[i + 2]) * points[i].co[:] +
                 (knots[i + 2] - knots[i + 1]) * points[i + 1].co[:]) / (knots[i + 3] - knots[i + 1])

            bezier_points.append(v)
            bezier_points.append(points[i + 1].co)

    if spline.order_u == 4:
        c = ((knots[5] - knots[4]) * points[0].co[:] +
             (knots[4] - knots[2]) * points[1].co[:]) / (knots[5] - knots[2])

        bezier_points.append(c)

        for i in range(len(points) - spline.order_u + 1):
            b = ((knots[i + 5] - knots[i + 3]) * points[i + 1].co[:] +
                 (knots[i + 3] - knots[i + 2]) * points[i + 2].co[:]) / (knots[i + 5] - knots[i + 2])
            c = ((knots[i + 5] - knots[i + 4]) * points[i + 1].co[:] +
                 (knots[i + 4] - knots[i + 2]) * points[i + 2].co[:]) / (knots[i + 5] - knots[i + 2])
            v = ((knots[i + 4] - knots[i + 3]) * bezier_points[-1][:] +
                 (knots[i + 3] - knots[i + 2]) * b[:]) / (knots[i + 4] - knots[i + 2])

            bezier_points.append(v)
            bezier_points.append(b)
            bezier_points.append(c)

        bezier_points = bezier_points[1:-2]  # Или придется делать цикл на 1 итерацию меньше и добавять в конце vL

    if spline.order_u == 5:
        d = ((knots[6] - knots[5]) * ((knots[6] - knots[5]) * points[0].co[:] +
                                      (knots[5] - knots[2]) * points[1].co[:]) / (knots[6] - knots[2]) +
             (knots[5] - knots[3]) * ((knots[7] - knots[5]) * points[1].co[:] +
                                      (knots[5] - knots[3]) * points[2].co[:]) / (knots[7] - knots[3])) / (
                knots[6] - knots[3])
        bezier_points.append(d)

        for i in range(len(points) - spline.order_u + 1):
            b = ((knots[i + 6] - knots[i + 4]) * ((knots[i + 6] - knots[i + 4]) * points[i + 1].co[:] +
                                                  (knots[i + 6] - knots[i + 2]) * points[i + 2].co[:]) / (
                     knots[i + 6] - knots[i + 2]) +
                 (knots[i + 4] - knots[i + 3]) * ((knots[i + 7] - knots[i + 4]) * points[i + 2].co[:] +
                                                  (knots[i + 4] - knots[i + 3]) * points[i + 3].co[:]) / (
                     knots[i + 7] - knots[i + 3])) / (knots[i + 6] - knots[i + 3])
            c = ((knots[i + 6] - knots[i + 5]) * ((knots[i + 6] - knots[i + 4]) * points[i + 1].co[:] +
                                                  (knots[i + 6] - knots[i + 2]) * points[i + 2].co[:]) / (
                     knots[i + 6] - knots[i + 2]) +
                 (knots[i + 4] - knots[i + 3]) * ((knots[i + 7] - knots[i + 5]) * points[i + 2].co[:] +
                                                  (knots[i + 5] - knots[i + 3]) * points[i + 3].co[:]) / (
                     knots[i + 7] - knots[i + 3]) + (knots[i + 5] - knots[i + 4]) * points[i + 2].co[:]) / (
                    knots[i + 6] - knots[i + 3])
            d = ((knots[i + 6] - knots[i + 5]) * ((knots[i + 6] - knots[i + 5]) * points[i + 1].co[:] +
                                                  (knots[i + 5] - knots[i + 2]) * points[i + 2].co[:]) / (
                     knots[i + 6] - knots[i + 2]) +
                 (knots[i + 5] - knots[i + 3]) * ((knots[i + 7] - knots[i + 5]) * points[i + 2].co[:] +
                                                  (knots[i + 5] - knots[i + 3]) * points[i + 3].co[:]) / (
                     knots[i + 7] - knots[i + 3])) / (knots[i + 6] - knots[i + 3])
            v = ((knots[i + 5] - knots[i + 4]) * bezier_points[-1][:] +
                 (knots[i + 4] - knots[i + 3]) * b[:]) / (knots[i + 4] - knots[i + 2])

            bezier_points.append(v)
            bezier_points.append(b)
            bezier_points.append(c)
            bezier_points.append(d)

        bezier_points = bezier_points[1:-3]

    return bezier_points


def material_to_struct(material):
    mirror_settings = material.raytrace_mirror
    if mirror_settings.use:
        ambient_color = [col * mirror_settings.reflect_factor for col in material.mirror_color]
    else:
        ambient_color = [col * material.ambient for col in bpy.context.scene.world.ambient_color]

    diffuse_color = [col * material.diffuse_intensity for col in material.diffuse_color]
    specular_color = [col * material.specular_intensity for col in material.specular_color]
    emission_color = [col * material.emit for col in material.diffuse_color]

    ambient_color.append(material.alpha)
    diffuse_color.append(material.alpha)
    specular_color.append(material.specular_alpha)
    emission_color.append(material.alpha)

    # XXX Blender has no color emission, it's using diffuse color instead...
    # emission_color = [col * material.emit for col in material.diffuse_color]
    # emission_color.append(1.0)

    # emission_color = [col * material.volume.emission for col in material.volume.emission_color]

    shininess = (0.4 - material.specular_slope) / 0.0004 if material.specular_shader == 'WARDISO' else (material.specular_hardness - 1) / 0.51

    return ambient_color, diffuse_color, specular_color, emission_color, shininess


def light_to_struct(lamp):
    if lamp.type == 'POINT':
        return ((0.0, 0.0, 0.0),
                bpy.context.scene.world.ambient_color,
                lamp.color,
                lamp.color,
                lamp.energy, # constant_coefficient, - этой хуйни вообще нет
                lamp.linear_attenuation,
                lamp.quadratic_attenuation,
                lamp.energy)

class ExportObjCHeader(bpy.types.Operator, ExportHelper, IOOBJOrientationHelper):

    bl_label   = 'Export Objective-C header'
    bl_idname  = 'export_scene.h'
    bl_options = {'PRESET'}

    filename_ext = ".h"
    filter_glob = StringProperty(
        default="*.h",
        options={'HIDDEN'},
    )

    '''
    materials_export_type = EnumProperty(
            name="Materials export type",
            description="Export materials by",
            items=(('NM', "No Materials", "Dont export materials"),
                   ('FM', "As Separate File", "Export materials in to separate file"),
                   ('CM', "As Color", "Export materials as color in to Objective-C header"),
                   ('MM', "As OpenGL Structure", "Export materials as OpenGL materials in to Objective-C header")),
            default='NM',
            )
    texture_export_type = EnumProperty(
            name="Texture export type",
            description="Export texture by",
            items=(('NT', "No Texture", "Don't export texture"),
                   ('FT', "As Separate File", "Export texture as separate file"),
                   ('CT', "As Binary Array", "Export texture as binary array in to Objective-C header")),
            default='NT',
           )
    animation_export_type = EnumProperty(
            name="Animation",
            description="Write out an Objective-C header for each frame",
            items=(('NA', "No Animation", "Export only current frame"),
                   ('MA', "File for each frame", "Write out an Objective-C header for each frame"),
                   ('SA', "File for all frame", "Write out a one Objective-C header for all frame"),
                   ('IA', "Interpolation", "Calculate interpolation function for each vertex")),
            default='NA',
            )
    '''

    prop_use_selection = BoolProperty(
        name="Selection Only",
        description="Export selected objects only",
        default=False,
    )

    prop_use_global_matrix = BoolProperty(
        name="Use global matrix",
        description="Export object transformed by global matrix",
        default=False,
    )

    # object group
    prop_use_mesh_modifiers = BoolProperty(
        name="Apply Modifiers",
        description="Apply modifiers (preview resolution)",
        default=True,
    )

    '''
    # extra data group
    use_edges = BoolProperty(
            name="Include Edges",
            description="",
            default=True,
            )
    use_smooth_groups = BoolProperty(
            name="Smooth Groups",
            description="Write sharp edges as smooth groups",
            default=False,
            )
    use_smooth_groups_bitflags = BoolProperty(
            name="Bitflag Smooth Groups",
            description="Same as 'Smooth Groups', but generate smooth groups IDs as bitflags "
                        "(produces at most 32 different smooth groups, usually much less)",
            default=False,
            )
    use_normals = BoolProperty(
            name="Write Normals",
            description="Export one normal per vertex and per face, to represent flat faces and sharp edges",
            default=True,
            )
    use_uvs = BoolProperty(
            name="Include UVs",
            description="Write out the active UV coordinates",
            default=True,
            )
    '''

    prop_use_triangles = BoolProperty(
        name="Triangulate Faces",
        description="Convert all faces to triangles",
        default=False,
    )

    prop_use_vertex_groups = BoolProperty(
        name="Polygroups",
        description="",
        default=False,
    )

    '''
    def hide_include_prop(self, context):
        if self.prop_export_object_as_file:
            self.global_scale.options = {}
        else:
            self.global_scale.options = {'HIDDEN'}
    '''

    prop_export_object_as_file = BoolProperty(
        name="Export objects separately",
        description="Export each object to separate file",
        default=False,
        #update=hide_include_prop
    )

    prop_export_curve_as_function = BoolProperty(
        name="Export curve as function",
        description="",
        default=True,
    )

    prop_use_vertex_indices = BoolProperty(
        name="Export vertex indices too",
        description="",
        default=True,
    )

    prop_use_symmetrical_indices_output = BoolProperty(
        name="Export indices as symmetrical square",
        description="Export vertex indices more pretty (as symmetrical square)",
        default=True,
    )

    '''
    class ExportMeshSettings(bpy.types.PropertyGroup):
        export_color   = BoolProperty(name="Vertex color", default=True)
        export_normal  = BoolProperty(name="Vertex normal", default=True)
        export_texture = BoolProperty(name="Texture coordinates", default=True)

    bpy.utils.register_class(ExportMeshSettings)

    prop_export = PointerProperty(
        type=ExportMeshSettings,
        name="Export"
    )
    '''

    prop_export_color = BoolProperty(
        name="Export vertex color",
        description="",
        default=True,
    )

    prop_export_as_color_map = BoolProperty(
        name="Export color as color map",
        description="Each vertex in mesh can be associated with many colors (color per adjacent polygon).\n"\
                    "So it can be impossible to export colors correct for every vertex.\n"\
                    "Unless each vertex associated only with ONE color",
        default=True,
    )

    prop_export_normal = BoolProperty(
        name="Export vertex normal",
        description="",
        default=True,
    )

    prop_export_texture = BoolProperty(
        name="Export texture coordinates",
        description="",
        default=True,
    )

    prop_export_material = BoolProperty(
        name="Export object's materials",
        description="",
        default=True,
    )

    '''
    use_nurbs = BoolProperty(
            name="Write Nurbs",
            description="Write nurbs curves as OBJ nurbs rather than converting to geometry",
            default=False,
            )
    use_vertex_groups = BoolProperty(
            name="Polygroups",
            description="",
            default=False,
            )

    # grouping group
    use_blen_objects = BoolProperty(
            name="Objects as OBJ Objects",
            description="",
            default=True,
            )
    group_by_object = BoolProperty(
            name="Objects as OBJ Groups",
            description="",
            default=False,
            )
    group_by_material = BoolProperty(
            name="Material Groups",
            description="",
            default=False,
            )
    prop_keep_vertex_order = BoolProperty(
        name="Keep Vertex Order",
        description="",
        default=False,
    )
    '''
    global_scale = FloatProperty(
        name="Scale",
        min=0.01, max=1000.0,
        default=1.0,
    )

    prop_export_language = EnumProperty(
        name="Export to language",
        items=[
            ("C++", "C++"),
            ("Java", "Java"),
            ("Swift", "Swift"),
            ("OBJ-C", "Objective-C")
        ],
        default="OBJ-C"
    )

    prop_export_gl_type = EnumProperty(
        name="Export to GL API type",
        items=[
            ("GL4", "OpenGL 4.0"),
            ("GLES2", "OpenGL ES 2.0")
        ],
        default="GLES2"
    )

    path_mode = path_reference_mode

    check_extension = True

    def execute(self, context):
        from mathutils import Matrix                                         
        global_matrix = Matrix.Scale(self.global_scale, 4) * axis_conversion(to_forward=self.axis_forward, to_up=self.axis_up).to_4x4()

        # Exit edit mode before exporting, so current object states are exported properly.
        if bpy.ops.object.mode_set.poll():
            bpy.ops.object.mode_set(mode='OBJECT')

        objects = context.selected_objects if self.prop_use_selection else context.scene.objects
        dir_path, _ = os.path.split(self.filepath)

        sorted_objects = []
        for obj in objects:
            if obj.type in {'MESH', 'CURVE', 'SURFACE', 'ARMATURE', 'LAMP'}:
                for i in range(len(sorted_objects)):
                    if len(obj.name) < len(sorted_objects[i].name):
                        sorted_objects.insert(i, obj)
                        break
                else:
                    sorted_objects.append(obj)

        # for group in bpy.data.groups:
        #     self.export_group(group, dir=dir_path)
        #     for object in group.objects:
        #         sorted_objects.remove(object)

        for obj in sorted_objects:
            if obj.type == 'LAMP':
                self.export_light(context.scene, obj.data, dir=dir_path, name=obj.name, location=obj.location)
                continue

            try:
                mesh = obj.to_mesh(context.scene, self.prop_use_mesh_modifiers, 'PREVIEW', calc_tessface=False)
                self.export_mesh(mesh, dir=dir_path, name=obj.name, material=obj.active_material)
            except RuntimeError:
                continue

        self.export_scene(context.scene, sorted_objects, dir=dir_path, global_matrix=global_matrix)

        self.report({'INFO'}, 'Objects exported successfully!')
        return {'FINISHED'}

        scene_name = context.scene.name.replace(' ', '_').replace('.', '_')
        objects = context.selected_objects if self.prop_use_selection else context.scene.objects
        dir_path, main_file_name = os.path.split(self.filepath)
        main_file_name = os.path.splitext(main_file_name)[0]

        with open(self.filepath, "w+t", encoding="utf8", newline="\n") as main_file:
            main_file.write('#ifndef _%s_H_\n' % main_file_name.upper())
            main_file.write('#define _%s_H_\n\n' % main_file_name.upper())

            if self.prop_export_object_as_file:
                resource_file_name = 'resources'
                resource_file = open(os.path.join(dir_path, resource_file_name + '.h'), "w+t", encoding="utf8", newline="\n")
                resource_file.write('#ifndef _%s_H_\n' % resource_file_name.upper())
                resource_file.write('#define _%s_H_\n\n' % resource_file_name.upper())
            else:
                resource_file = main_file

            for obj in objects:
                if self.prop_export_curve_as_function and obj.type == 'CURVE':
                    with open(os.path.join(dir_path, '%s.h' % obj.name.lower()), "w+t", encoding="utf8", newline="\n") as object_file:
                        object_file.write('#import "Math.h"\n\n')
                        if obj.data.extrude > 0:
                            self.export_surface(context, obj.data, object_file, name=name_compact(obj.name), matrix_world=obj.matrix_world)
                        else:
                            self.export_curve(obj.data, object_file, name=name_compact(obj.name), matrix_world=obj.matrix_world)
                        #shutil.copyfile('Obj-C/Math.h', os.path.join(dir_path, 'Math.h'))
                        #shutil.copyfile('Obj-C/Math.cpp', os.path.join(dir_path, 'Math.cpp'))

                        continue
                else:
                    try:
                        mesh = obj.to_mesh(context.scene, self.prop_use_mesh_modifiers, 'PREVIEW', calc_tessface=False)
                        mesh_name = obj.name.upper().replace(' ', '_').replace('.', '_')

                        if self.prop_use_global_matrix:
                            mesh.transform(global_matrix * obj.matrix_world)
                    except RuntimeError:
                        continue

                if self.prop_export_object_as_file:
                    main_file.write('#include "%s.h"\n\n' % mesh_name.lower())
                    with open(os.path.join(dir_path, '%s.h' % mesh_name.lower()), "w+t", encoding="utf8", newline="\n") as file:
                        object_file.write('#import "GLProgram.h"\n\n')
                        self.export_mesh(mesh, object_file, name=mesh_name, matrix_world=obj.matrix_world)
                else:
                    self.export_mesh(mesh, main_file, name=mesh_name, matrix_world=obj.matrix_world)

                cur_material = obj.active_material
                if cur_material and cur_material.name not in materials:
                    self.export_material(cur_material, context.scene, resource_file)
                    materials.append(cur_material.name)

            if self.prop_export_object_as_file:
                resource_file.write('#endif  // _%s_H_\n' % resource_file_name.upper())
                resource_file.close()

            main_file.write('#endif  // _%s_H_\n' % main_file_name.upper())

        self.report({'INFO'}, 'Objects exported successfully!')
        return {'FINISHED'}

    '''
    @staticmethod
    def export_material(material, scene, file):
        ambient_color = scene.world.ambient_color.append(1.0) * material.ambient
        diffuse_color = material.diffuse_color.append(material.translucency)
        specular_color = material.specular_color.append(material.specular_alpha) * material.specular_intensity
        emission_color = [col * material.volume.emission for col in material.volume.emission_color]

        file.write('const Material %s = {\n'
                   '\t{%.4f, %.4f, %.4f, %.4f},\n'  # ambient
                   '\t{%.4f, %.4f, %.4f, %.4f},\n'  # diffuse
                   '\t{%.4f, %.4f, %.4f, %.4f},\n'  # specular
                   '\t{%.4f, %.4f, %.4f, %.4f},\n'  # emission
                   '\t%.4f, %.4f\n'           # shininess, transparency
                   '}\n\n' % (material.name.upper(),
                              ambient_color[0], ambient_color[1], ambient_color[2], ambient_color[3],
                              diffuse_color[0], diffuse_color[1], diffuse_color[2], diffuse_color[3],
                              specular_color[0], specular_color[1], specular_color[2], specular_color,
                              emission_color[0], emission_color[1], emission_color[2], emission_color[3],
                              material.emit, material.alpha)

                   # mesh.uv_texutres[]
    '''

    '''
    # Write images!

    if face_img:  # We have an image on the face!
        filepath = face_img.filepath
        if filepath:  # may be '' for generated images
            # write relative image path
            filepath = bpy_extras.io_utils.path_reference(filepath, source_dir, dest_dir,
                                                          path_mode, "", copy_set, face_img.library)
            fw('map_Kd %s\n' % filepath)  # Diffuse mapping image
            del filepath
        else:
            # so we write the materials image.
            face_img = None

    if mat:  # No face image. if we havea material search for MTex image.
        image_map = {}
        # backwards so topmost are highest priority
        for mtex in reversed(mat.texture_slots):
            if mtex and mtex.texture and mtex.texture.type == 'IMAGE':
                image = mtex.texture.image
                if image:
                    # texface overrides others
                    if (mtex.use_map_color_diffuse and (face_img is None) and
                            (mtex.use_map_warp is False) and (mtex.texture_coords != 'REFLECTION')):
                        image_map["map_Kd"] = image
                    if mtex.use_map_ambient:
                        image_map["map_Ka"] = image
                    # this is the Spec intensity channel but Ks stands for specular Color

                    # if mtex.use_map_specular:
                    #     image_map["map_Ks"] = image

                    if mtex.use_map_color_spec:  # specular color
                        image_map["map_Ks"] = image
                    if mtex.use_map_hardness:  # specular hardness/glossiness
                        image_map["map_Ns"] = image
                    if mtex.use_map_alpha:
                        image_map["map_d"] = image
                    if mtex.use_map_translucency:
                        image_map["map_Tr"] = image
                    if mtex.use_map_normal:
                        image_map["map_Bump"] = image
                    if mtex.use_map_displacement:
                        image_map["disp"] = image
                    if mtex.use_map_color_diffuse and (mtex.texture_coords == 'REFLECTION'):
                        image_map["refl"] = image
                    if mtex.use_map_emit:
                        image_map["map_Ke"] = image

        for key, image in sorted(image_map.items()):
            filepath = bpy_extras.io_utils.path_reference(image.filepath, source_dir, dest_dir,
                                                          path_mode, "", copy_set, image.library)
            fw('%s %s\n' % (key, repr(filepath)[1:-1]))
    '''

    def export_scene(self, scene, objects, **kwargs):
        scene_header_file_name = os.path.join(kwargs['dir'], '%s.h' % class_name(scene.name))
        scene_source_file_name = os.path.join(kwargs['dir'], '%s.m' % class_name(scene.name))
        with open(scene_header_file_name, "w+t", encoding="utf8", newline="\n") as file:
            for obj in objects:
                file.write('#import "%s.h"\n' % class_name(obj.name))

            file.write('\n')
            file.write('@interface %s: NSObject <BFGLDrawable>\n{\n' % class_name(scene.name))
            file.write('\tGLKMatrix4 m_globalMatrix;\n\n')
            for obj in objects:
                file.write('\t%s *m_%s;\n' % (class_name(obj.name), member_name(obj.name)))

            file.write('\n')
            file.write('\tNSArray *m_lights;\n')
            file.write('\tNSArray *m_objects;\n')
            file.write('}\n\n')
            file.write('-(void)resetGlobalMatrix;\n')
            file.write('-(void)scaleGlobalMatrix:(float[3])axisComps;\n')
            file.write('-(void)translateGlobalMatrix:(float[3])axisComps;\n')
            file.write('-(void)rotateGlobalMatrix:(float)radians AxisComps:(float[3])axisComps;\n\n')
            file.write('@property (nonatomic) GLKMatrix4 globalMatrix;\n')
            file.write('@property (nonatomic, readonly) NSArray *lights;\n')
            file.write('@property (nonatomic, readonly) NSArray *objects;\n')
            for obj in objects:
                file.write('@property (nonatomic, readonly) %s *%s;\n' % (class_name(obj.name), member_name(obj.name)))
            file.write('\n')
            file.write('@end\n\n')

        with open(scene_source_file_name, "w+t", encoding="utf8", newline="\n") as file:
            file.write('#import "%s.h"\n\n' % class_name(scene.name))

            bound_box = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # left, right, bottom, top, near, far
            for obj in objects:
                matrix = matrix_to_string(kwargs['global_matrix'] * obj.matrix_basis, '\t')
                file.write('float %sModelMatrix[16] = {\n%s\n};\n\n' % (class_name(obj.name), matrix))

                for i in range(8):
                    bound_box[0] = min(obj.bound_box[i][0] * 1.1, bound_box[0])
                    bound_box[1] = max(obj.bound_box[i][0] * 1.1, bound_box[1])
                    bound_box[2] = min(obj.bound_box[i][1] * 1.1, bound_box[2])
                    bound_box[3] = max(obj.bound_box[i][1] * 1.1, bound_box[3])
                    bound_box[4] = min(obj.bound_box[i][2] * 1.1, bound_box[4])
                    bound_box[5] = max(obj.bound_box[i][2] * 1.1, bound_box[5])

            render = scene.render
            camera = scene.camera
            camera_data = scene.camera.data
            axis_up_vector = (1.0 if self.axis_up == 'X' else -1.0 if self.axis_up == '-X' else 0.0,
                              1.0 if self.axis_up == 'Y' else -1.0 if self.axis_up == '-Y' else 0.0,
                              1.0 if self.axis_up == 'Z' else -1.0 if self.axis_up == '-Z' else 0.0)
            vp_matrix = mathutils.Matrix(
                (camera.location,
                 (0.0, 0.0, 0.0),
                 axis_up_vector))  # TODO rotate global_matrix by camera.rotation_euler use self.axis_up

            file.write('@implementation %s\n\n' % class_name(scene.name))
            file.write('-(id)init\n'
                       '{\n'
                       '\tself = [super init];\n'
                       '\tif (self)\n'
                       '\t{\n'
                       '\t\t[self resetGlobalMatrix];\n\n')
            for obj in objects:
                file.write('\t\tm_%s = [[%s alloc] init];\n' % (member_name(obj.name), class_name(obj.name)))
            file.write('\n')
            for obj in objects:
                if obj.type != 'LAMP':
                    file.write('\t\t[m_%s setModelMatrix: GLKMatrix4MakeWithArrayAndTranspose(%sModelMatrix)];\n' % (member_name(obj.name), class_name(obj.name)))
            file.write('\n')
            file.write('\t\tm_lights = [NSArray arrayWithObjects:%s, nil];\n' % ', '.join(('m_' + member_name(obj.name) for obj in objects if obj.type == 'LAMP')))
            file.write('\t\tm_objects = [NSArray arrayWithObjects:%s, nil];\n' % ', '.join(('m_' + member_name(obj.name) for obj in objects if obj.type != 'LAMP')))
            file.write('\t}\n\n'
                       '\treturn self;\n'
                       '}\n\n')
            file.write('-(void)dealloc\n'
                       '{\n'
                       '}\n\n')
            file.write('-(void)resetGlobalMatrix\n'
                       '{\n')
            if camera.data.type == 'ORTHO':
                file.write('\t//TODO: float aspect = width()/height();\n')
                file.write('\tGLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(%s);\n' %
                           ', '.join(('%.4f' % (val * camera.data.ortho_scale) for val in bound_box)))  # camera.shift_x!
            if camera.data.type == 'PERSP':
                # camera.angle if camera.lens if camera.lens_unit
                file.write('\tGLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(%s)' % '')  # GLKMatrix4MakeFrustum?
            file.write('\tGLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(%s);\n\n' % matrix_to_string(vp_matrix, '\t' + ' ' * 38, False))
            file.write('\tm_globalMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);\n'
                       '}\n\n')
            file.write('-(void)scaleGlobalMatrix:(float[3])axisComps\n'
                       '{\n'
                       '\tm_globalMatrix = GLKMatrix4Scale(m_globalMatrix, axisComps[0], axisComps[1], axisComps[2]);\n'
                       '}\n\n')
            file.write('-(void)translateGlobalMatrix:(float[3])axisComps\n'
                       '{\n'
                       '\tm_globalMatrix = GLKMatrix4Translate(m_globalMatrix, axisComps[0], axisComps[1], axisComps[2]);\n'
                       '}\n\n')
            file.write('-(void)rotateGlobalMatrix:(float)radians AxisComps:(float[3])axisComps\n'
                       '{\n'
                       '\tm_globalMatrix = GLKMatrix4Rotate(m_globalMatrix, radians, axisComps[0], axisComps[1], axisComps[2]);\n'
                       '}\n\n')
            file.write('-(void)beforeDraw:(BFGLProgram *)program\n'
                       '{\n')
            for obj in objects:
                file.write('\t[m_%s beforeDraw:program];\n' % member_name(obj.name))
            file.write('}\n\n')
            file.write('-(void)afterDraw:(BFGLProgram *)program\n'
                       '{\n')
            for obj in objects:
                file.write('\t[m_%s afterDraw:program];\n' % member_name(obj.name))
            file.write('}\n\n')
            file.write('-(void)draw:(BFGLProgram *)program\n'
                       '{\n'
                       '\tGLint global_matrix = [program uniform:@"globalMatrix"];\n\n'
                       '\tglUniformMatrix4fv(global_matrix, 1, 0, m_globalMatrix.m);\n\n')
            for obj in objects:
                file.write('\t[m_%s draw:program];\n' % member_name(obj.name))
            file.write('}\n\n'
                       '@synthesize globalMatrix = m_globalMatrix,\n'
                       '            lights = m_lights,\n'
                       '            objects = m_objects,\n')
            for obj in objects:
                file.write(' ' * 12 + '%s = m_%s,\n' % (member_name(obj.name), member_name(obj.name)))

            file.seek(file.tell() - 2, os.SEEK_SET)
            file.write(';\n')
            file.write('@end')

    def export_light(self, scene, lamp, **kwargs):
        header_file_path = os.path.join(kwargs['dir'], '%s.h' % class_name(kwargs['name']))
        with open(header_file_path, "w+t", encoding="utf8", newline="\n") as file:
            file.write('#import "GLProgram.h"\n')
            if lamp.type == 'POINT':
                base_class = 'BFGLPointLight'
                file.write('#import "GLPointLight.h"\n\n')
            file.write('@interface %s : %s\n' % (class_name(kwargs['name']), base_class))
            # for action in actions:
            #     file.write('-(void)%s:(float)t;\n' % action.name)
            file.write('@end\n\n')

        source_file_path = os.path.join(kwargs['dir'], '%s.m' % class_name(kwargs['name']))
        with open(source_file_path, "w+t", encoding="utf8", newline="\n") as file:
            file.write('#import "%s.h"\n\n' % class_name(kwargs['name']))
            file.write('@implementation %s\n\n'
                       '-(id)init\n'
                       '{\n'
                       '\tself = [super init];\n'
                       '\tif (self)\n'
                       '\t{\n' % class_name(kwargs['name']))
            if lamp.type == 'POINT':
                def tuple_2_str(tuple):
                    return ', '.join(('%.6f' % f for f in tuple))

                # constant_coefficient, - этой хуйни вообще нет
                attenuation = (lamp.energy, lamp.linear_attenuation, lamp.quadratic_attenuation)
                file.write('\t\t[self setLightEnergy: %.4sf];\n' % lamp.energy)
                file.write('\t\t[self setPosition: GLKVector3Make(%s)];\n' % tuple_2_str(kwargs['location']))
                file.write('\t\t[self setAmbientColor: GLKVector3Make(%s)];\n' % tuple_2_str(scene.world.ambient_color))
                file.write('\t\t[self setDiffuseColor: GLKVector3Make(%s)];\n' % tuple_2_str(lamp.color))
                file.write('\t\t[self setSpecularColor: GLKVector3Make(%s)];\n' % tuple_2_str(lamp.color))
                file.write('\t\t[self setLightAttenuation: GLKVector3Make(%s)];\n' % tuple_2_str(attenuation))
            file.write('\t}\n\n'
                       '\treturn self;\n'
                       '}\n\n')
            file.write('-(void)dealloc\n'
                       '{\n'
                       '}\n\n')
            file.write('@end')

    def export_mesh(self, mesh, **kwargs):
        mesh_triangulate(mesh)
        mesh.calc_normals_split()

        indices_count = 0
        for polygon in mesh.polygons:
            indices_count += polygon.loop_total

        indices_str = '\n\t'
        for polygon in mesh.polygons:
            indices_str += ', '.join(('%d' % mesh.loops[i].vertex_index for i in polygon.loop_indices)) + ',\n\t'

        indices_str = indices_str[:-3] + '\n'

        vertex_count = len(mesh.vertices)

        vertexes_str = '\n\t'
        for vertex in mesh.vertices:
            row_data = '{%s}' % (', '.join(('%.6f' % co for co in vertex.co)))
            if self.prop_export_color and not self.prop_export_as_color_map:
                row_data += ', {%d, %d, %d, %d}' % (0.0, 0.0, 0.0, 1.0)
            if self.prop_export_normal:
                row_data += ', {%s}' % (', '.join(('%.6f' % co for co in vertex.normal)))
            if self.prop_export_texture:
                row_data += ', {%.3f, %.3f}' % (0.0, 0.0)

            vertexes_str += '{%s},\n\t' % row_data

        vertexes_str = vertexes_str[:-3] + '\n'

        #Добавить карту цветов и, возможно, карту нормалей, которую можно генерировать прям в блендоре

        actions = []
        #Данные анимации - массив массивов (для каждого сплайна) массивов (для каждой точки) сплайнов
        # actions = [object.shape_keys.animation_data.action]
        # for track in surface.shape_keys.animation_data.nla_tracks:
        #     for strip in track.strips:
        #         actions.append(strip.action)

        header_file_path = os.path.join(kwargs['dir'], '%s.h' % class_name(kwargs['name']))
        with open(header_file_path, "w+t", encoding="utf8", newline="\n") as file:
            file.write('#import "GLProgram.h"\n\n')
            file.write('@interface %s: NSObject <BFGLDrawable>\n{\n' % class_name(kwargs['name']))
            file.write('\tGLuint m_indexBuffer;\n'
                       '\tGLuint m_vertexBuffer;\n'
                       '\tGLKMatrix4 m_modelMatrix;\n')
            # if kwargs['material']:
            #     file.write('\tBFMaterial m_material;\n')
            # file.write('\tconst GLuint m_Indices[%d];\n' % indices_count)
            # file.write('\tconst BFVertex m_Vertexes[%d];\n' % vertex_count)

            # for action in actions:
            #     file.write('\tNSMutableArray *m_%sData;\n' % action.name)
            file.write('}\n\n')
            file.write('@property (nonatomic) GLKMatrix4 modelMatrix;\n\n')

            # for action in actions:
            #     file.write('-(void)%s:(float)t;\n' % action.name)
            file.write('@end\n\n')

        source_file_path = os.path.join(kwargs['dir'], '%s.m' % class_name(kwargs['name']))
        with open(source_file_path, "w+t", encoding="utf8", newline="\n") as file:
            file.write('#import "%s.h"\n\n' % class_name(kwargs['name']))
            file.write('#import "Math.h"\n'
                       '#import "BFFinaly.h"\n\n')
            file.write('static const GLuint kIndices%s[%d] = {%s};\n\n' % (class_name(kwargs['name']), indices_count, indices_str))
            file.write('static const BFVertex kVertexes%s[%d] = {%s};\n\n' % (class_name(kwargs['name']), vertex_count, vertexes_str))
            if kwargs['material']:
                material = kwargs['material']
                file.write('static const BFMaterial k%sMaterial = {\n%s\n};\n\n' % (material.name, struct_to_string(material_to_struct(material), '\t')))
            file.write('@implementation %s\n\n'
                       '-(id)init\n'
                       '{\n'
                       '\tself = [super init];\n'
                       '\tif (self)\n'
                       '\t{\n'
                       '\t\tm_modelMatrix = GLKMatrix4Identity;\n\n' % class_name(kwargs['name']))
            file.write('\t\tglGenBuffers(1, &m_indexBuffer);\n'
                       '\t\tglGenBuffers(1, &m_vertexBuffer);\n\n'
                       '\t\tglBindBuffer(GL_ARRAY_BUFFER, m_vertexBuffer);\n'
                       '\t\tglBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_indexBuffer);\n\n')
            file.write('\t\tglBufferData(GL_ARRAY_BUFFER, sizeof(kVertexes%s), kVertexes%s, %s);\n'
                       % (class_name(kwargs['name']), class_name(kwargs['name']), 'GL_DYNAMIC_DRAW' if len(actions) else 'GL_STATIC_DRAW'))
            file.write('\t\tglBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(kIndices%s), kIndices%s, GL_STATIC_DRAW);\n\n'
                       % (class_name(kwargs['name']), class_name(kwargs['name'])))
            file.write('\t\tglBindBuffer(GL_ARRAY_BUFFER, 0);\n'
                       '\t\tglBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);\n'
                       '\t}\n\n'
                       '\treturn self;\n'
                       '}\n\n')
            file.write('-(void)dealloc\n'
                       '{\n'
                       '\tglDeleteBuffers(1, &m_indexBuffer);\n'
                       '\tglDeleteBuffers(1, &m_vertexBuffer);\n'
                       '}\n\n')
            file.write('-(void)beforeDraw:(BFGLProgram *)program\n'
                       '{\n'
                       '}\n\n')
            file.write('-(void)afterDraw:(BFGLProgram *)program\n'
                       '{\n'
                       '}\n\n')
            file.write('-(void)draw:(BFGLProgram *)program\n'
                       '{\n'
                       '\t@autoreleasepool\n'
                       '\t{\n'
                       '\t\tNSMutableArray *finalys = [NSMutableArray array];\n\n'
                       '\t\tglBindBuffer(GL_ARRAY_BUFFER, m_vertexBuffer);\n'
                       '\t\tglBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_indexBuffer);\n\n'
                       '\t\t@try\n'
                       '\t\t{\n'
                       '\t\t\tGLint modelMatrixUniform = [program uniform:@"modelMatrix"];\n'
                       '\t\t\tglUniformMatrix4fv(modelMatrixUniform, 1, 0, m_modelMatrix.m);\n'
                       '\t\t}\n'
                       '\t\t@catch(NSException *) {}\n\n'
                       '\t\t@try\n'
                       '\t\t{\n'
                       '\t\t\tGLint positionAttrib = [program attribute:@"position"];\n\n'
                       '\t\t\tglEnableVertexAttribArray(positionAttrib);\n\n'
                       '\t\t\tglVertexAttribPointer(positionAttrib, 3, GL_FLOAT, GL_FALSE, sizeof(BFVertex), BUFFER_OFFSET(0));\n\n'
                       '\t\t\t[finalys addObject:[BFFinaly finalyWithFunctor:^void(){\n'
                       '\t\t\t\tglDisableVertexAttribArray(positionAttrib);\n'
                       '\t\t\t}]];\n'
                       '\t\t}\n'
                       '\t\t@catch(NSException *) {}\n\n'
                       '\t\t@try\n'
                       '\t\t{\n'
                       '\t\t\tGLint normalAttrib = [program attribute:@"normal"];\n\n'
                       '\t\t\tglEnableVertexAttribArray(normalAttrib);\n\n'
                       '\t\t\tglVertexAttribPointer(normalAttrib, 3, GL_FLOAT, GL_FALSE, sizeof(BFVertex), BUFFER_OFFSET(sizeof(BFPoint3D)));\n\n'
                       '\t\t\t[finalys addObject:[BFFinaly finalyWithFunctor:^void(){\n'
                       '\t\t\t\tglDisableVertexAttribArray(normalAttrib);\n'
                       '\t\t\t}]];\n'
                       '\t\t}\n'
                       '\t\t@catch(NSException *) {}\n\n'
                       '\t\t@try\n'
                       '\t\t{\n'
                       '\t\t\tGLint useTextureUniform = [program uniform:@"useTexture"];\n'
                       '\t\t\tGLint textCoordAttrib = [program attribute:@"textCoord"];\n\n'
                       '\t\t\tglEnableVertexAttribArray(textCoordAttrib);\n\n'
                       '\t\t\tglUniform1i(useTextureUniform, 1);\n'
                       '\t\t\tglVertexAttribPointer(textCoordAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(BFVertex), BUFFER_OFFSET(sizeof(BFPoint3D) * 2));\n\n'
                       '\t\t\t[finalys addObject:[BFFinaly finalyWithFunctor:^void(){\n'
                       '\t\t\t\tglUniform1i(useTextureUniform, 0);\n'
                       '\t\t\t\tglDisableVertexAttribArray(textCoordAttrib);\n'
                       '\t\t\t}]];\n'
                       '\t\t}\n'
                       '\t\t@catch(NSException *) {}\n\n')
            if kwargs['material']:
                material = kwargs['material']
                file.write('\t\t@try\n'
                           '\t\t{\n'
                           '\t\t\tGLint useMaterialUniform    = [program uniform:@"useMaterial"];\n'
                           '\t\t\tGLint materialAmbientColor  = [program uniform:@"material.ambientColor"];\n'
                           '\t\t\tGLint materialDiffuseColor  = [program uniform:@"material.diffuseColor"];\n'
                           '\t\t\tGLint materialSpecularColor = [program uniform:@"material.specularColor"];\n'
                           '\t\t\tGLint materialEmissionColor = [program uniform:@"material.emissionColor"];\n'
                           '\n'
                           '\t\t\tglUniform1i(useMaterialUniform, 1);\n'
                           '\t\t\tglUniform4fv(materialAmbientColor,  1, (const GLfloat *)&k%sMaterial.ambientColor);\n'
                           '\t\t\tglUniform4fv(materialDiffuseColor,  1, (const GLfloat *)&k%sMaterial.diffuseColor);\n'
                           '\t\t\tglUniform4fv(materialSpecularColor, 1, (const GLfloat *)&k%sMaterial.specularColor);\n'
                           '\t\t\tglUniform4fv(materialEmissionColor, 1, (const GLfloat *)&k%sMaterial.emissionColor);\n'
                           '\n'
                           '\t\t\t[finalys addObject:[BFFinaly finalyWithFunctor:^void(){ glUniform1i(useMaterialUniform, 0); }]];\n'
                           '\t\t}\n' % (material.name, material.name, material.name, material.name))
                file.write('\t\t@catch(NSException *) {}\n\n')
            file.write('\t\tglDrawElements(GL_TRIANGLES, sizeof(kIndices%s)/sizeof(GLuint), GL_UNSIGNED_INT, 0);\n\n' % class_name(kwargs['name']))
            file.write('\t\tglBindBuffer(GL_ARRAY_BUFFER, 0);\n'
                       '\t\tglBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);\n'
                       '\t}\n'
                       '}\n\n'
                       '@synthesize modelMatrix = m_modelMatrix;\n\n'
                       '@end')
        return

        if self.prop_use_vertex_indices:
            # Если мы решили сохранить порядок вывода вершин, то для нормальной отрисовки
            # также необходимо экспортировать и список индексов этих вершин
            file.write('const GLuint %s_VERTEX_COUNT = %d;\n' % (mesh_name, len(mesh.vertices)))
            file.write('const Vertex %s_VERTICES[%s_VERTEX_COUNT] = {\n' % (mesh_name, mesh_name))

            for vertex in mesh.vertices:
                data = '{%.6f, %.6f, %.6f}' % (vertex.co[0], vertex.co[1], vertex.co[2])
                if self.prop_export_color and not self.prop_export_as_color_map:
                    data += ', {%d, %d, %d, %d}' % (0.0, 0.0, 0.0, 1.0)
                if self.prop_export_normal:
                    data += ', {%.6f, %.6f, %.6f}' % (vertex.normal[0], vertex.normal[1], vertex.normal[2])
                if self.prop_export_texture:
                    data += ', {%.3f, %.3f}' % (0.0, 0.0)

                file.write('\t{%s},\n' % data)

            file.seek(file.tell()-2, os.SEEK_SET)
            file.write('\n};\n\n')

            # loops[l_idx].normal
            # textures = me.uv_textures[:]

            indices_count = 0
            for polygon in mesh.polygons:
                indices_count += polygon.loop_total

            file.write('const GLuint %s_INDEX_COUNT = %d;\n' % (mesh_name, indices_count))
            file.write('const GLuint %s_INDICES[%s_INDEX_COUNT] = {\n' % (mesh_name, mesh_name))

            # Этот ключ задает относительно симметричный вывод индексов типа:
            # GLubyte
            # indices[36] = {0, 1, 2, 0, 2, 3,
            #                0, 3, 4, 0, 4, 5,
            #                0, 5, 6, 0, 6, 1,
            #                7, 6, 1, 7, 1, 2,
            #                7, 4, 5, 7, 5, 6,
            #                7, 2, 3, 7, 3, 4};
            if self.prop_use_symmetrical_indices_output:
                array = []
                indices_in_row = int(math.sqrt(indices_count))
                max_indices_in_row = indices_in_row if indices_in_row < 20 else 20
                for polygon in mesh.polygons:
                    array.extend([str(mesh.loops[loop_index].vertex_index) for loop_index in polygon.loop_indices])

                    if len(array) >= max_indices_in_row:
                        file.write('\t%s,\n' % ', '.join(array[0:max_indices_in_row]))
                        array = array[max_indices_in_row:len(array)]

                if len(array) > 0:
                    file.write('\t%s,\n' % ', '.join(array[0:max_indices_in_row]))
            else:
                # Иначе под индексы вершин каждого полигона отведена своя строка
                array = []
                for polygon in mesh.polygons:
                    for loop_index in polygon.loop_indices:
                        array.append(str(mesh.loops[loop_index].vertex_index))

                    file.write('\t%s,\n' % ', '.join(array))
                    array = []

            file.seek(file.tell()-2, os.SEEK_SET)
            file.write('\n};\n\n')

            # Export colors map
            cur_color_layer = mesh.vertex_colors.active
            if self.prop_export_color and self.prop_export_as_color_map and cur_color_layer:

                file.write('const GLuint %s_COLORS_COUNT = %d;\n' % (mesh_name, indices_count * 4))
                file.write('const GLfloat %s_COLORS[%s_COLORS_COUNT] = {\n' % (mesh_name, mesh_name))

                for polygon in mesh.polygons:
                    file.write('\t// Polygon %d\n' % polygon.index)
                    material = mesh.materials[polygon.material_index]
                    for loop_index in polygon.loop_indices:
                        color = cur_color_layer.data[loop_index].color
                        file.write('\t%.3f, %.3f, %.3f, %.3f,\n' % (color[0], color[1], color[2], material.alpha))

                file.seek(file.tell() - 2, os.SEEK_SET)
                file.write('\n};\n\n')

        else:
            # Если не сохранять порядок вергин, то вершины будет сгруппированны по полигонам,
            # к которым они относятся. Это приведет к дублированию вершин
            vertex_count = 0
            for polygon in mesh.polygons:
                vertex_count += polygon.loop_total

            cur_color_layer = mesh.vertex_colors.active
            cur_texture_layer = mesh.uv_layers.active

            file.write('const GLuint %s_VERTEX_COUNT = %d;\n' % (mesh_name, vertex_count))
            file.write('const Vertex %s_VERTICES[%s_VERTEX_COUNT] = {\n' % (mesh_name, mesh_name))

            for polygon in mesh.polygons:
                file.write('\t// Polygon %d\n' % polygon.index)
                material = mesh.materials[polygon.material_index]
                for loop_index in polygon.loop_indices:
                    vertex = mesh.vertices[mesh.loops[loop_index].vertex_index]

                    data = '{%.6f, %.6f, %.6f}' % (vertex.co[0], vertex.co[1], vertex.co[2])
                    if self.prop_export_color and cur_color_layer:
                        color = cur_color_layer.data[loop_index].color
                        data += ', {%.3f, %.3f, %.3f, %.3f}' % (color[0], color[1], color[2], material.alpha)
                    if self.prop_export_normal:
                        data += ', {%.6f, %.6f, %.6f}' % (vertex.normal[0], vertex.normal[1], vertex.normal[2])
                    if self.prop_export_texture and cur_texture_layer:
                        texture = cur_texture_layer.data[loop_index].uv
                        data += ', {%.3f, %.3f}' % (texture[0], texture[1])

                    file.write('\t{%s},\n' % data)

            file.seek(file.tell()-2, os.SEEK_SET)
            file.write('\n};\n\n')

        # Выводим текстуру в файл
        if self.prop_export_texture and cur_texture_layer:
            image = mesh.uv_textures.active.data

    @staticmethod
    def export_curve(curve, file, **kwargs):
        file.write('@interface BF%s: BFObject <BFCurve>\n{\n' % kwargs['name'])
        file.write('\tNSArray *m_splines;\n')
        file.write('\tGLKMatrix4 m_objectMatrix;\n')
        file.write('}\n\n')
        action = curve.shape_keys.animation_data.action
        if action:
            file.write('\t-(void)%s:(float)t;' % action.name)
        file.write('@end\n\n')

        file.write('@implementation BF%s\n\n' % kwargs['name'])
        file.write('-(id)init\n{\n'
                   '\tself = [super init];\n'
                   '\tif (self)\n\t{\n')

        point_count_array = []
        for index, spline in enumerate(curve.splines):
            bezier_points = []
            if spline.type == 'BEZIER':
                bezier_points = bezier_points_for_bezier_spline(spline)

            # https://www.codeproject.com/Articles/996281/NURBS-curve-made-easy
            if spline.type == 'NURBS':
                bezier_points = bezier_points_for_NURB_spline(spline)

            result_str = ''
            point_count_array.append(len(bezier_points))
            for i in range(0, len(bezier_points) - 1, 2):
                result_str += '\t\t\t' + '{%s}, ' % ', '.join(('%.6f' % co for co in bezier_points[i])) \
                                       + '{%s}, ' % ', '.join(('%.6f' % co for co in bezier_points[i + 1])) + '\n'
            else:
                result_str = result_str[:-3]

            file.write('\t\tBFPoint3D points_%d[] = {\n%s\n\t\t};\n\n' % (index, result_str))

        for index, spline in enumerate(curve.splines):
            file.write('\t\t[m_splines addObject: [[BFSpline alloc] initWithPoints: points_%d Count: %d Order: %d];\n' %
                       (index, point_count_array[index], 4 if spline.type == 'BEZIER' else spline.order_u))

        matrix  = ', '.join(('%.6f' % co for co in kwargs['matrix_world'][0])) + ',\n\t\t' + ' ' * 33
        matrix += ', '.join(('%.6f' % co for co in kwargs['matrix_world'][1])) + ',\n\t\t' + ' ' * 33
        matrix += ', '.join(('%.6f' % co for co in kwargs['matrix_world'][2])) + ',\n\t\t' + ' ' * 33
        matrix += ', '.join(('%.6f' % co for co in kwargs['matrix_world'][3]))

        file.write('\n\t\t m_objectMatrix = GLKMatrix4Make(%s);\n\t}\n\n\treturn self;\n}\n\n' % matrix)
        file.write('- (GLKMatrix4) getModelMatrix\n{\n\treturn m_objectMatrix;\n}\n\n')
        file.write('- (BFPoint3D) getPointAt: (float) t\n{\n\treturn [self getPointAt: t OnSpline: 0];\n}\n\n')
        file.write('- (BFPoint3D) getPointAt: (float) t OnSpline: (int) spline\n'
                   '{\n\treturn [m_splines[spline] getPointAt: t];\n}\n')
        file.write('- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int) count\n'
                   '{\n\treturn [self getLineFrom: t_start To: t_end WithSegments: count OnSpline: 0];\n}\n\n')
        file.write('- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithSegments: (int) count OnSpline: (int) spline\n'
                   '{\n\treturn [m_splines[spline] getLineFrom: t_start To: t_end WithSegments: count];\n}\n\n')
        file.write('- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle\n'
                   '{\n\treturn [self getLineFrom: t_start To: t_end WithMinAngle: angle OnSpline: 0];\n}\n\n')
        file.write('- (NSArray *) getLineFrom: (float) t_start To: (float) t_end WithMinAngle: (float) angle OnSpline: (int) spline\n'
                   '{\n\treturn [m_splines[spline] getLineFrom: t_start To: t_end WithMinAngle: angle];\n}\n\n')

        file.write('@end')


    '''
        return_type = 'CGPoint' if curve.dimensions == '2D' else 'CGPoint3D'
        for spline in curve.splines:
            file.write('%s %s(float t)\n{' % (return_type, kwargs['name']))
            if spline.type == 'BEZIER':
                bezier_points = list(spline.bezier_points)
                if spline.use_cyclic_u:
                    bezier_points.append(spline.bezier_points[0])

                bezier_point_count = len(bezier_points)

                for index in range(bezier_point_count - 1):
                    first_point = bezier_points[index]
                    second_point = bezier_points[index + 1]

                    if index < bezier_point_count - 1:
                        file.write('\tif(t >= %.4f && t < %.4f)\n{\n' % (index/bezier_point_count, (index + 1)/bezier_point_count))
                    else:
                        file.write('\tif(t >= %.4f && t <= 1.0)\n{\n' % (index / bezier_point_count))

                    # TODO: Сделать один массив с точками, а потом каким-нибдь макаром передавать в функцию нужный кусок массива

                    file.write('\t\tCGPoint points[4] = {\n'
                               '\t\t\t{%.6f, %.6f}, {%.6f, %.6f},\n'
                               '\t\t\t{%.6f, %.6f}, {%.6f, %.6f}\n'
                               '\t\t};\n\n' % (first_point.co[0], first_point.co[1],
                                               first_point.handle_right[0], first_point.handle_right[1],
                                               second_point.handle_left[0], second_point.handle_left[1],
                                               second_point.co[0], second_point.co[1]))

                    file.write('\t\treturn CubicBezierCurve(points, t * %d / %d);\n\n' % (bezier_point_count, index + 1))

                    file.write('\t};\n')

                    #(ob_mat * pt.co.to_3d())[:])

                    # file.write('\t\tCGPoint result;')
                    # file.write('\t\tfloat lt = t * %d / %d;\n' % (bezier_point_count, index + 1))
                    # file.write('\t\tCGPoint p0 = CGPointMake(%.4f, %.4f);\n'   % first_point.co[:])
                    # file.write('\t\tCGPoint p1 = CGPointMake(%.4f, %.4f);\n'   % first_point.handle_right[:])
                    # file.write('\t\tCGPoint p2 = CGPointMake(%.4f, %.4f);\n'   % second_point.handle_left[:])
                    # file.write('\t\tCGPoint p3 = CGPointMake(%.4f, %.4f);\n\n' % second_point.co[:])
                    # file.write('\t\tresult.x =  pow((1 - lt), 3) * p0.x + 3 * pow((1 - lt), 2) * lt * p1.x + 3 * (1 - lt) * pow(lt, 2) * p2.x + pow(lt, 3) * p3.x;\n')
                    # file.write('\t\tresult.y =  pow((1 - lt), 3) * p0.y + 3 * pow((1 - lt), 2) * lt * p1.y + 3 * (1 - lt) * pow(lt, 2) * p2.y + pow(lt, 3) * p3.y;\n')
                    # file.write('\t\treturn result;\n};\n\n')

                    # TODO: Написать функция рисования адаптивным методом через сравнение углов и как раз можно использовать все опорные точки

            # https://www.codeproject.com/Articles/996281/NURBS-curve-made-easy
            if spline.type == 'NURBS':
                bezier_points = list(spline.points)
                if spline.use_cyclic_u:
                    bezier_points.append(spline.points[0])

                knots = [0]
                for index, point in enumerate(bezier_points):
                    knots.append(knots[index] + point.weight)

                bezier_point_count = len(bezier_points)
                bezier_segment_count = len(bezier_points) - spline.order_u + 1
                for index in range(bezier_segment_count):
                    if index < bezier_segment_count:
                        file.write('\tif(t >= %.4f && t < %.4f)\n{\n' % (index / bezier_segment_count,
                                                                        (index + 1) / bezier_segment_count))
                    else:
                        file.write('\tif(t >= %.4f && t <= 1.0)\n{\n' % (index / bezier_segment_count))

                    if spline.order_u == 3:
                        v0 = ((knots[index + 3] - knots[index + 2]) * bezier_points[index].co[:] +
                              (knots[index + 2] - knots[index + 1]) * bezier_points[index + 1].co[:]) / (knots[index + 3] - knots[index + 1])
                        b0 = bezier_points[index + 1].co[:]
                        v1 = ((knots[(index + 1) + 3] - knots[(index + 1) + 2]) * bezier_points[(index + 1)].co[:] +
                              (knots[(index + 1) + 2] - knots[(index + 1) + 1]) * bezier_points[(index + 1) + 1].co[:]) / \
                              (knots[(index + 1) + 3] - knots[(index + 1) + 1])

                        file.write('\t\tCGPoint points[3] = {\n'
                                   '\t\t\t{%.6f, %.6f}, {%.6f, %.6f}, {%.6f, %.6f}\n'
                                   '\t\t};\n\n' % (v0[0], v0[1], b0[0], b0[1], v1[0], v1[1]))

                        file.write('\t\treturn QuadraticBezierCurve(points, t * %d / %d);\n\n' % (bezier_segment_count, index + 1))

                    file.write('\t};\n')
            file.write('\treturn CGPointMake(0.0, 0.0);\n};\n\n')
        print(kwargs)
    '''

    def export_surface(self, context, surface, file, **kwargs):
        file.write('@interface BF%s: BFObject <BFSurface>\n{\n' % kwargs['name'])
        file.write('\tNSMutableArray *m_splines;\n')
        # Данные анимации - массив массивов (для каждого сплайна) массивов (для каждой точки) сплайнов
        actions = [surface.shape_keys.animation_data.action]
        for track in surface.shape_keys.animation_data.nla_tracks:
            for strip in track.strips:
                actions.append(strip.action)

        for action in actions:
            file.write('\tNSMutableArray *m_%sData;\n' % action.name)
        file.write('}\n\n')

        for action in actions:
            file.write('-(void)%s:(float)t;\n' % action.name)

        file.write('\tGLKMatrix4 m_objectMatrix;\n')
        file.write('\n@end\n\n')

        file.write('@implementation BF%s\n\n' % kwargs['name'])
        file.write('-(id)init\n{\n'
                   '\tself = [super init];\n'
                   '\tif (self)\n\t{\n'
                   '\t\tm_splines = [NSMutableArray array];\n\n')

        point_count_array = []
        for index, spline in enumerate(surface.splines):
            bezier_points = []
            if spline.type == 'BEZIER':
                bezier_points = bezier_points_for_bezier_spline(spline)
            # https://www.codeproject.com/Articles/996281/NURBS-curve-made-easy
            if spline.type == 'NURBS':
                bezier_points = bezier_points_for_NURB_spline(spline)

            result_str = ''
            point_count_array.append(len(bezier_points))
            for i in range(len(bezier_points)):
                result_str += '\t\t\t' if i % 2 == 0 else ''
                result_str += '{%s}, ' % ', '.join(('%.6f' % co for co in bezier_points[i]))
                result_str += '\n' if i % 2 > 0 else ''
            else:
                result_str = result_str[:-2 if i % 2 == 0 else -3]

            file.write('\t\tBFPoint3D spline%d_points[] = {\n%s\n\t\t};\n\n' % (index, result_str))

        for index, spline in enumerate(surface.splines):
            if spline.type == 'BEZIER':
                file.write('\t\t[m_splines addObject: [[BFExtrudedSpline alloc] initWithSpline:\n'
                           '\t\t                              [[BFSpline alloc] initWithPoints: spline%d_points Count:%d Order:%d] Extrude:%d]];\n' %
                           (index, point_count_array[index], 4, surface.extrude))

        for action in actions:
            file.write('\n\t\t[m_%sData = [NSMutableArray array];\n\n' % action.name)
            # (start_frame, end_frame) = action.frame_range
            key_frames = []
            for fcurve in action.fcurves:
                for key_frame in fcurve.keyframe_points:
                    if key_frames.count(key_frame.co[0]) == 0:
                        key_frames.append(key_frame.co[0])
            key_frames.sort()
            for s_index, spline in enumerate(surface.splines):
                splines_str = ''
                list_of_points = []
                '''
                for frame in key_frames:
                    context.scene.frame_set(frame)
                    if spline.type == 'BEZIER':
                        list_of_points.append(bezier_points_for_bezier_spline(spline))
                    if spline.type == 'NURBS':
                        list_of_points.append(bezier_points_for_NURB_spline(spline))
                '''
                for key in surface.shape_keys.key_blocks:
                    if spline.type == 'BEZIER':
                        bezier_points = []
                        points = list(key.data)
                        if spline.use_cyclic_u:
                            points.append(spline.bezier_points[0])

                        for i in range(len(points) - 1):
                            bezier_points.append(points[i].co)
                            bezier_points.append(points[i].handle_right)
                            bezier_points.append(points[i + 1].handle_left)
                        else:
                            bezier_points.append(points[-1].co)  # has been i
                        list_of_points.append(bezier_points)
                    if spline.type == 'NURBS':
                        list_of_points.append(bezier_points_for_NURB_spline(key.data))

                file.write('\t\t{\n')
                point_count = point_count_array[s_index]
                for p_index in range(point_count):
                    result_str = ''
                    spline_for_point = bezier_interpolation([frame_points[p_index] for frame_points in list_of_points])
                    if spline_for_point:
                        for i in range(len(spline_for_point)):
                            result_str += '\t\t\t\t' if i % 2 == 0 else ''
                            result_str += '{%s}, ' % ', '.join(('%.6f' % co for co in spline_for_point[i]))
                            result_str += '\n' if i % 2 > 0 else ''
                        else:
                            result_str = result_str[:-2 if i % 2 == 0 else -3]

                        file.write('\t\t\tBFPoint3D point%d_data[] = {\n%s\n\t\t\t};\n\n' % (p_index, result_str))
                        splines_str += '[[BFSpline alloc] initWithPoints: point%d_data Count:%d Order:%d],\n\t\t\t' % (p_index, len(spline_for_point), 4)
                        splines_str += ' ' * (44 + len(action.name))
                    else:
                        splines_str += '[NSNull null], \n\t\t\t' + ' ' * (44 + len(action.name))

                file.write('\t\t\t[m_%sData addObject:[NSArray arrayWithObjects:%s nil]];\n\t\t}\n' % (action.name, splines_str))

        matrix = ', '.join(('%.6f' % co for co in kwargs['matrix_world'][0])) + ',\n\t\t' + ' ' * 33
        matrix += ', '.join(('%.6f' % co for co in kwargs['matrix_world'][1])) + ',\n\t\t' + ' ' * 33
        matrix += ', '.join(('%.6f' % co for co in kwargs['matrix_world'][2])) + ',\n\t\t' + ' ' * 33
        matrix += ', '.join(('%.6f' % co for co in kwargs['matrix_world'][3]))

        file.write('\n\t\t m_objectMatrix = GLKMatrix4Make(%s);\n'
                   '\t}\n\n'
                   '\treturn self;\n'
                   '}\n\n' % matrix)

        file.write('-(GLKMatrix4)getModelMatrix\n'
                   '{\n'
                   '\treturn m_objectMatrix;\n'
                   '}\n\n')
        file.write('-(BFVertex)getPointAt:(BFPointUV)point\n'
                   '{\n'
                   '\treturn [self getPointAt:point OnSpline:0];\n'
                   '}\n\n')
        file.write('-(BFVertex)getPointAt:(BFPointUV)point OnSpline:(int)spline\n'
                   '{\n'
                   '\treturn [(BFExtrudedSpline *)m_splines[spline] getPointAt:point];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getLineByPoints:(NSArray *)points WithSegments:(int)count\n'
                   '{\n'
                   '\treturn [self getLineByPoints:points WithSegments:(int)count OnSpline:0];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getLineByPoints:(NSArray *)points WithMinAngle:(float)angle\n'
                   '{\n'
                   '\treturn [self getLineByPoints:points WithMinAngle:angle OnSpline:0];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getSurfaceByPoints:(NSArray *)points WithSegments:(int)count\n'
                   '{\n'
                   '\treturn [self getSurfaceByPoints:points WithSegments:count OnSpline:0];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getSurfaceByPoints:(NSArray *)points WithMinAngle:(float)angle\n'
                   '{\n'
                   '\treturn [self getSurfaceByPoints:points WithMinAngle:angle OnSpline:0];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getLineByPoints:(NSArray *)points WithSegments:(int)count OnSpline:(int)spline\n'
                   '{\n'
                   '\tNSArray *data = [(BFExtrudedSpline *)m_splines[spline] getLineByPoints:points WithSegments:count];\n'
                   '\treturn [[BFDefaultMesh alloc] initWithData:data GLPrimitive:GL_LINE_STRIP Matrix:m_objectMatrix];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getLineByPoints:(NSArray *)points WithMinAngle:(float)angle OnSpline:(int)spline\n'
                   '{\n'
                   '\tNSArray *data = [(BFExtrudedSpline *)m_splines[spline] getLineByPoints:points WithMinAngle:angle];\n'
                   '\treturn [[BFDefaultMesh alloc] initWithData:data GLPrimitive:GL_LINE_STRIP Matrix:m_objectMatrix];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getSurfaceByPoints:(NSArray *)points WithSegments:(int)count OnSpline:(int)spline\n'
                   '{\n'
                   '\tNSArray *data = [(BFExtrudedSpline *)m_splines[spline] getSurfaceByPoints:points WithSegments:count];\n'
                   '\treturn [[BFDefaultMesh alloc] initWithData:data GLPrimitive:GL_TRIANGLES Matrix:m_objectMatrix];\n'
                   '}\n\n')
        file.write('-(BFObject<BFMesh> *)getSurfaceByPoints:(NSArray *)points WithMinAngle:(float)angle OnSpline:(int)spline\n'
                   '{\n'
                   '\tNSArray *data = [(BFExtrudedSpline *)m_splines[spline] getSurfaceByPoints:points WithMinAngle:angle];\n'
                   '\treturn [[BFDefaultMesh alloc] initWithData:data GLPrimitive:GL_TRIANGLES Matrix:m_objectMatrix];\n'
                   '}\n\n')

        for action in actions:
            file.write('-(void)%s:(float)t\n'
                       '{\n'
                       '\tNSInteger splineCount = [m_splines count];\n'
                       '\tfor (int spline_index = 0; spline_index < splineCount; spline_index++)\n'
                       '\t{\n'
                       '\t\tBFExtrudedSpline *spline = [m_splines objectAtIndex: spline_index];\n'
                       '\t\tNSUInteger pointCount = [[[spline spline] points] count];\n'
                       '\t\tfor (int point_index = 0; point_index < pointCount; point_index++)\n'
                       '\t\t{\n'
                       '\t\t\tBFSpline *interpolation_spline = [[m_%sData objectAtIndex:spline_index] objectAtIndex:point_index];\n'
                       '\t\t\tif (![interpolation_spline isEqual:[NSNull null]])\n'
                       '\t\t\t\t*[[[[spline spline] points] objectAtIndex:point_index] BFPoint3DRef] = [interpolation_spline getPointAt:t];\n'
                       '\t\t}\n'
                       '\t}\n'
                       '}\n\n' % (action.name, action.name))

        file.write('@end')





def write_mtl(scene, filepath, path_mode, copy_set, mtl_dict):
    from mathutils import Color

    world = scene.world
    if world:
        world_amb = world.ambient_color
    else:
        world_amb = Color((0.0, 0.0, 0.0))

    source_dir = os.path.dirname(bpy.data.filepath)
    dest_dir = os.path.dirname(filepath)

    with open(filepath, "w", encoding="utf8", newline="\n") as f:
        fw = f.write

        fw('# Blender MTL File: %r\n' % (os.path.basename(bpy.data.filepath) or "None"))
        fw('# Material Count: %i\n' % len(mtl_dict))

        mtl_dict_values = list(mtl_dict.values())
        mtl_dict_values.sort(key=lambda m: m[0])

        # Write material/image combinations we have used.
        # Using mtl_dict.values() directly gives un-predictable order.
        for mtl_mat_name, mat, face_img in mtl_dict_values:
            # Get the Blender data for the material and the image.
            # Having an image named None will make a bug, dont do it :)

            fw('\nnewmtl %s\n' % mtl_mat_name)  # Define a new material: matname_imgname

            if mat:
                use_mirror = mat.raytrace_mirror.use and mat.raytrace_mirror.reflect_factor != 0.0

                # convert from blenders spec to 0 - 1000 range.
                if mat.specular_shader == 'WARDISO':
                    tspec = (0.4 - mat.specular_slope) / 0.0004
                else:
                    tspec = (mat.specular_hardness - 1) / 0.51
                fw('Ns %.6f\n' % tspec)
                del tspec

                # Ambient
                if use_mirror:
                    fw('Ka %.6f %.6f %.6f\n' % (mat.raytrace_mirror.reflect_factor * mat.mirror_color)[:])
                else:
                    fw('Ka %.6f %.6f %.6f\n' % (mat.ambient, mat.ambient, mat.ambient))  # Do not use world color!
                fw('Kd %.6f %.6f %.6f\n' % (mat.diffuse_intensity * mat.diffuse_color)[:])  # Diffuse
                fw('Ks %.6f %.6f %.6f\n' % (mat.specular_intensity * mat.specular_color)[:])  # Specular
                # Emission, not in original MTL standard but seems pretty common, see T45766.
                # XXX Blender has no color emission, it's using diffuse color instead...
                fw('Ke %.6f %.6f %.6f\n' % (mat.emit * mat.diffuse_color)[:])
                if hasattr(mat, "raytrace_transparency") and hasattr(mat.raytrace_transparency, "ior"):
                    fw('Ni %.6f\n' % mat.raytrace_transparency.ior)  # Refraction index
                else:
                    fw('Ni %.6f\n' % 1.0)
                fw('d %.6f\n' % mat.alpha)  # Alpha (obj uses 'd' for dissolve)

                # See http://en.wikipedia.org/wiki/Wavefront_.obj_file for whole list of values...
                # Note that mapping is rather fuzzy sometimes, trying to do our best here.
                if mat.use_shadeless:
                    fw('illum 0\n')  # ignore lighting
                elif mat.specular_intensity == 0:
                    fw('illum 1\n')  # no specular.
                elif use_mirror:
                    if mat.use_transparency and mat.transparency_method == 'RAYTRACE':
                        if mat.raytrace_mirror.fresnel != 0.0:
                            fw('illum 7\n')  # Reflection, Transparency, Ray trace and Fresnel
                        else:
                            fw('illum 6\n')  # Reflection, Transparency, Ray trace
                    elif mat.raytrace_mirror.fresnel != 0.0:
                        fw('illum 5\n')  # Reflection, Ray trace and Fresnel
                    else:
                        fw('illum 3\n')  # Reflection and Ray trace
                elif mat.use_transparency and mat.transparency_method == 'RAYTRACE':
                    fw('illum 9\n')  # 'Glass' transparency and no Ray trace reflection... fuzzy matching, but...
                else:
                    fw('illum 2\n')  # light normaly

            else:
                # Write a dummy material here?
                fw('Ns 0\n')
                fw('Ka %.6f %.6f %.6f\n' % world_amb[:])  # Ambient, uses mirror color,
                fw('Kd 0.8 0.8 0.8\n')
                fw('Ks 0.8 0.8 0.8\n')
                fw('d 1\n')  # No alpha
                fw('illum 2\n')  # light normaly

            # Write images!
            if face_img:  # We have an image on the face!
                filepath = face_img.filepath
                if filepath:  # may be '' for generated images
                    # write relative image path
                    filepath = bpy_extras.io_utils.path_reference(filepath, source_dir, dest_dir,
                                                                  path_mode, "", copy_set, face_img.library)
                    fw('map_Kd %s\n' % filepath)  # Diffuse mapping image
                    del filepath
                else:
                    # so we write the materials image.
                    face_img = None

            if mat:  # No face image. if we havea material search for MTex image.
                image_map = {}
                # backwards so topmost are highest priority
                for mtex in reversed(mat.texture_slots):
                    if mtex and mtex.texture and mtex.texture.type == 'IMAGE':
                        image = mtex.texture.image
                        if image:
                            # texface overrides others
                            if (mtex.use_map_color_diffuse and (face_img is None) and
                                (mtex.use_map_warp is False) and (mtex.texture_coords != 'REFLECTION')):
                                image_map["map_Kd"] = image
                            if mtex.use_map_ambient:
                                image_map["map_Ka"] = image
                            # this is the Spec intensity channel but Ks stands for specular Color
                            '''
                            if mtex.use_map_specular:
                                image_map["map_Ks"] = image
                            '''
                            if mtex.use_map_color_spec:  # specular color
                                image_map["map_Ks"] = image
                            if mtex.use_map_hardness:  # specular hardness/glossiness
                                image_map["map_Ns"] = image
                            if mtex.use_map_alpha:
                                image_map["map_d"] = image
                            if mtex.use_map_translucency:
                                image_map["map_Tr"] = image
                            if mtex.use_map_normal:
                                image_map["map_Bump"] = image
                            if mtex.use_map_displacement:
                                image_map["disp"] = image
                            if mtex.use_map_color_diffuse and (mtex.texture_coords == 'REFLECTION'):
                                image_map["refl"] = image
                            if mtex.use_map_emit:
                                image_map["map_Ke"] = image

                for key, image in sorted(image_map.items()):
                    filepath = bpy_extras.io_utils.path_reference(image.filepath, source_dir, dest_dir,
                                                                  path_mode, "", copy_set, image.library)
                    fw('%s %s\n' % (key, repr(filepath)[1:-1]))


def test_nurbs_compat(ob):
    if ob.type != 'CURVE':
        return False

    for nu in ob.data.splines:
        if nu.point_count_v == 1 and nu.type != 'BEZIER':  # not a surface and not bezier
            return True

    return False


def write_nurb(fw, ob, ob_mat):
    tot_verts = 0
    cu = ob.data

    # use negative indices
    for nu in cu.splines:
        if nu.type == 'POLY':
            DEG_ORDER_U = 1
        else:
            DEG_ORDER_U = nu.order_u - 1  # odd but tested to be correct

        if nu.type == 'BEZIER':
            print("\tWarning, bezier curve:", ob.name, "only poly and nurbs curves supported")
            continue

        if nu.point_count_v > 1:
            print("\tWarning, surface:", ob.name, "only poly and nurbs curves supported")
            continue

        if len(nu.points) <= DEG_ORDER_U:
            print("\tWarning, order_u is lower then vert count, skipping:", ob.name)
            continue

        pt_num = 0
        do_closed = nu.use_cyclic_u
        do_endpoints = (do_closed == 0) and nu.use_endpoint_u

        for pt in nu.points:
            fw('v %.6f %.6f %.6f\n' % (ob_mat * pt.co.to_3d())[:])
            pt_num += 1
        tot_verts += pt_num

        fw('g %s\n' % (name_compat(ob.name)))  # name_compat(ob.getData(1)) could use the data name too
        fw('cstype bspline\n')  # not ideal, hard coded
        fw('deg %d\n' % DEG_ORDER_U)  # not used for curves but most files have it still

        curve_ls = [-(i + 1) for i in range(pt_num)]

        # 'curv' keyword
        if do_closed:
            if DEG_ORDER_U == 1:
                pt_num += 1
                curve_ls.append(-1)
            else:
                pt_num += DEG_ORDER_U
                curve_ls = curve_ls + curve_ls[0:DEG_ORDER_U]

        fw('curv 0.0 1.0 %s\n' % (" ".join([str(i) for i in curve_ls])))  # Blender has no U and V values for the curve

        # 'parm' keyword
        tot_parm = (DEG_ORDER_U + 1) + pt_num
        tot_parm_div = float(tot_parm - 1)
        parm_ls = [(i / tot_parm_div) for i in range(tot_parm)]

        if do_endpoints:  # end points, force param
            for i in range(DEG_ORDER_U + 1):
                parm_ls[i] = 0.0
                parm_ls[-(1 + i)] = 1.0

        fw("parm u %s\n" % " ".join(["%.6f" % i for i in parm_ls]))

        fw('end\n')

    return tot_verts


def write_file(filepath, objects, scene,
               use_triangles=False,
               use_edges=False,
               use_smooth_groups=False,
               use_smooth_groups_bitflags=False,
               use_normals=False,
               use_uvs=True,
               materials_export_type='NM',
               use_mesh_modifiers=True,
               use_blen_objects=True,
               group_by_object=False,
               group_by_material=False,
               keep_vertex_order=False,
               use_vertex_groups=False,
               use_nurbs=True,
               global_matrix=None,
               path_mode='AUTO',
               progress=ProgressReport(),
               ):
    """
    Basic write function. The context and options must be already set
    This can be accessed externaly
    eg.
    write( 'c:\\test\\foobar.h', Blender.Object.GetSelected() ) # Using default options.
    """
    if global_matrix is None:
        global_matrix = mathutils.Matrix()

    def veckey3d(v):
        return round(v.x, 4), round(v.y, 4), round(v.z, 4)

    def veckey2d(v):
        return round(v[0], 4), round(v[1], 4)

    def findVertexGroupName(face, vWeightMap):
        """
        Searches the vertexDict to see what groups is assigned to a given face.
        We use a frequency system in order to sort out the name because a given vetex can
        belong to two or more groups at the same time. To find the right name for the face
        we list all the possible vertex group names with their frequency and then sort by
        frequency in descend order. The top element is the one shared by the highest number
        of vertices is the face's group
        """
        weightDict = {}
        for vert_index in face.vertices:
            vWeights = vWeightMap[vert_index]
            for vGroupName, weight in vWeights:
                weightDict[vGroupName] = weightDict.get(vGroupName, 0.0) + weight

        if weightDict:
            return max((weight, vGroupName) for vGroupName, weight in weightDict.items())[1]
        else:
            return '(null)'

    with ProgressReportSubstep(progress, 2, "OBJ Export path: %r" % filepath, "OBJ Export Finished") as subprogress1:
        with open(filepath, "w", encoding="utf8", newline="\n") as f:
            fw = f.write

            # Tell the obj file what material file to use.
            if materials_export_type == 'FM':
                mtlfilepath = os.path.splitext(filepath)[0] + ".mtl"
                # filepath can contain non utf8 chars, use repr
                fw('//mtllib %s\n' % repr(os.path.basename(mtlfilepath))[1:-1])

            # Initialize totals, these are updated each object
            totverts = totuvco = totno = 1

            face_vert_index = 1

            # A Dict of Materials
            # (material.name, image.name):matname_imagename # matname_imagename has gaps removed.
            mtl_dict = {}
            # Used to reduce the usage of matname_texname materials, which can become annoying in case of
            # repeated exports/imports, yet keeping unique mat names per keys!
            # mtl_name: (material.name, image.name)
            mtl_rev_dict = {}

            copy_set = set()

            # Get all meshes
            subprogress1.enter_substeps(len(objects))
            for i, ob_main in enumerate(objects):
                # ignore dupli children
                if ob_main.parent and ob_main.parent.dupli_type in {'VERTS', 'FACES'}:
                    # XXX
                    subprogress1.step("Ignoring %s, dupli child..." % ob_main.name)
                    continue

                obs = []
                if ob_main.dupli_type != 'NONE':
                    # XXX
                    print('creating dupli_list on', ob_main.name)
                    ob_main.dupli_list_create(scene)

                    obs = [(dob.object, dob.matrix) for dob in ob_main.dupli_list]

                    # XXX debug print
                    print(ob_main.name, 'has', len(obs), 'dupli children')
                else:
                    obs = [(ob_main, ob_main.matrix_world)]

                subprogress1.enter_substeps(len(obs))
                for ob, ob_mat in obs:
                    with ProgressReportSubstep(subprogress1, 6) as subprogress2:
                        uv_unique_count = no_unique_count = 0

                        # Nurbs curve support
                        if use_nurbs and test_nurbs_compat(ob):
                            ob_mat = global_matrix * ob_mat
                            totverts += write_nurb(fw, ob, ob_mat)
                            continue
                        # END NURBS

                        try:
                            me = ob.to_mesh(scene, use_mesh_modifiers, 'PREVIEW', calc_tessface=False)
                        except RuntimeError:
                            me = None

                        if me is None:
                            continue

                        me.transform(global_matrix * ob_mat)

                        if use_triangles:
                            # _must_ do this first since it re-allocs arrays
                            mesh_triangulate(me)

                        if use_uvs:
                            faceuv = len(me.uv_textures) > 0
                            if faceuv:
                                uv_texture = me.uv_textures.active.data[:]
                                uv_layer = me.uv_layers.active.data[:]
                        else:
                            faceuv = False

                        me_verts = me.vertices[:]

                        # Make our own list so it can be sorted to reduce context switching
                        face_index_pairs = [(face, index) for index, face in enumerate(me.polygons)]
                        # faces = [ f for f in me.tessfaces ]

                        if use_edges:
                            edges = me.edges
                        else:
                            edges = []

                        if not (len(face_index_pairs) + len(edges) + len(me.vertices)):  # Make sure there is something to write
                            # clean up
                            bpy.data.meshes.remove(me)
                            continue  # dont bother with this mesh.

                        if use_normals and face_index_pairs:
                            me.calc_normals_split()
                            # No need to call me.free_normals_split later, as this mesh is deleted anyway!
                            loops = me.loops
                        else:
                            loops = []

                        if (use_smooth_groups or use_smooth_groups_bitflags) and face_index_pairs:
                            smooth_groups, smooth_groups_tot = me.calc_smooth_groups(use_smooth_groups_bitflags)
                            if smooth_groups_tot <= 1:
                                smooth_groups, smooth_groups_tot = (), 0
                        else:
                            smooth_groups, smooth_groups_tot = (), 0

                        materials = me.materials[:]
                        material_names = [m.name if m else None for m in materials]

                        # avoid bad index errors
                        if not materials:
                            materials = [None]
                            material_names = [name_compat(None)]

                        # Sort by Material, then images
                        # so we dont over context switch in the obj file.
                        if keep_vertex_order:
                            pass
                        else:
                            if faceuv:
                                if smooth_groups:
                                    sort_func = lambda a: (a[0].material_index,
                                                           hash(uv_texture[a[1]].image),
                                                           smooth_groups[a[1]] if a[0].use_smooth else False)
                                else:
                                    sort_func = lambda a: (a[0].material_index,
                                                           hash(uv_texture[a[1]].image),
                                                           a[0].use_smooth)
                            elif len(materials) > 1:
                                if smooth_groups:
                                    sort_func = lambda a: (a[0].material_index,
                                                           smooth_groups[a[1]] if a[0].use_smooth else False)
                                else:
                                    sort_func = lambda a: (a[0].material_index,
                                                           a[0].use_smooth)
                            else:
                                # no materials
                                if smooth_groups:
                                    sort_func = lambda a: smooth_groups[a[1] if a[0].use_smooth else False]
                                else:
                                    sort_func = lambda a: a[0].use_smooth

                            face_index_pairs.sort(key=sort_func)

                            del sort_func

                        # Set the default mat to no material and no image.
                        contextMat = 0, 0  # Can never be this, so we will label a new material the first chance we get.
                        contextSmooth = None  # Will either be true or false,  set bad to force initialization switch.

                        if use_blen_objects or group_by_object:
                            name1 = ob.name
                            name2 = ob.data.name
                            if name1 == name2:
                                obnamestring = name_compat(name1)
                            else:
                                obnamestring = '%s_%s' % (name_compat(name1), name_compat(name2))

                            #if use_blen_objects:
                            #    fw('o %s\n' % obnamestring)  # Write Object name
                            #else:  # if group_by_object:
                            #    fw('g %s\n' % obnamestring)
                            
                            fw('const GLuint %s_VERTEX_COUNT = %d;\n' % (obnamestring.upper(), len(me_verts)))
                            fw('const Vertex %s[%s_VERTEX_COUNT] = {\n' % (obnamestring, obnamestring.upper()))

                        subprogress2.step()

                        # Vert
                        for v in me_verts:
                            fw('v %.6f %.6f %.6f\n' % v.co[:])

                        subprogress2.step()

                        # UV
                        if faceuv:
                            # in case removing some of these dont get defined.
                            uv = f_index = uv_index = uv_key = uv_val = uv_ls = None

                            uv_face_mapping = [None] * len(face_index_pairs)

                            uv_dict = {}
                            uv_get = uv_dict.get
                            for f, f_index in face_index_pairs:
                                uv_ls = uv_face_mapping[f_index] = []
                                for uv_index, l_index in enumerate(f.loop_indices):
                                    uv = uv_layer[l_index].uv
                                    uv_key = veckey2d(uv)
                                    uv_val = uv_get(uv_key)
                                    if uv_val is None:
                                        uv_val = uv_dict[uv_key] = uv_unique_count
                                        fw('vt %.6f %.6f\n' % uv[:])
                                        uv_unique_count += 1
                                    uv_ls.append(uv_val)

                            del uv_dict, uv, f_index, uv_index, uv_ls, uv_get, uv_key, uv_val
                            # Only need uv_unique_count and uv_face_mapping

                        subprogress2.step()

                        # NORMAL, Smooth/Non smoothed.
                        if use_normals:
                            no_key = no_val = None
                            normals_to_idx = {}
                            no_get = normals_to_idx.get
                            loops_to_normals = [0] * len(loops)
                            for f, f_index in face_index_pairs:
                                for l_idx in f.loop_indices:
                                    no_key = veckey3d(loops[l_idx].normal)
                                    no_val = no_get(no_key)
                                    if no_val is None:
                                        no_val = normals_to_idx[no_key] = no_unique_count
                                        fw('vn %.6f %.6f %.6f\n' % no_key)
                                        no_unique_count += 1
                                    loops_to_normals[l_idx] = no_val
                            del normals_to_idx, no_get, no_key, no_val
                        else:
                            loops_to_normals = []

                        if not faceuv:
                            f_image = None

                        subprogress2.step()

                        # XXX
                        if use_vertex_groups:
                            # Retrieve the list of vertex groups
                            vertGroupNames = ob.vertex_groups.keys()
                            if vertGroupNames:
                                currentVGroup = ''
                                # Create a dictionary keyed by face id and listing, for each vertex, the vertex groups it belongs to
                                vgroupsMap = [[] for _i in range(len(me_verts))]
                                for v_idx, v_ls in enumerate(vgroupsMap):
                                    v_ls[:] = [(vertGroupNames[g.group], g.weight) for g in me_verts[v_idx].groups]

                        for f, f_index in face_index_pairs:
                            f_smooth = f.use_smooth
                            if f_smooth and smooth_groups:
                                f_smooth = smooth_groups[f_index]
                            f_mat = min(f.material_index, len(materials) - 1)

                            if faceuv:
                                tface = uv_texture[f_index]
                                f_image = tface.image

                            # MAKE KEY
                            if faceuv and f_image:  # Object is always true.
                                key = material_names[f_mat], f_image.name
                            else:
                                key = material_names[f_mat], None  # No image, use None instead.

                            # Write the vertex group
                            if use_vertex_groups:
                                if vertGroupNames:
                                    # find what vertext group the face belongs to
                                    vgroup_of_face = findVertexGroupName(f, vgroupsMap)
                                    if vgroup_of_face != currentVGroup:
                                        currentVGroup = vgroup_of_face
                                        fw('g %s\n' % vgroup_of_face)

                            # CHECK FOR CONTEXT SWITCH
                            if key == contextMat:
                                pass  # Context already switched, dont do anything
                            else:
                                if key[0] is None and key[1] is None:
                                    # Write a null material, since we know the context has changed.
                                    if group_by_material:
                                        # can be mat_image or (null)
                                        fw("g %s_%s\n" % (name_compat(ob.name), name_compat(ob.data.name)))
                                    if materials_export_type == 'FM':
                                        fw("usemtl (null)\n")  # mat, image

                                else:
                                    mat_data = mtl_dict.get(key)
                                    if not mat_data:
                                        # First add to global dict so we can export to mtl
                                        # Then write mtl

                                        # Make a new names from the mat and image name,
                                        # converting any spaces to underscores with name_compat.

                                        # If none image dont bother adding it to the name
                                        # Try to avoid as much as possible adding texname (or other things)
                                        # to the mtl name (see [#32102])...
                                        mtl_name = "%s" % name_compat(key[0])
                                        if mtl_rev_dict.get(mtl_name, None) not in {key, None}:
                                            if key[1] is None:
                                                tmp_ext = "_NONE"
                                            else:
                                                tmp_ext = "_%s" % name_compat(key[1])
                                            i = 0
                                            while mtl_rev_dict.get(mtl_name + tmp_ext, None) not in {key, None}:
                                                i += 1
                                                tmp_ext = "_%3d" % i
                                            mtl_name += tmp_ext
                                        mat_data = mtl_dict[key] = mtl_name, materials[f_mat], f_image
                                        mtl_rev_dict[mtl_name] = key

                                    if group_by_material:
                                        # can be mat_image or (null)
                                        fw("g %s_%s_%s\n" % (name_compat(ob.name), name_compat(ob.data.name), mat_data[0]))
                                    if materials_export_type == 'FM':
                                        fw("usemtl %s\n" % mat_data[0])  # can be mat_image or (null)

                            contextMat = key
                            if f_smooth != contextSmooth:
                                if f_smooth:  # on now off
                                    if smooth_groups:
                                        f_smooth = smooth_groups[f_index]
                                        fw('s %d\n' % f_smooth)
                                    else:
                                        fw('s 1\n')
                                else:  # was off now on
                                    fw('s off\n')
                                contextSmooth = f_smooth

                            f_v = [(vi, me_verts[v_idx], l_idx)
                                   for vi, (v_idx, l_idx) in enumerate(zip(f.vertices, f.loop_indices))]

                            fw('f')
                            if faceuv:
                                if use_normals:
                                    for vi, v, li in f_v:
                                        fw(" %d/%d/%d" % (totverts + v.index,
                                                          totuvco + uv_face_mapping[f_index][vi],
                                                          totno + loops_to_normals[li],
                                                          ))  # vert, uv, normal
                                else:  # No Normals
                                    for vi, v, li in f_v:
                                        fw(" %d/%d" % (totverts + v.index,
                                                       totuvco + uv_face_mapping[f_index][vi],
                                                       ))  # vert, uv

                                face_vert_index += len(f_v)

                            else:  # No UV's
                                if use_normals:
                                    for vi, v, li in f_v:
                                        fw(" %d//%d" % (totverts + v.index, totno + loops_to_normals[li]))
                                else:  # No Normals
                                    for vi, v, li in f_v:
                                        fw(" %d" % (totverts + v.index))

                            fw('\n')

                        subprogress2.step()

                        # Write edges.
                        if use_edges:
                            for ed in edges:
                                if ed.is_loose:
                                    fw('l %d %d\n' % (totverts + ed.vertices[0], totverts + ed.vertices[1]))

                        # Make the indices global rather then per mesh
                        totverts += len(me_verts)
                        totuvco += uv_unique_count
                        totno += no_unique_count

                        # clean up
                        bpy.data.meshes.remove(me)

                if ob_main.dupli_type != 'NONE':
                    ob_main.dupli_list_clear()

                subprogress1.leave_substeps("Finished writing geometry of '%s'." % ob_main.name)
            subprogress1.leave_substeps()

        subprogress1.step("Finished exporting geometry, now exporting materials")

        # Now we have all our materials, save them
        if materials_export_type == 'FM':
            write_mtl(scene, mtlfilepath, path_mode, copy_set, mtl_dict)

        # copy all collected files.
        bpy_extras.io_utils.path_reference_copy(copy_set)


def menu_func_export(self, context):
    self.layout.operator(ExportObjCHeader.bl_idname, text="Objective-C header (.h)")
    
def register():
    bpy.utils.register_module(__name__)
    bpy.types.INFO_MT_file_export.append(menu_func_export)
 
def unregister():
    bpy.utils.unregister_module(__name__)
    bpy.types.INFO_MT_file_export.remove(menu_func_export)
 
if __name__ == "__main__":
    register()
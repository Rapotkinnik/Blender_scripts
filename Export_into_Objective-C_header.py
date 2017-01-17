#required this structure:
#typedef struct
#{
#    GLfloat vertexPosition[3];
#    GLfloat vertexColor[4];
#    GLfloat normalDirection[3];
#    GLfloat texturePosition[3];
#}Vertex;

bl_info = {
    'name': 'Objective-C header',
    'author': 'Nikolay Rapotkin',
    'version': (0, 0, 1),
    'blender': (2, 74, 0),
    'location': 'File > Export',
    'description': 'Export meshes into Objective-C header for OpenGL ES painting',
    'warning': '',
    'wiki_url': '',
    'tracker_url': '',
    'support': 'COMMUNITY',
    'category': 'Import-Export'}
    
import os
import bpy
import mathutils
import bpy_extras.io_utils

from bpy.props           import BoolProperty, FloatProperty, StringProperty, EnumProperty
from progress_report     import ProgressReport, ProgressReportSubstep
from bpy_extras.io_utils import ExportHelper, orientation_helper_factory, path_reference_mode, axis_conversion

IOOBJOrientationHelper = orientation_helper_factory("IOOBJOrientationHelper", axis_forward='-Z', axis_up='Y')
      
class ExportObjCHeader(bpy.types.Operator, ExportHelper, IOOBJOrientationHelper):

    bl_idname = "export_scene.h"
    bl_label = 'Export Objective-C header'
    bl_options = {'PRESET'}

    filename_ext = ".h"
    filter_glob = StringProperty(
        default="*.h;*.mtl",
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

    prop_use_objet_as_file_export = BoolProperty(
        name="Export objects separately",
        description="Export each object to separate file",
        default=False,
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
    keep_vertex_order = BoolProperty(
            name="Keep Vertex Order",
            description="",
            default=False,
            )

    global_scale = FloatProperty(
            name="Scale",
            min=0.01, max=1000.0,
            default=1.0,
            )
'''

    path_mode = path_reference_mode

    check_extension = True

    def execute(self, context):
        from mathutils import Matrix                                         
        global_matrix = Matrix.Scale(self.global_scale, 4) * axis_conversion(to_forward=self.axis_forward, to_up=self.axis_up).to_4x4()

        with ProgressReport(context.window_manager) as progress:
            base_name, ext = os.path.splitext(str(self.filepath))
            context_name = [base_name, '', '', ext]  # Base name, scene name, frame number, extension

            scene = context.scene

            # Exit edit mode before exporting, so current object states are exported properly.
            if bpy.ops.object.mode_set.poll():
                bpy.ops.object.mode_set(mode='OBJECT')

            objects = context.selected_objects if self.prop_use_selection else scene.objects

            if self.prop_use_objet_as_file_export:
                for obj in objects:
                    try:
                        mesh = obj.to_mesh(scene, self.prop_use_mesh_modifiers, 'PREVIEW', calc_tessface=False)
                    except RuntimeError:
                        continue

                    with open(filepath, "w", encoding="utf8", newline="\n") as file:
                        export_mesh(mesh, file, {'use_global_matrix': self.prop_use_global_matrix,
                                                 'global_matrix': global_matrix,
                                                 'use_triangules': self.prop_use_triangles})
            else:
                with open(filepath, "w", encoding="utf8", newline="\n") as file:
                    for obj in objects:
                        try:
                            mesh = obj.to_mesh(scene, self.prop_use_mesh_modifiers, 'PREVIEW', calc_tessface=False)
                        except RuntimeError:
                            continue

                        export_mesh(mesh, file, {'use_global_matrix': self.prop_use_global_matrix,
                                                 'global_matrix': global_matrix,
                                                 'use_triangules': self.prop_use_triangles})


            '''
            orig_frame = scene.frame_current

            # Export an animation?
            if self.animation_export_type == 'MA':
                scene_frames = range(scene.frame_start, scene.frame_end + 1)  # Up to and including the end frame.

            if self.animation_export_type == 'NA':
                scene_frames = [orig_frame]  # Dont export an animation.

            # Loop through all frames in the scene and export.
            progress.enter_substeps(len(scene_frames))
            for frame in scene_frames:
                if self.animation_export_type == 'MA':  # Add frame to the filepath.
                    context_name[2] = '_%.6d' % frame

                scene.frame_set(frame, 0.0)
                if self.use_selection:
                    objects = context.selected_objects
                else:
                    objects = scene.objects

                full_path = ''.join(context_name)

                # erm... bit of a problem here, this can overwrite files when exporting frames. not too bad.
                # EXPORT THE FILE.
                progress.enter_substeps(1)
                write_file(full_path, objects, scene,
                           self.use_triangles,
                           self.use_edges,
                           self.use_smooth_groups,
                           self.use_smooth_groups_bitflags,
                           self.use_normals,
                           self.use_uvs,
                           self.materials_export_type,
                           self.use_mesh_modifiers,
                           self.use_blen_objects,
                           self.group_by_object,
                           self.group_by_material,
                           self.keep_vertex_order,
                           self.use_vertex_groups,
                           self.use_nurbs,
                           global_matrix,
                           self.path_mode,
                           progress,
                           )
                progress.leave_substeps()

            scene.frame_set(orig_frame, 0.0)
            '''
            progress.leave_substeps()
            
        return {'FINISHED'}
   
'''   
    def execute(self, context):
        from mathutils import Matrix                                         
        global_matrix = Matrix.Scale(self.global_scale, 4) * axis_conversion(to_forward=self.axis_forward, to_up=self.axis_up).to_4x4()
        if global_matrix is None:
            global_matrix = mathutils.Matrix()

        scene = context.scene

        # Exit edit mode before exporting, so current object states are exported properly.
        if bpy.ops.object.mode_set.poll():
            bpy.ops.object.mode_set(mode='OBJECT')

        objects = context.selected_objects if self.use_selection else scene.objects

        with open(self.filepath, "w", encoding="utf8", newline="\n") as f:
            fw = f.write

            if self.include_vertex_header:
                fw("#import \"%s\"\n\n" % self.include_vertex_header)
            elif self.use_normals:
                fw("typedef struct\n"
                   "{\n"
                   "\tGLfloat vertexPosition[3];\n"
                   "\tGLfloat vertexColor[4];\n"
                   "\tGLfloat normalDirection[3];\n"
                   "\tGLfloat texturePosition[2];\n"
                   "}Vertex;\n\n")
            else:
                fw("typedef struct\n"
                   "{\n"
                   "\tGLfloat vertexPosition[3];\n"
                   "\tGLfloat vertexColor[4];\n"
                   "\tGLfloat texturePosition[2];\n"
                   "}Vertex;\n\n")

            # Tell the obj file what material file to use.
            # if materials_export_type == 'FM':
            #    mtlfilepath = os.path.splitext(filepath)[0] + ".mtl"
            #    # filepath can contain non utf8 chars, use repr
            #    fw('//mtllib %s\n' % repr(os.path.basename(mtlfilepath))[1:-1])

            for obj in objects:
                if obj.parent and obj.parent.dupli_type in {'VERTS', 'FACES'}:
                    continue

                # if use_nurbs and object.type == 'CURVE':
                #   points = object.data.splines.points
                #    continue

                try:
                    me = obj.to_mesh(scene, self.use_mesh_modifiers, 'PREVIEW', calc_tessface=False)
                except RuntimeError:
                    continue

                if self.export_as_scene:
                    me.transform(global_matrix * obj.matrix_world)

                # Triangulation
                import bmesh
                bm = bmesh.new()

                bm.from_mesh(me)
                bmesh.ops.triangulate(bm, faces=bm.faces)
                bm.to_mesh(me)
                bm.free()

                me.calc_normals_split()

                object_name = obj.name.upper().replace(" ", "_")

                if self.use_vertex_indexing:
                    vertex_count = len(me.vertices);
                    fw('const GLuint %s_VERTEX_COUNT = %d;\n' % (object_name, vertex_count))
                    fw('const Vertex %s[%s_VERTEX_COUNT] = {\n' % (object_name, object_name))

                    #for i in range(vertex_count - 1):
                    #   vertex = me.vertices[i]
                    #    #       vertex position     vertex color          normal           texture
                    #    fw('\t{{%.6f, %.6f, %.6f}, {%d, %d, %d, %d}, {%.6f, %.6f, %.6f}, {%.3f, %.3f}},\n', vertex)

                    #last_vertex = me.vertices[vertex_count - 1]
                    #fw('\t{{%.6f, %.6f, %.6f}, {%d, %d, %d, %d}, {%.6f, %.6f, %.6f}, {%.3f, %.3f}}\n};\n\n', last_vertex)

                    vertex_count = len(me.vertices);
                    for i, vertex in enumerate(me.vertices):
                        #       vertex position           vertex color             normal           texture
                        fw('\t{{%.6f, %.6f, %.6f}, {%.3f, %.3f, %.3f, %.3f}, {%.6f, %.6f, %.6f}, {%.3f, %.3f}}' % (
                            vertex.co[0], vertex.co[1], vertex.co[2], 0.0, 0.0, 0.0, 1.0,
                            vertex.normal[0], vertex.normal[1], vertex.normal[2], 0.0, 0.0))
                        if i < vertex_count - 1:
                            fw(',\n')
                        else:
                            fw('\n};\n\n')

                    # loops[l_idx].normal
                    # textures = me.uv_textures[:]

                    # GLubyte
                    # indices[36] = {0, 1, 2, 0, 2, 3,
                    #                0, 3, 4, 0, 4, 5,
                    #                0, 5, 6, 0, 6, 1,
                    #                7, 6, 1, 7, 1, 2,
                    #                7, 4, 5, 7, 5, 6,
                    #                7, 2, 3, 7, 3, 4};

                    indices_count = 0
                    for poly in me.polygons:
                        indices_count += poly.loop_total

                    fw('const GLuint %s_INDICES_COUNT = %d;\n' % (object_name, indices_count))
                    fw('const GLubyte %s_INDICES[%s_INDICES_COUNT] = {\n' % (object_name, object_name))

                    polygons_count = len(me.polygons);
                    for i, polygon in enumerate(me.polygons):
                        array = []
                        for loop_index in range(poly.loop_start, poly.loop_start + poly.loop_total):
                            array.append(str(me.loops[loop_index].vertex_index))

                        fw('\t%s' % ', '.join(array))

                        if i < polygons_count - 1:
                            fw(',\n')
                        else:
                            fw('\n};\n\n')
                else:
                    vertex_count = 0
                    for poly in me.polygons:
                        vertex_count += poly.loop_total

                    fw('const GLuint %s_VERTEX_COUNT = %d;\n' % (object_name, vertex_count))
                    fw('const Vertex %s[%s_VERTEX_COUNT] = {\n' % (object_name, object_name))

                    vertex_counter = 0
                    for poly in me.polygons:
                        for loop_index in range(poly.loop_start, poly.loop_start + poly.loop_total):
                            vertex_counter += 1
                            vertex = me.vertices[me.loops[loop_index].vertex_index]
                            fw('\t{{%.6f, %.6f, %.6f}, {%d, %d, %d, %d}, {%.6f, %.6f, %.6f}, {%.3f, %.3f}}' % (
                                vertex.co[0], vertex.co[1], vertex.co[2], 0.0, 0.0, 0.0, 1.0,
                                vertex.normal[0], vertex.normal[1], vertex.normal[2], 0.0, 0.0))

                            if vertex_counter < vertex_count - 1:
                                fw(',\n')
                            else:
                                fw('\n};\n\n')

        return {'FINISHED'}
'''
        
def name_compat(name):
    if name is None:
        return 'None'
    else:
        return name.replace(' ', '_')
    

def mesh_triangulate(me):
    import bmesh
    bm = bmesh.new()
    
    bm.from_mesh(me)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()


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

def export_mesh(mesh, file, **kwargs):
    if kwargs.use_global_matrix:
        mesh.transform(kwargs.global_matrix * mesh.matrix_world)

    if kwargs.use_triangles:
        import copy
        import bmesh

        bm = bmesh.new()
        mesh = copy.deepcopy(mesh) #TODO: Подумать, нужно ли удалять это объект!

        bm.from_mesh(mesh)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bm.to_mesh(mesh)
        bm.free()

    mesh.calc_normals_split()
    mesh_name = mesh.name.upper().replace(" ", "_")

    file.write('const GLuint %s_VERTEX_COUNT = %d;\n' % mesh_name, len(mesh.vertices))
    file.write('const Vertex %s[%s_VERTEX_COUNT] = {\n' % mesh_name, mesh_name)

    for vertex in mesh.vertices:
        file.write('\t{{%.6(pos_x)f, %.6(pos_y)f, %.6(pos_z)f}, {%(color_r)d, %(color_g)d, %(color_b)d, %(color_a)d},\
                       {%.6(normal_x)f, %.6(normal_y)f, %.6(normal_z)f}, {%.3(texture_u)f, %.3(texture_v)f}},' %
                   {"pos_x": vertex.co[0], "pos_y": vertex.co[1], "pos_z": vertex.co[2],
                    "color_r": 0.0, "color_g": 0.0, "color_b": 0.0, "color_a": 1.0,
                    "normal_x": vertex.normal[0], "normal_y": vertex.normal[1], "normal_z": vertex.normal[2],
                    "texture_u": 0.0, "texture_v": 0.0})

    file.seek(-1, os.SEEK_CUR)
    file.write('\n}\n')


def export_curv(curve, file, **kwargs):
    print(kwargs)


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
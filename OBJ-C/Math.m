#import "Math.h"

@implementation Curve

- (void) set_order: (unsigned int) order;
- (void) use_control_points: (bool) use;

- (GLKMatrix4x4) get_model_matrix;

- (Point3D) get_point: (float) t;

- (Point3D[]) get_line_from: (float) t_start to: (float) t_end with_segments: (unsigned int) count;
- (Point3D[]) get_line_from: (float) t_start to: (float) t_end with_min_angle: (float) angle;

@end
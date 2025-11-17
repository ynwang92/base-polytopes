import numpy as np
from scipy.spatial import ConvexHull
from itertools import product
from math import gcd

def prime(v):
    return gcd(v[0], v[1], v[2]) == 1

def is_point_in_convex_hull(point, hull):
    for eq in hull.equations:
        if np.dot(eq[:-1], point) + eq[-1] > 1e-12:
            return False
    return True

def get_integer_points_in_convex_hull(hull):
    min_bound = np.floor(hull.min_bound).astype(int)
    max_bound = np.ceil(hull.max_bound).astype(int)

    x_range = range(min_bound[0], max_bound[0] + 1)
    y_range = range(min_bound[1], max_bound[1] + 1)
    z_range = range(min_bound[2], max_bound[2] + 1)

    integer_points = []
    for point in product(x_range, y_range, z_range):
        if prime(point) and is_point_in_convex_hull(point, hull):
            integer_points.append(point)

    return np.array(integer_points)

if __name__ == '__main__':
    v1 = np.array([1,0,0], dtype = object)
    v2 = np.array([0,1,0], dtype = object)
    v3 = np.array([0,0,1], dtype = object)
    v4 = np.array([-1,-84,-516], dtype = object)
    vlist = [v1, v2, v3, v4]
    hull = ConvexHull(vlist)
import numpy as np
from scipy.spatial import ConvexHull
import basic
from check import checkn, checkn_non_primitive
from solve3 import solve, solve_lattice 
import convex
import copy
from math import gcd

def toString(vlist):
    string_list = []
    for v in vlist:
        string_list.append('{%d, %d, %d}' % (v[0], v[1], v[2]))
    return '{' + ','.join(string_list) + '}'

def StringToList(s):
    s = s[:-2]
    vlist_str = s.split(' ')
    vlist = []
    for temp in vlist_str:
        v_str = temp[1: -1]
        v1, v2, v3 = int(v_str.split(',')[0]), int(v_str.split(',')[1]), int(v_str.split(',')[2])
        vlist.append(np.array([v1, v2, v3], dtype = object))
    return vlist

def equal(v1, v2):
    return v1[0] == v2[0] and v1[1] == v2[1] and v1[2] == v2[2]

def good_dual_base_v5(vlist):
    if checkn_non_primitive(vlist):
        hull = ConvexHull(vlist)
        if len(hull.vertices) == 5:
            return True
    return False

def has_smaller_box(vlist):
    hull = ConvexHull(vlist)
    points = convex.get_integer_points_in_convex_hull(hull)
    for v in vlist:
        new_point_list = np.array([x for x in points if not equal(v , x)], dtype=object)
        if checkn_non_primitive(new_point_list):
            return True
    return False

def Is_minimal_box_v5(vlist):
    if not good_dual_base_v5(vlist):
        return 'NG'
    if has_smaller_box(vlist):
        return 'NM'
    return 'M'

def primary_explore_3d_v5(fix_vlist: list, bound, step_size):
    out_info_dict = {'NG': 'Not a good G-polytope', 'NM': 'Has smaller polytope', 'M': '*******-------Minimal polytope-------*******'}
    minimal_list = []
    edge_list = []
    for a1 in range(bound):
        for b1 in range(bound):
            for c1 in range(bound):
                for a2 in range(bound):
                    for b2 in range(bound):
                        for c2 in range(bound):
                            vlist = copy.deepcopy(fix_vlist)
                            v4 = np.array([-a1, -b1, -c1], dtype = object)
                            v5 = np.array([-a2, -b2, -c2], dtype = object)
                            vlist.append(v4)
                            vlist.append(v5)
                            print('Checking:' + toString(vlist))
                            check_minimal = Is_minimal_box_v5(vlist)
                            if check_minimal == 'M':
                                if (bound - a1) <= step_size or (bound - b1) <= step_size or (bound - c1) <= step_size or (bound - a2) <= step_size or (bound - b2) <= step_size or (bound - c2) <= step_size:
                                    edge_list.append(vlist)
                                else:
                                    minimal_list.append(vlist)
    return minimal_list, edge_list

def gen_nearby_vlist_3d_v5(step_size, vlist, upperbound):
    v0, v1, v2 = vlist[0], vlist[1], vlist[2]
    v3 = vlist[3]
    v4 = vlist[4]
    a1, b1, c1 = -v3[0], -v3[1], -v3[2]
    a2, b2, c2 = -v4[0], -v4[1], -v4[2]
    nearby_list = []
    for da1 in range(min(step_size + 1, upperbound - a1 + 1)):
        for db1 in range(min(step_size + 1, upperbound - b1 + 1)):
            for dc1 in range(min(step_size + 1, upperbound - c1 + 1)):
                for da2 in range(min(step_size + 1, upperbound - a2 + 1)):
                    for db2 in range(min(step_size + 1, upperbound - b2 + 1)):
                        for dc2 in range(min(step_size + 1, upperbound - c2 + 1)):
                            nearby_list.append([v0, v1, v2, np.array([-(a1 + da1), -(b1 + db1), -(c1 + dc1)], dtype = object), np.array([-(a2 + da2), -(b2 + db2), -(c2 + dc2)], dtype = object)])
    return nearby_list

def id_v5(vlist):
    return '%d-%d-%d-%d-%d-%d' % (-vlist[3][0], -vlist[3][1], -vlist[3][2], -vlist[4][0], -vlist[4][1], -vlist[4][2])

def near_explore_3d_v5(beginning_list, step_size, upperbound):
    waiting_queue = beginning_list
    visited = set()
    for l in waiting_queue:
        visited.add(id_v5(l))
    minimal_list = []
    while waiting_queue:
        vlist = waiting_queue.pop(0)
        vid = id(vlist)
        print('Checking:' + toString(vlist))
        if Is_minimal_box_v5(vlist) == 'M':
            minimal_list.append(vlist)
            new_nearby_list = gen_nearby_vlist_3d_v5(step_size, vlist, upperbound)
            for new_vlist in new_nearby_list:
                nvid = id(new_vlist)
                if nvid not in visited:
                    waiting_queue.append(new_vlist)
                    visited.add(nvid)
    return minimal_list

def auto_search_v5(fix_vlist, primary_bound, final_bound, step_size):
    minimal_primary, edge_list = primary_explore_3d_v5(fix_vlist, primary_bound, step_size)
    minimal_near = near_explore_3d_v5(edge_list, step_size, final_bound)
    minimal_full = minimal_primary + minimal_near
    return minimal_full

if __name__ == '__main__':
    #Similar to 4 vertices case
    bound1, bound2 = 1, 6
    start, end = 1501, 1911
    v123_file_name = 'v123_bound_%d_to_%d.txt' % (bound1, bound2)
    out_filename = '3d_minimal_bound_%d_to_%d_ord_%d_to_%d.txt' % (bound1, bound2, start, end)
    with open(v123_file_name, 'r') as v_file:
        v123list_list_str = v_file.readlines()
        v_file.close()
    with open(out_filename, 'w') as file:
        for i in range(start, end + 1):
            v123list_str = v123list_list_str[i - 1]
            v123list = StringToList(v123list_str)
            print(toString(v123list))
            file.write('------'+ toString(v123list) + '------\n')
            primary_bound = 4
            final_bound = 10
            step_size = 2
            minimal = auto_search_v5(v123list, primary_bound, final_bound, step_size)
            for l in minimal:
                file.write(toString(l) + '\n')
        file.close()

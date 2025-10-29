import numpy as np
from scipy.spatial import ConvexHull
from check import checkn_non_primitive
import convex
import copy
from math import gcd

def equal(v1, v2):
    return v1[0] == v2[0] and v1[1] == v2[1] and v1[2] == v2[2]

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

def good_dual_base(vlist):
    return checkn_non_primitive(vlist)

def has_smaller_box(vlist):
    hull = ConvexHull(vlist)
    points = convex.get_integer_points_in_convex_hull(hull)
    for v in vlist:
        #print(v)
        new_point_list = np.array([x for x in points if not equal(v , x)], dtype=object)
        #print(new_point_list)
        if checkn_non_primitive(new_point_list):
            return True
    return False

def Is_minimal_box(vlist):
    if not good_dual_base(vlist):
        return 'NG'
    if has_smaller_box(vlist):
        return 'NM'
    return 'M'

def primary_explore_3d(fix_vlist: list, bound, step_size):
    out_info_dict = {'NG': 'Not a good G-polytope', 'NM': 'Has smaller polytope', 'M': '*******-------Minimal polytope-------*******'}
    minimal_list = []
    edge_list = []
    # need to specify the first three vertices in advance
    for a in range(bound):
        print('a=%d' % a)
        for b in range(bound):
            for c in range(bound):
                vlist = copy.deepcopy(fix_vlist)
                v4 = np.array([-a, -b, -c], dtype = object)
                vlist.append(v4)
                check_minimal = Is_minimal_box(vlist)
                if check_minimal == 'M':
                    if (bound - a) <= step_size or (bound - b) <= step_size or (bound - c) <= step_size:
                        edge_list.append(vlist)
                    else:
                        minimal_list.append(vlist)
    return minimal_list, edge_list

def gen_nearby_vlist_3d(step_size, vlist, upperbound):
    v0, v1, v2 = vlist[0], vlist[1], vlist[2]
    v3 = vlist[3]
    a, b, c = -v3[0], -v3[1], -v3[2]
    nearby_list = []
    for da in range(min(step_size + 1, upperbound - a + 1)):
        for db in range(min(step_size + 1, upperbound - b + 1)):
            for dc in range(min(step_size + 1, upperbound - c + 1)):
                nearby_list.append([v0, v1, v2, np.array([-(a + da), -(b + db), -(c + dc)], dtype = object)])
    return nearby_list

def id(vlist):
    return '%d-%d-%d' % (-vlist[3][0], -vlist[3][1], -vlist[3][2])

def near_explore_3d(beginning_list, step_size, upperbound):
    #Try to find minimal box in nearby region
    waiting_queue = beginning_list
    visited = set()
    for l in waiting_queue:
        visited.add(id(l))
    minimal_list = []
    while waiting_queue:
        vlist = waiting_queue.pop(0)
        vid = id(vlist)
        if Is_minimal_box(vlist) == 'M':
            #print(vlist[3])
            minimal_list.append(vlist)
            new_nearby_list = gen_nearby_vlist_3d(step_size, vlist, upperbound)
            for new_vlist in new_nearby_list:
                #print(new_vlist)
                nvid = id(new_vlist)
                if nvid not in visited:
                    waiting_queue.append(new_vlist)
                    visited.add(nvid)
    return minimal_list

def auto_search(fix_vlist, primary_bound, final_bound, step_size):
    minimal_primary, edge_list = primary_explore_3d(fix_vlist, primary_bound, step_size)
    print('Primary completed')
    minimal_near = near_explore_3d(edge_list, step_size, final_bound)
    print('Full completed')
    minimal_full = minimal_primary + minimal_near
    return minimal_full

if __name__ == '__main__':
    #m = bound
    m = 6
    #choose the starting & ending id in the list of first three vertices
    start, end = 1, 1086
    v123_file_name = 'v123_max_%d.txt' % m
    out_filename = '3d_minimal_max_%d.txt' % (m)
    with open(v123_file_name, 'r') as v_file:
        v123list_list_str = v_file.readlines()
        v_file.close()
    with open(out_filename, 'w') as file:
        for i in range(start, end + 1):
            v123list_str = v123list_list_str[i - 1]
            v123list = StringToList(v123list_str)
            print(toString(v123list))
            file.write('------'+ toString(v123list) + '------\n')
            primary_bound = 10
            final_bound = 50
            step_size = 6
            minimal = auto_search(v123list, primary_bound, final_bound, step_size)
            for l in minimal:
                file.write(toString(l) + '\n')
        file.close()
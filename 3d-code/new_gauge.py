import numpy as np
from scipy.spatial import ConvexHull
from scipy.spatial._qhull import QhullError
from basic import divisor, sign, insiden
from solve3 import solve, solve_lattice
from check import primitive

#To get the points inside a given polytope
def gen_inside_points(vlist):
    hull = ConvexHull(vlist)
    facets = hull.simplices
    ineqs = []
    for facet in facets:
        v1, v2, v3 = vlist[facet[0]], vlist[facet[1]], vlist[facet[2]]
        a, b = v2 - v1, v3 - v1
        norm = np.array([a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]], dtype = object)
        offset = -np.dot(v1, norm)
        if offset > 10 ** (-10):
            ineqs.append(np.array([offset, norm[0], norm[1], norm[2]], dtype = object))
        elif offset < -10 ** (-10):
            ineqs.append(np.array([-offset, -norm[0], -norm[1], -norm[2]],dtype = object))
    #print(ineqs)
    solutions = [s[1:] for s in solve(ineqs, 3)]
    inside_points = []
    for solution in solutions:
        inside_points.append(solution)
    return inside_points

#generate the primitive rays in a polytope
def gen_rays(vlist):
    hull = ConvexHull(vlist)
    facets = hull.simplices
    #print(facets)
    ineqs = []
    for facet in facets:
        v1, v2, v3 = vlist[facet[0]], vlist[facet[1]], vlist[facet[2]]
        a , b = v2 - v1, v3 - v1
        norm = np.array([a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]], dtype = object)
        offset = -np.dot(v1, norm)
        if offset > 10**(-10):
            ineqs.append(np.array([offset, norm[0], norm[1], norm[2]], dtype = object))
        elif offset<-10**(-10):
            ineqs.append(np.array([-offset, -norm[0], -norm[1], -norm[2]], dtype = object))
    #print(ineqs)
    solutions = [s[1:] for s in solve(ineqs, 3)]
    rays = []
    for solution in solutions:
        if primitive(solution):
            rays.append(solution)
    return rays

#compute vanishing order
def order(ray , poly_vertices_list: list , offset):
    min_us = []
    my_order = 10 ** (9)
    for u in poly_vertices_list:
        cur = np.dot(ray, u) + offset
        if cur < my_order:
            my_order = cur
            min_us = [u]
        elif cur == my_order:
            min_us.append(u)
    return my_order, min_us

#compute the gauge factor of rays in a given polytope
def determine_gauge(vlist):
    gauge = {'SU2':0,'SU3':0,'G2':0,'SO7':0,'SO8':0,'F4':0,'E6':0,'E7':0,'E8':0}
    fpoly = solve_lattice(vlist, 4)
    gpoly = solve_lattice(vlist, 6)
    try:
        fhull = ConvexHull(fpoly)
        fpoly_vertices_list = [fhull.points[_] for _ in fhull.vertices]
    except QhullError:
        x = fpoly[0][0]
        fpoly_yz = [s[1:] for s in fpoly]
        fhull = ConvexHull(fpoly_yz)
        fpoly_yz_vertices_list = [fhull.points[_] for _ in fhull.vertices]
        fpoly_vertices_list = [np.array([x, _[0], _[1]], dtype = object) for _ in fpoly_yz_vertices_list]
    ghull = ConvexHull(gpoly)
    gpoly_vertices_list = [ghull.points[_] for _ in ghull.vertices]
    rays = gen_rays(vlist)
    for ray in rays:
        ordf, vecf = order(ray, fpoly_vertices_list, 4)
        ordg, vecg = order(ray, gpoly_vertices_list, 6)
        if ordf == 1 and ordg >= 2:
            gauge['SU2'] += 1
        elif ordf>=2 and ordg == 2:
            if len(vecg) == 1 and divisor(vecg[0]) % 2 == 0:
                gauge['SU3'] += 1
            else:
                gauge['SU2'] += 1
        elif ordf >= 3 and ordg == 4:
            if len(vecg) == 1 and divisor(vecg[0]) % 2 == 0:
                gauge['E6'] += 1
            else:
                gauge['F4'] += 1
        elif ordf == 3 and ordg >= 5:
            gauge['E7']+=1
        elif ordf >= 4 and ordg == 5:
            gauge['E8'] += 1
        elif ordf == 2 and ordg >= 4:
            if len(vecf) == 1 and divisor(vecf[0]) % 2 == 0:
                gauge['SO8'] += 1
            else:
                gauge['SO7'] += 1
        elif ordf >= 3 and ordg == 3:
            if len(vecg) == 1 and divisor(vecg[0]) % 3 == 0:
                gauge['SO8'] += 1
            else:
                gauge['G2'] += 1
        elif ordf == 2 and ordg == 3:
            if ((len(vecf) + len(vecg) == 2 and divisor(vecf[0]) % 2 == 0) and divisor(vecg[0])%3 == 0):
                gauge['SO8'] += 1
            else:
                gauge['G2'] += 1
    return gauge

if __name__ == '__main__':
    print('----------test gauge.py----------')
    #test codes
    v1 = np.array([-6, -6, 1],dtype=object)
    v2 = np.array([-6, 37, -6],dtype=object)
    v3 = np.array([188, 14, -3],dtype=object)
    v4 = np.array([503, 23, -6],dtype=object)
    v5 = np.array([20, 17, -6],dtype=object)
    v6 = np.array([1119, -4, -4],dtype=object)
    v7 = np.array([436, -3, -6],dtype=object)
    v8 = np.array([573, -4, -5],dtype=object)
    v9 = np.array([614, -3, -2],dtype=object)
    v10 = np.array([110, -3, -3],dtype=object)
    v11 = np.array([765, 2, -6],dtype=object)
    v12 = np.array([1299, -5, -5],dtype=object)
    v13 = np.array([219, 1, -6],dtype=object)
    #vlist=[v5,v6,v7,v8,v9,v10]
    vlist = [v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13]
    #rays=gen_rays(vlist)
    gauge = determine_gauge(vlist)
    #print(rays)
    print(gauge)
    print('----------test gauge.py end----------')

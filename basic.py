import numpy as np
from math import gcd
from scipy.spatial import ConvexHull

# Determine the gcd of components for a given vertex
def divisor(v):
    return gcd(int(v[0]), int(v[1]), int(v[2]))

# Control the error
def sign(x):
    if abs(x) <= 10 ** (-7):
        return 0
    elif x > 0:
        return 1
    return -1

# The cross product for two vertices
def cross(a, b):
    return np.array([a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]],dtype = object)

#Determine whether a point p are in the plane defined by three vertices v1v2v3
def coplanar(v1, v2, v3, p):
    norm = cross(v2 - v1, v3 - v1)
    if abs(np.dot(p - v1, norm)) < 10 ** (-7):
        return True
    return False

#Judge whether p and v4 are in the same side of the plane defined by three vertices v1v2v3
def sameside(v1, v2, v3, v4, p):
    norm = cross(v2-v1,v3-v1)
    return sign(np.dot(v4 - v1, norm)) == sign(np.dot(p - v1, norm))

#Judge whether p and v4 are in the same side of the plane defined by three vertices v1v2v3, or p or v4 are in the plane
def NotWrongSide(v1, v2, v3, v4, p):
    norm = cross(v2 - v1, v3 - v1)
    return sign(np.dot(v4 - v1, norm)) == sign(np.dot(p - v1, norm)) or sign(np.dot(p - v1, norm)) * sign(np.dot(v4 - v1, norm)) == 0

#Determine where a point is inside a given polytope. If the point is on a facet, still return True
def insiden(vertices, facets, point):
    for i in range(len(facets)):
        # Check whether point and another point(test point) in the polytope are in two sides of a facet
        p = 999
        # Try to look for another point in the polytope as a test point
        for j in range(len(vertices)):
            if j == facets[i][0] or j == facets[i][1] or j == facets[i][2]:
                continue
            normal = cross(vertices[facets[i][1]] - vertices[facets[i][0]], vertices[facets[i][2]] - vertices[facets[i][0]])
            if abs(np.dot(normal, vertices[j] - vertices[facets[i][0]])) >= 10 ** (-7):
                p = j
                break
        if not NotWrongSide(vertices[facets[i][0]], vertices[facets[i][1]], vertices[facets[i][2]], vertices[p], point):
            return False
    return True

#Determine where a point is inside a given polytope. If the point is on a facet, return False
def interiorn(vertices,facets,point):
    for i in range(len(facets)):
        p = 999
        for j in range(len(vertices)):
            if j == facets[i][0] or j == facets[i][1] or j == facets[i][2]:
                continue
            normal = cross(vertices[facets[i][1]] - vertices[facets[i][0]], vertices[facets[i][2]] - vertices[facets[i][0]])
            if abs(np.dot(normal, vertices[j] - vertices[facets[i][0]])) >= 10**(-7):
                p = j
                break
        if not sameside(vertices[facets[i][0]], vertices[facets[i][1]], vertices[facets[i][2]], vertices[p], point):
            return False
    return True

if __name__ == '__main__':
    print('----------test basic.py----------')
    #test codes
    v1 = np.array([-6, -6, -6], dtype = object)
    v2 = np.array([3606, -6, -6], dtype = object)
    v3 = np.array([-6, 37, -6], dtype = object)
    v4 = np.array([-6, -6, 1], dtype = object)
    vlist = [v1, v2, v3, v4]
    o = np.array([-6, 35, -5])
    hull = ConvexHull(vlist)
    vert = hull.points
    facets = hull.simplices
    #print(np.dot(norm,v3-v1))
    print(insiden(vert, facets, o))
    print('----------test basic.py end----------')
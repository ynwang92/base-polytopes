import numpy as np
from sympy import Matrix
from sympy.matrices.normalforms import hermite_normal_form

def toString(vlist):
    s = ''
    for v in vlist:
        s += (str(v[0]) + str(v[1]) + str(v[2]))
    return s

import itertools

def generate_permutations(n):
    numbers = list(range(1, n+1))
    permutations = list(itertools.permutations(numbers))
    return permutations

def hermite_normal_form(A):
    A = A.copy()
    m, n = A.shape
    row = 0
    for col in range(n):
        pivot_row = None
        for r in range(row, m):
            if A[r, col] != 0:
                if pivot_row is None or abs(A[r, col]) < abs(A[pivot_row, col]):
                    pivot_row = r
        if pivot_row is None:
            continue
        if pivot_row != row:
            A[[row, pivot_row]] = A[[pivot_row, row]]
        pivot = A[row, col]
        for r in range(m):
            if r != row and A[r, col] != 0:
                q = A[r, col] // pivot
                A[r] -= q * A[row]
        row += 1
        if row == m:
            break
    for i in range(min(m, n)):
        if A[i, i] < 0:
            A[i] *= -1
    return A


def H_perm(vlist, perm_list, n):
    li = []
    for p in perm_list:
        new = []
        for i in range(n):
            new.append(vlist[p[i] - 1])
        m = np.matrix(new).transpose()
        Hm = hermite_normal_form(m)
        Hm_list = [[Hm[0, c], Hm[1, c], Hm[2, c]] for c in range(n)]
        li.append(toString(Hm_list))
    return li

def check_perm(filename, outfilename, perm_list, n):
    with open(filename, 'r') as file:
        lines = file.readlines()
        file.close()
    pset = []
    goodbase = []
    for i in range(len(lines)):
        line_str = lines[i][2:-3].split('},{')
        print(line_str)
        vlist = []
        for j in range(n):
            vlist.append([int(line_str[j].split(',')[0]), int(line_str[j].split(',')[1]), int(line_str[j].split(',')[2])])
        perm_vlist = H_perm(vlist, perm_list, n)
        flag = True
        for p in perm_vlist:
            if p in pset:
                flag = False
                break
        if flag:
            goodbase.append(lines[i])
            pset += perm_vlist
    print(goodbase)
    with open(outfilename, 'w') as outfile:
        for g in goodbase:
            outfile.write(g)
        outfile.close()
    return goodbase


n = 4
perm_list = generate_permutations(n)
check_perm('full_minimal_test.txt', 'full_minimal_perm_test.txt', perm_list, n)
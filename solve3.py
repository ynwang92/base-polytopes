import numpy as np
import math

#To control error
def reduce(x: float):
    if abs(x - math.ceil(x)) < 10**(-10):
        return math.ceil(x)
    elif abs(x - math.floor(x)) < 10**(-10):
        return math.floor(x)
    return x

#Classify inequations by the sign of the nth coefficient
def classify(ineqs, n):
    upper, lower, none = [], [], []
    for ineq in ineqs:
        initial = reduce(ineq[n])
        if initial > 0:
            lower.append(ineq)
        elif initial < 0:
            upper.append(ineq)
        else:
            none.append(ineq)
    return upper, lower, none

# Decrease number of unknowns by 1
def decompose(ineqs,n):
    new_ineqs = []
    upper, lower, none = classify(ineqs, n)
    for up in upper:
        for low in lower:
            new_ineqs.append(low[n] * up[:-1] - up[n] * low[:-1])
    for no in none:
        new_ineqs.append(no[:-1])
    return new_ineqs

#Substitute the solved variables
def substitute(ineqs, solution, n):
    upper, lower, none = classify(ineqs,n)
    upperbound = min([-np.dot(solution, up[:-1])/up[-1] for up in upper])
    lowerbound = max([-np.dot(solution, low[:-1])/low[-1] for low in lower])
    return reduce(upperbound),reduce(lowerbound)

#main function
def solve(ineqs, n):
    if n==1:
        upper,lower,none = classify(ineqs,n)
        upperbound = min([-up[0]/up[n] for up in upper])
        lowerbound = max([-low[0]/low[n] for low in lower])
        return [np.array([1, i], dtype = object) for i in range(math.ceil(reduce(lowerbound)), math.floor(reduce(upperbound)) + 1)]
    else:
        new_ineqs = decompose(ineqs, n)
        solutions = solve(new_ineqs, n - 1)
        new_solutions = []
        for solution in solutions:
            upperbound, lowerbound = substitute(ineqs, solution, n)
            for i in range(math.ceil(lowerbound), math.floor(upperbound) + 1):
                new_solutions.append(np.append(solution, i))
        return new_solutions

#solve the dual polytope, offset = 4 for F-polytope, =6 for G-polytope
def solve_lattice(vlist, offset):
    ineqs = []
    for v in vlist:
        ineq = np.insert(v, 0, offset)
        ineqs.append(np.array(ineq, dtype = object))
    return [s[1:] for s in solve(ineqs, 3)]

if __name__ == '__main__':
    #test codes
    print('----------test solve3.py----------')
    v1 = np.array([1,0,0],dtype=object)
    v2 = np.array([0,1,0],dtype=object)
    v3 = np.array([0,0,1],dtype=object)
    v4 = np.array([-1,-84,-516],dtype=object)
    vlist = [v1, v2, v3, v4]
    solution = solve_lattice(vlist, 6)
    i = 0
    for s in solution:
        if math.gcd(s[0], s[1], s[2]) == 1:
            i += 1
    print(i)
    print('----------test solve3.py end----------')
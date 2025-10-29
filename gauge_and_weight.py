import numpy as np
from math import log10 as lg
from math import factorial as f
from new_gauge import determine_gauge

#compute the weight factor
def weight(h11,n,m,N,fix,R):
    logw = (n - fix) * lg(R) - lg(N) - (n - m) * lg(h11 + fix + 3 - m) - lg(f(n - fix)) + lg(f(n - m))
    return 10 ** logw

#Parameters:file_type = 'l'(large) or 'm'(medium) or 's'(small) or 't'(tiny)
file_type = 's'
n = 30
#R = number of primitive rays
R = 91504
filename = '3dn%d%cnew-fix2.txt' % (n, file_type)
with open(filename,'r') as my_file:
    lines = my_file.readlines()
    print(filename)
    my_file.close()
N = len(lines)
for i in range(len(lines)):
    line = lines[i]
    print('{', end='')
    raw_vlist = line[:-1].split(' ')[1][1: -1]
    vlist = []
    for vv in raw_vlist.split(')('):
        v0 = vv.split(',')
        vlist.append(np.array([int(_) for _ in v0], dtype = object))
    print('{', end = '')
    for j in range(len(vlist)):
        v = vlist[j]
        print('{' + str(v[0]) + ',' + str(v[1]) + ',' + str(v[2]) + '}',end = '')
        if j != len(vlist) - 1:
            print(',',end = '')
    print('}', end = ',')
    h11 = int(line.split(' ')[3].split('=')[1])
    print(h11, end = ',')
    print('{', end = '')
    gauge=determine_gauge(vlist)
    #gauge = {'SU2':1,'SU3':2,'G2':3,'SO7':4,'SO8':5,'F4':6,'E6':7,'E7':8,'E8':9}
    print(str(gauge['SU2']) + ',' + str(gauge['SU3']) + ',' + str(gauge['G2']) + ',' + str(gauge['SO7']) + ',' + str(gauge['SO8']) + ',' + str(gauge['F4']) + ',' + str(gauge['E6']) + ',' + str(gauge['E7']) + ',' + str(gauge['E8']),end = '')
    print('}', end = ',')
    m = int(line.split(' ')[2])
    w = weight(h11, n, m, N, 2, R)
    print('{:.2e}'.format(w), end = '')
    print('}')

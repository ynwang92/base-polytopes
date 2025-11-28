# base-polytopes
Codes and data for 2509.13252



Files for 2d Monte Carlo program
*****
2d/MonteCarlo-2D.nb
The program of 2d Monte Carlo of random polytopes in a fixed box, in Mathematica. 
In the function MonteCarlon, the first parameter is the set of points to choose from, for example rays[LIST] generates all primitive points in the convex hull of LIST. 
The second parameter denote the set of points that are always chosen in the random polytope . 
The third parameter is n, the number of randomly chosen points. 
The fourth parameter is the number of samplings. 
The fifth parameter controls whether to compute the number of each gauge groups on the base polytope, which are listed in the order of (SU (2), SU (3), G2, SO (7), SO (8), F4, E6, E7, E8). 
The sixth parameter asks if the set of points in the first parameter are contained in a maximal box dual to a minimal G - polytope, otherwise one should input False and check the G-polytope condition. 
Increasing the seventh parameter would increase the number of GL(2, Z) elements used to check the GL (2, Z) redundancy in the fixed box, getting a more accurate weight factor.
*****
2d/2d-k=5.zip.001~2d/2d-k=5.zip.005
The data for Monte Carlo approach in 2d k=5 polytopes dual to P2, F0, F2,..., F10, listed in Table 4 of 2509.13252. The output data are the list of sampled points, h^{1,1}(B), weight factors.
*****
2d/2d-k=6.zip.001~2d/2d-k=6.zip.005
The data for Monte Carlo approach in 2d k=6 polytopes dual to P2, F0, F2,..., F12, listed in Table 1 of 2509.13252. The output data are the list of sampled points, h^{1,1}(B), weight factors.



Files for 3d Monte Carlo program
*****
3d-G-polytopes.txt
The list of 4553 minimal 3d G polytopes , after one compute the dual polytope B={v|<u,v>>=-6, v\in G}, the dual polytope B are the maximal 3d boxes in which we sample the points. Each line contains the vertices of each G polytope.
*****
basic.py
Basic functional programs. Function insiden is used to check whether a point is in the polytope defined by given vertices. Function interiorn is used to check whether a point is in the interior part of the polytope defined by given vertices. If the point lies on the boundary, then insiden with return True while interiorn will return False.
*****
check.py
Programs to determine whether a given polytope is a good polytope, that is , whether the dual polytope contains the origin in the interior. Function checkn will further check whether the vertices of polytope are all primitive rays(gcd of components equals 1). In the function checkn and checkn_non_primitive, the parameter is a list of vertices of the polytope to be checked. 
*****
solve3.py
The programs to solve the dual polytope. 
In the function solve_lattice, the first parameter is the list of vertices of polytope.
The second parameter offset determines the type of dual polytope. It is defined by the parameter n in the definition of dual polytope B={v|<u,v>>=-n, v\in G}. 
*****
fix_check.py
The programs to do the Monte Carlo in a given box. 
In the function run, the first parameter is the total number of samples. 
The second parameter is the number of points you randomly choose in the given box. 
Moreover, there are two places that need to fix by hand.
In line 27 and 28, you should fix some vertices by hand to increase the efficiency. Fixed points can be changed at this place, and update the fixed point list in line 32.
In line 30, the txt file for list of primitive rays should be given in advance. It is the list of all primitive rays in the box. The txt file should contain several lines. Each line stands for a primitive ray, and in the form of three coordinate seperated by space like "a b c".
*****
new_gauge.py
The programs to compute the gauge groups for a given polytope. 
In the function determine_gauge, the parameter is the list of vertices for the polytope. The output is a dictionary-type object with gauge group type as key and number of corresponding gauge group as value. 
*****
3d_minimal_local_file.py
The programs to look for the minimal box with four vertices in a given region.
In the function auto_search, the first parameter is a list of all choices for the first three vertices called fixed list. 
The second parameter is an integer called primary bound. The program will enumerate all the points (-a, -b, -c) with 0 <= a,b,c < primary bound. Then adding them to the list of fixed list to form a g polytope and find minimal ones among them. 
The third parameter is an integer called final bound. After finding all minimal G polytopes in primary bound, the program will try to look for more minimal G polytopes in final bound by try to consider nearby G polytopes of the minimal  G polytopes we already found. 
The fourth parameter controls the size of nearby regions mentioned above. 
*****
3d_minimal_v5_local_file.py
The programs to look for the minimal box with five vertices in a given region.
The function auto_search_v5 is similar to the four vertices case.
*****
permutational_vn.py
The programs to check and remove the permutational redundancy.
In the function check_perm, the first parameter is the txt file name of the polytope list. Each line stands for a polytope. The polytopes are presented in vertices in an array like "{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {0, -1, -1}, {-1, 0, -1}}". 
The second parameter is the name of the output file that contains all the different polytopes after removing permutational redundancy. 
The third parameter is the list of full permutational list of numbers from 1 to n. That can be generated by function generate_permutations.
The fourth parameter is the number of vertices for the polytope.  
*****
MonteCarlo3d-[type].7z
The data for Monte Carlo approach in 3d polytopes. Different types are,
large: R = 181203
medium: R = 136247
small: R = 91504
tiny: R = 46665(The list of tiny samples are seperated into two parts due to the file size)
The output data are the list of sampled points, h^{1,1}(B), weight factors.
*****
3d_gauge+weight_[type].7z
The data for gauge groups and weight factors for good 3d polytopes. Different types are named similarly as above. each line stands for a good polytope. Information of the polytope are arranged in the form {{vertices}, h^{1,1}(B),{gauge groups(order:SU2,SU3,G2,SO7,SO8,F4,E6,E7,E8),weight factor}}.

--------------------------------------------------------------------
--------------------------------------------------------------------

Code for exact computation of 2D polytopes in 2d-code subdirectory, further documentation also in readme.txt file there (including some info about how to run julia code easily), reproduced here


The julia code generates the 2d bases in 2 independent ways, one
"top-down" from the largest polytopes and the other "bottom up" from
the smallest polytopes.


-------------------------------------------------------------------


generate.jl: produces all 2D bases starting with the minimal bases P2,
Hirzebruch F_n.  Starts with 2D polytopes P2 and Hirzebruch surfaces
0-2k, and at each number of rays x produces a collection of all 2D
polytopes with x rays iteratively by taking the collection at x -1,
blowing up in all positions, and checking the resulting polytope is
acceptable (k-dual restricted to integers is a polytope containing the
origin).

Arguments:

--max value of x to stop at
--k value of k (ranging from 1 to 6, 6 gives all valid bases, smaller
  k gives a more tractable set with similar properties)
--directory where to put the results

Output files:

collection-x:  Collection of all the bases at size x (x toric rays),
listed by intersection numbers

terminal-x.m: Terminal bases that cannot be blown up further to get a
good base

sizes.m: The number of distinct bases at each size

----------------------------------------------------------

down.jl: produces all 2D bases starting from the k-dual of a given
minimal base m, which gives a maximal box.  For a given value of k,
allowed values for m are 0--2k (Hirzebruch surfaces) or m = 13 (P2).
Starting from the maximal box, removes one vertex at a time, getting
all polytopes contained within that box, and keeps a list of distinct
polytopes identified in canonical form (lowest lexicographic form of
all versions under rotation and reflection).

Arguments:

--m Which maximal box to start with (0--13: dual of Hirzebruch or P2)
--k value of k
--directory where to put the results
--final where to stop (i.e. minimal number of rays to compute at,
--should be n =3 if you want to get everything)

Output files:

blowdown-collection-kx-my-nz: auxiliary file that keeps track of
intermediate collections with information about which rays can be
blown down; this is not useful for end results but needed for the
software to work.

blowdown-canonical-kx-my-nz:  A list of distinct bases that appear
contained within the maximal box from m = y, at k = x, with n = z
rays.  Includes multiplicity of times that this base appears within
that box (different SL(2, Z) copies)

blowdown-sizes-kx-my.m: summary statistics on the number of bases with
each number of rays n from a particular starting box m = y


--------------------------------------------------------

combine.jl: combines output from down.jl with different values of m to
give a combined statistic on the number of bases with each number of
rays n.

Arguments: directory containing the output files from down.jl

Output files:

blowdown-multiplicities-k x.m: produces a list of the number of bases
for each number of rays n.  If all the code is working this should be
the same as sizes.m from generate.jl

summary-kx.m: the total number of bases contained in each box m

---------------------------------------------------------

Bottom line: if you run all the code as above for any given value of
k, running generate.jl once, and down.jl 2k +2 times with m = 0,... 2
k, 13, and then run combine.jl as above you should get answers from
both sets of code that agree in the files sizes.m and summary-kx.m.

Example output files from k = 1 from the runs above (and also runs of
down.jl for m = 0, 1, 2, 13 before running combine.jl) are included.



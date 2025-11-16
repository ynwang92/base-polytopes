# base-polytopes
Codes and data for 2509.13252

Code for exact computation of 2D polytopes in 2d-code subdirectory, further documentation there.



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





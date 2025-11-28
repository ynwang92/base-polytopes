This directory contains a julia package to compute all 2D bases
systematically, generalized to arbitrary k,for the paper "Statistics
of Base Polytopes in F-theory" by Taylor, Wang, and Yu.

The julia code generates these bases into independent ways, one
"top-down" from the largest polytopes and the other "bottom up" from
the smallest polytopes.

Code by WT, with some help from Claude.
----------------------------------------------------

If you are familiar with julia packages you can install this package
in whatever way you are familiar with on your machine.  A basic
approach, however, is the following.  First, make sure julia is
installed.  Then, from this directory, you can run the code in the
following example ways: (only basic usage is documented and verified
here, there are some fancier things that the code can do which is
documented in the code; note that the optional checkpointing process in
down.jl is not guaranteed to work; that is not needed for any of the
results in the paper)

$ julia --project=./ ./ToricBases/bin/generate.jl --max 10 --k 1 --directory test-g

$ julia --project=./ ./ToricBases/bin/down.jl --m 0 --k 1 --directory test-d --final 3

$ julia --project=./ ./ToricBases/bin/combine.jl -d test-d 1

------------------------------------------------------------------

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

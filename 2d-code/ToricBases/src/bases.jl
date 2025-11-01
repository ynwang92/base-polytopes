# bases.jl

using Base: @kwdef

"""
    BaseCollection

Represents a collection of toric bases with the same intersection length.
Uses canonical forms to eliminate redundancy under symmetries.

Fields:
- bases::Set{Vector{Int32}}: Set of intersection sequences in canonical form
- intersection_length::Int32: Length of intersection sequences in this collection
"""
struct BaseCollection
    bases::Set{Vector{Int32}}
    intersection_length::Int32
    
    # Inner constructor to enforce invariants
    function BaseCollection(intersection_length::Integer)
        intersection_length >= 3 || throw(ArgumentError("Intersection length must be ≥ 3"))
        new(Set{Vector{Int32}}(), Int32(intersection_length))
    end
end

"""
    add_if_new!(collection::BaseCollection, intersections::Vector{Int32})

Attempts to add a new intersection sequence to the collection.
Returns true if the sequence was new and added, false if already present.

Note: Assumes intersections is already in canonical form for efficiency.
"""
function add_if_new!(collection::BaseCollection, intersections::Vector{Int32})
    length(intersections) == collection.intersection_length || 
        throw(ArgumentError("Wrong intersection length"))
    
    if intersections ∉ collection.bases
        push!(collection.bases, intersections)
        return true
    end
    return false
end

"""
    base_size(collection::BaseCollection)

Returns the number of distinct bases in the collection.
"""
base_size(collection::BaseCollection) = length(collection.bases)

"""
    get_bases(collection::BaseCollection)

Returns an iterator over all bases in the collection.
"""
get_bases(collection::BaseCollection) = collection.bases

"""
    initialize_collection(n::Integer)

Creates an initial collection for intersection length n.
For n=3, includes only CP², 
For n = 4, includes some Hirzebruch surfaces,
for other n returns empty collection.
"""
function initialize_collection(n::Integer, k::Integer)
    collection = BaseCollection(n)
    
    if n == 3
        # CP² case
        add_if_new!(collection, Int32[1, 1, 1])
    elseif n == 4
        # Hirzebruch surfaces F_m for m ≤ 2k
        # m = 0 case
        add_if_new!(collection, Int32[0, 0, 0, 0])
        # m > 0 cases, using canonical form [-m, 0, m, 0]
        for m in 1:(2*k)
            add_if_new!(collection, Int32[-m, 0, m, 0])
        end
    end
    
    return collection
end

# adding new structures for blowing down

# Additional structures for blowdown process

"""
    BlowdownBase

Represents a specific geometric realization of a base obtained by removing vertices
from an initial maximal base.

Fields:
- active_rays::BitVector: Efficient storage of which original rays are present
- vertices::Vector{Int32}: Current vertex indices into original rays
- lower_bound::Int32: Lower vertex index already considered for removal (-1 if none)
- upper_bound::Int32: Upper vertex index already considered for removal (-1 if none)
"""
struct BlowdownBase
    active_rays::BitVector
    vertices::Vector{Int32}
    lower_bound::Int32
    upper_bound::Int32
    
    # Constructor
    function BlowdownBase(active::BitVector, verts::Vector{Int32}, 
                         lower::Integer = -1, upper::Integer = -1)
        length(active) >= length(verts) || 
            throw(ArgumentError("Active rays vector must be at least as long as vertex list"))
        all(v -> 1 <= v <= length(active), verts) ||
            throw(ArgumentError("Vertex indices must be within bounds"))
        new(active, convert(Vector{Int32}, verts), 
            Int32(lower), Int32(upper))
    end
end

"""
    BlowdownCollection

Collection of bases at a given ray count level, derived from an initial maximal base.

Fields:
- initial_rays::Vector{Tuple{Int32,Int32}}: Complete set of rays from initial k-dual
- n_initial::Int32: Number of rays in initial configuration
- bases::Set{BlowdownBase}: Current set of geometric realizations
- ray_count::Int32: Current number of rays (n)
"""
struct BlowdownCollection
    initial_rays::Vector{Tuple{Int32,Int32}}  # note the double closing brackets
    n_initial::Int32
    bases::Set{BlowdownBase}
    ray_count::Int32
    
    # Inner constructor for initial collection
    function BlowdownCollection(rays::Vector{Tuple{Int32,Int32}}, n::Integer)
        n_init = Int32(length(rays))
        n >= 3 || throw(ArgumentError("Number of rays must be ≥ 3"))
        n <= n_init || throw(ArgumentError("Current ray count must not exceed initial"))
        new(rays, n_init, Set{BlowdownBase}(), Int32(n))
    end
end

"""
    add_base!(collection::BlowdownCollection, base::BlowdownBase)

Add a new base to the collection. Returns true if the base was new and added,
false if already present.
"""
function add_base!(collection::BlowdownCollection, base::BlowdownBase)
    count(base.active_rays) == collection.ray_count || 
        throw(ArgumentError("Base has wrong number of active rays"))
        
    if base ∉ collection.bases
        push!(collection.bases, base)
        return true
    end
    return false
end

"""
    base_count(collection::BlowdownCollection)

Returns the number of distinct geometric realizations in the collection.
"""
base_count(collection::BlowdownCollection) = length(collection.bases)

"""
    get_bases(collection::BlowdownCollection)

Returns an iterator over all bases in the collection.
"""
get_bases(collection::BlowdownCollection) = collection.bases


# Export needed symbols
export BaseCollection, add_if_new!, base_size, get_bases, initialize_collection,
       # Export the new symbols
       BlowdownBase, BlowdownCollection, add_base!, base_count



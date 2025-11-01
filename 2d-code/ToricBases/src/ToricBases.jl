module ToricBases

# using Polymake
using StaticArrays

# Include our component files
include("bases.jl")
include("geometry.jl")
include("io.jl")

test_revise() = println("test 2")

# Re-export all the functions we want to make available

# Re-export all the functions we want to make available
export BaseCollection, base_size, get_bases, initialize_collection,    # original from bases.jl
       BlowdownBase, BlowdownCollection, add_base!, base_count,       # new from bases.jl
       
       compute_new_intersections, canonical, generate_rays,           # original from geometry.jl
       check_lattice_properties, process_base_collection,
       initialize_blowdown_collection, compute_removed_vertex_base,   # new from geometry.jl
       compute_intersection_sequence, is_valid_base,
       analyze_canonical_forms, process_collection_down,
       
       initialize_size_file, append_size_to_mathematica_file,        # original from io.jl
       save_collection, load_collection,
       save_terminal_bases, consolidate_terminal_bases,
       save_blowdown_collection, load_blowdown_collection,           # new from io.jl
       save_canonical_forms
       
end # module

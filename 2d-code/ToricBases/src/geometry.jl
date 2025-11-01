# geometry.jl

#using Polymake
#const Polytope = Polymake.polytope

"""
    compute_new_intersections(old_intersections::Vector{Int32}, i::Integer) -> Vector{Int32}

Compute new intersection numbers after blowing up at position i.
Returns a new vector with length increased by 1.
"""
function compute_new_intersections(old_intersections::Vector{Int32}, i::Integer)
    n = length(old_intersections)
    1 ≤ i ≤ n || throw(ArgumentError("Invalid position $i for length $n"))
    
    # Create new array with space for n+1 elements
    new_I = Vector{Int32}(undef, n + 1)
    
    # Copy old values
    copyto!(new_I, 1, old_intersections, 1, i-1)
    copyto!(new_I, i+1, old_intersections, i, n-i+1)
    
    # Insert -1 at position i
    new_I[i] = -1
    
    # Decrease adjacent values (with periodic boundary)
    left = mod1(i-1, n+1)
    right = mod1(i+1, n+1)
    new_I[left] -= 1
    new_I[right] -= 1
    
    return new_I
end

"""
    canonical(intersections::Vector{Int32}) -> Vector{Int32}

Return the lexicographically first equivalent sequence under rotations and reflections.
"""
function canonical(intersections::Vector{Int32})
    n = length(intersections)
    min_sequence = intersections
    
    # Check all rotations
    for i in 1:n
        # Forward rotation
        rotated = circshift(intersections, -(i-1))
        if rotated < min_sequence
            min_sequence = copy(rotated)
        end
        
        # Reversed rotation
        reversed = reverse(rotated)
        if reversed < min_sequence
            min_sequence = copy(reversed)
        end
    end
    
    return min_sequence
end

"""
    generate_rays(self_intersections::Vector{Int32}) -> Vector{Tuple{Int32,Int32}}

Compute the rays of a 2D smooth toric variety from self-intersection numbers.
Returns list of points in Z², starting with (1,0), (0,1).
"""
function generate_rays(self_intersections::Vector{Int32})
    rays = [(Int32(1), Int32(0)), (Int32(0), Int32(1))]
    
    # Track just the previous two points for efficiency
    r_prev = Int32[1, 0]
    r_curr = Int32[0, 1]
    
    # Generate remaining rays using recursive formula
    for c in @view self_intersections[1:end-2]
        if c == 0
            r_next = -r_prev
        else
            r_next = -r_prev - c * r_curr
        end
        push!(rays, (Int32(r_next[1]), Int32(r_next[2])))
        r_prev = r_curr
        r_curr = r_next
    end
    
    return rays
end

"""
    check_lattice_properties(intersections::Vector{Int32}, n::Integer, k::Integer) -> Bool

Check if the polytope defined by the intersections satisfies:
1. Only one additional lattice point compared to previous stage
2. k times dual polytope contains origin in interior


function check_lattice_properties(intersections::Vector{Int32}, n::Integer, k::Integer)
    # TODO: Implement proper polytope checks once Polymake integration is resolved
    # Currently returns true for testing purposes
    return true
end

Preceding version was a placesaver, accurate version at the bottom of this file.

This version does not work, need to deal with poly make.

function check_lattice_properties(intersections::Vector{Int32}, n::Integer, k::Integer)
    rays = generate_rays(intersections)
    
    # Convert to matrix format for Polymake
    n_rays = length(rays)
    pm_points = Matrix{Rational{Int64}}(undef, n_rays, 2)
    for (i, r) in enumerate(rays)
        pm_points[i,1] = r[1]
        pm_points[i,2] = r[2]
    end
    
    p = Polytope.Polytope(POINTS=pm_points)
        
    # Check number of lattice points in original polytope
    if Polytope.N_LATTICE_POINTS(p) != n + 1
        return false
    end
    
    # Get dual polytope and scale by k
    dual = k * Polytope.DUAL(p)
    
    # Get integral points of the scaled dual polytope
    int_points = Polytope.LATTICE_POINTS(dual)
    # Create polytope from just the integral points
    int_dual = Polytope.Polytope(POINTS=int_points)
    
    # Check if origin is in interior of polytope formed by integral points
    origin = [0, 0]
    return origin ∈ Polytope.INTERIOR_POINTS(int_dual)
end
"""

"""
    process_base_collection(input_collection::BaseCollection, k::Integer) -> 
        Tuple{BaseCollection, Set{Vector{Int32}}}

Process a collection of bases to generate all possible blowups.
Returns new collection and set of terminal bases.
"""
function process_base_collection(input_collection::BaseCollection, k::Integer)
    n = input_collection.intersection_length
    output_collection = initialize_collection(n + 1, k)
    terminal_bases = Set{Vector{Int32}}()
    
    for base in get_bases(input_collection)
        is_terminal = true
        
        for i in 1:n
            new_I = compute_new_intersections(base, i)
            
            # Check in order of increasing computational cost
            if new_I ∈ output_collection.bases
                is_terminal = false
            else
                canonical_form = canonical(new_I)
                if canonical_form ∈ output_collection.bases
                    is_terminal = false
                else
                    if check_lattice_properties(new_I, Int32(i), Int32(k))
                        is_terminal = false
                        push!(output_collection.bases, canonical_form)
                    end
                end
            end
        end
        
        is_terminal && push!(terminal_bases, base)
    end
    
    return output_collection, terminal_bases
end

# computing vertices, given 2D points

"""
Compute 2D cross product of vectors formed by three points.
Returns > 0 for left turn, < 0 for right turn, 0 for collinear.
"""
function cross_product(p1::Tuple{Int32,Int32}, p2::Tuple{Int32,Int32}, p3::Tuple{Int32,Int32})::Int64
    (x2, y2) = p2
    (x1, y1) = p1
    (x3, y3) = p3
    return Int64(x2 - x1) * Int64(y3 - y1) - Int64(y2 - y1) * Int64(x3 - x1)
end

"""
Compute vertices of the convex hull of a set of 2D points in counterclockwise order.
Returns both the vertices and their indices in the original list.
"""
function compute_vertices(points::Vector{Tuple{Int32,Int32}})::Tuple{Vector{Tuple{Int32,Int32}}, Vector{Int32}}
    # Nothing to do if we have 3 or fewer points
    if length(points) ≤ 3
        return points, collect(Int32(1):Int32(length(points)))
    end
    
    # Initialize with all points and their indices
    current_points = copy(points)
    indices = collect(Int32(1):Int32(length(points)))
    points_removed = true
    
    while points_removed
        points_removed = false
        i = 1
        n = length(current_points)
        
        while i ≤ length(current_points)
            # Get three consecutive points (wrapping around)
            prev_idx = mod1(i - 1, n)
            curr_idx = i
            next_idx = mod1(i + 1, n)
            
            # Check turn direction
            cp = cross_product(current_points[prev_idx], 
                             current_points[curr_idx], 
                             current_points[next_idx])
            
            # Remove point if it makes a right turn or is collinear
            if cp ≤ 0
                deleteat!(current_points, curr_idx)
                deleteat!(indices, curr_idx)
                points_removed = true
                n -= 1
            else
                i += 1
            end
        end
    end
    
    return current_points, indices
end

"""
Check if a toric variety created by blowup contains any unexpected lattice points.
Only checks sums of adjacent rays due to smoothness condition.
Takes the original ray list, index of blowup ray, and vertices with their indices.
Returns true if no unexpected lattice points exist, false otherwise.
"""
function check_inclusion(rays::Vector{Tuple{Int32,Int32}}, 
                        blowup_idx::Int32,
                        vertices::Vector{Tuple{Int32,Int32}}, 
                        vertex_indices::Vector{Int32})::Bool
    n = length(rays)
    # Find position of blowup vertex in vertex list
    blowup_pos = findfirst(i -> i == blowup_idx, vertex_indices)
    if blowup_pos === nothing
        error("Blowup ray must be a vertex")
    end
    
    # Get indices of adjacent vertices (with cyclic wrapping)
    next_pos = mod1(blowup_pos + 1, length(vertices))
    prev_pos = mod1(blowup_pos - 1, length(vertices))
    j_idx = vertex_indices[next_pos]
    k_idx = vertex_indices[prev_pos]
    
    # Check all adjacent pairs going counterclockwise from blowup_idx to j_idx
    curr_idx = blowup_idx
    while curr_idx != j_idx
        next_idx = mod1(curr_idx + 1, n)
        sum_ray = (Int32(rays[curr_idx][1] + rays[next_idx][1]), 
                  Int32(rays[curr_idx][2] + rays[next_idx][2]))
#	print(curr_idx, j_idx, sum_ray)
        if cross_product(rays[blowup_idx], sum_ray, rays[j_idx]) <= 0
            return false
        end
        curr_idx = next_idx
    end
    
    # Check all adjacent pairs going clockwise from blowup_idx to k_idx
    curr_idx = blowup_idx
    while curr_idx != k_idx
        prev_idx = mod1(curr_idx - 1, n)
        sum_ray = (Int32(rays[curr_idx][1] + rays[prev_idx][1]), 
                  Int32(rays[curr_idx][2] + rays[prev_idx][2]))
#	println(curr_idx, k_idx, sum_ray) # print stuff for debugging
        if cross_product(rays[k_idx], sum_ray, rays[blowup_idx]) <= 0
            return false
        end
        curr_idx = prev_idx
    end
    
    return true
end

"""
Compute all primitive lattice points in k times the dual polytope given vertices in counterclockwise order.
Returns vector of primitive Int32 tuples representing lattice points.
"""
function find_dual_lattice_points(vertices::Vector{Tuple{Int32,Int32}}, k::Int32)::Vector{Tuple{Int32,Int32}}
   #print("Finding dual points:")
   #println(vertices)
   if length(vertices) < 2
       error("Polytope must have at least two vertices")
   end

   # Preprocess vertices into upper/lower bound lists based on sign of x-coordinate
   upper_bounds = Tuple{Int32,Int32}[]  # rays with negative x-coordinate
   lower_bounds = Tuple{Int32,Int32}[]  # rays with positive x-coordinate

   upper_y = false
   for v in @view vertices[1:end]
       if v[1] < 0
           push!(upper_bounds, v)
       elseif v[1] > 0
           push!(lower_bounds, v)
       elseif v[1] == 0 && v[2] < 0
           upper_y = true # upper bound at k in this case
       end
   end
   
   # Need at least one upper bound for a finite set of points
   if isempty(upper_bounds)
       error("Polytope must have at least one vertex with negative x-coordinate")
   end
   
   points = Tuple{Int32,Int32}[]
   y = Int32(-k)
   
   while true
       if upper_y && y > k
           break
       end
       
       # Start with bound from (1,0) ray
       min_x = -k//1
       max_x = 5000//1 # Upper bound
       
       # Update minimum x from lower bounds
       for (a,b) in lower_bounds
           x_bound = (-k - b*y)//a  # a is positive here
           min_x = max(min_x, x_bound)
       end
       
       # Update bounds from upper bounds (a < 0)
       for (a,b) in upper_bounds
           x_bound = (-k - b*y)//a  # a is negative here
           max_x = min(max_x, x_bound)
       end
       #println(y, min_x, max_x)
       
       # Convert rational bounds to integers directly
       min_x_int = Int32(ceil(min_x))
       max_x_int = Int32(floor(max_x))
       
       if max_x_int > 4000
           error("x too big")
       end
       
       if y > 0 && min_x > max_x
           break
       end
       
       if min_x_int <= max_x_int
           for x in min_x_int:max_x_int
               if gcd(x, y) == 1
                   push!(points, (x, y))
               end
           end
       end
       
       y += 1
   end
   
   return points
end

"""
Check if the origin is in the interior of the convex hull of a set of 2D points.
Does this by verifying that the angles between adjacent points (sorted by angle)
cover all directions (no gap > π).
"""
function origin_is_interior(points::Vector{Tuple{Int32,Int32}})::Bool
   # Need at least 2 points
   if length(points) < 2
       return false
   end
   
   # Compute angles in [0,2π) for each point
   angles = Float64[]
   for (x,y) in points
       angle = atan(Float64(y), Float64(x))
       if angle < 0
           angle += 2π
       end
       push!(angles, angle)
   end
   
   # Sort angles
   sort!(angles)
   #println(angles)
   
   # Check gaps between consecutive angles and wrap around
   for i in 1:length(angles)
       next_angle = i < length(angles) ? angles[i+1] : angles[1] + 2π
       if next_angle - angles[i] >= 3.14159 # slightly smaller to avoid rounding errors
           return false
       end
   end
   
   return true
end

"""
Check lattice properties of a toric variety defined by intersection numbers.
Takes intersection numbers, index of blown-up ray, and scaling factor k.
Returns true only if:
1. No unexpected lattice points exist after blowup
2. Origin is interior to k-scaled lattice dual polytope
"""
function check_lattice_properties(
   self_intersections::Vector{Int32}, 
   blowup_idx::Int32, 
   k::Int32
)::Bool
   #println(self_intersections, " at ", blowup_idx)
   # First generate the rays from intersection numbers
   rays = generate_rays(self_intersections)
   
   # Compute vertices and their positions in original ray list
   vertices, vertex_indices = compute_vertices(rays)
   
   # Check no unexpected lattice points from blowup
   # note: blowup index is shifted by 1!
   if !check_inclusion(rays, Int32(mod1(blowup_idx + 1, length(rays))), vertices, vertex_indices)
       return false
   end
   
   # Find primitive points in k-scaled dual polytope
   dual_points = find_dual_lattice_points(vertices, k)
   
   # Check if origin is interior to dual points
   return origin_is_interior(dual_points)
end

# add stuff for additional blowing down approach

# Functions for initializing blowdown process

# Functions for initializing blowdown process


"""
    generate_dual_rays(m::Integer, k::Integer) -> Vector{Tuple{Int32,Int32}}

Generate rays for k-dual of P² (m = -1 or 13) or Hirzebruch surface F_m (0 ≤ m ≤ 12).
Returns vector of primitive ray vectors, ordered counterclockwise starting with (1,0).
"""
function generate_dual_rays(m::Integer, k::Integer)::Vector{Tuple{Int32,Int32}}
    # Handle P² case
    if m == -1 || m == 13
        vertices = [(Int32(1), Int32(0)), 
                   (Int32(0), Int32(1)), 
                   (Int32(-1), Int32(-1))]
    # Handle Hirzebruch surface F_m
    elseif 0 ≤ m ≤ 12
        vertices = [(Int32(1), Int32(0)),
                   (Int32(0), Int32(1)),
                   (Int32(-1), Int32(m)),
                   (Int32(0), Int32(-1))]
    else
        throw(ArgumentError("Invalid m value: must be -1, 13, or 0-12"))
    end
    
    # Find primitive points in k times dual polytope
    primitive_rays = find_dual_lattice_points(vertices, Int32(k))
    
    isempty(primitive_rays) && error("No primitive rays found")
    
    # Check (1,0) is present
    any(p -> p == (Int32(1), Int32(0)), primitive_rays) || 
        error("(1,0) must be among primitive rays")
    
    # Sort by angle from positive x-axis, [0, 2π)
    sort!(primitive_rays, by = p -> begin
        angle = atan(Float64(p[2]), Float64(p[1]))
        angle < 0 ? angle + 2π : angle
    end)
    
    return primitive_rays
end
"""
    create_initial_base(rays::Vector{Tuple{Int32,Int32}}) -> BlowdownBase

Create initial base with all rays active and computed vertices.
"""
function create_initial_base(rays::Vector{Tuple{Int32,Int32}})::BlowdownBase
    n_rays = length(rays)
    active_rays = trues(n_rays)
    
    # Compute vertices using existing function
    _, vertex_indices = compute_vertices(rays)
    
    return BlowdownBase(active_rays, vertex_indices)  # uses default -1, -1 for bounds
end

function initialize_blowdown_collection(m::Integer, k::Integer)::BlowdownCollection
    rays = generate_dual_rays(m, k)
    n_rays = length(rays)
    
    collection = BlowdownCollection(rays, n_rays)
    add_base!(collection, create_initial_base(rays))
    
    return collection
end

# now code to find new bases after a blowdown.

"""
   compute_removed_vertex_base(
       rays::Vector{Tuple{Int32,Int32}>, 
       old_base::BlowdownBase,
       vertex_pos::Int32     # position in vertex list to remove
   ) -> BlowdownBase

Creates new base by removing vertex at vertex_pos. Updates active rays,
computes new vertices maintaining counterclockwise order, and updates bounds
tracking which vertices have been "tried". Returns new base object.
"""
function compute_removed_vertex_base(
   rays::Vector{Tuple{Int32,Int32}},
   old_base::BlowdownBase,
   vertex_pos::Int
)::BlowdownBase
   n_vertices = length(old_base.vertices)

#   println(old_base.active_rays, " ", old_base.vertices, " ", vertex_pos)
   
   # Get initial adjacent positions
   prev_pos = mod1(vertex_pos - 1, n_vertices)
   next_pos = mod1(vertex_pos + 1, n_vertices)
   
   # Create new active rays with removed vertex marked inactive
   new_active = copy(old_base.active_rays)
   new_active[old_base.vertices[vertex_pos]] = false
   
   # Initialize with rays between prev and next vertices, including both endpoints
   current_rays = Int32[old_base.vertices[prev_pos]]  # Start with prev_idx
   current_idx = old_base.vertices[prev_pos]
   end_idx = old_base.vertices[next_pos]
   
   # Collect all active rays between prev and next
   while current_idx != end_idx
       current_idx = mod1(current_idx + 1, length(rays))
       if new_active[current_idx]
           push!(current_rays, current_idx)
       end
   end
#   push!(current_rays, end_idx)  # Add the final next_idx
#   current rays should already include from previous to end, both included
#   println(current_rays)

# Iteratively remove non-convex points between prev and next
    points_removed = true
    while points_removed
        points_removed = false
        i = 2  # Start after prev_pos
        n = length(current_rays)
        
        while i < n   # Now will include i = n-1
            # Get three consecutive rays (no wrapping)
            prev_idx = i - 1
            curr_idx = i
            next_idx = i + 1
	    
           # Check turn direction
           cp = cross_product(rays[current_rays[prev_idx]], 
                            rays[current_rays[curr_idx]], 
                            rays[current_rays[next_idx]])
           
           # Remove point if it makes a right turn or is collinear
           if cp ≤ 0
               deleteat!(current_rays, curr_idx)
               points_removed = true
               n -= 1
           else
               i += 1
           end
       end
   end

# note: there are various scenarios where previous/next are either
# both above or both below lower/upper, or split.  If split, vertex
# can be on either side.  Tried using shift to track for purposes of
# constructing new vertices but just added_beginning for new
# lower/upper

# Build new vertex list and handle wrapping correctly
    new_vertices = copy(old_base.vertices)
    deleteat!(new_vertices, vertex_pos)
    
    shift = 0
    # Adjust prev_pos if we removed a vertex before it
    if vertex_pos < prev_pos
        #prev_pos -= 1
	shift = -1
    end
    
   # Determine crossover point where indices decrease
   split_idx = findfirst(i -> current_rays[i] > current_rays[i + 1],
                         1:length(current_rays)-1)
   
   added_beginning = 0

#   println(new_vertices, " ", current_rays, " ", split_idx, " ", prev_pos,  " ", added_beginning)
   
   if split_idx === nothing
       # No crossover - insert all after prev_pos
       insert_pos = prev_pos + shift
       for ray_idx in @view current_rays[2:end-1]
           insert!(new_vertices, insert_pos + 1, ray_idx)
           insert_pos += 1
       end
   else
       # Add vertices before crossover after prev_pos
       insert_pos = prev_pos + shift
       for ray_idx in @view current_rays[2:split_idx]
           insert!(new_vertices, insert_pos + 1, ray_idx)
           insert_pos += 1
            # If inserting before lower_bound, increment added_beginning
            if prev_pos + shift < old_base.lower_bound
                added_beginning += 1
            end
       end
       # Add vertices after crossover at start
       for ray_idx in reverse(@view current_rays[split_idx+1:end-1])
           insert!(new_vertices, 1, ray_idx)
           added_beginning += 1
       end
   end

# Update bounds accounting for tried vertices and vertex list reordering
    if vertex_pos < old_base.lower_bound
        added_beginning -= 1  # Adjust for shift left
    end
    
    new_lower, new_upper = if old_base.lower_bound == -1 && old_base.upper_bound == -1
        if vertex_pos == 1
            # Still haven't tried any vertices
            (Int32(-1), Int32(-1))
        else
            # Have now tried vertices 1 through prev_pos
            (1 + added_beginning, prev_pos + added_beginning)
        end
    else
        # Normal bound updating with shift for added vertices
        (old_base.lower_bound + added_beginning, prev_pos + added_beginning)
    end
   
   return BlowdownBase(new_active, new_vertices, Int32(new_lower), Int32(new_upper))
end

"""
   process_collection_down(
       collection::BlowdownCollection
   ) -> BlowdownCollection

Process a collection of bases at ray count n to generate all valid bases
with ray count n-1 by systematically removing vertices. Returns new collection.
"""
function process_collection_down(collection::BlowdownCollection)::BlowdownCollection
   # Create new collection for n-1 rays
   new_collection = BlowdownCollection(
       collection.initial_rays,
       collection.ray_count - 1
   )
   
   # Process each base in current collection
   for base in collection.bases
       n_vertices = length(base.vertices)
       
       # flag to set if done
       done = false
       # Determine starting and ending vertex positions
       if base.upper_bound == -1
           # No vertices tried yet, try all vertices
           start_pos = 1
           end_pos = 1   # Will stop after wrapping around back to 1
       else
           # Start after last tried vertex, end at lower_bound
           start_pos = mod1(base.upper_bound + 1, n_vertices)
           end_pos = base.lower_bound
	   if start_pos == end_pos
	      done = true # nothing more to try
	   end
       end
       
       # Try removing each untried vertex
       pos = start_pos
       while true

           # stop if done
	   done && break
           # Create new base with this vertex removed
           new_base = compute_removed_vertex_base(
               collection.initial_rays,
               base,
               pos
           )
           
           # Check if valid and add to collection if so
           if is_valid_base(collection.initial_rays, new_base)
               add_base!(new_collection, new_base)
           end
           
           # Move to next vertex position
           pos = mod1(pos + 1, n_vertices)

           # Stop if we've reached ending position
           pos == end_pos && break

       end
   end
   
   return new_collection
end

"""
    analyze_canonical_forms(collection::BlowdownCollection) 
        -> Dict{Vector{Int32}, Int32}

Analyze a collection to find canonical forms and their multiplicities.
Returns dictionary mapping canonical intersection sequences to their count.
"""
function analyze_canonical_forms(collection::BlowdownCollection)
    # Map from canonical form to count of realizations
    canonical_forms = Dict{Vector{Int32}, Int32}()
    
    for base in collection.bases
        # Convert active rays to intersection sequence
        active_rays = findall(base.active_rays)
        intersections = compute_intersection_sequence(collection.initial_rays, active_rays)
        
        # Get canonical form and update count
        can_form = canonical(intersections)
        canonical_forms[can_form] = get(canonical_forms, can_form, 0) + 1
    end
    
    return canonical_forms
end

"""
   is_valid_base(rays::Vector{Tuple{Int32,Int32}}, base::BlowdownBase) -> Bool

Check if a base is valid by verifying the origin lies in the proper interior
of the polytope defined by its active rays. Uses vertex angles to determine
if any angle ≥ π (with small epsilon tolerance for numerical stability).
"""
function is_valid_base(
   rays::Vector{Tuple{Int32,Int32}},
   base::BlowdownBase
)::Bool
   # Get actual ray coordinates for each vertex
   vertex_rays = [rays[v] for v in base.vertices]
   
   # Need at least 3 vertices for a proper interior
   length(vertex_rays) < 3 && return false
   
   # Compute angles between consecutive vertices
   n = length(vertex_rays)
   for i in 1:n
       p1 = vertex_rays[i]
       p2 = vertex_rays[mod1(i + 1, n)]
       
       # Get angles in [0,2π) for each point
       angle1 = atan(Float64(p1[2]), Float64(p1[1]))
       angle1 < 0 && (angle1 += 2π)
       angle2 = atan(Float64(p2[2]), Float64(p2[1]))
       angle2 < 0 && (angle2 += 2π)
       
       # Compute difference in counterclockwise direction
       diff = angle2 - angle1
       diff < 0 && (diff += 2π)
       
       # Check if angle is too large (use same epsilon as in origin_is_interior)
       diff >= 3.14159 && return false
   end
   
   return true
end

"""
    compute_intersection_sequence(rays::Vector{Tuple{Int32,Int32}}, 
                                active_indices::Vector{Int32}) -> Vector{Int32}

Compute intersection numbers from a sequence of rays.
For each ray, uses the relation c * r_curr + r_prev + r_next = 0
where c is the intersection number we're solving for.
Returns the sequence of intersection numbers.
"""
function compute_intersection_sequence(
    rays::Vector{Tuple{Int32,Int32}},
    active_indices::Vector{Int} # changed to regular integer
)::Vector{Int32}
    n = length(active_indices)
    intersections = Vector{Int32}(undef, n)
    
    for i in 1:n
        # Get three consecutive rays (with wrapping)
        prev = rays[active_indices[mod1(i-1, n)]]
        curr = rays[active_indices[i]]
        next = rays[active_indices[mod1(i+1, n)]]
        
        # If curr = (x,y), then c * (x,y) + (x_prev,y_prev) + (x_next,y_next) = (0,0)
        # Taking either component gives us c
        if curr[1] != 0
            c = -(prev[1] + next[1]) ÷ curr[1]
        else
            c = -(prev[2] + next[2]) ÷ curr[2]
        end
        
        intersections[i] = c
    end
    
    return intersections
end

# Export the public interface
export compute_new_intersections, canonical, generate_rays, 
       check_lattice_properties, process_base_collection, compute_vertices,
       check_inclusion, find_dual_lattice_points, origin_is_interior
       # Export new functions
       generate_dual_rays, initialize_blowdown_collection

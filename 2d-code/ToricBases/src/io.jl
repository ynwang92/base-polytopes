"""
    initialize_size_file(filename::String)

Creates a new size file with initial entry for n=3.
"""

function initialize_size_file(filename::String)
    open(filename, "w") do f
        write(f, "{\n{3, 1}\n}")  # Single set of braces
    end
end

"""
    append_size_to_mathematica_file(n::Integer, size::Integer, filename::String)

Appends new size information to the Mathematica file, maintaining proper list syntax.
"""


function append_size_to_mathematica_file(n::Integer, size::Integer, filename::String)
    # Read current content
    content = read(filename, String)
    # Remove the closing brace AND the newline before it
    content = content[1:end-2]  # This removes both '\n' and '}'
    
    # Append new entry and closing brace
    open(filename, "w") do f
        write(f, content)
        write(f, ",\n{$n, $size}\n}")  # Single closing brace
    end
end
"""
    save_collection(collection::BaseCollection, filename::String; compress::Bool=false)

Save collection to file, optionally using compressed format.
"""
function save_collection(collection::BaseCollection, filename::String; compress::Bool=false)
    if compress
        open(filename, "w") do f
            bases = sort!(collect(get_bases(collection)))
            # Write number of bases and intersection length
            write(f, Int32(length(bases)))
            write(f, Int32(collection.intersection_length))
            # Write each base's intersections
            for base in bases
                write(f, base)
            end
        end
    else
        open(filename, "w") do f
            write(f, "# length=$(collection.intersection_length)\n")
            for intersections in sort!(collect(get_bases(collection)))
                write(f, join(intersections, " "), "\n")
            end
        end
    end
end

"""
    load_collection(filename::String; compress::Bool=false) -> BaseCollection

Load collection from file, handling both compressed and text formats.
"""
function load_collection(filename::String; compress::Bool=false)
    if !isfile(filename)
        error("File not found: $filename")
    end
    
    if compress
        open(filename, "r") do f
            # Read header information
            num_bases = read(f, Int32)
            intersection_length = read(f, Int32)
            
            collection = BaseCollection(intersection_length)
            # Read each base
            for _ in 1:num_bases
                intersections = Vector{Int32}(undef, intersection_length)
                read!(f, intersections)
                push!(collection.bases, intersections)
            end
            return collection
        end
    else
        collection = nothing
        open(filename, "r") do f
            while true
                line = readline(f)
                isempty(line) && break
                
                if startswith(line, "#")
                    # Parse header
                    m = match(r"length=(\d+)", line)
                    if !isnothing(m)
                        intersection_length = parse(Int32, m[1])
                        collection = BaseCollection(intersection_length)
                    end
                else
                    # Parse intersection numbers
                    intersections = Int32[parse(Int32, x) for x in split(line)]
                    push!(collection.bases, intersections)
                end
            end
        end
        return collection
    end
end

"""
    save_terminal_bases(terminal_bases::Set{Vector{Int32}}, n::Integer, filename::String)

Save terminal bases to a file in Mathematica format.
"""
function save_terminal_bases(terminal_bases::Set{Vector{Int32}}, n::Integer, filename::String)
    open(filename, "w") do f
        # Sort bases for consistent output
        for base in sort!(collect(terminal_bases))
            write(f, string('[', join(base, ", "), ']'), "\n")
        end
    end
end

"""
    consolidate_terminal_bases(directory::String, output_file::String)

Collect all terminal-n.m files from directory into a single consolidated file.
Returns number of terminal bases found.
"""
function consolidate_terminal_bases(directory::String, output_file::String)
    terminal_count = 0
    open(output_file, "w") do outf
        write(outf, "{")
        first_file = true
        
        # Find and process all terminal-*.m files
        for file in readdir(directory)
            if startswith(file, "terminal-") && endswith(file, ".m")
                if !first_file
                    write(outf, ",")
                end
                first_file = false
                
                # Extract n from filename
                n = parse(Int, match(r"terminal-(\d+)\.m", file)[1])
                
                # Read and format the content
                content = read(joinpath(directory, file), String)
                bases = split(strip(content), '\n')
                terminal_count += length(bases)
                
                # Write to consolidated file
                write(outf, "\n{$n, {")
		bases = [string('[', join(base, ", "), ']') for base in split(strip(content), '\n')] # added to fix problem
                write(outf, join(bases, ","))
                write(outf, "}}")
            end
        end
        write(outf, "\n}")
    end
    return terminal_count
end

"""
    save_blowdown_collection(collection::BlowdownCollection, filename::String,
                           k::Integer, m::Integer; compress::Bool=false)

Save blowdown collection to file, optionally using compressed format.
Includes k and m parameters in metadata.
"""
function save_blowdown_collection(collection::BlowdownCollection, filename::String,
                                k::Integer, m::Integer; compress::Bool=false)
    if compress
        open(filename, "w") do f
            # Write header information
            write(f, Int32(k))  # Add k to header
            write(f, Int32(m))  # Add m to header
            write(f, Int32(length(collection.initial_rays)))
            write(f, Int32(collection.ray_count))
            
            # Rest remains the same
            for ray in collection.initial_rays
                write(f, Int32(ray[1]))
                write(f, Int32(ray[2]))
            end
            
            bases = collect(collection.bases)
            write(f, Int32(length(bases)))
            
            for base in bases
                write(f, base.active_rays.chunks)
                write(f, Int32(length(base.vertices)))
                write(f, base.vertices)
                write(f, base.lower_bound)
                write(f, base.upper_bound)
            end
        end
    else
        open(filename, "w") do f
            # Write header with k and m
            write(f, "# k=$k\n")
            write(f, "# m=$m\n")
            write(f, "# n_initial=$(length(collection.initial_rays))\n")
            write(f, "# n=$(collection.ray_count)\n")
            
            # Rest remains the same
            write(f, "# initial_rays\n")
            for ray in collection.initial_rays
                write(f, "$(ray[1]) $(ray[2])\n")
            end
            
            write(f, "# bases\n")
	    #added sorting for clarity
            for base in sort(collect(collection.bases), by = b -> b.active_rays)
                active_str = join([Int(x) for x in base.active_rays], "")
                vertex_str = join(base.vertices, " ")
                write(f, "$active_str | $vertex_str | $(base.lower_bound) $(base.upper_bound)\n")
            end
        end
    end
end

"""
    load_blowdown_collection(filename::String, k::Integer, m::Integer; 
                           compress::Bool=false) -> BlowdownCollection

Load blowdown collection from file, verifying k and m parameters match.
"""
function load_blowdown_collection(filename::String, k::Integer, m::Integer; 
                                compress::Bool=false)
    if !isfile(filename)
        error("File not found: $filename")
    end
    
    if compress
        open(filename, "r") do f
            # Read and verify k and m
            file_k = read(f, Int32)
            file_m = read(f, Int32)
            if file_k != k || file_m != m
                error("File parameters (k=$file_k, m=$file_m) don't match requested (k=$k, m=$m)")
            end
            
            # Rest remains the same
            n_initial = read(f, Int32)
            ray_count = read(f, Int32)
            
            rays = Vector{Tuple{Int32,Int32}}(undef, n_initial)
            for i in 1:n_initial
                x = read(f, Int32)
                y = read(f, Int32)
                rays[i] = (x, y)
            end
            
            collection = BlowdownCollection(rays, ray_count)
            
            num_bases = read(f, Int32)
            for _ in 1:num_bases
                active = BitVector(undef, n_initial)
                read!(f, active.chunks)
                
                n_vertices = read(f, Int32)
                vertices = Vector{Int32}(undef, n_vertices)
                read!(f, vertices)
                
                lower = read(f, Int32)
                upper = read(f, Int32)
                
                add_base!(collection, BlowdownBase(active, vertices, lower, upper))
            end
            
            return collection
        end
    else
        rays = Vector{Tuple{Int32,Int32}}()
        collection = nothing
        
        open(filename, "r") do f
            while !eof(f)
                line = readline(f)
                isempty(line) && continue
                
                if startswith(line, "#")
                    if (m = match(r"k=(\d+)", line)) !== nothing
                        file_k = parse(Int, m[1])
                        file_k == k || error("File k=$file_k doesn't match requested k=$k")
                    elseif (m = match(r"m=(-?\d+)", line)) !== nothing
                        file_m = parse(Int, m[1])
                        file_m == m || error("File m=$file_m doesn't match requested m=$m")
                    elseif (m = match(r"n_initial=(\d+)", line)) !== nothing
                        n_initial = parse(Int32, m[1])
                    elseif (m = match(r"n=(\d+)", line)) !== nothing
                        ray_count = parse(Int32, m[1])
                        if !isempty(rays)
                            collection = BlowdownCollection(rays, ray_count)
                        end
                    end
                elseif collection === nothing
                    x, y = parse.(Int32, split(line))
                    push!(rays, (x, y))
                else
                    active_str, vertex_str, bounds_str = split(line, "|")
                    active = BitVector([c == '1' for c in strip(active_str)])
                    vertices = parse.(Int32, split(strip(vertex_str)))
                    lower, upper = parse.(Int32, split(strip(bounds_str)))
                    add_base!(collection, BlowdownBase(active, vertices, lower, upper))
                end
            end
        end
        return collection
    end
end

"""
    save_canonical_forms(forms::Dict{Vector{Int32}, Int32}, filename::String,
                        k::Integer, m::Integer)

Save canonical forms and their multiplicities to a file in Mathematica format.
Includes k and m in metadata.
"""
function save_canonical_forms(forms::Dict{Vector{Int32}, Int32}, filename::String,
                            k::Integer, m::Integer)
    open(filename, "w") do f
        write(f, "# k=$k\n# m=$m\n{\n")
        sorted_forms = sort!(collect(forms))
        for (i, (form, count)) in enumerate(sorted_forms)
            write(f, "{")
            write(f, string('[', join(form, ", "), ']'))
            write(f, ", $count}")
            if i < length(sorted_forms)
                write(f, ",\n")
            end
        end
        write(f, "\n}")
    end
end

# Export the new functions
export save_blowdown_collection, load_blowdown_collection,
       save_canonical_forms, analyze_canonical_forms

export initialize_size_file, append_size_to_mathematica_file,
       save_collection, load_collection,
       save_terminal_bases, consolidate_terminal_bases


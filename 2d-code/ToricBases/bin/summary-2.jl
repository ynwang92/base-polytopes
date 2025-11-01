#!/usr/bin/env julia

push!(LOAD_PATH, joinpath(@__DIR__, ".."))



using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "directory"
            help = "Directory containing the blowdown files"
            required = true
    end
    return parse_args(s)
end

function main()
    args = parse_commandline()
    directory = args["directory"]
    
    # Initialize data structure to store results
    # Dict{Int, Dict{Int, Dict{Int, Int}}} represents Dict[k][m][n] = size
    results = Dict{Int, Dict{Int, Dict{Int, Int}}}()
    
    # Process all files in the directory
    for file in readdir(directory, join=true)
        # Match filename pattern "blowdown-canonical-k{k}-m{m}-n{n}"
        m = match(r"blowdown-canonical-k(\d+)-m(\d+)-n(\d+)", basename(file))
        if m !== nothing
            k, m, n = parse.(Int, m.captures)
            
            # Process file and count bases
            count = count_bases(file)
            
            # Store the result
            if !haskey(results, k)
                results[k] = Dict{Int, Dict{Int, Int}}()
            end
            if !haskey(results[k], m)
                results[k][m] = Dict{Int, Int}()
            end
            results[k][m][n] = count
        end
    end
    
    # Write results to files
    for (k, k_data) in results
        write_results_file(directory, k, k_data)
    end
    
    println("Processing complete.")
end

function count_bases(file)
    # Simply count the number of entries by counting the pattern {[...], integer}
    content = read(file, String)
    
    # Count occurrences of the pattern
    count = length(collect(eachmatch(r"\{(\[.*?\]), \d+\}", content)))
    
    return count
end

function write_results_file(directory, k, k_data)
    filename = joinpath(directory, "sizes-canonical-k$k")
    open(filename, "w") do f
        write(f, "sizes[$k] = \n{\n")
        
        # Sort m values
        m_values = sort(collect(keys(k_data)))
        
        for (i, m) in enumerate(m_values)
            write(f, "{$m, \n{{")
            
            # Sort n values
            n_values = sort(collect(keys(k_data[m])))
            
            for (j, n) in enumerate(n_values)
                size = k_data[m][n]
                if j < length(n_values)
                    write(f, "$n, $size},\n {")
                else
                    write(f, "$n, $size}")
                end
            end
            
            if i < length(m_values)
                write(f, "}},\n")
            else
                write(f, "}}\n")
            end
        end
        
        write(f, "}\n")
    end
    println("Results written to $filename")
end

main()
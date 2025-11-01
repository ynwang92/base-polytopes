#!/usr/bin/env julia

push!(LOAD_PATH, joinpath(@__DIR__, ".."))


"""
ToricBases Generator
===================

This script generates all possible 2D toric varieties that can serve as bases
for elliptic Calabi-Yau manifolds through iterative blowups.

Examples:
---------

1. Basic usage (start from n=3, go to n=4):
   ./generate.jl

2. Start from n=3, generate up to n=6:
   ./generate.jl --max 6

3. Generate bases starting from n=4 up to n=6:
   ./generate.jl --size 4 --max 6

4. Use compressed binary format and custom directory:
   ./generate.jl --compress --directory my_data --max 6

5. Only save the final collection (useful for large n):
   ./generate.jl --max 8 --maxonly

Output Files:
------------
- collection-n or compressed-collection-n: Base collections for each n
- terminal-n.m: Terminal bases found at each n
- sizes.m: List of collection sizes in Mathematica format

Notes:
------
- Parameter k (default=6) controls admissibility of bases for F-theory
- Collections are saved in canonical form under symmetries
- Binary format (--compress) reduces disk usage for large collections
"""

using ToricBases
using ArgParse


#!/usr/bin/env julia

using ToricBases
using ArgParse

function parse_commandline()
    s = ArgParseSettings(
        description = "Generate all 2D polytopes for F-theory bases through iterative blowups"
    )

    @add_arg_table! s begin
        "--size", "-s"
            help = "Initial intersection length"
            arg_type = Int
            default = 3
        "--k"
            help = "Multiplicative factor for dual polytope (typically 6 for F-theory)"
            arg_type = Int
            default = 6
        "--max", "-m"
            help = "Maximum intersection length"
            arg_type = Int
        "--maxonly"
            help = "Only save the final collection"
            action = :store_true
        "--directory", "-d"
            help = "Directory for saving/reading files"
            default = "data"
        "--compress", "-c"
            help = "Use compressed format for collection files"
            action = :store_true
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()
    
    # Set default max if not provided
    max_size = isnothing(args["max"]) ? args["size"] + 1 : args["max"]
    
    # Create directory if it doesn't exist
    mkpath(args["directory"])
    
    # Initialize size tracking
    size_file = joinpath(args["directory"], "sizes.m")
    if !isfile(size_file)
        initialize_size_file(size_file)
    end
    
    # Initial collection
    n = args["size"]
    input_collection = initialize_collection(n, args["k"])
    
    # If starting size isn't 3, try to load from file
    if n != 3
        input_filename = joinpath(args["directory"], 
            args["compress"] ? "compressed-collection-$n" : "collection-$n")
        if isfile(input_filename)
            input_collection = load_collection(input_filename, compress=args["compress"])
        end
    end
    
    # Process collections iteratively
    while n < max_size
        output_filename = joinpath(args["directory"],
            args["compress"] ? "compressed-collection-$(n+1)" : "collection-$(n+1)")
        
        # Process and store output
        output_collection, terminal_bases = process_base_collection(input_collection, args["k"])
        
        # Save collection if not maxonly or if it's the final collection
        if !args["maxonly"] || n == max_size - 1
            save_collection(output_collection, output_filename, compress=args["compress"])
        end
        
        # Save sizes
        append_size_to_mathematica_file(n+1, base_size(output_collection), size_file)
        
        # Save terminal bases if any found
        if !isempty(terminal_bases)
            terminal_filename = joinpath(args["directory"], "terminal-$n.m")
            save_terminal_bases(terminal_bases, n, terminal_filename)
        end
        
        # Progress report
        println("Completed n = $(n+1), found $(base_size(output_collection)) bases")
        if !isempty(terminal_bases)
            println("Found $(length(terminal_bases)) terminal bases")
        end
        
        # Prepare for next iteration
        input_collection = output_collection
        n += 1
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
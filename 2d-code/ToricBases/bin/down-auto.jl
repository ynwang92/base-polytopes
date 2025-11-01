#!/usr/bin/env julia

push!(LOAD_PATH, joinpath(@__DIR__, ".."))

"""
ToricBases Blowdown Generator
============================

This script generates all possible 2D toric varieties that can serve as bases
for elliptic Calabi-Yau manifolds through systematic blowdowns of maximal bases.

Examples:
---------

1. Basic usage (start from dual of P², generate all blowdowns):
  ./blowdown.jl --m -1

2. Start from dual of Hirzebruch surface F_2:
  ./blowdown.jl --m 2

3. Start from existing collection at n=10, blowdown to n=6:
  ./blowdown.jl --m 2 --n 10 --final 6

4. Use compressed binary format and custom directory:
  ./blowdown.jl --m 2 --compress --directory my_data

5. Automatically find and use the collection with smallest n value:
  ./blowdown.jl --m 2 --auto

Output Files:
------------
- blowdown-collection-n: Base collections for each n
- blowdown-canonical-n: Canonical forms and multiplicities for each n
- blowdown-sizes.m: List of collection sizes in Mathematica format

Notes:
------
- Parameter k (default=6) controls admissibility of bases for F-theory
- m = -1 or 13 specifies P², 0 ≤ m ≤ 12 specifies Hirzebruch surface F_m
- Collections and canonical forms saved for each value of n
"""

using ToricBases
using ArgParse

function parse_commandline()
   s = ArgParseSettings(
       description = "Generate all F-theory bases through systematic blowdowns"
   )

   @add_arg_table! s begin
       "--m"
           help = "Dual base parameter: -1/13 for P², 0-12 for F_m"
           arg_type = Int
           required = true
       "--k"
           help = "Multiplicative factor for dual polytope (typically 6 for F-theory)"
           arg_type = Int
           default = 6
       "--n"
           help = "Starting ray count (if not specified, starts from maximal base)"
           arg_type = Int
       "--auto"
           help = "Automatically use collection with smallest n value for given k and m"
           action = :store_true
       "--final"
           help = "Final ray count (default n-1 or 3, whichever is larger)"
           arg_type = Int
       "--directory", "-d"
           help = "Directory for saving/reading files"
           default = "data"
       "--compress", "-c"
           help = "Use compressed format for collection files"
           action = :store_true
   end

   return parse_args(s)
end

function find_smallest_n_collection(k, m, directory, compress)
    # Find all matching blowdown collection files
    file_pattern = compress ? 
        "blowdown-compressed-collection-k$(k)-m$(m)-n" : 
        "blowdown-collection-k$(k)-m$(m)-n"
    
    n_values = []
    for file in readdir(directory)
        if startswith(file, file_pattern)
            # Extract n value from filename
            n_str = match(r"n(\d+)$", file)
            if !isnothing(n_str)
                push!(n_values, parse(Int, n_str[1]))
            end
        end
    end
    
    if isempty(n_values)
        return nothing  # No matching files found
    else
        return minimum(n_values)  # Return smallest n value
    end
end

function main()
   args = parse_commandline()
   
   # Validate m parameter
   if args["m"] ∉ vcat(-1, 0:12, 13)
       error("m must be -1, 13, or 0-12")
   end
   
   # Create directory if it doesn't exist
   mkpath(args["directory"])
   
   # Initialize or load initial collection
   local input_collection
   
   if args["auto"]
       # Find the collection with smallest n value
       if !isnothing(args["n"])
           @warn "Both --auto and --n specified. --auto will take precedence."
       end
       
       smallest_n = find_smallest_n_collection(
           args["k"], args["m"], args["directory"], args["compress"])
       
       if isnothing(smallest_n)
           println("No existing collection files found. Starting from maximal base.")
           input_collection = initialize_blowdown_collection(args["m"], args["k"])
       else
           println("Found collection with smallest n = $(smallest_n). Starting from there.")
           filename = joinpath(args["directory"], 
                args["compress"] ? "blowdown-compressed-collection-k$(args["k"])-m$(args["m"])-n$(smallest_n)" :
                                 "blowdown-collection-k$(args["k"])-m$(args["m"])-n$(smallest_n)")
            input_collection = load_blowdown_collection(filename, args["k"], args["m"], 
                                                      compress=args["compress"])
       end
   elseif isnothing(args["n"])
       # Generate maximal base from m
       input_collection = initialize_blowdown_collection(args["m"], args["k"])
   else
       # Load existing collection
       filename = joinpath(args["directory"], 
            args["compress"] ? "blowdown-compressed-collection-k$(args["k"])-m$(args["m"])-n$(args["n"])" :
                             "blowdown-collection-k$(args["k"])-m$(args["m"])-n$(args["n"])")
        input_collection = load_blowdown_collection(filename, args["k"], args["m"], 
                                                  compress=args["compress"])
   end
   
   # Determine final n
   n = input_collection.ray_count
   final_n = if isnothing(args["final"])
       max(n-1, 3)  # Don't go below 3 rays
   else
       args["final"] ≥ 3 || error("Final ray count must be ≥ 3")
       args["final"]
   end

   # Process collections downward
    first_iteration = true
    while n >= final_n
        # Generate new collection (or use input for first maximal case)
        output_collection = if first_iteration && n == input_collection.n_initial
            first_iteration = false
            input_collection
        else
            process_collection_down(input_collection)
        end
        
        # Save collection
        collection_filename = joinpath(args["directory"],
            args["compress"] ? "blowdown-compressed-collection-k$(args["k"])-m$(args["m"])-n$n" :
                             "blowdown-collection-k$(args["k"])-m$(args["m"])-n$n")
        save_blowdown_collection(output_collection, collection_filename, 
                               args["k"], args["m"], compress=args["compress"])
        
        # Analyze and save canonical forms
        canonical_forms = analyze_canonical_forms(output_collection)
        canonical_filename = joinpath(args["directory"], 
                                    "blowdown-canonical-k$(args["k"])-m$(args["m"])-n$n")
        save_canonical_forms(canonical_forms, canonical_filename, args["k"], args["m"])
        
        # Save sizes
        size_file = joinpath(args["directory"], 
                            "blowdown-sizes-k$(args["k"])-m$(args["m"]).m")
        if !isfile(size_file)
            open(size_file, "w") do f
                write(f, "{\n{$n, $(length(output_collection.bases))}\n}")
            end
        else
            append_size_to_mathematica_file(n, 
                length(output_collection.bases), size_file)
        end
        
        # Progress report
        println("Completed n = $n")
        println("Found $(length(output_collection.bases)) bases")
        println("$(length(canonical_forms)) distinct canonical forms")
        
        # Prepare for next iteration
        input_collection = output_collection
        n -= 1
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
   main()
end
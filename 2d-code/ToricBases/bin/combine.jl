#!/usr/bin/env julia

push!(LOAD_PATH, joinpath(@__DIR__, ".."))

#!/usr/bin/env julia

"""
ToricBases Collection Combiner
=============================

Combines and analyzes results from multiple blowdown runs.

Usage:
   ./combine.jl [-d DIRECTORY] [-v] k

Arguments:
   k               Value of k to analyze
   -d, --directory Directory containing blowdown files (default: current)
   -v, --verbose   Include full intersection sequences in output

Output files:
   summary-k{k}.m:                  Total counts by m value
   blowdown-multiplicities-k{k}.m:  Distinct sequences by n value
   blowdown-intersections-k{k}.m:   Full sequences (if verbose)
   intersection-distribution-k{k}.m: Total distinct sequences by m value
   combine-log.txt:                 Processing log with ranges
"""

using ArgParse

function parse_commandline()
   s = ArgParseSettings(
       description = "Combine and analyze results from multiple blowdown runs"
   )

   @add_arg_table! s begin
       "k"
           help = "Value of k to analyze"
           arg_type = Int
           required = true
       "--directory", "-d"
           help = "Directory containing blowdown files"
           default = "."
       "--verbose", "-v"
           help = "Include full intersection sequences in output"
           action = :store_true
   end

   return parse_args(s)
end

"""
   process_size_files(k::Integer, directory::String)

Process all blowdown-sizes-k{k}-m*.m files and output summary.
Returns list of found m values.
"""
function process_size_files(k::Integer, directory::String)::Vector{Int}
   m_values = Int[]
   totals = Dict{Int,Int}()
   
   # Find all size files for this k
   pattern = "blowdown-sizes-k$k-m"
   for file in readdir(directory)
       if startswith(file, pattern) && endswith(file, ".m")
           # Extract m value from filename
           m = parse(Int, match(r"m(-?\d+)\.m$", file)[1])
           push!(m_values, m)
           
           # Read and sum multiplicities
           content = read(joinpath(directory, file), String)
           # Remove outer braces and whitespace
           content = strip(content[2:end-1])
           # Parse each {n, count} pair
           for pair in split(content, "},")
               # Clean up the pair string
               pair = replace(pair, "{" => "")
               pair = replace(pair, "}" => "")
               # Split into n and count
               n_str, count_str = split(strip(pair), ",")
               total = parse(Int, strip(count_str))
               totals[m] = get(totals, m, 0) + total
           end
       end
   end
   
   # Write summary
   open(joinpath(directory, "summary-k$k.m"), "w") do f
       write(f, "{\n")
       sorted_entries = sort(collect(totals))
       for (i, (m, total)) in enumerate(sorted_entries)
           write(f, "{$m, $total}")
           i < length(sorted_entries) && write(f, ",\n")
       end
       write(f, "\n}")
   end
   
   return sort(m_values)
end

"""
   parse_canonical_file(filename::String) -> Set{Vector{Int32}}

Extract unique intersection sequences from canonical form file.
"""
function parse_canonical_file(filename::String)::Set{Vector{Int32}}
   sequences = Set{Vector{Int32}}()
   content = read(filename, String)
   
   # Skip header lines starting with #
   for line in split(content, '\n')
       startswith(line, '#') && continue
       isempty(line) && continue
       
       # Parse sequence from [...] format
       if (m = match(r"\[(.*?)\]", line)) !== nothing
           seq = parse.(Int32, split(m[1], ","))
           push!(sequences, seq)
       end
   end
   
   return sequences
end

"""
   process_canonical_files(k::Integer, m_values::Vector{Int}, directory::String, verbose::Bool)

Process all canonical form files for each n value.
"""
function process_canonical_files(k::Integer, m_values::Vector{Int}, 
                              directory::String, verbose::Bool)
   # Find all n values that exist for any m
   n_values = Set{Int}()
   for m in m_values
       pattern = "blowdown-canonical-k$k-m$m-n"
       for file in readdir(directory)
           if startswith(file, pattern)
               n = parse(Int, match(r"n(\d+)$", file)[1])
               push!(n_values, n)
           end
       end
   end
   
   # Track total sequence counts by m
   m_totals = Dict{Int, Int}()
   for m in m_values
       m_totals[m] = 0
   end
   
   # Process each n value
   results = Dict{Int, Union{Int, Vector{Vector{Int32}}}}()
   loglines = String[]
   
   for m in m_values
       # Find min and max n for this m
       n_range = filter(n -> isfile(joinpath(directory, 
           "blowdown-canonical-k$k-m$m-n$n")), minimum(n_values):maximum(n_values))
       
       if isempty(n_range)
           push!(loglines, "For m=$m, no files found")
           continue
       end
       
       # Check for missing files
       missing = setdiff(minimum(n_range):maximum(n_range), n_range)
       if isempty(missing)
           push!(loglines, "For m=$m, processed files with n=$(minimum(n_range)) to $(maximum(n_range))")
       else
           push!(loglines, "For m=$m, processed files with n=$(minimum(n_range)) to $(maximum(n_range)) " *
                         "(missing n values: $(join(missing, ',')))")
       end
   end
   
   # Write log file
   open(joinpath(directory, "combine-log.txt"), "w") do f
       write(f, join(loglines, '\n'))
   end
   
   # Process each n value
   for n in sort(collect(n_values))
       all_sequences = Set{Vector{Int32}}()
       
       # Collect sequences from all m values
       for m in m_values
           filename = joinpath(directory, "blowdown-canonical-k$k-m$m-n$n")
           if isfile(filename)
               sequences = parse_canonical_file(filename)
               union!(all_sequences, sequences)
               # Add count to m total
               m_totals[m] += length(sequences)
           end
       end
       
       if verbose
           # Store full sequence list
           sequences_list = sort!(collect(all_sequences))  # lexicographic order
           results[n] = sequences_list
       else
           # Store just the count
           results[n] = length(all_sequences)
       end
   end
   
   # Write multiplicities file
   open(joinpath(directory, "blowdown-multiplicities-k$k.m"), "w") do f
       write(f, "{\n")
       sorted_ns = sort(collect(keys(results)))
       for (i, n) in enumerate(sorted_ns)
           if !verbose
               write(f, "{$n, $(results[n])}")
           else
               write(f, "{$n, $(length(results[n]))}")
           end
           i < length(sorted_ns) && write(f, ",\n")
       end
       write(f, "\n}")
   end
   
   # Write intersections file if verbose
   if verbose
       open(joinpath(directory, "blowdown-intersections-k$k.m"), "w") do f
           write(f, "{\n")
           sorted_ns = sort(collect(keys(results)))
           for (i, n) in enumerate(sorted_ns)
               write(f, "{$n, {")
               sequences = results[n]::Vector{Vector{Int32}}
               for (j, seq) in enumerate(sequences)
                   write(f, string('[', join(seq, ","), ']'))
                   j < length(sequences) && write(f, ",")
               end
               write(f, "}}")
               i < length(sorted_ns) && write(f, ",\n")
           end
           write(f, "\n}")
       end
   end
   
   # Write intersection distribution file
   open(joinpath(directory, "intersection-distribution-k$k.m"), "w") do f
       write(f, "{\n")
       sorted_ms = sort(collect(keys(m_totals)))
       for (i, m) in enumerate(sorted_ms)
           write(f, "{$m, $(m_totals[m])}")
           i < length(sorted_ms) && write(f, ",\n")
       end
       write(f, "\n}")
   end
end

function main()
   args = parse_commandline()
   
   # Process size files first to get m values
   m_values = process_size_files(args["k"], args["directory"])
   
   # Process canonical files
   process_canonical_files(args["k"], m_values, args["directory"], args["verbose"])
end

if abspath(PROGRAM_FILE) == @__FILE__
   main()
end
using Test
using ToricBases

@testset "All tests" begin

@testset "BaseCollection tests" begin
    # Test basic collection creation
    @test_throws ArgumentError BaseCollection(2)  # too small
    collection = BaseCollection(3)
    @test base_size(collection) == 0

    # Test CP² initialization
    collection = initialize_collection(3, 6)
    @test base_size(collection) == 1
    @test Int32[1, 1, 1] ∈ get_bases(collection)

    # Test Hirzebruch surface initialization
    collection = initialize_collection(4, 6)
    @test base_size(collection) == 13  # 0 and m for m = 1..12
    
    # Check specific Hirzebruch cases
    bases = get_bases(collection)
    @test Int32[0, 0, 0, 0] ∈ bases  # F₀
    @test Int32[-1, 0, 1, 0] ∈ bases # F₁
    @test Int32[-6, 0, 6, 0] ∈ bases # F₆
    @test Int32[-12, 0, 12, 0] ∈ bases # F₁₂
end

@testset "Geometric Operations" begin
    @testset "compute_new_intersections" begin
        # Test basic blowup
        base = Int32[1, 1, 1]  # CP²
        new_i = compute_new_intersections(base, 1)
        @test new_i == Int32[−1, 0, 1, 0]

        # Test Hirzebruch blowup
        hirz = Int32[−2, 0, 2, 0]
        @test compute_new_intersections(hirz, 1) == Int32[-1, −3, 0, 2, -1]
        @test compute_new_intersections(hirz, 2) == Int32[−3, −1, −1, 2, 0]
        
        # Test boundary cases
        @test_throws ArgumentError compute_new_intersections(base, 0)
        @test_throws ArgumentError compute_new_intersections(base, 4)
    end

    @testset "canonical form" begin
        # Test CP²
        @test canonical(Int32[1, 1, 1]) == Int32[1, 1, 1]
        
        # Test Hirzebruch surfaces
        @test canonical(Int32[2, 0, −2, 0]) == canonical(Int32[−2, 0, 2, 0])
        @test canonical(Int32[0, 2, 0, −2]) == canonical(Int32[−2, 0, 2, 0])
        
        # Test longer sequence
        seq = Int32[−2, −1, −1, 1, −1]
        @test canonical(seq) <= seq  # canonical form should be lexicographically minimal
    end

    @testset "generate_rays" begin
        # Test CP²
        cp2_rays = generate_rays(Int32[1, 1, 1])
        @test cp2_rays == [(1,0), (0,1), (-1,-1)]
        
        # Test F₁
        f1_rays = generate_rays(Int32[-1, 0, 1, 0])
        @test f1_rays == [(1,0), (0,1), (-1,1), (0,-1)]
    end

    @testset "check_lattice_properties" begin
        # Test known valid cases
        @test check_lattice_properties(Int32[1, 1, 1], 3, 6) == true  # CP²
        @test check_lattice_properties(Int32[-1, 0, 1, 0], 4, 6) == true  # F₁
        
        # Test known invalid case - too many lattice points
        @test check_lattice_properties(Int32[-1, -12, 1, 0], 4, 6) == false
    end

    @testset "process_base_collection" begin
        # Start with CP²
        input = initialize_collection(3, 6)
        output, terminal = process_base_collection(input, 6)
        
        # Check basic properties
        @test base_size(output) > 0  # should generate some bases
        @test output.intersection_length == 4  # length should increase by 1
        
        # Check that one of the known outputs (F₁) is present
        f1_canonical = canonical(Int32[-1, 0, 1, 0])
        @test f1_canonical ∈ get_bases(output)
    end
end

Base.@show "Starting I/O tests"  # This will print when we reach this point

@testset "I/O Operations" begin
    # Create temporary directory for test files
    test_dir = mktempdir()
Base.@show " made temporary directory"  # This will print when we reach this point


@testset "Size file handling" begin
    size_file = joinpath(test_dir, "sizes.m")
    
    # Test initialization
    initialize_size_file(size_file)
    content = read(size_file, String)
    @test content == "{\n{3, 1}\n}"
    
    # Test appending
    append_size_to_mathematica_file(4, 13, size_file)
    content = read(size_file, String)
    @test content == "{\n{3, 1},\n{4, 13}\n}"
    
    # Test multiple appends
    append_size_to_mathematica_file(5, 25, size_file)
    content = read(size_file, String)
    @test content == "{\n{3, 1},\n{4, 13},\n{5, 25}\n}"
end

    @testset "Collection saving/loading - text format" begin
        # Create a test collection
        collection = BaseCollection(3)
        push!(collection.bases, Int32[1, 1, 1])
        
        # Save and reload
        filename = joinpath(test_dir, "test_collection.txt")
        save_collection(collection, filename)
        loaded = load_collection(filename)
        
        # Test equality
        @test loaded.intersection_length == collection.intersection_length
        @test loaded.bases == collection.bases
        
        # Test file content
        content = read(filename, String)
        @test startswith(content, "# length=3")
        @test contains(content, "1 1 1")
    end
    
    @testset "Collection saving/loading - compressed format" begin
        # Create a test collection with multiple bases
        collection = BaseCollection(4)
        push!(collection.bases, Int32[-2, 0, 2, 0])
        push!(collection.bases, Int32[0, 0, 0, 0])
        
        # Save and reload
        filename = joinpath(test_dir, "test_collection.bin")
        save_collection(collection, filename, compress=true)
        loaded = load_collection(filename, compress=true)
        
        # Test equality
        @test loaded.intersection_length == collection.intersection_length
        @test loaded.bases == collection.bases
        
        # Test file exists and is not empty
        @test isfile(filename)
        @test filesize(filename) > 0
    end
    
    # Test error handling
    @testset "Error handling" begin
        @test_throws ErrorException load_collection("nonexistent_file.txt")
        @test_throws ErrorException load_collection("nonexistent_file.bin", compress=true)
    end
end

@testset "Terminal Base Operations" begin
    test_dir = mktempdir()
    
    @testset "Save terminal bases" begin
        # Create some test terminal bases
        terminal_bases = Set{Vector{Int32}}([
            Int32[1, 1, 1],
            Int32[-2, 0, 2]
        ])
        
        filename = joinpath(test_dir, "terminal-3.m")
        save_terminal_bases(terminal_bases, 3, filename)
        
        # Verify content
        content = read(filename, String)
        @test contains(content, "[1, 1, 1]")
        @test contains(content, "[-2, 0, 2]")
    end
    
    @testset "Consolidate terminal bases" begin
        # Create multiple terminal files
        term3 = Set{Vector{Int32}}([Int32[1, 1, 1]])
        term4 = Set{Vector{Int32}}([Int32[-2, 0, 2, 0]])
        
        save_terminal_bases(term3, 3, joinpath(test_dir, "terminal-3.m"))
        save_terminal_bases(term4, 4, joinpath(test_dir, "terminal-4.m"))
        
        # Consolidate files
        output_file = joinpath(test_dir, "all-terminal.m")
        count = consolidate_terminal_bases(test_dir, output_file)
        
        # Verify
        @test count == 2  # Total number of terminal bases
        content = read(output_file, String)
        @test startswith(content, "{")
        @test endswith(content, "}")
        @test contains(content, "{3, {[1, 1, 1]}}")
        @test contains(content, "{4, {[-2, 0, 2, 0]}}")
    end
end

end
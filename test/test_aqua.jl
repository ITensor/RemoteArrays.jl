using Aqua: Aqua
using RemoteArrays: RemoteArrays
using Test: @testset

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(RemoteArrays)
end

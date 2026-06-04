module RemoteArrays
using Dagger
using LinearAlgebra

export rarray, scopeof, RemoteArray

mutable struct RemoteArray{T, N, A} <: AbstractArray{T, N}
    task::Any
    size::NTuple{N, Int}
    function RemoteArray{T, N, A}(task, size) where {T, N, A}
        return new{T, N, A}(task, size)
    end
end

function RemoteArray{T, N, A}(task) where {T, N, A}
    size = fetch(Dagger.spawn(size, task))
    return RemoteArray{T, N, A}(task, size)
end

Base.size(ra::RemoteArray) = ra.size

Dagger.memory_space(ra::RemoteArray) = Dagger.memory_space(ra.task)

function scopeof(ra::RemoteArray)
    space = Dagger.memory_space(ra)
    return UnionScope(map(ExactScope, collect(Dagger.processors(space))))
end

storagetype(::RemoteArray{T, N, A}) where {T, N, A} = A
storagetype(::Type{<:RemoteArray{T, N, A}}) where {T, N, A} = A

function rarray(a::A, options = Dagger.Options()) where {T, N, A <: AbstractArray{T, N}}
    task = Dagger.spawn(identity, options, a)
    return RemoteArray{T, N, A}(task, size(a))
end

function rarray(a::AbstractArray, proc::Dagger.Processor)
    scope = ExactScope(proc)
    opts = Dagger.Options(; compute_scope = scope)
    return rarray(a, opts)
end

rarray(f, dims) = rarray(f, Float64, dims)
function rarray(f, ::Type{T}, dims::NTuple{N, Int64}) where {T, N}
    A = Base.promote_op(f, Type{T}, typeof(dims))
    return RemoteArray{T, N, A}(Dagger.spawn(f, T, dims), dims)
end

function Base.getindex(ra::RemoteArray, I::Vararg{Int, N}) where {N}
    return fetch(Dagger.spawn(getindex, ra.task, I...))
end

function Base.setindex!(ra::RemoteArray, v, I::Vararg{Int, N}) where {N}
    ra.task = Dagger.spawn(setindex!, ra.task, v, I...)
    return ra
end

function Base.similar(ra::RemoteArray{T, N}) where {T, N}
    A = Base.promote_op(similar, storagetype(ra))
    return RemoteArray{T, N, A}(Dagger.spawn(similar, ra.task), size(ra))
end

function Base.similar(ra::RemoteArray{T, N}, ::Type{S}) where {T, N, S}
    A = Base.promote_op(similar, storagetype(ra), Type{S})
    return RemoteArray{S, N, A}(Dagger.spawn(similar, ra.task, S), size(ra))
end

function Base.similar(ra::RemoteArray{T}, dims::NTuple{N, Int64}) where {T, N}
    A = Base.promote_op(similar, storagetype(ra), typeof(dims))
    return RemoteArray{T, N, A}(Dagger.spawn(similar, ra.task, dims), dims)
end

function Base.similar(ra::RemoteArray, ::Type{T}, dims::NTuple{N, Int64}) where {T, N}
    A = Base.promote_op(similar, storagetype(ra), Type{T}, typeof(dims))
    return RemoteArray{T, N, A}(Dagger.spawn(similar, ra.task, T, dims), dims)
end

function LinearAlgebra.mul!(
        C::RemoteArray,
        A::RemoteArray,
        B::RemoteArray,
        alpha::Number,
        beta::Number
    )
    task = Dagger.spawn(LinearAlgebra.mul!, C.task, A.task, B.task, alpha, beta)
    C.task = task
    return C
end

function Base.show(io::IO, mime::MIME"text/plain", ra::RemoteArray)
    ready = isready(ra.task)
    n, m = size(ra)

    print(io, "$(n)×$(m) $(typeof(ra)) in ")
    ion = IOContext(io, :indent => (get(io, :indent, 0) + 0))
    if ready
        scope = scopeof(ra)
        print(ion, scope, "\n")
    else
        print(ion, "unknown scope (running):", "\n")
    end

    char = ready ? () -> "✓" : () -> rand(['◒', '◐', '◓', '◑'])

    c = 1
    for i in 1:n
        print(io, "  ")
        for j in 1:m
            print(io, " ")
            print(io, char())
            if j < m
                print(io, " ")
            end
            c += 1
        end
        if i < n
            print(io, "\n")
        end
    end

    return nothing
end

Base.fetch(ra::RemoteArray) = fetch(ra.task)

end # module RemoteArrays

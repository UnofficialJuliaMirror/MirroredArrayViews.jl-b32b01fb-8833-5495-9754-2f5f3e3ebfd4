module MirroredArrays

import Base: size, getindex, setindex!, similar

export MirroredArray

struct MirroredArray{D, N, T, ARR} <: AbstractArray{T, N}
    data::ARR

    function MirroredArray(arr::AbstractArray{T, N}, dims::Int...) where {T, N}
        for dim in dims
            if !(dim >= 1 && dim <= N)
                throw(BoundsError(arr, "Expect dim <= N; dim = $dim, N = $N"))
            end
        end
        new{(dims...,), N, T, typeof(arr)}(arr)
    end
end

size(A::MirroredArray) = size(A.data)

@generated function mirror_indices(A::MirroredArray{D, N}, indices::NTuple{N, I}
                                  ) where {D, N} where I <: Integer
    dim_mask = ( (i in D for i ∈ 1:N)..., )
    mult_mask = -2 .* dim_mask .+ 1

    quote
        indices .* $mult_mask .+ (size(A) .+ 1) .* $dim_mask
    end
end

function getindex(A::MirroredArray{D, N}, indices::Vararg{I, N}
                 ) where {D, N} where I <: Integer
    A.data[mirror_indices(A, indices)...]
end

function setindex!(A::MirroredArray{D, N}, v, indices::Vararg{I, N}
                  ) where {D, N} where I <: Integer
    A.data[mirror_indices(A, indices)...] = v
end

similar(A::MirroredArray{D}) where D = MirroredArray(similar(A.data), D...)

end # module


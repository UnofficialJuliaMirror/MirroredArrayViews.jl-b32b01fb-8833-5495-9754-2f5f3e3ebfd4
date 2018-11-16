module MirroredArrayViews

import Base: size, getindex, setindex!, similar

export MirroredArrayView

struct MirroredArrayView{D, N, T, ARR} <: AbstractArray{T, N}
    data::ARR

    function MirroredArrayView(arr::AbstractArray{T, N},
                               dims::Int...;
                               checkdims::Val{B}=Val(true)) where {T, N, B}
        if B
            for dim in dims
                if !(dim >= 1 && dim <= N)
                    throw(BoundsError(arr, "Expect dim <= N; dim = $dim, N = $N"))
                end
            end
        end
        new{(dims...,), N, T, typeof(arr)}(arr)
    end
end

size(A::MirroredArrayView) = size(A.data)

@generated function mirror_indices(A::MirroredArrayView{D, N},
                                   indices::NTuple{N, I}
                                  ) where {D, N} where I <: Integer
    dim_mask = ( (i in D for i ∈ 1:N)..., )
    mult_mask = -2 .* dim_mask .+ 1

    quote
        indices .* $mult_mask .+ (size(A) .+ 1) .* $dim_mask
    end
end

function getindex(A::MirroredArrayView{D, N}, indices::Vararg{I, N}
                 ) where {D, N} where I <: Integer
    A.data[mirror_indices(A, indices)...]
end

function setindex!(A::MirroredArrayView{D, N}, v, indices::Vararg{I, N}
                  ) where {D, N} where I <: Integer
    A.data[mirror_indices(A, indices)...] = v
end

function similar(A::MirroredArrayView{D}) where D
    # Use the checkdims keyword to skip overhead of checking dimensions
    # when calling similar.
    MirroredArrayView(similar(A.data), D..., checkdims=Val(false))
end

end # module


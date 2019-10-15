mutability(::Type{BigInt}) = IsMutable()

# zero
promote_operation(::typeof(zero), ::Type{BigInt}) = BigInt
mutable_operate!(::typeof(zero), x::BigInt) = Base.GMP.MPZ.set_si!(x, 0)

# one
promote_operation(::typeof(one), ::Type{BigInt}) = BigInt
mutable_operate!(::typeof(one), x::BigInt) = Base.GMP.MPZ.set_si!(x, 1)

# +
promote_operation(::typeof(+), ::Type{BigInt}...) = BigInt
function mutable_operate_to!(output::BigInt, ::typeof(+), a::BigInt, b::BigInt)
    return Base.GMP.MPZ.add!(output, a, b)
end

# *
promote_operation(::typeof(*), ::Type{BigInt}...) = BigInt
function mutable_operate_to!(output::BigInt, ::typeof(*), a::BigInt, b::BigInt)
    return Base.GMP.MPZ.mul!(output, a, b)
end

# add_mul
function mutable_operate_to!(output::BigInt, ::typeof(add_mul), args::BigInt...)
    return mutable_buffered_operate_to!(BigInt(), output, add_mul, args...)
end
function mutable_buffered_operate_to!(buffer::BigInt, output::BigInt, ::typeof(add_mul),
                                      a::BigInt, args::BigInt...)
    mutable_operate_to!(buffer, *, args...)
    return mutable_operate_to!(output, +, a, buffer)
end

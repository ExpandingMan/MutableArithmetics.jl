# Example of mutable types that can implement this API: BigInt, Array, JuMP.AffExpr, MultivariatePolynomials.AbstractPolynomial
# `mutable_operate!(add_mul, ...)` is similar to `JuMP.add_to_expression(...)`
# `operate!(add_mul, ...)` is similar to `JuMP.destructive_add(...)`
# `operate!` is similar to `MOI.Utilities.operate!`

"""
    promote_operation(op::Function, ArgsTypes::Type...)

Returns the type returned to the call `operate(op, args...)` where the types of
the arguments `args` are `ArgsTypes`.
"""
function promote_operation end

# Define Traits
abstract type MutableTrait end
struct IsMutable <: MutableTrait end
struct NotMutable <: MutableTrait end

"""
    mutability(T::Type, ::typeof(op), args::Type...)::MutableTrait

Return `IsMutable` to indicate an object of type `T` can be modified to be
equal to `op(args...)`.
"""
function mutability(T::Type, op, args::Type...)
    if mutability(T) isa IsMutable && promote_operation(op, args...) == T
        return IsMutable()
    else
        return NotMutable()
    end
end
mutability(x, op, args...) = mutability(typeof(x), op, typeof.(args)...)
mutability(::Type) = NotMutable()

function mutable_operate_to_fallback(::NotMutable, output, op::Function, args...)
    throw(ArgumentError("Cannot call `mutable_operate_to!($output, $op, $(args...))` as `$output` cannot be modifed to equal the result of the operation. Use `operate!` or `operate_to!` instead which returns the value of the result (possibly modifying the first argument) to write generic code that also works when the type cannot be modified."))
end

function mutable_operate_to_fallback(::IsMutable, op::Function, args...)
    error("`mutable_operate_to!($op, $(args...))` is not implemented yet.")
end

"""
    mutable_operate_to!(output, op::Function, args...)

Modify the value of `output` to be equal to the value of `op(args...)`. Can
only be called if `mutability(output, op, args...)` returns `true`.
"""
function mutable_operate_to!(output, op::Function, args...)
    mutable_operate_fallback(mutability(output, op, args...), output, op, args...)
end

"""
    mutable_operate!(op::Function, args...)

Modify the value of `args[1]` to be equal to the value of `op(args...)`. Can
only be called if `mutability(args[1], op, args...)` returns `true`.
"""
function mutable_operate!(op::Function, args...)
    mutable_operate_to!(args[1], op, args...)
end

"""
    mutable_buffered_operate_to!(buffer, output, op::Function, args...)

Modify the value of `output` to be equal to the value of `op(args...)`,
possibly modifying `buffer`. Can only be called if
`mutability(output, op, args...)` returns `true`.
"""
function mutable_buffered_operate_to! end

"""
    mutable_buffered_operate!(buffer, op::Function, args...)

Modify the value of `args[1]` to be equal to the value of `op(args...)`,
possibly modifying `buffer`. Can only be called if
`mutability(args[1], op, args...)` returns `true`.
"""
function mutable_buffered_operate!(buffer, op::Function, args...)
    mutable_buffered_operate_to!(buffer, args[1], op, args...)
end

"""
    operate_to!(output, op::Function, args...)

Returns the value of `op(args...)`, possibly modifying `output`.
"""
function operate_to!(output, op::Function, args...)
    return operate_to_fallback!(mutability(output, op, args...), output, op, args...)
end

function operate_to_fallback!(::NotMutable, output, op::Function, args...)
    return op(args...)
end
function operate_to_fallback!(::IsMutable, output, op::Function, args...)
    return mutable_operate_to!(output, op, args...)
end

"""
    operate!(op::Function, args...)

Returns the value of `op(args...)`, possibly modifying `args[1]`.
"""
function operate!(op::Function, args...)
    return operate_fallback!(mutability(args[1], op, args...), op, args...)
end

function operate_fallback!(::NotMutable, op::Function, args...)
    return op(args...)
end
function operate_fallback!(::IsMutable, op::Function, args...)
    return mutable_operate!(op, args...)
end

"""
    buffered_operate_to!(buffer, output, op::Function, args...)

Returns the value of `op(args...)`, possibly modifying `buffer` and `output`.
"""
function buffered_operate_to!(buffer, output, op::Function, args...)
    return buffered_operate_to_fallback!(mutability(output, op, args...),
                                         buffer, output, op, args...)
end

function buffered_operate_to_fallback!(::NotMutable, buffer, output, op::Function, args...)
    return op(args...)
end
function buffered_operate_to_fallback!(::IsMutable, buffer, output, op::Function, args...)
    return mutable_buffered_operate_to!(buffer, output, op, args...)
end

"""
    buffered_operate!(buffer, op::Function, args...)

Returns the value of `op(args...)`, possibly modifying `buffer`.
"""
function buffered_operate!(buffer, op::Function, args...)
    return buffered_operate_fallback!(mutability(args[1], op, args...),
                                      buffer, op, args...)
end

function buffered_operate_fallback!(::NotMutable, buffer, op::Function, args...)
    return op(args...)
end
function buffered_operate_fallback!(::IsMutable, buffer, op::Function, args...)
    return mutable_buffered_operate!(buffer, op, args...)
end
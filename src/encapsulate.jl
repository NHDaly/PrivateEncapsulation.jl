function _get_field end

params(ex) = isexpr(ex, :curly) ? ex.args[2:end] : []
tname(ex) = isexpr(ex, :curly) ? ex.args[1] : ex

get_struct_def(ex) = nothing
function get_struct_def(ex::Expr)
    if ex.head === :struct
        return ex
    elseif ex.head === :block
        for arg in ex.args
            maybe = get_struct_def(arg)
            if maybe !== nothing
                return maybe
            end
        end
        return nothing
    end
    return nothing
end

macro encapsulate(ex)
    @assert ex.head === :struct || ex.head === :macrocall
    if ex.head === :macrocall
        ex = macroexpand(__module__, ex)
        struct_def = get_struct_def(ex)
    else
        struct_def = ex
    end
    @assert struct_def.head === :struct
    @capture(struct_def, struct T_ <: ParentType_ fields__ end |
                 struct T_ fields__ end |
                 mutable struct T_ <: ParentType_ fields__ end |
                 mutable struct T_ fields__ end) ||
        throw(ErrorException("Usage: @encapsulate struct ..."))
    return quote
        $(esc(ex))
        function Base.getproperty(x::$(esc(T)), field::Symbol) where {$(esc.(params(T))...)}
            throw(EncapsulationViolation(x, field))
        end
        # const $(Symbol("$(T)FriendModulesArray")) = [$(esc(__module__))]
        function $PrivateEncapsulation._get_field(mod::Module, x::$(esc(T)), field::Symbol) where {$(esc.(params(T))...)}
            mod == $(esc(__module__)) || throw(EncapsulationViolation(x, field, mod))
            return getfield(x, field)
        end
        Base.@__doc__ $(esc(tname(T)))
    end
end

macro access(ex)
    @assert ex.head === :(.) && length(ex.args) == 2
    (a, b) = ex.args
    return :($PrivateEncapsulation._get_field($(esc(__module__)), $(esc(a)), $(esc(b))))
end
# TODO: How to friend other modules in a performant way?
# macro friend(ex)
#     (a, b) = ex.args
#     return :($PrivateEncapsulation._get_field($(esc(__module__)), $(esc(a)), $(esc(b))))
# end

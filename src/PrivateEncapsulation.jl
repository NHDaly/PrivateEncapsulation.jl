module PrivateEncapsulation

using MacroTools: MacroTools
using MacroTools: @capture, @q
using MacroTools: isexpr, namify

export @encapsulate, @access, EncapsulationViolation

struct EncapsulationViolation <: Exception
    obj::Any
    field::Symbol
    mod::Union{Nothing,Module}
end
EncapsulationViolation(obj, field::Symbol) = EncapsulationViolation(obj, field, nothing)

function Base.showerror(io::IO, ex::EncapsulationViolation)
    if ex.mod === nothing
        println(io, "EncapsulationViolation: Illegal direct field access `getproperty(::",
                typeof(ex.obj), ", ", Meta.quot(ex.field), ")`.\n",
                "  Object: ", ex.obj, "\n\n",
                "  Fields of this struct cannot be accessed from outside the module.",)
    else
        println(io, "EncapsulationViolation: Illegal call to `@access` from module `",
                ex.mod, "` for `getproperty(::", typeof(ex.obj), ", ", Meta.quot(ex.field),
                ")`.\n",
                "  Object: ", ex.obj, "\n\n",
                "  Fields of this struct cannot be accessed from outside the module.",)
    end
end

include("encapsulate.jl")

end # module PrivateEncapsulation

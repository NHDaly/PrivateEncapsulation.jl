module PrivateEncapsulation

using MacroTools: MacroTools
using MacroTools: @capture, @q
using MacroTools: isexpr, namify

export @encapsulate, @access, EncapsulationViolation

"""
    @encapsulate struct S ... end

Defines a struct `S` with private fields. The fields of the struct cannot be accessed
directly from outside the module.

Illegal access from outside the module throws an `EncapsulationViolation` exception.

Within the module defining the struct, to access the fields, use `@access(x.field)`.
See also:
  - `@access` for accessing fields of the struct.
"""
macro encapsulate end

"""
    @access x.field
    @access(x.field)

Access `field` of the object `x`, a struct defined in the current module via the
`@encapsulate` macro.

Outside this module, `@access(x.field)` throws an `EncapsulationViolation` exception.

See also:
  - `@encapsulate`
"""
macro access end

include("exception.jl")
include("encapsulate.jl")

end # module PrivateEncapsulation

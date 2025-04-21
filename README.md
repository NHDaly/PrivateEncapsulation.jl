# PrivateEncapsulation

[![Build Status](https://github.com/nhdaly/PrivateEncapsulation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/nhdaly/PrivateEncapsulation.jl/actions/workflows/CI.yml?query=branch%3Amain)


## Example:
```julia
julia> module MyVectors
           using PrivateEncapsulation: @encapsulate, @access
           @encapsulate struct MyStack{T}
               v::Vector{T}
           end
           MyStack{T}() where {T} = MyStack{T}(Vector{T}())
           Base.push!(v::MyStack, x) = (push!(@access(v.v), x); v)
           Base.pop!(v::MyStack) = pop!(@access(v.v))
           Base.length(v::MyStack) = length(@access(v.v))
       end
Main.MyVectors
```
Outside that module:
```julia

julia> s = MyVectors.MyStack{Int}()
Main.MyVectors.MyStack{Int64}(Int64[])

julia> push!(s, 1)
Main.MyVectors.MyStack{Int64}([1])

julia> length(s)
1

julia> s.v
ERROR: EncapsulationViolation: Illegal direct field access `getproperty(::Main.MyVectors.MyStack{Int64}, :v)`.
  Object: Main.MyVectors.MyStack{Int64}([1])

  Fields of this struct cannot be accessed from outside the module.

Stacktrace:
 [1] getproperty(x::Main.MyVectors.MyStack{Int64}, field::Symbol)
   @ Main.MyVectors ~/work/Delve/packages/PrivateEncapsulation/src/encapsulate.jl:15
 [2] top-level scope
   @ REPL[36]:1

julia> @access(s.v)
ERROR: EncapsulationViolation: Illegal call to `@access` from module `Main` for `getproperty(::Main.MyVectors.MyStack{Int64}, :v)`.
  Object: Main.MyVectors.MyStack{Int64}([1])

  Fields of this struct cannot be accessed from outside the module.

Stacktrace:
 [1] _get_field(mod::Module, x::Main.MyVectors.MyStack{Int64}, field::Symbol)
   @ Main.MyVectors ~/work/Delve/packages/PrivateEncapsulation/src/encapsulate.jl:19
 [2] top-level scope
   @ REPL[37]:1
```

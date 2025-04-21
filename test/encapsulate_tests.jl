@testitem "@encapsulate @access Example: Vector" begin
    module MyVectors
        using PrivateEncapsulation: @encapsulate, @access
        @encapsulate struct MyStack{T}
            v::Vector{T}
        end
        MyStack{T}() where {T} = MyStack{T}(Vector{T}())
        Base.push!(v::MyStack, x) = (push!(@access(v.v), x); v)
        Base.pop!(v::MyStack) = pop!(@access(v.v))
        Base.length(v::MyStack) = length(@access(v.v))
    end
    s = MyVectors.MyStack{Int}()
    @test length(s) == 0
    @test push!(s, 1) == s
    @test length(s) == 1
    @test pop!(s) == 1

    @test_throws EncapsulationViolation(s, :v) s.v
    @test_throws EncapsulationViolation(s, :v) s.v[1]
    @test_throws EncapsulationViolation(s, :v, @__MODULE__) @access(s.v)
end

@testitem "Error handling" begin
    module Foos
        using PrivateEncapsulation: @encapsulate, @access
        @encapsulate struct Foo
            x
        end
    end
    f = Foos.Foo(5)
    @test_throws EncapsulationViolation(f, :x) f.x
    @test_throws EncapsulationViolation(f, :x, @__MODULE__) @access(f.x)

    e = try f.x catch ex; ex end
    @test sprint(Base.showerror, e) ==
        """
        EncapsulationViolation: Illegal direct field access `getproperty(::$Foos.Foo, :x)`.
          Object: $Foos.Foo(5)

          Fields of this struct cannot be accessed from outside the module.
        """

    e = try @access(f.x) catch ex; ex end
    @test sprint(Base.showerror, e) ==
        """
        EncapsulationViolation: Illegal call to `@access` from module `$(@__MODULE__)` \
            for `getproperty(::$Foos.Foo, :x)`.
          Object: $Foos.Foo(5)

          Fields of this struct cannot be accessed from outside the module.
        """
end

@testitem "@encapsulate macro edge cases" begin
    # (The macro returns the struct that was defined in the macro.)
    @test @eval(@encapsulate struct S1 end) == @eval(S1)

    abstract type A1 end
    @test @eval(@encapsulate struct S2 <: A1
        x
    end) == @eval(S2)
    @test_throws EncapsulationViolation(S2(1), :x) S2(1).x
    # Inside the same module it's fine.
    @test @access(S2(1).x) == 1

    abstract type A2{T} end
    @test @eval(@encapsulate struct S3{T1,T2} <: A2{T2}
        x::T1
        y::T2
    end) == @eval(S3)
    @test_throws EncapsulationViolation(S3(1, 2), :x) S3(1, 2).x
    @test_throws EncapsulationViolation(S3(1, 2), :y) S3(1, 2).y
    @test @access(S3(1,2).x) == 1
    @test @access(S3(1,2).y) == 2

    @test @eval(@encapsulate mutable struct M1 end) == @eval(M1)
    @test @eval(@encapsulate mutable struct M2 <: A1 end) == @eval(M2)
    @test @eval(@encapsulate mutable struct M3 <: A2{M3} end) == @eval(M3)

    @test @eval(@encapsulate mutable struct M4 <: A1
        x
        y::Int
    end) == @eval(M4)

    m = M4(1, 2)
    @test_throws EncapsulationViolation(m, :x) m.x
    @test_throws EncapsulationViolation(m, :y) m.y
    @test @access(m.x) == 1
    @test @access(m.y) == 2
end

@testitem "docstrings" begin
    """
    MyStruct is great
    """
    @encapsulate struct MyStruct end

    @test string(@doc(MyStruct)) == "MyStruct is great\n"
end

@testitem "@encapsulate macro errors" begin
    # @encapsulate must immediately be followed by a struct or mutable struct.
    @test_throws Exception @eval(@encapsulate begin struct S1 end ; struct S2 end end)
    @test_throws Exception @eval(@encapsulate 10)
    @test_throws Exception @eval(@encapsulate foo(x) = 2)
end


@testitem "@encapsulate composes with other macros" begin
    abstract type A1 end
    @test @eval(@encapsulate Base.@kwdef struct S1 <: A1
        x
        y::Int
    end) == @eval(S1)
    @test S1(x = 1, y = 2) == S1(1, 2)
    s = S1(x = 1, y = 2)
    @test_throws EncapsulationViolation(s, :x) s.x
    @test @access(s.x) == 1

    """
    S2 is great
    """
    @encapsulate Base.@kwdef struct S2 <: A1
        x
    end
    @test S2(x = 1) == S2(1)
    @test_throws EncapsulationViolation(S2(1), :x) S2(1).x
    @test @access(S2(1).x) == 1

    @test string(@doc(S2)) == "S2 is great\n"
end

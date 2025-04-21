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

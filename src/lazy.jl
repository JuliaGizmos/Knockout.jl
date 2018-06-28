struct LazyPair{T}
    first::Observable{T}
    second::Observable{Any}
    f
    g
    function LazyPair(first::Observable{T}, second::Observable, f, g) where {T}
        on(first) do val
            fval = f(val)
            (second[] == fval) || Observables.setexcludinghandlers(second, fval, x -> x !== g)
        end
        on(second) do val
            gval = g(val)
            (first[] == gval) || Observables.setexcludinghandlers(first, gval, x -> x !== f)
        end
        new{T}(first, second, f, g)
    end
end

LazyPair(first::Observable, second = Observable{Any}(first[]); f = identity, g = identity) =
    LazyPair(first, second, f, g)

struct LazyPair{T}
    first::Observable{T}
    second::Observable{Any}
    f
    g
    function LazyPair(first::Observable{T}, second::Observable; f = identity, g = identity) where {T}
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

LazyPair(first::Observable; f = identity, g = identity) =
    LazyPair(first, Observable{Any}(f(first[])); f = f, g = g)

_get(x) = x
_get(x::Observable) = x[]
_get(x::LazyPair) = _get(x.second)

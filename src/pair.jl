struct ObservablePair{T}
    first::Observable{T}
    second::Observable
    f
    g
    function ObservablePair(first::Observable{T}, second::Observable; f = identity, g = identity) where {T}
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

ObservablePair(first::Observable; f = identity, g = identity) =
    ObservablePair(first, Observable{Any}(f(first[])); f = f, g = g)

struct ObservablePair{S, T}
    first::Observable{S}
    second::Observable{T}
    f
    g
    first2second
    second2first
    function ObservablePair(first::Observable{S}, second::Observable{T}; f = identity, g = identity) where {S, T}
        first2second = on(first) do val
            fval = f(val)
            (second[] == fval) || Observables.setexcludinghandlers(second, fval, x -> x !== g)
        end
        second2first = on(second) do val
            gval = g(val)
            (first[] == gval) || Observables.setexcludinghandlers(first, gval, x -> x !== f)
        end
        new{S, T}(first, second, f, g, first2second, second2first)
    end
end

ObservablePair(first::Observable; f = identity, g = identity) =
    ObservablePair(first, Observable{Any}(f(first[])); f = f, g = g)

off(o::ObservablePair) = (off(o.first, o.first2second); off(o.second, o.second2first))

unwrap(x) = x
function unwrap(obs::Observable{<:Observable})
    obs1 = obs[]
    obs2 = Observable{Any}(obs1[])
    p = ObservablePair(obs1, obs2)
    on(obs) do val
        off(p)
        (val[] != obs2[]) && (obs2[] = val[])
        p = ObservablePair(val, obs2)
    end
    obs2
end

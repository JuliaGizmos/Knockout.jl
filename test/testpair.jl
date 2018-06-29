v = Knockout.ObservablePair(Observable(1.0), f = exp, g = log)
@test v.second[] ≈ e
v.first[] = 0
@test v.second[] ≈ 1
v.second[] = 2
@test v.first[] ≈ log(2)

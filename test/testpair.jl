using Observables
import Compat.MathConstants: e

v = Knockout.ObservablePair(Observable(1.0), f = exp, g = log)
@test v.second[] ≈ e
v.first[] = 0
@test v.second[] ≈ 1
v.second[] = 2
@test v.first[] ≈ log(2)

obs = Observable(Observable(2))
o2 = Knockout.unwrap(obs)

o2[] = 12
sleep(0.1)
@test obs[][] == 12
obs[][] = 22
sleep(0.1)
@test o2[] == 22
obs[] = Observable(11)
sleep(0.1)
@test o2[] == 11

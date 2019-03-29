const _pkg_root = dirname(dirname(@__FILE__))
const _pkg_deps = joinpath(_pkg_root,"deps")
const _pkg_assets = joinpath(_pkg_root,"assets")

!isdir(_pkg_assets) && mkdir(_pkg_assets)

download("https://cdn.jsdelivr.net/npm/@tko/build.reference@4.0.0-alpha8/dist/build.reference.min.js", joinpath(_pkg_assets, "knockout.js"))

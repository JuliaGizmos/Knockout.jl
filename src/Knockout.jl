module Knockout

using WebIO, Observables, JSExpr, JSON

export knockout

const knockout_js = joinpath(@__DIR__, "..", "assets", "knockout.js")

function knockout(template, data, extra_js = js"")
    id = WebIO.newid("knockout-component")
    widget = Scope(;
        imports=Any[knockout_js]
    )
    widget.dom = Node(:div, template, attributes=Dict("name" => id))
    ko_data = Dict()
    watches = Dict()
    for (k, v) in data
        skey = string(k)
        ko_data[skey] = isa(v, Observable) ? v[] : v
        if isa(v, Observable)
            # associate the observable with the widget
            setobservable!(widget, skey, v)

            # forward updates from Julia to Knockoutjs
            onjs(v, @js function (val)
                this.model[$skey](val)
            end)

            # forward updates from Knockoutjs to Julia
            watches[skey] = @js this[$skey].subscribe( function(newText)
                $v[] = newText
            end)
        end
    end

    json_data = JSON.json(ko_data)
    on_import = js"""
    function (ko) {
        function AppViewModel() {
            var json_data = JSON.parse($json_data);
            for (var key in json_data) {
                this[key] = ko.observable(json_data[key]);
            }
            $(values(watches)...)
            $extra_js
        }
        var elements = document.getElementsByName($id);
        var element = elements[elements.length-1];
        this.model = new AppViewModel();
        ko.applyBindings(this.model, element);
    }
    """
    onimport(widget, on_import)
    widget
end

end # module

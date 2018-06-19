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
                if val != this.model[$skey]()
                    this.valueFromJulia[$skey] = true
                    this.model[$skey](val)
                end
            end)

            # forward updates from Knockoutjs to Julia
            watches[skey] = @js this[$skey].subscribe( function(val)
                if !self.valueFromJulia[$skey]
                    $v[] = val
                end
                self.valueFromJulia[$skey] = false
            end)
        end
    end

    json_data = JSON.json(ko_data)
    on_import = js"""
    function (ko) {
        ko.extenders.preserveType = function(target, isNumber) {
            var result = ko.pureComputed({
                read: target,
                write: function(newValue) {
                    var current = target();
                    var valueToWrite = isNumber ? parseFloat(newValue) : newValue;
                    if (valueToWrite !== current) {
                        target(valueToWrite);
                    }
                }
            })
            result(target());

            return result;
        };
        var json_data = JSON.parse($json_data);
        var self = this;
        function AppViewModel() {
            for (var key in json_data) {
                var isNumber = (typeof(json_data[key]) == "number");
                this[key] = ko.observable(json_data[key]).extend({preserveType: isNumber});
            }
            $(values(watches)...)
            $extra_js
        }
        var elements = document.getElementsByName($id);
        var element = elements[elements.length-1];
        self.model = new AppViewModel();
        self.valueFromJulia = {};
        for (var key in json_data) {
            self.valueFromJulia[key] = false;
        }
        ko.applyBindings(self.model, element);
    }
    """
    onimport(widget, on_import)
    widget
end

end # module

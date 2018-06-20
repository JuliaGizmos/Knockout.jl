__precompile__()

module Knockout

using WebIO, Observables, JSExpr, JSON

export knockout

const knockout_js = joinpath(@__DIR__, "..", "assets", "knockout.js")

function knockout(template, data, extra_js = js""; computed = [], methods = [])
    id = WebIO.newid("knockout-component")
    widget = Scope(id;
        imports=Any[knockout_js]
    )
    widget.dom = template
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

    methods_dict = Dict()
    for (k, f) in methods
        skey = string(k)
        methods_dict[skey] = @js this[$skey] = $f
    end

    computed_dict = Dict()
    for (k, f) in computed
        skey = string(k)
        computed_dict[skey] = @js this[$skey] = ko.computed($f, this)
    end

    json_data = JSON.json(ko_data)
    on_import = js"""
    function (ko) {
        ko.extenders.preserveType = function(target, preserve) {
            var result = ko.pureComputed({
                read: target,
                write: function(newValue) {
                    var current = target();
                    var isNumber = typeof(current) == 'number';
                    var valueToWrite = (preserve && isNumber) ? parseFloat(newValue) : newValue;
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
                this[key] = ko.observable(json_data[key]).extend({preserveType: true});
            }
            $(dict2js(methods_dict))
            $(dict2js(computed_dict))
            $(dict2js(watches))
            $extra_js
        }
        self.model = new AppViewModel();
        self.valueFromJulia = {};
        for (var key in json_data) {
            self.valueFromJulia[key] = false;
        }
        ko.applyBindings(self.model, self.dom);
    }
    """
    onimport(widget, on_import)
    widget
end

function dict2js(d::Associative)
    isempty(d) ? js"" : js"$(values(d)...)"
end

end # module

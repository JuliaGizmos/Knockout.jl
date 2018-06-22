using Knockout, WebIO, Blink
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here
s = Observable(["a", "b", "c"])
t = Node(:select, attributes = Dict("data-bind" => "options : options"));
n = (knockout(t, ["options" => s]));
cleanup = !AtomShell.isinstalled()

cleanup && AtomShell.install()

w = Window(Blink.@d(:show => false)); sleep(5.0)

body!(w, n)

str = "<select data-bind=\"options : options\">" *
    "<option value=\"a\">a</option>" *
    "<option value=\"b\">b</option>" *
    "<option value=\"c\">c</option>" *
    "</select></div>"
blink_body = Blink.@js w document.querySelector("body").innerHTML
@test contains(blink_body, str)

s[] = ["c", "d"]
sleep(1.0)
str = "<select data-bind=\"options : options\">" *
    "<option value=\"c\">c</option>" *
    "<option value=\"d\">d</option>" *
    "</select></div>"

blink_body = Blink.@js w document.querySelector("body").innerHTML
@test contains(blink_body, str)

cleanup && AtomShell.uninstall()

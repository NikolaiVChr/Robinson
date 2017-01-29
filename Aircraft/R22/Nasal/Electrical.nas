####    simple electrical system    ####
####    Syd Adams    ####

aircraft.light.new("controls/lighting/strobe-state", [1.0, 1.0], "controls/lighting/strobe");

setlistener("/sim/signals/fdm-initialized", func {
    print("Electrical ... Check");
    settimer(update_electrical,5);
});


var update_bus=func {
    var amps=0;
    var batt_vlt = getprop("systems/electrical/sources/battery");
    var batt_swt= getprop("controls/electric/battery-switch");
    var batt_output=batt_vlt * batt_swt;
    var alt_vlt = getprop("systems/electrical/sources/alternator");
    var alt_swt=getprop("controls/electric/engine/generator");
    var n1 = getprop("engines/engine/n1") -10;
    n1 *=0.033333;
    if(n1>1.0)n1=1.0;
    if(n1< 0.0)n1=0.0;
    var alt_output=(alt_vlt * alt_swt) * n1;
    if(batt_output>alt_output){
        setprop("systems/electrical/sources/bus",batt_output);
        setprop("systems/electrical/amps",batt_output * -2.5);
    }else{
        setprop("systems/electrical/sources/bus",alt_output);
        setprop("systems/electrical/amps",alt_output * 0.8);
    }
}

var update_outputs=func {
    var outprop="systems/electrical/outputs/";
    var power = getprop("systems/electrical/sources/bus");
    setprop(outprop~"adf",power);
    setprop(outprop~"nav",power);
    setprop(outprop~"transponder",power);
}

var update_variables=func {
    var outprop="systems/electrical/outputs/norm/";
    var power = getprop("systems/electrical/sources/bus");
    var power_norm=0;
    if(power > 0.0) power_norm = power * (1.0 / power);
    var dimmer = getprop("controls/lighting/dimmer-switch");
    setprop(outprop~"instrument-lights",power_norm * dimmer);
    setprop(outprop~"strobe",power_norm * getprop("controls/lighting/strobe-state/state"));
    setprop(outprop~"landing-lights",power_norm * getprop("controls/lighting/landing-lights"));
    setprop(outprop~"nav-lights",power_norm * getprop("controls/lighting/nav-lights"));
}

var update_electrical = func {
    update_bus();
    update_outputs();
    update_variables();
    settimer(update_electrical, 0);
}


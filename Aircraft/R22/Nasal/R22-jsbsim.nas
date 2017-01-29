aircraft.livery.init("Aircraft/R22/Models/Liveries", "sim/model/livery/name", "sim/model/livery/index");
var RPM_arm=props.globals.getNode("/instrumentation/alerts/rpm",1);
var engine_on=props.globals.initNode("engines/engine/on",0,"BOOL");
var electric_key=props.globals.getNode("/controls/electric/key",1);
var last_time = 0;
var start_timer=0;

var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

setlistener("/sim/signals/fdm-initialized", func {
    setprop("/instrumentation/clock/flight-meter-hour",0);
    setprop("controls/engines/engine/propeller-pitch",0);
    setprop("/rotors/main/blade/position-deg", 0);
    setprop("/rotors/main/blade[1]/position-deg", 180);
    setprop("/rotors/tail/blade/position-deg", 0);
    setprop("/rotors/tail/blade[1]/position-deg", 180);
    RPM_arm.setBoolValue(0);
    print("Systems ... Check");
    settimer(update_systems,2);
    setprop("sim/model/sound/volume", 0.5);
});

setlistener("/sim/signals/reinit", func {
    RPM_arm.setBoolValue(0);
    setprop("sim/model/autostart",0);
    setprop("controls/engines/engine/propeller-pitch",0);
    Shutdown();
});

setlistener("/sim/current-view/internal", func(vw) {
    if(vw.getValue()){
        setprop("sim/model/sound/volume1", 0.5);
    }else setprop("sim/model/sound/volume1", 1.0);
},1,0);

setlistener("/gear/gear[1]/wow", func(gr) {
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);

setlistener("/sim/crashed", func(ko) {
    if(ko.getValue()){
    kill_engine();
    setprop("/rotors/main/rpm",0);
    setprop("/rotors/tail/rpm",0);
    setprop("sim/model/autostart",0);
    }
},0,0);

setlistener("/sim/model/autostart", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

setlistener("controls/electric/key", func{
    var mg=electric_key.getValue(0);
    setprop("controls/engines/engine/magnetos", mg);
},1,0);

var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/electric/key",3);
setprop("controls/engines/engine/magnetos",3);
setprop("controls/engines/engine/propeller-pitch",0);
engine_on.setValue(1);
setprop("controls/engines/engine[0]/clutch",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/lighting/instrument-lights",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/electric/key",0);
setprop("controls/engines/engine/magnetos",0);
setprop("controls/engines/engine[0]/clutch",0);
setprop("controls/engines/engine/propeller-pitch",0);
engine_on.setValue(0);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}


var mysin = func(theta){
    var sin = theta / 90.;
    if (sin > 3) sin -=4;
    if (sin > 1) sin=2-sin;
    return(sin);
}


var main_rotor = func{
    var omega = getprop("fdm/jsbsim/propulsion/engine/rotor-rpm") * 60;
    var a0    =getprop("fdm/jsbsim/propulsion/engine/a0-rad")* 57.29578;
    var a1    =getprop("fdm/jsbsim/propulsion/engine/a1-rad")* 57.29578;
    var b1    =getprop("fdm/jsbsim/propulsion/engine/b1-rad")* 57.29578;

    if (omega < 61) omega=0; # JSBSim always turns at 1 RPM.
    var deltaT= getprop("/sim/time/delta-sec");
    var blade = getprop("/rotors/main/blade/position-deg");
    blade += omega*deltaT;
    while (blade > 360) blade -= 360;
    if (blade > 180){
       var blade1 = blade - 180;
    }else{
       var blade1 = blade + 180;
    }

    var flap = a0 - math.sin(blade /57.296) * b1 - math.cos(blade /57.296) *a1;
    var flap1= a0 - math.sin(blade1/57.296) * b1 - math.cos(blade1/57.296) *a1;

    setprop("/rotors/main/blade/position-deg", blade);
    setprop("/rotors/main/blade/flap-deg",     flap);
    setprop("/rotors/main/blade[1]/position-deg", blade1);
    setprop("/rotors/main/blade[1]/flap-deg",     flap1);

}

var tail_rotor = func{
    var omega = getprop("fdm/jsbsim/propulsion/engine[1]/rotor-rpm") * 60;
    var a0    =getprop("fdm/jsbsim/propulsion/engine[1]/a0-rad")* 57.29578;
    var a1    =getprop("fdm/jsbsim/propulsion/engine[1]/a1-rad")* 57.29578;
    var b1    =getprop("fdm/jsbsim/propulsion/engine[1]/b1-rad")* 57.29578;

    if (omega < 61) omega=0; # JSBSim always turns at 1 RPM.
    var deltaT= getprop("/sim/time/delta-sec");
    var blade = getprop("/rotors/tail/blade/position-deg");
    blade += omega*deltaT;
    while (blade > 360) blade -= 360;
    if (blade > 180){
       var blade1 = blade - 180;
    }else{
       var blade1 = blade + 180;
    }

    var flap = a0 - math.sin(blade /57.296) * b1 - math.cos(blade /57.296) *a1;
    var flap1= a0 - math.sin(blade1/57.296) * b1 - math.cos(blade1/57.296) *a1;

    setprop("/rotors/tail/blade/position-deg", blade);
    setprop("/rotors/tail/blade/flap-deg",     flap);
    setprop("/rotors/tail/blade[1]/position-deg", blade1);
    setprop("/rotors/tail/blade[1]/flap-deg",     flap1);

}

var kill_engine=func{
        setprop("/engines/engine/clutch-engaged",0);
        engine_on.setValue(0);
        start_timer=0;
}




var update_systems = func {

    
#    var fuel = 1 - getprop("engines/engine/out-of-fuel");
#    var running =engine_on.getValue() * fuel;
#    if(running==0)engine_on.setValue(running);
#     var throttle = getprop("/controls/rotor/engine-throttle");
    flight_meter();
    main_rotor();
    tail_rotor();
if(!RPM_arm.getBoolValue()){
if(getprop("/rotors/main/rpm") > 450)RPM_arm.setBoolValue(1);
}



#if(!running){
#    if(getprop("controls/engines/engine/starter")) start_timer+=1 else start_timer = 0;
#    if(start_timer >60){
#        running=1 * fuel;
#        start_timer=0;
#        engine_on.setValue(running);
#    }
#    setprop("/engines/engine/clutch-engaged",running);
#}elsif(running){
#    if(getprop("/controls/engines/engine/clutch")){
#        setprop("/engines/engine/clutch-engaged",running);
#        }else{
#           setprop("/engines/engine/clutch-engaged",0);
#        }
#    }

settimer(update_systems,0);
}



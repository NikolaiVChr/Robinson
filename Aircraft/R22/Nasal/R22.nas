aircraft.livery.init("Aircraft/R22/Models/Liveries", "sim/model/livery/name", "sim/model/livery/index");
var RPM_arm=props.globals.getNode("/instrumentation/alerts/rpm",1);
var engine_on=props.globals.initNode("engines/engine/on",0,"BOOL");
var last_time = 0;
var start_timer=0;

var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

setlistener("/sim/signals/fdm-initialized", func {
    setprop("/instrumentation/clock/flight-meter-hour",0);
    RPM_arm.setBoolValue(0);
    print("Systems ... Check");
    settimer(update_systems,2);
    setprop("sim/model/sound/volume", 0.5);
});

setlistener("/sim/signals/reinit", func {
    RPM_arm.setBoolValue(0);
    setprop("/controls/engines/engine/throttle",1);
    setprop("sim/model/autostart",0);
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

setlistener("controls/engines/engine/magnetos", func(mg){
    if(mg.getValue() == 0)engine_on.setValue(0);
},1,0);


var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/electric/key",3);
setprop("controls/engines/engine/magnetos",3);
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
engine_on.setValue(0);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

var kill_engine=func{
        setprop("/controls/engines/engine/magnetos",0);
        setprop("/engines/engine/clutch-engaged",0);
        engine_on.setValue(0);
        start_timer=0;
}




var update_systems = func {

    
    var fuel = 1 - getprop("engines/engine/out-of-fuel");
    var running =engine_on.getValue() * fuel;
    if(running==0)engine_on.setValue(running);
     var throttle = getprop("/controls/rotor/engine-throttle");
    flight_meter();
if(!RPM_arm.getBoolValue()){
if(getprop("/rotors/main/rpm") > 525)RPM_arm.setBoolValue(1);
}



if(!running){
    if(getprop("controls/engines/engine/starter")) start_timer+=1 else start_timer = 0;
    if(start_timer >60){
        running=1 * fuel;
        start_timer=0;
        engine_on.setValue(running);
    }
    setprop("/engines/engine/clutch-engaged",running);
}elsif(running){
    if(getprop("/controls/engines/engine/clutch")){
        setprop("/engines/engine/clutch-engaged",running);
        }else{
            setprop("/engines/engine/clutch-engaged",0);
        }
    }

settimer(update_systems,0);
}



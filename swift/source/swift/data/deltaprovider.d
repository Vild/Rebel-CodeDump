module swift.data.deltaprovider;

import swift.engine;
import swift.data.dataprovider;
import swift.event.deltaevent;

import std.datetime : Clock, TickDuration;

class DeltaProvider : DataProvider {
public:
	this() {
		oldtime = Clock.currAppTick;
	}

	mixin BaseDataProvider;

	void Update(Engine engine) {
		TickDuration curtime = Clock.currAppTick;
		TickDuration diff = curtime - oldtime;
		double delta = diff.usecs; //1 000 000 µsec/ 1 sec
		engine.EventQueue ~= new DeltaEvent(delta/1_000_000);
		oldtime = curtime;
	}
private:
	TickDuration oldtime;
}


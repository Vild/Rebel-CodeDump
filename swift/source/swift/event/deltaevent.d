module swift.event.deltaevent;

import swift.event.event;

class DeltaEvent : Event {
public:
	this(double delta) {
		this.delta = delta;
		extraData = ["Delta": delta];
	}

	@property double Delta() { return delta; }

	mixin BaseEvent;
private:
	double delta;
}


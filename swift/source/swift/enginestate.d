module swift.enginestate;

import swift.engine;
import swift.event.event;

abstract class EngineState {
public:
	abstract void Start(Engine engine); //Illegal to change state here!
	abstract void Tick(Engine engine, Event[] events);
	abstract void Stop(Engine engine); //Illegal to change state here!
}
module swift.engine;

import core.thread : Thread;
import core.time : dur;

import swift.data.convar;
import swift.data.dataprovider;
import swift.enginestate;
import swift.event.event;
import swift.log.log;

class Engine {
public:
	this() {
		log = log.MainLogger;
		state = null;
		newstate = null;
		eventQueue.reserve(64);
	}

	~this() {
		eventQueue.destroy;
		dataProviders.destroy;
		if (state !is null)
			state.destroy;
	}

	void MainLoop() {
		if (state is null)
			destroy(state);
		state = newstate;
		newstate = null;
		assert(state !is null, "Engine must have a EngineState!");
		quit = false;
		int i = 0;
		state.Start(this);
		while (!quit) {
			foreach (DataProvider dp; dataProviders)
				dp.Update(this);
			beforeTick();
			state.Tick(this, eventQueue);
			afterTick();
			eventQueue = [];

			if (newstate !is null) {
				state.Stop(this);
				if (state is null)
					destroy(state);
				state = newstate;
				newstate = null;
				state.Start(this);
			}
		}
		state.Stop(this);
	}

	@property ref Log Logger() { return log; }
	@property ref EngineState State() { return state; }
	@property ref EngineState State(EngineState state) {
		newstate = state;
		return this.state;
	}

	@property ref DataProvider[] DataProviders() { return dataProviders; }
	@property ref Event[] EventQueue() { return eventQueue; }

	@property ref bool Quit() { return quit; }

protected:
	void beforeTick() {} //For engine stuff
	void afterTick() {} //For engine stuff

	Log log;
	EngineState state;
	EngineState newstate;

	DataProvider[] dataProviders;
	Event[] eventQueue;

	bool quit;
}

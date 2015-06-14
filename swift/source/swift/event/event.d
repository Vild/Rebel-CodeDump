module swift.event.event;

interface Event {
	string toString();
}

mixin template BaseEvent() {
	private import std.json;

	override string toString() {
		auto addArray(JSONValue a, JSONValue b) {
			JSONValue ret = JSONValue(a);

			if (b.type == JSON_TYPE.OBJECT)
				foreach(string key, JSONValue val; b)
					ret.object()[key] = val;

			return ret;
		}
		JSONValue roota = ["Class" : this.classinfo.name];
		JSONValue root = JSONValue(addArray(roota, extraData));

		return toJSON(&root, true);
	}

	JSONValue extraData;
}
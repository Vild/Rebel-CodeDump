module swift.data.dataprovider;

import swift.engine;

interface DataProvider {
	void Update(Engine engine);

	string toString();
}

mixin template BaseDataProvider() {
	override string toString() {
		return this.classinfo.name;
	}
}
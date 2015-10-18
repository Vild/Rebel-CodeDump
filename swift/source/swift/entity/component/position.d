module swift.entity.component.position;

import swift.entity.component.component;
import swift.data.vector;

class Position : Component {
public:
	this(vec3 position) {
		this.position = position;
	}

	@property ref vec3 Pos() { return position; }

	mixin TypeDecl;
	
	override string toString() {
		return position.toString;
	}
private:
	vec3 position;
}


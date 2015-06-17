module swift.entity.positioncomponent;

import swift.entity.component;
import swift.data.vector;

class PositionComponent : Component {
public:
	this(vec3 pos) {
		this.pos = pos;
	}

	@property ref vec3 Position() { return pos; }

	mixin TypeDecl;
private:
	vec3 pos;
}


module swift.entity.positioncomponent;

import swift.entity.entitysystem;
import swift.data.vector;

class PositionComponent : Component {
public:
	this(vec3 pos) {
		this.pos = pos;
	}

	@property ref vec3 Position() { return pos; }
	@property ref float X() { return pos.x; }
	@property ref float Y() { return pos.y; }
	@property ref float Z() { return pos.z; }

	mixin TypeDecl;
private:
	vec3 pos;
}


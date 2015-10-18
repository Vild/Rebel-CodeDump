module swift.entity.component.velocity;

import swift.entity.component.component;
import swift.data.vector;

class Velocity : Component {
public:
	this(vec3 velocity) {
		this.velocity = velocity;
	}
	
	@property ref vec3 Vel() { return velocity; }
	
	mixin TypeDecl;

	override string toString() {
		return velocity.toString;
	}

private:
	vec3 velocity;
}


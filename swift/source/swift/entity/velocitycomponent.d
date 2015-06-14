module swift.entity.velocitycomponent;

import swift.entity.entitysystem;
import swift.data.vector;

class VelocityComponent : Component {
public:
	this(vec3 velocity) {
		this.velocity = velocity;
	}
	
	@property ref vec3 Velocity() { return velocity; }
	@property ref float X() { return velocity.x; }
	@property ref float Y() { return velocity.y; }
	@property ref float Z() { return velocity.z; }
	
	mixin TypeDecl;
private:
	vec3 velocity;
}


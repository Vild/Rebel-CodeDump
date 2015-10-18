module swift.entity.system.movement;

import swift.entity.system.system;
import swift.entity.component.velocity;
import swift.entity.component.position;
import swift.entity.entity;
import artemisd.utils.type;

import artemisd.all;

final class Movement : System {
public:
	this() {
		Aspect aspect = new Aspect();
		if(aspect.getAllSet.length < Position.TypeId + 1)
			aspect.getAllSet.length = Position.TypeId + 1;

		aspect.getAllSet[Position.TypeId] = 1;
		super(aspect);
	}

	mixin TypeDecl;
private:
	override protected void process(Entity e) {
		Position pos = e.getComponent!Position;
		Velocity vel = e.getComponent!Velocity;

		pos.Pos.x += vel.Vel.x * world.getDelta();
		pos.Pos.y += vel.Vel.y * world.getDelta();
		pos.Pos.z += vel.Vel.z * world.getDelta();
	}
}


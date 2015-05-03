module rebel.camera.freecamera;

import rebel.camera.abstractcamera;
import gl3n.linalg;

class FreeCamera : AbstractCamera {
public:
	this() {
		translation = vec3(0);
		speed = 0.5;
	}

	override void Update() {
		mat4 R = yawPitchRoll(yaw, pitch, roll);
		position += translation;
		//translation = vec3(0);

		look = vec3(R*vec4(0, 0, 1, 0));
		vec3 tgt = position+look;
		up = vec3(R*vec4(0, 1, 0, 0));
		right = cross(look, up);
		V = mat4.look_at(position, tgt, up);
	}

	void Walk(float dt) {
		translation += (look * speed * dt);
		Update();
	}

	void Strafe(float dt) {
		translation += (right * speed * dt);
		Update();
	}

	void Lift(float dt) {
		translation += (up * speed * dt);
		Update();
	}

	@property ref vec3 Translation(vec3 translation) { //TODO: maybe add Update(); somehow
		this.translation = translation;
		Update();
		return this.translation;
	}

	@property ref vec3 Translation() { //TODO: maybe add Update(); somehow
		return translation;
	}

	@property ref float Speed() {
		return speed;
	}

private:
	float speed;
	vec3 translation;
}


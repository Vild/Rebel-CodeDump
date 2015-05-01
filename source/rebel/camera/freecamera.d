module rebel.camera.freecamera;

import rebel.camera.abstractcamera;
import gl3n.linalg;

class FreeCamera : AbstractCamera {
public:
	this() {
		translation = vec3(0);
	}

	override void Update() {
		super.Update;

		mat4 R = GetMatrixUsingYawPitchRoll(yaw, pitch, roll);
		position += translation;
		translation = vec3(0);

		look = vec3(R*vec4(0, 0, 1, 0));
		vec3 tgt = position+look;
		up = vec3(R*vec4(0, 1, 0, 0));
		right = cross(look, up);
		V = mat4.look_at(position, tgt, up);
	}

	override void Rotate(float yaw, float pitch, float roll) {
		this.yaw = yaw;
		this.pitch = pitch;
		this.roll = roll;
	}

	void Walk(float dt) {
		translation += (look * dt);
	}

	void Strafe(float dt) {
		translation += (right * dt);
	}

	void Lift(float dt) {
		translation += (up * dt);
	}

	@property ref vec3 Translation() {
		return translation;
	}

	@property ref float Speed() {
		return speed;
	}

private:
	float speed;
	vec3 translation;
}


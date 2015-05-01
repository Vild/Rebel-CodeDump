module rebel.camera.targetcamera;

import rebel.camera.abstractcamera;
import gl3n.linalg;
import std.stdio;

class TargetCamera : AbstractCamera{
public:
	this() {
		right = vec3(1, 0, 0);
		up = vec3(0, 1, 0);
		look = vec3(0, 0, -1);
		minRy = -60;
		maxRy = 60;
		minDistance = 1;
		maxDistance = 10;
	}

	override void Update() {
		mat4 R = yawPitchRoll(yaw, pitch, 0);
		vec3 T = vec3(R*vec4(0, 0, distance, 0));
		position = target + T;
		look = (target - position).normalized;
		up = vec3(R*vec4(UP, 0));
		right = cross(look, up);
		V = mat4.look_at(position, target, up);
	}

	override void Rotate(float yaw, float pitch, float roll) {
		float p = min(max(pitch, minRy), maxRy);
		super.Rotate(yaw, p, roll);
	}

	@property vec3 Target(vec3 target) {
		this.target = target;
		distance = .distance(position, target);
		distance = max(minDistance, min(distance, maxDistance));
		return this.target;
	}

	@property vec3 Target() { return target; }

	void Pan(float dx, float dy) {
		vec3 X = right * dx;
		vec3 Y = up * dy;
		position += X + Y;
		target += X + Y;
		Update();
	}

	void Zoom(float amount) {
		position += look * amount;
		distance = .distance(position, target);
		distance = max(minDistance, min(distance, maxDistance));
		Update();
	}

	void Move(float dx, float dy) {
		vec3 X = right * dx;
		vec3 Y = up * dy;
		position += X + Y;
		target += X + Y;
		Update();
	}
private:
	vec3 target;

	float minRy;
	float maxRy;

	float distance;
	float minDistance;
	float maxDistance;
}


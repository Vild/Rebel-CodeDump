module rebel.opengl.plane;

import gl3n.linalg;
import gl3n.math;

class Plane {
public:
	enum Where {
		COPLANAR, FRONT, BACK
	}

	this() {
		n = vec3(0, 1, 0);
		d = 0;
	}
	this(vec3 normal, vec3 p) {
		n = normal;
		d = -dot(normal, p);
	}

	~this() {
	}

	static Plane FromPoints(vec3 v1, vec3 v2, vec3 v3) { //TODO: make constructor
		Plane temp = new Plane();
		vec3 e1 = v2-v1;
		vec3 e2 = v3-v1;
		temp.N = cross(e1, e2).normalized();
		temp.d = -dot(temp.N, v1);
		return temp;
	}

	Where Classify(vec3 p) {
		enum EPSILON = 0.0001;
		float res = GetDistance(p);
		if (res > EPSILON)
			return Where.FRONT;
		else if (res < EPSILON)
			return Where.BACK;
		else
			return Where.COPLANAR;
	}

	float GetDistance(vec3 p) {
		return dot(n, p) + d;
	}

	@property ref vec3 N() { return n; }
	@property ref float D() { return d; }
private:
	vec3 n;
	float d;
}


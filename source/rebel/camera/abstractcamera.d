module rebel.camera.abstractcamera;

import gl3n.linalg;
import gl3n.math: radians;

import rebel.opengl.plane;

abstract class AbstractCamera {
public:
	this() {
		near = 0.1;
		far = 1000;
		P = mat4(1);
		V = mat4(1);
	}

	~this() {

	}

	void SetupProjection(float fov, float width, float height, float near = 0.1, float far = 1000) {
		this.near = near;
		this.far = far;
		this.fov = fov;
		this.width = width;
		this.height = height;
		this.P = mat4.perspective(width, height, fov, near, far);
	}

	abstract void Update() {
	}
	abstract void Rotate(float yaw, float pitch, float roll) {
		this.yaw = radians(yaw);
		this.pitch = radians(pitch);
		this.roll = radians(roll);
		Update();
	}

	@property mat4 ViewMatrix() { return V; }
	@property mat4 ProjectionMatrix() { return P; }

	@property ref vec3 Position() { return position; }

	@property float FOV() { return fov; }
	@property float FOV(float fov) {
		this.fov = fov;
		//this.P = perspective(fov, AspectRatio, near, far); TODO: remove
		this.P = mat4.perspective(width, height, fov, near, far);
		return fov;
	}
	@property float Width() { return width; }
	@property float Height() { return height; }
	@property float AspectRatio() { return width/height; }

	void CalcFrustumPlanes() {
		vec3 cN = position + look*near;
		vec3 cF = position + look*far;

		float Hnear = 2.0 * tan(radians(fov/2.)) * near;
		float Wnear = Hnear * AspectRatio;

		float Hfar = 2.0 * tan(radians(fov/2.)) * far;
		float Wfar = Hfar * AspectRatio;

		float hHnear = Hnear/2.0;
		float hWnear = Wnear/2.0;
		float hHfar = Hfar/2.0;
		float hWfar = Wfar/2.0;

		farPts[0] = cF + up*hHfar - right*hWfar;
		farPts[1] = cF - up*hHfar - right*hWfar;
		farPts[2] = cF - up*hHfar + right*hWfar;
		farPts[3] = cF + up*hHfar + right*hWfar;


		nearPts[0] = cN + up*hHnear - right*hWnear;
		nearPts[1] = cN - up*hHnear - right*hWnear;
		nearPts[2] = cN - up*hHnear + right*hWnear;
		nearPts[3] = cN + up*hHnear + right*hWnear;

		planes[0] = Plane.FromPoints(nearPts[3], nearPts[0], farPts[0]);
		planes[1] = Plane.FromPoints(nearPts[1], nearPts[2], farPts[2]);
		planes[2] = Plane.FromPoints(nearPts[0], nearPts[1], farPts[1]);
		planes[3] = Plane.FromPoints(nearPts[2], nearPts[3], farPts[2]);
		planes[4] = Plane.FromPoints(nearPts[0], nearPts[3], farPts[2]);
		planes[5] = Plane.FromPoints( farPts[3],  farPts[0], farPts[1]);
	}

	bool IsPointInFrustum(vec3 point) {
		for (int i = 0; i < 6; i++) {
			if (planes[i].GetDistance(point) < 0)
				return false;
		}
		return true;
	}

	bool IsSphereInFrustum(vec3 center, float radius) {
		for (int i = 0; i < 6; i++) {
			float d = planes[i].GetDistance(center);
			if (d < -radius)
				return false;
		}
		return true;
	}

	bool IsBoxInFrustum(vec3 min, vec3 max) {
		for (int i = 0; i < 6; i++) {
			vec3 p = min, n = max;
			vec3 N = planes[i].N;
			if (N.x >= 0) {
				p.x = max.x;
				n.x = min.x;
			}
			if (N.y >= 0) {
				p.y = max.y;
				n.y = min.y;
			}
			if (N.z >= 0) {
				p.z = max.z;
				n.z = min.z;
			}

			if (planes[i].GetDistance(p) < 0)
				return false;
		}
		return true;
	}

	void GetFrustumPlanes(vec4 fp[6]) {
		for (int i = 0; i < 6; i++)
			fp[i] = vec4(planes[i].N, planes[i].D);
	}

	/*mat4 yawPitchRoll(float y, float p, float r) {
		return mat4.identity.rotatez(r).rotatey(p).rotatex(y);
	}*/

	mat4 GetMatrixUsingYawPitchRoll(float yaw, float pitch, float roll) {
		return mat4.identity.rotatex(pitch).rotatey(yaw).rotatez(roll);
	}
	mat4 yawPitchRoll(float yaw, float pitch, float roll) {
		float tmp_ch = cos(yaw);
		float tmp_sh = sin(yaw);
		float tmp_cp = cos(pitch);
		float tmp_sp = sin(pitch);
		float tmp_cb = cos(roll);
		float tmp_sb = sin(roll);
		
		mat4 Result;
		Result[0][0] = tmp_ch * tmp_cb + tmp_sh * tmp_sp * tmp_sb;
		Result[0][1] = tmp_sb * tmp_cp;
		Result[0][2] = -tmp_sh * tmp_cb + tmp_ch * tmp_sp * tmp_sb;
		Result[0][3] = 0;
		Result[1][0] = -tmp_ch * tmp_sb + tmp_sh * tmp_sp * tmp_cb;
		Result[1][1] = tmp_cb * tmp_cp;
		Result[1][2] = tmp_sb * tmp_sh + tmp_ch * tmp_sp * tmp_cb;
		Result[1][3] = 0;
		Result[2][0] = tmp_sh * tmp_cp;
		Result[2][1] = -tmp_sp;
		Result[2][2] = tmp_ch * tmp_cp;
		Result[2][3] = 0;
		Result[3][0] = 0;
		Result[3][1] = 0;
		Result[3][2] = 0;
		Result[3][3] = 1;
		return Result.transposed;
	}

	mat4 perspective(float fovy, float aspect, float zNear, float zFar) {
		float tanHalfFovy = tan(fovy / 2);
		mat4 Result = mat4(0);
		Result[0][0] = 1 / (aspect * tanHalfFovy);
		Result[1][1] = 1 / (tanHalfFovy);
		Result[2][2] = - (zFar + zNear) / (zFar - zNear);
		Result[2][3] = - 1;
		Result[3][2] = - (2 * zFar * zNear) / (zFar - zNear);
		return Result.transposed;
	}

	vec3 farPts[4];
	vec3 nearPts[4];

protected:
	float yaw;
	float pitch;
	float roll;
	float fov;
	float width;
	float height;
	float near;
	float far;

	static vec3 UP = vec3(0, 1, 0);

	vec3 look;
	vec3 up;
	vec3 right;
	vec3 position;
	mat4 V; //View matrix
	mat4 P; //Projection matrix

	Plane planes[6];
}


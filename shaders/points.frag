#version 330 core

out vec4 vFragColor;

void main() {
	vec2 pos = (gl_PointCoord.xy - 0.5);
	if (0.25 < dot(pos, pos))
		discard;

	vFragColor = vec4(0, 0, 1, 1);
}

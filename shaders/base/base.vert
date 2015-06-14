#version 330 core

in vec3 vVertex;
in vec3 vNormal;
in vec4 vColor;

out vec4 oColor;

uniform mat4 MVP;

void main() {
	oColor = vColor;
	gl_Position = MVP * vec4(vVertex, 1);
}

#version 330 core

in vec3 vVertex;
in vec3 vNormal;
in vec4 vColor;
in vec2 vTexCoord;

out vec4 oColor;
out vec2 oTexCoord;

uniform mat4 MVP;

void main() {
	oColor = vColor;
	oTexCoord = vTexCoord;
	gl_Position = MVP * vec4(vVertex, 1);
}

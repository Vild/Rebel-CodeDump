#version 330 core

in vec3 vVertex;
in vec4 vColor;
in vec3 vTexCoord;

out vec4 oColor;
out vec3 oTexCoord;

uniform mat4 MVP;

void main() {
	vec4 pos = MVP * vec4(vVertex, 1);
	gl_Position = pos.xyww;
	oColor = vColor;
	//oTexCoord = vTexCoord;
	oTexCoord = vVertex;


	//gl_Position = MVP * vec4(vVertex, 1);
}

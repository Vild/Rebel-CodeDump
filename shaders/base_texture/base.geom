#version 330 core

layout(triangles) in;
layout(triangles, max_vertices=3) out;

uniform mat4 MVP;

void main() {
	for (int i = 0;i < gl_in.length(); i++) {
		gl_Position = MVP * gl_in[i].gl_Position;
		EmitVertex();
	}
	EndPrimitive();
}

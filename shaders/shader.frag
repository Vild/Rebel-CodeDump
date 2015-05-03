#version 330 core

out vec4 vFragColor;

uniform vec4 color;

void main() {
	vFragColor = color;//vec4(1,1,1,1);
}

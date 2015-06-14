#version 330 core

uniform sampler2D texture;

in vec4 oColor;
in vec2 oTexCoord;

out vec4 fFragColor;

void main() {
 	fFragColor = texture(texture, oTexCoord) * oColor;
}

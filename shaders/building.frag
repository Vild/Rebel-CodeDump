#version 330 core

uniform sampler2D tex;

in vec4 oColor;
in vec2 oTexCoord;

out vec4 fFragColor;

void main() {
 	fFragColor = texture(tex, oTexCoord) * oColor;
}

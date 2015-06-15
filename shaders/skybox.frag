#version 330 core
#extension GL_NV_shadow_samplers_cube : enable

uniform samplerCube texCube;

in vec4 oColor;
in vec3 oTexCoord;

out vec4 fFragColor;

void main() {
 	fFragColor = textureCube(texCube, oTexCoord) * oColor;
}

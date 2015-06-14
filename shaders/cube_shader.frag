#version 330 core

layout(location = 0) out vec4 vFragColor;	//fragment shader output

//uniform
in vec4 oColor; //constant colour

void main()
{
	//return constant colour as shader output
	vFragColor = oColor;
}

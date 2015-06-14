#version 330 core
  
layout(location = 0) in vec3 vVertex;  //object space vertex position
in vec4 vColor;

uniform mat4 MVP;  //combined modelview projection matrix
out vec4 oColor;

void main()
{ 	
	oColor = vColor; 
	//get clipspace position
	gl_Position = MVP*vec4(vVertex.xyz,1); 
}

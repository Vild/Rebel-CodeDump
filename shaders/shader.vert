#version 330 core
  
in vec3 vVertex; 

uniform mat4 MVP;  

void main() {  
	gl_Position = MVP*vec4(vVertex, 1);
}

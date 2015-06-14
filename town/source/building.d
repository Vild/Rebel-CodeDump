﻿module building;

import rebel.opengl.mesh;

import derelict.opengl3.gl3;
import rebel.opengl.texture;
import gl3n.linalg;

class Building : Mesh {
	this(vec3 size, Texture texture) {
		this.size = size;
		this.texture = texture;

		double r = 0.2;
		double d = 0.05;

		Vertex[] vertices = [
			Vertex(vec3(-0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec2(0.0*size.x, 0.0*size.y)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec2(1.0*size.x, 0.0*size.y)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec2(1.0*size.x, 1.0*size.y)),
			Vertex(vec3(-0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec2(0.0*size.x, 1.0*size.y)),
			
			Vertex(vec3(-0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec2(0.0*size.x, 0.0*size.y)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec2(1.0*size.x, 0.0*size.y)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec2(1.0*size.x, 1.0*size.y)),
			Vertex(vec3(-0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec2(0.0*size.x, 1.0*size.y)),
			
			Vertex(vec3( 0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec2(0.0*size.x, 0.0*size.y)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec2(1.0*size.x, 0.0*size.y)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec2(1.0*size.x, 1.0*size.y)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec2(0.0*size.x, 1.0*size.y)),
			
			Vertex(vec3(-0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec2(0.0*size.x, 0.0*size.y)),
			Vertex(vec3(-0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec2(1.0*size.x, 0.0*size.y)),
			Vertex(vec3(-0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec2(1.0*size.x, 1.0*size.y)),
			Vertex(vec3(-0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec2(0.0*size.x, 1.0*size.y))
		];
		GLuint[] indices = [
			0, 1, 2,
			2, 3, 0,
			
			4, 5, 6,
			6, 7, 4,
			
			3, 2, 5, 
			5, 4, 3,
			
			7, 6, 1,
			1, 0, 7,
			
			8, 9, 10,
			10, 11, 8,
			
			12, 13, 14,
			14, 15, 12
		];
		
		super(vertices, indices, GL_TRIANGLES);
		
		shader.LoadFromFile(GL_VERTEX_SHADER, "shaders/building.vert");
		shader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/building.frag");
		shader.CreateAndLinkProgram();
		shader.Use();
		shader.AddAttribute("vVertex");
		shader.AddAttribute("vColor");
		shader.AddAttribute("vTexCoord");
		shader.AddUniform("MVP");
		shader.AddUniform("tex");
		glUniform1i(*shader("tex"), 0);
		shader.UnUse();
		
		Init();
		
		destroy(indices);
		destroy(vertices);
	}
	
	~this() {
		destroy(shader);
	}
	
	override void SetCustomUniforms() {
		super.SetCustomUniforms;
		if (auto textureMap = shader("tex"))
			glUniform1i(*textureMap, 0);
	}

	override public void Render(mat4 MVP = mat4.identity) {
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture.Get);
		super.Render(MVP);
	}

	@property vec3 Size() { return size; }

private:
	vec3 size;
	Texture texture;
}


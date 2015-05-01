module rebel.opengl.mesh;

import derelict.opengl3.gl3;
import gl3n.linalg;
import std.typecons;

import rebel.opengl.shader;

struct Vertex {
	//I use vec4 for everyone because it will help with the padding.
	vec4 position;//3
	vec4 normal;//3
	vec4 color;//4
	vec4 texcoord;//2

	this(vec3 position = vec3(0), vec3 normal = vec3(0), vec4 color = vec4(1), vec2 texcoord = vec2(0)) {
		this.position = vec4(position, 0);
		this.normal = vec4(normal, 0);
		this.color = color;
		this.texcoord = vec4(texcoord, 0, 0);
	}
}

abstract class Mesh { //NOTE: This is like RenderableObject, but BETTER! >:D
public:
	this(Vertex[] vertices, GLuint[] indices, GLenum primType) {
		this.vertices = vertices.dup;
		this.indices = indices.dup;
		this.primType = primType;
		this.shader = new Shader();
	}

	~this() {
		glDeleteBuffers(1, &vboVerticesID);
		glDeleteBuffers(1, &vboIndicesID);
		glDeleteVertexArrays(1, &vaoID);
		destroy(shader);
		destroy(indices);
		destroy(vertices);
	}

	void Render(mat4 MVP = mat4.identity) {
		ShaderProgram.Use();

		if (auto MVP_ = shader("MVP"))
			glUniformMatrix4fv(*MVP_, 1, GL_TRUE, MVP.value_ptr);
		else {
			import std.stdio;
			writeln("NO MVP: ", shader.ID);
			assert(0);
		}
		SetCustomUniforms();

		glBindVertexArray(vaoID);
		glDrawElements(primType, cast(int)indices.length, GL_UNSIGNED_INT, cast(void *)0);
		glBindVertexArray(0);

		ShaderProgram.UnUse();
	}

	abstract void SetCustomUniforms() {
	}

	@property ref Shader ShaderProgram() { return shader; }

protected:
	Vertex[] vertices;
	GLuint[] indices;

	Shader shader;

	GLenum primType;
	
	GLuint vaoID;
	GLuint vboVerticesID;
	GLuint vboIndicesID;

	void Init() {
		glGenVertexArrays(1, &vaoID);
		glGenBuffers(1, &vboVerticesID);
		glGenBuffers(1, &vboIndicesID);
		
		glBindVertexArray(vaoID);
		glBindBuffer(GL_ARRAY_BUFFER, vboVerticesID);
		glBufferData(GL_ARRAY_BUFFER, this.vertices.length * this.vertices[0].sizeof, this.vertices.ptr, GL_STATIC_DRAW);
		
		if (auto vVertex = shader["vVertex"]) {
			glEnableVertexAttribArray(*vVertex);
			glVertexAttribPointer(*vVertex, 3, GL_FLOAT, GL_TRUE, Vertex.sizeof, cast(void *)this.vertices[0].position.offsetof);
		}
		if (auto vNormal = shader["vNormal"]) {
			glEnableVertexAttribArray(*vNormal);
			glVertexAttribPointer(*vNormal, 3, GL_FLOAT, GL_TRUE, Vertex.sizeof, cast(void *)this.vertices[0].normal.offsetof);
		}
		if (auto vColor = shader["vColor"]) {
			glEnableVertexAttribArray(*vColor);
			glVertexAttribPointer(*vColor, 3, GL_FLOAT, GL_TRUE, Vertex.sizeof, cast(void *)this.vertices[0].color.offsetof);
		}
		if (auto vTexCoord = shader["vTexCoord"]) {
			glEnableVertexAttribArray(*vTexCoord);
			glVertexAttribPointer(*vTexCoord, 2, GL_FLOAT, GL_TRUE, Vertex.sizeof, cast(void *)this.vertices[0].texcoord.offsetof);
		}
		
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIndicesID);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, this.indices.length * GLuint.sizeof, this.indices.ptr, GL_STATIC_DRAW);
		
		ShaderProgram.Use();
		SetCustomUniforms();
		ShaderProgram.UnUse();
	}
}


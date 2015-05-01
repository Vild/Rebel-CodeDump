module rebel.entities.grid;

import rebel.opengl.mesh;
import derelict.opengl3.gl3;
import gl3n.linalg;
import rebel.opengl.shader;
import std.typecons;

class Grid : Mesh {
public:
	this(int width = 10, int depth = 10) {
		this.width = width;
		this.depth = depth;

		Vertex[] vertices;
		GLuint[] indices;
		vertices.reserve(((width+1)+(depth+1))*2);
		indices.reserve(width*depth);
		int width_2 = width/2;
		int depth_2 = depth/2;
		for (int i = -width_2; i <= width_2; i++) {
			vertices ~= Vertex(vec3(i, 0, -depth_2));
			vertices ~= Vertex(vec3(i, 0,  depth_2));

			vertices ~= Vertex(vec3(-width_2, 0, i));
			vertices ~= Vertex(vec3( width_2, 0, i));
		}
		for (int i = 0; i < width*depth; i+=4) {
			indices ~= i;
			indices ~= i+1;
			indices ~= i+2;
			indices ~= i+3;
		}

		super(vertices, indices, GL_LINES);

		shader.LoadFromFile(GL_VERTEX_SHADER, "shaders/shader.vert");
		shader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/shader.frag");
		shader.CreateAndLinkProgram();
		shader.Use();
		shader.AddAttribute("vVertex");
		shader.AddUniform("MVP");
		shader.UnUse();

		Init();

		destroy(indices);
		destroy(vertices);
	}

	~this() {
		destroy(shader);
	}
private:
	int width;
	int depth;
}


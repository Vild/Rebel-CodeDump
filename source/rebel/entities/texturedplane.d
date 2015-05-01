module rebel.entities.texturedplane;

import rebel.opengl.mesh;
import derelict.opengl3.gl3;
import gl3n.linalg;
import rebel.opengl.shader;
import std.typecons;

class TexturedPlane : Mesh {
public:
	this(int width = 1000, int depth = 1000) {
		this.width = width;
		this.depth = depth;

		int width_2 = width/2;
		int depth_2 = depth/2;
		Vertex[] vertices = [
			Vertex(vec3(-width_2, 0, -depth_2)),
			Vertex(vec3( width_2, 0, -depth_2)),

			Vertex(vec3( width_2, 0,  depth_2)),
			Vertex(vec3(-width_2, 0,  depth_2))
		];
		GLuint[] indices = [0, 1, 2,  0, 2, 3];

		super(vertices, indices, GL_TRIANGLES);

		shader.LoadFromFile(GL_VERTEX_SHADER, "shaders/checker_shader.vert");
		shader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/checker_shader.frag");
		shader.CreateAndLinkProgram();
		shader.Use();
		shader.AddAttribute("vVertex");
		shader.AddUniform("MVP");
		shader.AddUniform("textureMap");
		glUniform1i(*shader("textureMap"), 0);
		shader.UnUse();

		Init();

		destroy(indices);
		destroy(vertices);
	}

	~this() {
		destroy(shader);
	}

	override public void SetCustomUniforms() {
		super.SetCustomUniforms;
		if (auto textureMap = shader("textureMap"))
			glUniform1i(*textureMap, 0);
	}
private:
	int width;
	int depth;
}


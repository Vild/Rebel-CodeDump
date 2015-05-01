module rebel.entities.unitcube;

import rebel.opengl.mesh;
import derelict.opengl3.gl3;
import gl3n.linalg;
import rebel.opengl.shader;
import std.typecons;

class UnitCube : Mesh {
public:
	this(vec3 color) {
		this.color = color;

		Vertex[] vertices = [
			Vertex(vec3(-0.5, -0.5, -0.5)),
			Vertex(vec3( 0.5, -0.5, -0.5)),
			Vertex(vec3( 0.5,  0.5, -0.5)),
			Vertex(vec3(-0.5,  0.5, -0.5)),
			Vertex(vec3(-0.5, -0.5,  0.5)),
			Vertex(vec3( 0.5, -0.5,  0.5)),
			Vertex(vec3( 0.5,  0.5,  0.5)),
			Vertex(vec3(-0.5,  0.5,  0.5))
		];
		GLuint[] indices = [
			//Bottom
			0, 5, 4,
			5, 0, 1,

			//Top
			3, 7, 6,
			3, 6, 2,

			//Front
			7, 4, 6,
			6, 4, 5,

			//Back
			2, 1, 3,
			3, 1, 0,

			//Left
			3, 0, 7,
			7, 0, 4,

			//Right
			6, 5, 2,
			2, 5, 1
		];

		super(vertices, indices, GL_LINES);

		shader.LoadFromFile(GL_VERTEX_SHADER, "shaders/shader.vert");
		shader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/shader.frag");
		shader.CreateAndLinkProgram();
		shader.Use();
		shader.AddAttribute("vVertex");
		shader.AddUniform("MVP");
		shader.AddUniform("vColor");
		shader.UnUse();

		Init();

		destroy(indices);
		destroy(vertices);
	}

	override void SetCustomUniforms() {
		super.SetCustomUniforms;
		if (auto vColor = shader("vColor"))
			glUniform3fv(*vColor, 1, color.value_ptr);
	}

private:
	vec3 color;
}


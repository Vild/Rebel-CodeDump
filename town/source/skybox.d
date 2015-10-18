module skybox;

import rebel.opengl.mesh;

import derelict.opengl3.gl3;
import swift.data.vector;
import rebel.opengl.cubemaptexture;

class Skybox : Mesh {
public:
	this(CubeMapTexture texture) {
		this.texture = texture;
		/+
		{ /* GL_TEXTURE_CUBE_MAP_POSITIVE_X */
			{1.0,  0.99,  0.99},
			{1.0,  0.99, -0.99},
			{1.0, -0.99, -0.99},
			{1.0, -0.99,  0.99},
		},
		{ /* GL_TEXTURE_CUBE_MAP_NEGATIVE_X */
			{-1.0,  0.99, -0.99},
			{-1.0,  0.99,  0.99},
			{-1.0, -0.99,  0.99},
			{-1.0, -0.99, -0.99},
		},
		{ /* GL_TEXTURE_CUBE_MAP_POSITIVE_Y */
			{-0.99, 1.0, -0.99},
			{ 0.99, 1.0, -0.99},
			{ 0.99, 1.0,  0.99},
			{-0.99, 1.0,  0.99},
		},
		{ /* GL_TEXTURE_CUBE_MAP_NEGATIVE_Y */
			{-0.99, -1.0,  0.99},
			{-0.99, -1.0, -0.99},
			{ 0.99, -1.0, -0.99},
			{ 0.99, -1.0,  0.99},
		},
		{ /* GL_TEXTURE_CUBE_MAP_POSITIVE_Z */
			{-0.99,  0.99, 1.0},
			{-0.99, -0.99, 1.0},
			{ 0.99, -0.99, 1.0},
			{ 0.99,  0.99, 1.0},
		},
		{ /* GL_TEXTURE_CUBE_MAP_NEGATIVE_Z */
			{ 0.99,  0.99, -1.0},
			{-0.99,  0.99, -1.0},
			{-0.99, -0.99, -1.0},
			{ 0.99, -0.99, -1.0},
		},

			+/
		
		Vertex[] vertices = [
			//+x
			Vertex(vec3( 1, -1,  1), vec3(0), vec4(1), vec3(1.0,  0.99,  0.99)),
			Vertex(vec3( 1, -1, -1), vec3(0), vec4(1), vec3(1.0,  0.99, -0.99)),
			Vertex(vec3( 1,  1, -1), vec3(0), vec4(1), vec3(1.0, -0.99, -0.99)),
			Vertex(vec3( 1,  1,  1), vec3(0), vec4(1), vec3(1.0, -0.99,  0.99)),
			
			//-x
			Vertex(vec3(-1, -1, -1), vec3(0), vec4(1), vec3(-1.0,  0.99, -0.99)),
			Vertex(vec3(-1, -1,  1), vec3(0), vec4(1), vec3(-1.0,  0.99,  0.99)),
			Vertex(vec3(-1,  1,  1), vec3(0), vec4(1), vec3(-1.0, -0.99,  0.99)),
			Vertex(vec3(-1,  1, -1), vec3(0), vec4(1), vec3(-1.0, -0.99, -0.99)),
			
			//+y
			Vertex(vec3(-1,  1,  1), vec3(0), vec4(1), vec3(-0.99, 1.0, -0.99)),
			Vertex(vec3( 1,  1,  1), vec3(0), vec4(1), vec3( 0.99, 1.0, -0.99)),
			Vertex(vec3( 1,  1, -1), vec3(0), vec4(1), vec3( 0.99, 1.0,  0.99)),
			Vertex(vec3(-1,  1, -1), vec3(0), vec4(1), vec3(-0.99, 1.0,  0.99)),
			
			//-y
			Vertex(vec3(-1, -1, -1), vec3(0), vec4(1), vec3(-0.99, -1.0,  0.99)),
			Vertex(vec3( 1, -1, -1), vec3(0), vec4(1), vec3(-0.99, -1.0, -0.99)),
			Vertex(vec3( 1, -1,  1), vec3(0), vec4(1), vec3( 0.99, -1.0, -0.99)),
			Vertex(vec3(-1, -1,  1), vec3(0), vec4(1), vec3( 0.99, -1.0,  0.99)),
			
			//+z
			Vertex(vec3(-1, -1,  1), vec3(0), vec4(1), vec3(-0.99,  0.99, 1.0)),
			Vertex(vec3( 1, -1,  1), vec3(0), vec4(1), vec3(-0.99, -0.99, 1.0)),
			Vertex(vec3( 1,  1,  1), vec3(0), vec4(1), vec3( 0.99, -0.99, 1.0)),
			Vertex(vec3(-1,  1,  1), vec3(0), vec4(1), vec3( 0.99,  0.99, 1.0)),
			
			//-z
			Vertex(vec3(-1,  1, -1), vec3(0), vec4(1), vec3( 0.99,  0.99, -1.0)),
			Vertex(vec3( 1,  1, -1), vec3(0), vec4(1), vec3(-0.99,  0.99, -1.0)),
			Vertex(vec3( 1, -1, -1), vec3(0), vec4(1), vec3(-0.99, -0.99, -1.0)),
			Vertex(vec3(-1, -1, -1), vec3(0), vec4(1), vec3( 0.99, -0.99, -1.0))
		];
		GLuint[] indices = [
			//+x
			0, 1, 2,
			2, 3, 0,
			
			//-x
			4, 5, 6,
			6, 7, 4,
			
			//+y
			8, 9, 10,
			10, 11, 8,
			
			//-y
			12, 13, 14,
			14, 15, 12,
			
			//+z
			16, 17, 18, 
			18, 19, 16,
			
			//-z
			20, 21, 22,
			22, 23, 20
		];
		
		super(vertices, indices, GL_TRIANGLES);
		
		shader.LoadFromFile(GL_VERTEX_SHADER, "shaders/skybox.vert");
		shader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/skybox.frag");
		shader.CreateAndLinkProgram();
		shader.Use();
		shader.AddAttribute("vVertex");
		shader.AddAttribute("vColor");
		shader.AddAttribute("vTexCoord");
		shader.AddUniform("MVP");
		shader.AddUniform("texCube");
		glUniform1i(*shader("texCube"), 0);
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
		if (auto textureMap = shader("texCube"))
			glUniform1i(*textureMap, 0);
	}

	override public void Render(mat4 MVP = mat4.identity) {
		glDisable(GL_DEPTH_TEST);
		glEnable(GL_TEXTURE_CUBE_MAP);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_CUBE_MAP, texture.Get);
		glCullFace(GL_FRONT);

		super.Render(MVP);

		glCullFace(GL_BACK);
		glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
		glDisable(GL_TEXTURE_CUBE_MAP);
		glEnable(GL_DEPTH_TEST);
	}

private:
	CubeMapTexture texture;
}


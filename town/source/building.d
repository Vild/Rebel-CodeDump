module building;

import rebel.opengl.mesh;

import derelict.opengl3.gl3;
import rebel.opengl.texture;
import swift.data.vector;
import rebel.ray.raybox;

class Building : Mesh {
	this(int id, vec3 size, Texture texture) {
		this.id = id;
		this.size = size;
		this.texture = texture;
		this.hit = false;

		double r = 0.4;
		double d = 0;

		Vertex[] vertices = [
			//+x
			Vertex(vec3( 0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 1.0*size.y, 0.0)),

			//-x
			Vertex(vec3(-0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3(-0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3(-0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3(-0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 1.0*size.y, 0.0)),

			//+y
			Vertex(vec3(-0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec3(0.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec3(1.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec3(1.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3(-0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec3(0.0*size.x, 0.0*size.y, 0.0)),

			//-y
			Vertex(vec3(-0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec3(0.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(d), vec3(1.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec3(1.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3(-0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(d), vec3(0.0*size.x, 0.0*size.y, 0.0)),

			//+z
			Vertex(vec3(-0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3(-0.5*size.x, 1.0*size.y,  0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 1.0*size.y, 0.0)),

			//-z
			Vertex(vec3(-0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 1.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 0.0*size.y, 0.0)),
			Vertex(vec3( 0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(1.0*size.x, 1.0*size.y, 0.0)),
			Vertex(vec3(-0.5*size.x, 0.0*size.y, -0.5*size.z), vec3(0), vec4(r), vec3(0.0*size.x, 1.0*size.y, 0.0))
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
		
		shader.LoadFromFile(GL_VERTEX_SHADER, "shaders/building.vert");
		shader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/building.frag");
		shader.CreateAndLinkProgram();
		shader.Use();
		shader.AddAttribute("vVertex");
		shader.AddAttribute("vColor");
		shader.AddAttribute("vTexCoord");
		shader.AddUniform("MVP");
		shader.AddUniform("hit");
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
		if (auto hit = shader("hit"))
			glUniform1i(*hit, !this.hit ? 1:0);
	}

	override public void Render(mat4 MVP = mat4.identity) {
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture.Get);
		super.Render(MVP);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	@property vec3 Size() { return size; }

	@property RayBox Hitbox() {
		vec3 p = Position.Position;
		return new RayBox(id, vec3(p.x - size.x/2, p.y, p.z - size.z/2), vec3(p.x + size.x/2, p.y + size.y, p.z + size.z/2));
	}

	@property ref bool Hit() { return hit; }

private:
	int id;
	vec3 size;
	Texture texture;
	bool hit;
}


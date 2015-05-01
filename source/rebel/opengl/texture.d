module rebel.opengl.texture;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.string : toStringz;
import std.stdio;

class Texture {
public:
	this(GLuint id) {
		this.id = id;
	}
	this(string file) {
		SDL_Surface * surface = IMG_Load(toStringz(file));
		assert(surface, "Could not load: "~ file);

		GLenum texture_format;
		auto nOfColors = surface.format.BytesPerPixel;
		if (nOfColors == 4) {
			if (surface.format.Rmask == 0x000000ff)
				texture_format = GL_RGBA;
			else
				texture_format = GL_BGRA;
		} else if (nOfColors == 3) {
			if (surface.format.Rmask == 0x000000ff)
				texture_format = GL_RGB;
			else
				texture_format = GL_BGR;
		} else {
			writeln("warning: the image is not truecolor..  this will probably break\n");
			assert(0);
		}

		glGenTextures(1, &id);
		glBindTexture(GL_TEXTURE_2D, id);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		glTexImage2D(GL_TEXTURE_2D, 0, texture_format, surface.w, surface.h, 0, texture_format, GL_UNSIGNED_BYTE, surface.pixels);
		SDL_FreeSurface(surface);
	}

	~this() {
		glDeleteTextures(1, &id);
	}

	GLuint Get() {
		return id;
	}
private:
	GLuint id;
}


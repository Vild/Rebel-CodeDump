module rebel.opengl.shader;
import derelict.opengl3.gl3;
import std.string;
import std.stdio;

class Shader{
public:
	this() {
		shaders.reserve(ShaderType.NUM_OF_SHADERS);
	}

	~this() {
		if (program != GLuint.max)
			glDeleteProgram(program);
	}

	void LoadFromString(GLenum type, string source, string file = "INLINE") {
		import std.c.string : strcpy, strlen;
		GLuint shader = glCreateShader(type);
		auto src_c = toStringz(source);
		char[] str_dc = new char[strlen(src_c)];
		strcpy(str_dc.ptr, src_c);
		auto src = [str_dc.ptr];
		glShaderSource(shader, 1, src.ptr, null);
		destroy(str_dc);

		GLint status;
		glCompileShader(shader);
		glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
		if (status == GL_FALSE) {
			GLint infoLogLength;
			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);
			GLchar[] infoLog = new GLchar[infoLogLength];
			glGetShaderInfoLog(shader, infoLogLength, null, infoLog.ptr);
			writeln("Compiler log@", file, ":", infoLog);
			destroy(infoLog);
			assert(0);
		}
		shaders ~= shader;
		sources ~= sourceInfo(type, source, file);
	}

	void LoadFromFile(GLenum type, string file) {
		import std.file : readText;
		LoadFromString(type, readText(file), file);
	}

	void CreateAndLinkProgram() {
		program = glCreateProgram();
		foreach (shader; shaders)
			glAttachShader(program, shader);

		GLint status;
		glLinkProgram(program);
		glGetProgramiv(program, GL_LINK_STATUS, &status);
		if (status == GL_FALSE) {
			GLint infoLogLength;
			
			glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);
			GLchar[] infoLog = new GLchar[infoLogLength];
			glGetProgramInfoLog(program, infoLogLength, null, infoLog.ptr);
			writeln("Link log: ", infoLog);
			destroy(infoLog);
			assert(0);
		}

		foreach (shader; shaders)
			glDeleteShader(shader);
	}

	void Use() {
		glUseProgram(program);
	}

	void UnUse() {
		glUseProgram(0);
	}

	void AddAttribute(string attribute) {
		attributeList[attribute] = glGetAttribLocation(program, toStringz(attribute));
		writeln(ID, " add[", attribute, "] = ", attributeList[attribute]);
	}

	void AddUniform(string uniform) {
		uniformLocationList[uniform] = glGetUniformLocation(program, toStringz(uniform));
		writeln(ID, " add(", uniform, ") = ", uniformLocationList[uniform]);
	}

	GLuint * opIndex(string attribute) {
		auto ret = (attribute in attributeList);
		return ret;
	}

	GLuint * opCall(string uniform) {
		auto ret = (uniform in uniformLocationList);
		return ret;
	}

	@property GLuint ID() { return program; }

	Shader dup() {
		auto shader = new Shader(sources);
		shader.attributeList = attributeList.dup;
		shader.uniformLocationList = uniformLocationList.dup;
		shader.CreateAndLinkProgram();
		return shader;
	}
protected:
	struct sourceInfo {
		GLenum type;
		string source;
		string file;
		this(GLenum type, string source, string file = "INLINE") {
			this.type = type;
			this.source = source;
			this.file = file;
		}
	}

	this(sourceInfo[] sources) {
		foreach(src; sources)
			LoadFromString(src.type, src.source, src.file);
	}

private:
	enum ShaderType {
		VERTEX, FRAGMENT, GEOMETRY, NUM_OF_SHADERS
	}
	GLuint program = GLuint.max;
	GLuint[] shaders;
	GLuint[string] attributeList;
	GLuint[string] uniformLocationList;

	sourceInfo[] sources;
}


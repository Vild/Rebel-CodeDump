module rebel.app;

import derelict.opengl3.gl3;
import derelict.sdl2.image;
import derelict.sdl2.sdl;

import gl3n.linalg;
import gl3n.math;

import rebel.camera.targetcamera;
import rebel.entities.texturedplane;
import rebel.opengl.mesh;
import rebel.opengl.shader;
import rebel.opengl.texture;

import std.algorithm : max,min;
import std.conv;
import std.stdio;

SDL_Window * window;
SDL_GLContext context;
Shader shader;

int w = 1280;
int	h = 960;

immutable EPSILON = 0.001f;
immutable EPSILON2 = EPSILON*EPSILON;

bool state = 0;
int oldX = 0, oldY = 0;
float rX = 0, rY = 0, fov = 45;

float dt = 0;
float last_time = 0, current_time = 0;

const float MOVE_SPEED = 5; //m/s

TargetCamera cam;

immutable MOUSE_FILTER_WEIGHT = 0.75f;
immutable MOUSE_HISTORY_BUFFER_SIZE = 10;

vec2 mouseHistory[MOUSE_HISTORY_BUFFER_SIZE];

float mouseX = 0, mouseY = 0;

bool useFiltering = true;

Texture checkerTexture;

TexturedPlane checker_plane;

template glCheck() {
	enum GLERROR = "GLenum error;
		while ((error = glGetError()) != GL_NO_ERROR)
			writeln(format(\"GL error detected: 0x%x %s@%s:%s\", error, __FILE__, __FUNCTION__, __LINE__));";
}

void filterMouseMoves(float dx, float dy) {
	for (int i = MOUSE_HISTORY_BUFFER_SIZE - 1; i > 0; i--)
		mouseHistory[i] = mouseHistory[i - 1];

	mouseHistory = vec2(dx, dy);

	float averageX = 0;
	float averageY = 0;
	float averageTotal = 0;
	float currentWeight = 1;

	for (int i = 0; i < MOUSE_HISTORY_BUFFER_SIZE; i++) {
		vec2 tmp = mouseHistory[i];
		averageX += tmp.x * currentWeight;
		averageY += tmp.y * currentWeight;
		averageTotal += 1.0 * currentWeight;
		currentWeight *= MOUSE_FILTER_WEIGHT;
	}

	mouseX = averageX / averageTotal;
	mouseY = averageY / averageTotal;
}

void OnInit() {
	GLuint checkerTextureID;
	GLubyte[128][128] data;
	for (int j = 0; j < 128; j++)
		for (int i = 0; i < 128; i++)
			data[i][j] = (i <= 64 && j <= 64 || i > 64 && j > 64) ? 255 : 0;

	mixin glCheck;
	glGenTextures(1, &checkerTextureID);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, checkerTextureID);

	mixin glCheck;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	mixin glCheck;
	GLfloat largest_supported_anisotropy;
	glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &largest_supported_anisotropy);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, largest_supported_anisotropy);

	mixin glCheck;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 4);

	mixin glCheck;
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, 128, 128, 0, GL_RED, GL_UNSIGNED_BYTE, cast(const(void)*)data);
	glGenerateMipmap(GL_TEXTURE_2D);
	checkerTexture = new Texture(checkerTextureID);

	checker_plane = new TexturedPlane();

	cam = new TargetCamera();
	cam.Position = vec3(5, 5, 5);
	cam.Target = vec3(0, 0, 0);

	mixin glCheck;
	vec3 look = (cam.Target - cam.Position).normalized();

	float yaw = degrees(atan2(look.z, look.x) + PI);
	float pitch = degrees(asin(look.y));

	rX = yaw;
	rY = pitch;

	if (useFiltering) 
		for (int i = 0; i < MOUSE_HISTORY_BUFFER_SIZE; i++)
			mouseHistory[i] = vec2(rX, rY);

	cam.Rotate(rX, rY, 0);

	mixin glCheck;

	writeln("Initialization successfull");
}

void OnShutdown() {
	destroy(checker_plane);
	destroy(checkerTexture);
	writeln("Shutdown successfull");
}

void OnResize(int w_, int h_) {
	w = w_;
	h = h_;
	glViewport(0, 0, w_, h_);
	cam.SetupProjection(45, w, h);
}

void OnRender() {
	last_time = current_time;
	current_time = SDL_GetTicks()/1000;
	dt = current_time - last_time;
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	mat4 MV = cam.ViewMatrix();
	mat4 P = cam.ProjectionMatrix();
	mat4 MVP = P*MV;

	checker_plane.Render(MVP);

	glFlush();
	SDL_GL_SwapWindow(window);
}

int main(string[] args) {
	DerelictSDL2.load();
	DerelictSDL2Image.load();
	DerelictGL3.load();

	SDL_Init(SDL_INIT_EVERYTHING);
	IMG_Init(IMG_INIT_PNG);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE); 
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG | SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);

	window = SDL_CreateWindow("Chapter 1", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, w, h, SDL_WINDOW_RESIZABLE | SDL_WINDOW_OPENGL);
	assert(window);
	context = SDL_GL_CreateContext(window);
	assert(context);
	scope(exit)
		SDL_GL_DeleteContext(context);
	DerelictGL3.reload();

	SDL_version ver;
	SDL_GetVersion(&ver);
	writeln("\tUsing SDL: ", ver.major, ".", ver.minor, ".", ver.patch);
	writeln("\tVender: ", to!string(glGetString(GL_VENDOR)));
	writeln("\tRenderer: ", to!string(glGetString(GL_RENDERER)));
	writeln("\tVersion: ", to!string(glGetString(GL_VERSION)));
	writeln("\tGLSL: ", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));
	writeln("\tExtensions: ");
	for (int i = 0; i < GL_NUM_EXTENSIONS; i++) {
		const char * s = glGetStringi(GL_EXTENSIONS, i);
		if (s == null)
			break;
		else
			writeln("\t\t", to!string(s));
	}
	{
		GLenum error;
		while ((error = glGetError()) != GL_NO_ERROR) {}
	}

	OnInit();
	OnResize(w, h);

	MainLoop();

	OnShutdown();
	SDL_Quit();

	return 0;
}

void MainLoop() {
	SDL_Event event;
	bool quit = false;
	while (!quit) {
		while(SDL_PollEvent(&event)) {
			if (true) {
				switch(event.type) {
					case SDL_QUIT: 
						quit = true;
						break;
					case SDL_KEYDOWN:
						switch (event.key.keysym.sym) {
							case SDLK_ESCAPE:
								quit = true;
								break;
							case SDLK_w:
								cam.Move(MOVE_SPEED * dt, 0);
								break;
							case SDLK_s:
								cam.Move(MOVE_SPEED * -dt, 0);
								break;
							case SDLK_a:
								cam.Move(0, MOVE_SPEED * -dt);
								break;
							case SDLK_d:
								cam.Move(0, MOVE_SPEED * dt);
								break;
							/*case SDLK_q:
								cam.Lift(dt);
								break;
							case SDLK_z:
								cam.Lift(dt);
								break;*/
							case SDLK_SPACE:
								useFiltering = !useFiltering;
								break;
							default:
								break;
						}
						break;
					case SDL_WINDOWEVENT:
						switch(event.window.event) {
							case SDL_WINDOWEVENT_RESIZED:
								OnResize(event.window.data1, event.window.data2);
								break;
							default:
								break;
						}
						break;
					case SDL_MOUSEBUTTONDOWN:
						oldX = event.button.x;
						oldY = event.button.y;

						goto case;
					case SDL_MOUSEBUTTONUP:
						state = (event.button.button != SDL_BUTTON_MIDDLE);
						break;
					case SDL_MOUSEMOTION:
						if (SDL_GetMouseState(null, null)) {
							auto x = event.motion.x;
							auto y = event.motion.y;
							if (!state) {
								fov += (y - oldY)/5.;
								cam.SetupProjection(fov, cam.Width, cam.Height);
							} else {
								rY += (y - oldY)/5.;
								rX += (oldX - x)/5.;
								if (useFiltering)
									filterMouseMoves(rX, rY);
								else {
									mouseX = rX;
									mouseY = rY;
								}
								cam.Rotate(mouseX, mouseY, 0);
							}
							oldX = x;
							oldY = y;
						}
						break;

					default:
						break;
				}
			}
		}

		/*vec3 t = cam.Translation();
		if (dot(t, t) > EPSILON2)
			cam.Translation = t*0.95;*/

		OnRender();
		//return;
		mixin glCheck;
	}
}
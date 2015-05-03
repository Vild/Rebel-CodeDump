module rebel.app;

import derelict.opengl3.gl3;
import derelict.sdl2.image;
import derelict.sdl2.sdl;

import gl3n.linalg;
import gl3n.math;

import rebel.camera.freecamera;
import rebel.entities.texturedplane;
import rebel.opengl.mesh;
import rebel.opengl.shader;
import rebel.opengl.texture;

import std.algorithm : max,min;
import std.conv;
import std.stdio;

SDL_Window * window;
SDL_GLContext context;
int w = 1280;
int	h = 960;
immutable EPSILON = 0.001f;
immutable EPSILON2 = EPSILON*EPSILON;
bool state = false;
int oldX = 0, oldY = 0;
float rX = -135, rY = 45, fov = 45;
const float MOVE_SPEED = 5; //m/s
immutable MOUSE_FILTER_WEIGHT = 0.75f;
immutable MOUSE_HISTORY_BUFFER_SIZE = 10;
vec2 mouseHistory[MOUSE_HISTORY_BUFFER_SIZE];
float mouseX = 0, mouseY = 0;
bool useFiltering = true;


Shader shader;
Shader pointShader;

GLuint vaoID;
GLuint vboVerticesID;
GLuint vboIndicesID;

GLuint vaoFrustumID;
GLuint vboFrustumVerticesID;
GLuint vboFrustumIndicesID;

const int NUM_X = 40;
const int NUM_Z = 40;

const float SIZE_X = 100;
const float SIZE_Z = 100;
const float HALF_SIZE_X = SIZE_X/2.0f;
const float HALF_SIZE_Z = SIZE_Z/2.0f;

vec3 vertices[(NUM_X+1)*(NUM_Z+1)];
const int TOTAL_INDICES = NUM_X*NUM_Z*2*3;
GLushort indices[TOTAL_INDICES];

FreeCamera cam;
FreeCamera world;
FreeCamera * currentCam;

vec3 frustum_vertices[8];

GLfloat white[4] = [1,1,1,1];
GLfloat red[4] = [1,0,0,0.5];
GLfloat cyan[4] = [0,1,1,0.5];

const int PX = 100;
const int PZ = 100;
const int MAX_POINTS=PX*PZ;

vec3 pointVertices[MAX_POINTS];
GLuint pointVAOID, pointVBOID;

int total_visible=0;

GLuint query;
int fps;
GLuint res;
double last;
double lastFPS;


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
	glGenQueries(1, &query);
	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	glEnable(GL_DEPTH_TEST);
	glPointSize(10);
	mixin glCheck;

	shader = new Shader();
	shader.LoadFromFile(GL_VERTEX_SHADER, "shaders/shader.vert");
	shader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/shader.frag");
	shader.CreateAndLinkProgram();
	shader.Use();
	shader.AddAttribute("vVertex");
	shader.AddUniform("MVP");
	shader.AddUniform("color");
	glUniform4fv(*shader("color"), 1, white.ptr);
	shader.UnUse();

	mixin glCheck;
		
	pointShader = new Shader();
	pointShader.LoadFromFile(GL_VERTEX_SHADER, "shaders/points.vert");
	pointShader.LoadFromFile(GL_GEOMETRY_SHADER, "shaders/points.geom");
	pointShader.LoadFromFile(GL_FRAGMENT_SHADER, "shaders/points.frag");
	pointShader.CreateAndLinkProgram();
	pointShader.Use();
	pointShader.AddAttribute("vVertex");
	pointShader.AddUniform("MVP");
	pointShader.AddUniform("t");
	pointShader.AddUniform("FrustumPlanes");
	pointShader.UnUse();
	
	mixin glCheck;

	int count = 0;
	int i=0, j=0;
	for (j=0;j<=NUM_Z;j++) {
		for (i=0;i<=NUM_X;i++) {
			vertices[count++] = vec3( ((float(i)/(NUM_X-1)) *2-1)* HALF_SIZE_X, 0, ((float(j)/(NUM_Z-1))*2-1)*HALF_SIZE_Z);
		}
	}

	GLushort* id = indices.ptr;
	for (i = 0; i < NUM_Z; i++) {
		for (j = 0; j < NUM_X; j++) {
			int i0 = i * (NUM_X+1) + j;
			int i1 = i0 + 1;
			int i2 = i0 + (NUM_X+1);
			int i3 = i2 + 1;
			if ((j+i)%2) {
				*id++ = cast(GLushort)i0; *id++ = cast(GLushort)i2; *id++ = cast(GLushort)i1;
				*id++ = cast(GLushort)i1; *id++ = cast(GLushort)i2; *id++ = cast(GLushort)i3;
			} else {
				*id++ = cast(GLushort)i0; *id++ = cast(GLushort)i2; *id++ = cast(GLushort)i3;
				*id++ = cast(GLushort)i0; *id++ = cast(GLushort)i3; *id++ = cast(GLushort)i1;
			}
		}
	}

	mixin glCheck;

	glGenVertexArrays(1, &vaoID);
	glGenBuffers(1, &vboVerticesID);
	glGenBuffers(1, &vboIndicesID);
	
	glBindVertexArray(vaoID);
	
	glBindBuffer(GL_ARRAY_BUFFER, vboVerticesID);

	glBufferData(GL_ARRAY_BUFFER, vertices[0].sizeof * vertices.length, vertices.ptr, GL_STATIC_DRAW);
	mixin glCheck;

	glEnableVertexAttribArray(*shader["vVertex"]);
	glVertexAttribPointer(*shader["vVertex"], 3, GL_FLOAT, GL_FALSE, 0, null);
	mixin glCheck;

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIndicesID);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices[0].sizeof * indices.length, indices.ptr, GL_STATIC_DRAW);
	mixin glCheck;

	cam = new FreeCamera();
	cam.Position = vec3(2, 2, 2);
	cam.Rotate(rX, rY, 0);

	cam.SetupProjection(fov, w, h, 1, 10);
	cam.Update();

	cam.CalcFrustumPlanes();

	world = new FreeCamera();
	world.Position = vec3(10, 10, 10);
	world.Rotate(rX, rY, 0);

	world.SetupProjection(fov, w, h, 0.1, 100.0f);
	world.Update();


	currentCam = &cam;


	glGenVertexArrays(1, &vaoFrustumID);
	glGenBuffers(1, &vboFrustumVerticesID);
	glGenBuffers(1, &vboFrustumIndicesID);
	
	frustum_vertices[0] = cam.farPts[0];
	frustum_vertices[1] = cam.farPts[1];
	frustum_vertices[2] = cam.farPts[2];
	frustum_vertices[3] = cam.farPts[3];
	
	frustum_vertices[4] = cam.nearPts[0];
	frustum_vertices[5] = cam.nearPts[1];
	frustum_vertices[6] = cam.nearPts[2];
	frustum_vertices[7] = cam.nearPts[3];
	
	GLushort frustum_indices[36]=[0,4,3,3,4,7, //top
		6,5,1,6,1,2, //bottom
			0,1,4,4,1,5, //left
			7,6,3,3,6,2, //right
			4,5,6,4,6,7, //near
			3,2,0,0,2,1, //far
	];
	glBindVertexArray(vaoFrustumID);
	
	glBindBuffer(GL_ARRAY_BUFFER, vboFrustumVerticesID);

	glBufferData(GL_ARRAY_BUFFER, frustum_vertices[0].sizeof * frustum_vertices.length, frustum_vertices.ptr, GL_DYNAMIC_DRAW);
	mixin glCheck;

	glEnableVertexAttribArray(*shader["vVertex"]);
	glVertexAttribPointer(*shader["vVertex"], 3, GL_FLOAT, GL_FALSE, 0, null);
	mixin glCheck;

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboFrustumIndicesID);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, frustum_indices[0].sizeof * frustum_indices.length, frustum_indices.ptr, GL_STATIC_DRAW);
	mixin glCheck;
		
		
	for(j=0;j<PZ;j++) {
		for(i=0;i<PX;i++) {
			float   x = i/(PX-1.0f);
			float   z = j/(PZ-1.0f);
			pointVertices[j*PX+i] = vec3(x,0,z);
		}
	}

	glGenVertexArrays(1, &pointVAOID);
	glGenBuffers(1, &pointVBOID);
	glBindVertexArray(pointVAOID);
	glBindBuffer(GL_ARRAY_BUFFER, pointVBOID);

	glBufferData(GL_ARRAY_BUFFER, pointVertices[0].sizeof * pointVertices.length, pointVertices.ptr, GL_STATIC_DRAW);

	glEnableVertexAttribArray(*pointShader["vVertex"]);
	glVertexAttribPointer(*pointShader["vVertex"], 3, GL_FLOAT, GL_FALSE,0,null);

	mixin glCheck;
	vec3 look = (cam.Position).normalized();

	float yaw = degrees(atan2(look.z, look.x) + PI);
	float pitch = degrees(asin(look.y));

	rX = yaw;
	rY = pitch;

	if (useFiltering) 
		for (i = 0; i < MOUSE_HISTORY_BUFFER_SIZE; i++)
			mouseHistory[i] = vec2(rX, rY);

	//cam.Rotate(rX, rY, 0);

	mixin glCheck;

	writeln("Initialization successfull");
}

void OnShutdown() {
	glDeleteQueries(1, &query);


	destroy(shader);
	destroy(pointShader);

	glDeleteBuffers(1, &vboVerticesID);
	glDeleteBuffers(1, &vboIndicesID);
	glDeleteVertexArrays(1, &vaoID);

	glDeleteVertexArrays(1, &vaoFrustumID);
	glDeleteBuffers(1, &vboFrustumVerticesID);
	glDeleteBuffers(1, &vboFrustumIndicesID);

	glDeleteVertexArrays(1, &pointVAOID);
	glDeleteBuffers(1, &pointVBOID);

	writeln("Shutdown successfull");
}

void OnResize(int w_, int h_) {
	w = w_;
	h = h_;
	glViewport(0, 0, w_, h_);
	cam.SetupProjection(cam.FOV, w, h);
	world.SetupProjection(world.FOV, w, h);
}

void OnUpdate(double delta) {
	ubyte * kb = SDL_GetKeyboardState(null);

	if (kb[SDL_SCANCODE_W])
		currentCam.Walk(delta);

	if (kb[SDL_SCANCODE_S])
		currentCam.Walk(-delta);

	if (kb[SDL_SCANCODE_A])
		currentCam.Strafe(-delta);

	if (kb[SDL_SCANCODE_D])
		currentCam.Strafe(delta);

	if (kb[SDL_SCANCODE_Q])
		currentCam.Lift(delta);

	if (kb[SDL_SCANCODE_Z])
			currentCam.Lift(-delta);

	vec3 t = currentCam.Translation();

	if(dot(t, t) > EPSILON2)
		currentCam.Translation = t*0.95f;
	currentCam.Update();

	if(currentCam == &cam) {
		currentCam.CalcFrustumPlanes();
		frustum_vertices[0] = cam.farPts[0];
		frustum_vertices[1] = cam.farPts[1];
		frustum_vertices[2] = cam.farPts[2];
		frustum_vertices[3] = cam.farPts[3];
		
		frustum_vertices[4] = cam.nearPts[0];
		frustum_vertices[5] = cam.nearPts[1];
		frustum_vertices[6] = cam.nearPts[2];
		frustum_vertices[7] = cam.nearPts[3];
	
		glBindVertexArray(vaoFrustumID);
		glBindBuffer(GL_ARRAY_BUFFER, vboFrustumVerticesID);
		glBufferSubData(GL_ARRAY_BUFFER, 0, frustum_vertices[0].sizeof * frustum_vertices.length, frustum_vertices.ptr);
		glBindVertexArray(0);
	}
}

void OnRender() {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	mat4 MV = currentCam.ViewMatrix();
	mat4 P = currentCam.ProjectionMatrix();
	mat4 MVP = P*MV;

	vec4 p[6];
	currentCam.GetFrustumPlanes(p);

	glBeginQuery(GL_PRIMITIVES_GENERATED, query);

	pointShader.Use();
	glUniform1f(*pointShader("t"), SDL_GetTicks() / 1000.0);
	glUniformMatrix4fv(*pointShader("MVP"), 1, GL_TRUE, MVP.value_ptr);
	glUniform4fv(*pointShader("FrustumPlanes"), p.length, cast(float*)p.ptr);

	glBindVertexArray(pointVAOID);
	glDrawArrays(GL_POINTS, 0, MAX_POINTS);

	pointShader.UnUse();

	glEndQuery(GL_PRIMITIVES_GENERATED);
	glGetQueryObjectuiv(query, GL_QUERY_RESULT, &res);

	shader.Use();
	glBindVertexArray(vaoID);
	glUniformMatrix4fv(*shader("MVP"), 1, GL_TRUE, MVP.value_ptr);
	glUniform4fv(*shader("color"), 1, white.ptr);
	glDrawElements(GL_TRIANGLES, TOTAL_INDICES, GL_UNSIGNED_SHORT, null);

	if(currentCam == &world) {
		glUniform4fv(*shader("color"), 1, red.ptr);

		glBindVertexArray(vaoFrustumID);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, null);
		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

		glDisable(GL_BLEND);
	}

	shader.UnUse();
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

	SDL_GL_SetSwapInterval(0);

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
	lastFPS = last = SDL_GetTicks()/1000.0;
	double delta = 0;
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
							case SDLK_1:
								currentCam = &cam;
								break;
							case SDLK_2:
								currentCam = &world;
								break;
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
						auto x = event.motion.x;
						auto y = event.motion.y;
						if (SDL_GetMouseState(null, null)) {
							if (!state) {
								fov += (y - oldY)/100.;
								currentCam.FOV = fov;
							} else {
								rY += (y - oldY)/5.;
								rX += (oldX - x)/5.;
								if (useFiltering)
									filterMouseMoves(rX, rY);
								else {
									mouseX = rX;
									mouseY = rY;
								}
	
								if (currentCam == &world) {
									cam.Rotate(mouseX, mouseY, 0);
									cam.CalcFrustumPlanes();
								} else
									currentCam.Rotate(mouseX, mouseY, 0);
							}

							cam.CalcFrustumPlanes();
							frustum_vertices[0] = cam.farPts[0];
							frustum_vertices[1] = cam.farPts[1];
							frustum_vertices[2] = cam.farPts[2];
							frustum_vertices[3] = cam.farPts[3];
							
							frustum_vertices[4] = cam.nearPts[0];
							frustum_vertices[5] = cam.nearPts[1];
							frustum_vertices[6] = cam.nearPts[2];
							frustum_vertices[7] = cam.nearPts[3];

							glBindVertexArray(vaoFrustumID);
							glBindBuffer(GL_ARRAY_BUFFER, vboFrustumVerticesID);
							glBufferSubData(GL_ARRAY_BUFFER, 0, frustum_vertices[0].sizeof * frustum_vertices.length, frustum_vertices.ptr);
							glBindVertexArray(0);
						}
						oldX = x;
						oldY = y;
						break;

					default:
						break;
				}
			}
		}

		double now = SDL_GetTicks()/1000.0;
		delta = now - last;
		last = now;

		OnUpdate(delta);

		OnRender();
		glFlush();
		SDL_GL_SwapWindow(window);
		fps++;

		if (now - lastFPS > 1.0) {
			import std.format;
			import std.string;
			SDL_SetWindowTitle(window, format("FPS: %3d :: Total visible points: %3d", fps, res).toStringz);
			lastFPS += 1;
			fps = 0;
		}
		mixin glCheck;
	}
}
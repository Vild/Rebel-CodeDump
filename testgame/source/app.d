module testgame.app;

import derelict.opengl3.gl3;

import swift.data.vector;

import swift.engine : Engine;
import swift.data.deltaprovider;
import swift.event.deltaevent;
import swift.enginestate;
import swift.event.event;
import swift.data.convar;
import swift.data.vector;

import rebel.graphicstate;
import rebel.data.sdleventprovider;
import rebel.event.keyboard.keydownevent;
import rebel.event.mouse.mousebuttondownevent;
import rebel.event.mouse.mousemoveevent;

import rebel.camera.freecamera;
import rebel.entity.texturedplane;
import rebel.opengl.mesh;
import rebel.opengl.shader;
import rebel.opengl.texture;
import rebel.entity.colorcube;

import std.algorithm : max,min;
import std.conv;
import std.stdio;

import rebel.event.window.resizeevent;
import rebel.rebelengine;

RebelEngine engine;

mixin BaseConVar;
mixin(FindAllConVar!(__MODULE__));

int main(string[] args) {
	try {
		engine = new RebelEngine("TestGame");

		engine.DataProviders ~= new DeltaProvider();
		engine.DataProviders ~= new SDLEventProvider();

		engine.State = new TestState(engine);
		engine.MainLoop;
	} catch (Exception e) {
		import std.stdio;
		writeln();
		writeln(e.msg);
	}
	return 0;
}

class TestState : GraphicState {
public:
	this(RebelEngine engine) {
		glGenQueries(1, &query);
		glEnable(GL_DEPTH_TEST);
		glPointSize(6);
		glLineWidth(6);
		
		cam = new FreeCamera();
		cam.Speed = MOVE_SPEED;
		cam.Position = vec3(2, 2, 2);
		cam.Rotate(rX, rY, 0);
		
		cam.SetupProjection(fov, engine.GetWindow.WindowSize.x, engine.GetWindow.WindowSize.y, 1, 10);
		cam.Update();
		
		cam.CalcFrustumPlanes();

		vec3 look = (cam.Position).normalized();
		
		float yaw = degrees(atan2(look.z, look.x) + PI);
		float pitch = degrees(asin(look.y));
		
		rX = yaw;
		rY = pitch;
		
		cam.Rotate(rX, rY, 0);
		
		for (int i = 0; i < cube.length; i++) {
			cube[i] = new ColorCube(vec4(
					((i) % cube.length) / cube.length,
					((i*2+3.4) % cube.length) / cube.length,
					((i*3+4.5) % cube.length) / cube.length,
					1));
			
			cube[i].Position.Position.x = i%3;
			cube[i].Position.Position.y = i/3;
		}
	}

	~this() {
		glDeleteQueries(1, &query);
	}

	override void Update(RebelEngine engine, Event[] events) {
		double delta = 0;
		foreach(Event event; events) {
			if (auto e = cast(ResizeEvent)event) {
				engine.GetWindow.WindowSize = e.WindowSize;
				cam.SetupProjection(cam.FOV, e.WindowSize.x, e.WindowSize.y);
			} else if (auto e = cast(DeltaEvent)event) {
				delta = e.Delta;
			} else if (auto e = cast(MouseButtonDownEvent)event) {
				mousePos = engine.GetMouse.Position;
			} else if (auto e = cast(MouseMoveEvent)event) {
				auto pos = e.Position;
				if (engine.GetMouse.RawState) {
					if (engine.GetMouse.Middle) {
						fov += (pos.y - mousePos.y)/100.;
						cam.FOV = fov;
					} else {
						rY += (pos.y - mousePos.y)/5.;
						rX += (mousePos.x - pos.x)/5.;
						
						cam.Rotate(rX, rY, 0);
					}

					cam.CalcFrustumPlanes();
				}
				mousePos = pos;
			}
		}
		import rebel.sdl.keyboard;
		auto _ = (KeyCode k) => engine.GetKeyboard.Check(k);

		if (_(KeyCode.KEY_ESCAPE))
			engine.Quit = true;

		if (_(KeyCode.KEY_W))
			cam.Walk(delta);
		if (_(KeyCode.KEY_A))
			cam.Strafe(-delta);
		if (_(KeyCode.KEY_S))
			cam.Walk(-delta);
		if (_(KeyCode.KEY_D))
			cam.Strafe(delta);
		if (_(KeyCode.KEY_Q))
			cam.Lift(-delta);
		if (_(KeyCode.KEY_E))
			cam.Lift(delta);

		vec3 t = cam.Translation();
		
		if(dot(t, t) > EPSILON2)
			cam.Translation = t*0.95f;
		cam.Update();
	}
	override void Render(RebelEngine engine) {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		mat4 MV = cam.ViewMatrix();
		mat4 P = cam.ProjectionMatrix();
		mat4 MVP = P * MV;
		
		vec4[6] p;
		cam.GetFrustumPlanes(p);
		
		glBeginQuery(GL_PRIMITIVES_GENERATED, query);
		for (int i = 0; i < cube.length; i++) {
			if (i == select)
				cube[i].Position.Position.z -= 0.2;
			cube[i].Render(MVP);
			if (i == select)
				cube[i].Position.Position.z += 0.2;
		}
		
		glEndQuery(GL_PRIMITIVES_GENERATED);
		glGetQueryObjectuiv(query, GL_QUERY_RESULT, &res);
	}
private:
	immutable EPSILON = 0.001f;
	immutable EPSILON2 = EPSILON*EPSILON;
	int oldX = 0, oldY = 0;
	float rX = -135, rY = 45, fov = 45;
	const double MOVE_SPEED = 2;
	vec2i mousePos;

	FreeCamera cam;

	GLuint query;
	int fps;
	GLuint res;
	double last;
	double lastFPS;
	
	ColorCube[3*3] cube;
	int select = -1;
}
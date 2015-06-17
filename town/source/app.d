module testgame.app;

import building;
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import gl3n.linalg;
import gl3n.math;
import rebel.camera.freecamera;
import rebel.data.sdleventprovider;
import rebel.entity.colorcube;
import rebel.entity.texturedplane;
import rebel.event.keyboard.keydownevent;
import rebel.event.mouse.mousebuttondownevent;
import rebel.event.mouse.mousemoveevent;
import rebel.event.window.resizeevent;
import rebel.graphicstate;
import rebel.opengl.cubemaptexture;
import rebel.opengl.mesh;
import rebel.opengl.shader;
import rebel.opengl.texture;
import rebel.rebelengine;
import skybox;
import std.algorithm : max,min;
import std.conv;
import std.datetime : clock;
import std.random;
import std.stdio;
import swift.data.convar;
import swift.data.deltaprovider;
import swift.data.vector;
import swift.engine : Engine;
import swift.enginestate;
import swift.event.deltaevent;
import swift.event.event;
import rebel.ray.raybox;
import rebel.ray.ray;

RebelEngine engine;

mixin BaseConVar;
mixin(FindAllConVar!(__MODULE__));

int main(string[] args) {
	try {
		engine = new RebelEngine("Town test");

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
		glPointSize(6);
		glLineWidth(6);
		
		cam = new FreeCamera();
		cam.Speed = MOVE_SPEED;
		cam.Position = vec3(0, 4, 2);
		cam.Rotate(rX, rY, 0);
		
		cam.SetupProjection(fov, engine.GetWindow.WindowSize.x, engine.GetWindow.WindowSize.y);
		cam.Update();
		
		cam.CalcFrustumPlanes();

		ray = new Ray();

		skybox = new Skybox(new CubeMapTexture("res/arrakis/arrakis_%s.png"));
		//skybox = new Skybox(new CubeMapTexture("res/tron/tron_%s.jpg"));

		uint seed = cast(uint)(unpredictableSeed + clock());
		gen = Random(seed);
		for (int x = 0; x < 10; x++)
			for (int z = 0; z < 10; z++)
				town ~= GenerateHouse(vec3((x-5)*3, 0, (z-5)*3));

		lastTime = SDL_GetTicks();
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
				if (engine.GetMouse.Right) {
					vec2i ws = engine.GetWindow.WindowSize;
					ray.Setup(cam, vec2(mousePos.x, mousePos.y), vec2(ws.x, ws.y));
					size_t hitted = ray.Trace(hitboxes);
					engine.Logger.Info("mouse: x: %d, y: %d", mousePos.x, mousePos.y);
					if (hitted == -1)
						engine.Logger.Error("No hit");
					else {
						RayBox rb = hitboxes[hitted];
						engine.Logger.Debug("Hit: %d", rb.ID);
						foreach(ref a; town)
							foreach(ref b; a)
								b.Hit = false;

						foreach(ref b; town[rb.ID])
							b.Hit = true;
					}
				} else
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

						rX = rX % 360;
						rY = max(min(rY, 90), -90);
						
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
		if (_(KeyCode.KEY_LSHIFT))
			cam.Lift(-delta);
		if (_(KeyCode.KEY_SPACE))
			cam.Lift(delta);

		//cam.Walk(delta/8.);
		//cam.Strafe(delta/8.);

		//rX += delta*8.;
	
		rX = rX % 360;
		rY = max(min(rY, 90), -90);
		
		cam.Rotate(rX, rY, 0);

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

		skybox.Render(cam.ProjectionMatrix * cam.SkyboxMatrix );

		foreach (cubes; town)
			foreach (cube; cubes)
				cube.Render(MVP);
		
		glEndQuery(GL_PRIMITIVES_GENERATED);
		glGetQueryObjectuiv(query, GL_QUERY_RESULT, &res);

		if (SDL_GetTicks() - lastTime >= 1000) {
			engine.Logger.Info("Drawed verties: %d", res);
			lastTime += 1000;
		}
	}
private:
	immutable EPSILON = 0.001f;
	immutable EPSILON2 = EPSILON*EPSILON;
	int oldX = 0, oldY = 0;
	float rX = 0, rY = 0, fov = 45;
	const double MOVE_SPEED = 10;
	vec2i mousePos;

	FreeCamera cam;

	GLuint query;
	int fps;
	GLuint res;
	double last;
	double lastFPS;
	uint lastTime;

	Skybox skybox;

	Building[][] town;
	int select = -1;
	RayBox[] hitboxes;
	Ray ray;

	Random gen;

	Building[] GenerateHouse(vec3 offset) {
		static int id_count = 0;
		Texture tex = new Texture("res/skyscaper.jpg");
		int amount = uniform(2, 5, gen);
		Building[] cubes;
		cubes.reserve(amount);
		double mw = 1;
		double mh = 4;
		double md = 1;		
		for (int i = 0; i < amount; i++) {
			double w = (i+1)*uniform(0, mw, gen);
			w = min(max(w, mw*0.5), mw);
			double h = mh/(i+1);
			double d = (i+1)*uniform(0, md, gen);
			d = min(max(d, md*0.5), mw);
			
			Building cube = new Building(id_count, vec3(w, h, d), tex);
			
			double xoff = uniform(-(w-0.1*i)/2., (w-0.1*i)/2., gen);
			double zoff = uniform(-(d-0.1*i)/2., (d-0.1*i)/2., gen);
			
			cube.Position.Position = vec3(
				xoff+offset.x,
				offset.y,//cube.Size.y / 2 + offset.y,
				zoff + offset.z
				);
			
			cubes ~= cube;
			hitboxes ~= cube.Hitbox;
		}
		id_count++;
		return cubes;
	}
}
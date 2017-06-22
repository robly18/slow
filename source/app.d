import std.stdio;
import derelict.sdl2.sdl;

import vector;
import entity;

auto g = Vec2!float(0, 10);

Entity[] staticEntities;

void main() {
	DerelictSDL2.load();
	
	SDL_Init(SDL_INIT_VIDEO);
	
	SDL_Window *w = SDL_CreateWindow("hi", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_SHOWN);
	SDL_Surface *s = SDL_GetWindowSurface(w);
	
	Entity ent = new Entity(Vec2!float(280, 40), Vec2!float(40, 40), 0xFF0000);
	int prevt = SDL_GetTicks();
	
	staticEntities ~= [new Entity(Vec2!float(300, 200), Vec2!float(100, 10))];
	
	bool quit = false;
	while (!quit) {
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) quit = true;
		}
		
		int newt = SDL_GetTicks();
		float dt = (newt - prevt) * 0.01;
		prevt = newt;
		
		ent.accelerate(g, dt);
		if (ent.pos.y + ent.size.y > 600) {
			if (ent.v.y > 0)
				ent.accelerate(Vec2!float(0, -(ent.pos.y + ent.size.y - 600) * 1000), dt);
			else
				ent.accelerate(Vec2!float(0, -(ent.pos.y + ent.size.y - 600) * 100), dt);
		}
		foreach (Entity se; staticEntities) {
			auto axis = ent.axisOfCollision(se);
			float coeff = (axis * ent.v < 0) ? 1000 : 100;
			ent.accelerate(ent.axisOfCollision(se) * coeff, dt);
		}
		ent.runTime(dt);
		
		SDL_FillRect(s, null, 0xFFFFFF);
		ent.render(s);
		foreach (Entity se; staticEntities) {
			se.render(s);
		}
		SDL_UpdateWindowSurface(w);
	}
}

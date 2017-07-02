import derelict.sdl2.sdl;

import std.conv;
import std.math;

import vector;
import constants;

class HealthComponent {
public:
	this (int h) {
		maxHealth = h;
		health = h;
	}

	int maxHealth;
	int health;
	
	void render(SDL_Surface *s, V2f pos, V2f size, V2f camera) {
		
		SDL_Rect r = {to!int(pos.x + size.x - healthWidth - 1 - camera.x),
					  to!int(pos.y + size.y - maxHealth - 2 - camera.y),
					  to!int(healthWidth),
					  to!int(maxHealth)};
		SDL_FillRect(s, &r, healthBgColor);
		r.y += maxHealth - health;
		r.h = health;
		SDL_FillRect(s, &r, healthColor);
	}
}
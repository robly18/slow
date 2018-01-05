import derelict.sdl2.sdl;

import std.conv;
import std.math;

import vector;
import constants;

import bar;

class HealthComponent {
public:
	this (int h) {
		maxHealth = h;
		health = h;
	}

	int maxHealth;
	int health;
	invariant {
		assert(health <= maxHealth);
	}
	
	void render(SDL_Surface *s, V2f pos, V2f size, V2f camera) {
		SDL_Rect r = {to!int(pos.x + size.x/2 - barWidth/2 - camera.x),
					  to!int(pos.y - healthHeight - healthDistance - camera.y),
					  barWidth,
					  healthHeight};
		renderBar(s, r, maxHealth, health, healthBgColor, healthColor, healthTicks);
	}
	
	
	void renderTaskbar(SDL_Surface *ts) {
		SDL_Rect r = {(screenWidth - taskbarBarWidth)/2,
					  10,
					  taskbarBarWidth,
					  taskbarHealthHeight};
		renderBar(ts, r, maxHealth, health, healthBgColor, healthColor, healthTicks);
	}
}
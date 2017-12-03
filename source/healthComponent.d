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
		int barWidth = to!int(maxHealth*healthScale);
		SDL_Rect r = {to!int(pos.x + size.x/2 - barWidth/2 - camera.x),
					  to!int(pos.y - healthHeight - healthDistance - camera.y),
					  to!int(barWidth),
					  healthHeight};
		SDL_FillRect(s, &r, healthBgColor);
		r.w = to!int(health*healthScale);
		SDL_FillRect(s, &r, healthColor);
	}
}
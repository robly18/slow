import derelict.sdl2.sdl;

import std.conv;
import std.math;
import std.algorithm.comparison;

import vector;
import constants;

class StaminaComponent {
public:
	this(int filledTicks) {
		maxTicks = filledTicks;
		ticks = filledTicks;
	}
	
	int ticks, maxTicks;
	
	void render(SDL_Surface *s, V2f pos, V2f size, V2f camera) {
		int barWidth = to!int(to!float(maxTicks) * cooldownBarScalingFactor);
		SDL_Rect r = {to!int(pos.x + size.x/2 - barWidth/2 - camera.x),
					  to!int(pos.y - cooldownDistance - cooldownHeight - camera.y),
					  barWidth,
					  cooldownHeight};
		SDL_FillRect(s, &r, cooldownBgColor);
		r.w = to!int(to!float(ticks) * cooldownBarScalingFactor);
		SDL_FillRect(s, &r, cooldownColor);
	}
	
	void rest(int moments) {
		ticks = max(0, ticks-moments);
	}
	
	void tire(int moments) {
		ticks += moments;
	}
	
	bool tired() {
		return ticks>0;
	}
}
import derelict.sdl2.sdl;

import std.conv;
import std.math;
import std.algorithm.comparison;

import vector;
import constants;

import bar;

class StaminaComponent {
public:
	this(int filledTicks) {
		maxTicks = filledTicks;
		ticks = filledTicks;
	}
	
	int ticks, maxTicks;
	
	invariant {
		assert(0 <= ticks);
		assert(ticks <= maxTicks);
	}
	
	void render(SDL_Surface *s, V2f pos, V2f size, V2f camera) {
		
		SDL_Rect r = {to!int(pos.x + size.x/2 - barWidth/2 - camera.x),
					  to!int(pos.y - cooldownDistance - cooldownHeight - camera.y),
					  barWidth,
					  cooldownHeight};
		renderBar(s, r, maxTicks, ticks, cooldownBgColor, cooldownColor, cooldownTicks);
	}
	
	void renderTaskbar(SDL_Surface *ts) {
		SDL_Rect r = {(screenWidth - taskbarBarWidth)/2,
					  10 + taskbarHealthHeight,
					  taskbarBarWidth,
					  taskbarCooldownHeight};
		renderBar(ts, r, maxTicks, ticks, cooldownBgColor, cooldownColor, cooldownTicks);
	}
	
	void renderSubTaskbar(SDL_Surface *ts, int cost) {
		SDL_Rect r = {(screenWidth - taskbarBarWidth)/2,
					  10 + taskbarHealthHeight + taskbarCooldownHeight,
					  taskbarBarWidth,
					  taskbarPredictedCooldownHeight};
		renderBar(ts, r, maxTicks, relativeTicks(cost), predictedCooldownBgColor, predictedCooldownColor, cooldownTicks);
	}
	
	void rest(int moments) {
		ticks = max(0, ticks-moments);
	}
	
	void tire(int moments) {
		assert(moments > 0);
		ticks += moments;
	}
	
	int relativeTicks(int ppm)
	in {
		assert(0 <= ppm);
		assert(ppm <= 1000);
	} do {
		int moments = (ppm * maxTicks + 999)/1000; //assures the rounding is up
		assert(0 <= moments);
		assert(moments <= maxTicks);
		return moments;
	}
	
	void tireRelative(int ppm) 
	in {
		assert(ppm > 0);
	} do {
		tire(relativeTicks(ppm));
	}
	
	bool tired() {
		return ticks>0;
	}
}
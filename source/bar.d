import derelict.sdl2.sdl;

import std.conv;



void renderBar(SDL_Surface* s, SDL_Rect r, int max, int current, int bgColor, int color, int tickSize) 
in {
	assert(current <= max);
} do {
	SDL_FillRect(s, &r, bgColor);
	SDL_Rect lit = r;
	lit.w = to!int(r.w * current / max);
	SDL_FillRect(s, &lit, color);
	int tickHeight = to!int(r.h * 0.2) + 1;
	SDL_Rect tick = {r.x, r.y + r.h - tickHeight, 1, tickHeight};
	for (int i = 1; i*tickSize < max; i++) {
		tick.x = r.x + r.w * tickSize * i / max;
		SDL_FillRect(s, &tick, 0x000000);
	}
}
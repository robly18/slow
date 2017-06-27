import derelict.sdl2.sdl;
import std.conv;

import vector;
import entity;

const int cooldownBgColor = 0x880000;
const int cooldownColor = 0xdd3333;
const int cooldownWidth = 8;

const float scalingFactor = 0.035;

abstract class AiComponent {
public:
	this (int p = 1000, int c0 = 0) {
		period = p;
		cooldown = c0;
	}
	
	abstract void run(ActiveEntity it, ActiveEntity player, ref Bullet[] bullets);
	
	void render(SDL_Surface *s, V2f pos, V2f size, V2f camera) {
		
		SDL_Rect r = {to!int(pos.x + size.x - cooldownWidth - 11 - camera.x),
					  to!int(pos.y + size.y - to!float(period) * scalingFactor - 2 - camera.y),
					  cooldownWidth,
					  to!int(to!float(period) * scalingFactor)};
		SDL_FillRect(s, &r, cooldownBgColor);
		r.y += to!int((period - cooldown) * scalingFactor);
		r.h = to!int(cooldown * scalingFactor);
		SDL_FillRect(s, &r, cooldownColor);
	}
	
	int cooldown = 0;
	const int period;
}

class NullAiComponent : AiComponent {
public:
	override void run(ActiveEntity it, ActiveEntity player, ref Bullet[] bullets) {
		if (cooldown != 0) {
			cooldown--;
			return;
		}
		cooldown = period;
		//nop
	}
}

class BasicAiComponent : AiComponent {
public:
	this (int p, int c) {
		super(p, c);
	}

	override void run(ActiveEntity it, ActiveEntity player, ref Bullet[] bullets) { //this will need to be refined at some point
		if (cooldown != 0) {
			cooldown--;
			return;
		}
		
		if (it.health.health <= 0) return;
		
		cooldown = period;
		
		
		auto delta = player.pos - it.pos;
		if (delta.norm() < 500) { //Todo add system like player
			delta.y += 0.4;
			delta = delta / delta.norm();
			bullets ~= new Bullet(it.color, it.center(), delta/delta.norm(), it);
			delta = delta / delta.norm() * -5;
			it.v += delta;
		} else {
			delta = delta / delta.norm();
			delta.y += 0.4;
			delta = delta / delta.norm();
			delta = delta * 50;
			it.v += delta;
		}
	}
}
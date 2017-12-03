import derelict.sdl2.sdl;
import std.conv;
import std.algorithm;

import vector;
public import entity;
public import world;


import constants;

abstract class AiComponent {
public:
	abstract void run(ActiveEntity it, World w);
	
	void render(SDL_Surface *s, V2f pos, V2f size, V2f camera) {
	}
}

class NullAiComponent : AiComponent {
public:
	override void run(ActiveEntity it, World w) {
		//nop
	}
}

enum InputType {
	SKIP, MOVE, NOP
}

struct Input {
	InputType type;
	int x, y; //absolute coordinates!!
}

abstract class PCAiComponent : AiComponent {
}

bool actOnPlayerInput(Input input, Player player) {
	if (input.type == InputType.NOP) return false;
	
	import std.stdio;
	writeln("stamina start: ", player.stamina.ticks);
	auto mpos = V2f(input.x, input.y);
	auto com = player.pos + player.size/2;
	auto delta = mpos - com;
	if (input.type == InputType.MOVE) {
		if (delta.norm() < 5) {
			player.v = V2f(0,0);
			player.stamina.tire(momentsPerTurn);
		} else {
			if (player.canJump()) {
				delta = normalizeToLessThan(delta, maxJumpVelocity);
				if (player.v * delta < 0) player.v = V2f(0,0);
				else player.v = delta * (player.v * delta) / (delta.norm() * delta.norm());
				player.v += delta;
				player.stamina.tire(momentsPerTurn);
			}
		}
	} else if (input.type == InputType.SKIP) {
		player.stamina.tire(momentsPerSkip);
	} else {
		import std.stdio;
		writeln("Error! Unknown input type!");
	}
	writeln("stamina end: ", player.stamina.ticks);
	return true;
}

class PlayerAiComponent : PCAiComponent {
	this(int pid) {
		id = pid;
	}
	int id;
	
	override void run(ActiveEntity it, World w) {
		it.stamina.rest(1);
	}
}
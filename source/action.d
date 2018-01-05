import derelict.sdl2.sdl;

import std.conv;

import constants;
import vector;

import entity;
import world;

V2f normalizedDelta(Player p, V2f target) {
	V2f delta = target - p.center();
	if (delta.norm() < zeroTolerance) return V2f(0,0);
	return normalizeToLessThan(delta, maxTargetDistance)/maxTargetDistance;
}

void drawPreview(SDL_Surface* s, int color, V2f pos, V2f size) {
	SDL_Rect r = {to!int(pos.x), to!int(pos.y), 2, 2};
	SDL_FillRect(s, &r, color);
	r.x += to!int(size.x) - 2;
	SDL_FillRect(s, &r, color);
	r.y += to!int(size.y) - 2;
	SDL_FillRect(s, &r, color);
	r.x -= to!int(size.x) - 2;
	SDL_FillRect(s, &r, color);
}

void renderImagePreview(SDL_Surface* s, Entity e, V2f velocity, int moments, V2f camera) {
	int momentsLeft = moments;
	while (momentsLeft > 0) {
		float deltat = momentsLeft * dt;
		V2f pos = e.pos + velocity * deltat + 0.5 * g * deltat * deltat - camera;
		drawPreview(s, 0xFF0000, pos, e.size);
		momentsLeft -= momentsPerPreview;
	}
}

class Action {
	abstract bool canAct(Player p, World w);
	abstract void act(Player p, World w, V2f target);
	abstract int cost(Player p, World w, V2f target);
	//this cost should be an integer between 1 and 1000 (1 thousand), where the latter represents
	//this will tire the user out completely, and 0 would represent no tiring at all, if that didn't cause bugs
	
	void renderPreview(SDL_Surface* s, Player p, World w, V2f mousePos, V2f camera) {
		//nop
	}
}

class Jump : Action {
	this(int groundedturns, float maxdeltap, int mincost, int maxcost)
	in {
		assert(mincost > 0);
		assert(maxcost > 0);
		assert(mincost <= 1000);
		assert(maxcost <= 1000);
	} do {
		maxTurnsSinceGrounded = groundedturns;
		maxDeltap = maxdeltap;
		minCost = mincost; maxCost = maxcost;
	}

	int maxTurnsSinceGrounded; //-1 for infinity
	float maxDeltap; //p is momentum
	
	int minCost, maxCost;
	
	V2f newVelocity(Player p, V2f target) {
		V2f delta = normalizedDelta(p, target);
		V2f deltap = delta * maxDeltap;
		V2f deltav = deltap * p.inv_mass;
		return deltav;
	}
	
	override bool canAct(Player p, World w) {
		if (maxTurnsSinceGrounded == -1) return true;
		return p.turnsSinceGrounded <= maxTurnsSinceGrounded;
	}
	
	override void act(Player p, World w, V2f target)
	in {
		assert(canAct(p, w));
	} do {
		p.stamina.tireRelative(cost(p, w, target));
		p.v = newVelocity(p, target);
	}
	
	override int cost(Player p, World w, V2f target)
	in {
		assert(canAct(p, w));
	} do {
		float rate = normalizedDelta(p, target).norm();
		return minCost + to!int(rate * (maxCost - minCost));
	}
	
	override void renderPreview(SDL_Surface* s, Player p, World w, V2f target, V2f camera) {
		V2f newv = newVelocity(p, target);
		renderImagePreview(s, p, newv, p.stamina.relativeTicks(cost(p, w, target)), camera);
	}
}

class Skip : Action {

}
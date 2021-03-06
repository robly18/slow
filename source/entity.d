import vector;
import std.conv;
import derelict.sdl2.sdl;
import std.algorithm.comparison;
import std.math;

import healthComponent;
import aiComponent;
import staminaComponent;

import constants;

class Entity { //entity is a rectangle
public:
	this (Vec2!float pos_, Vec2!float size_, int color_ = 0) {
		pos = pos_;
		size = size_;
		color = color_;
	}
	
	void render(SDL_Surface* s, V2f camera) {
		SDL_Rect r = {to!int(pos.x - camera.x),
					  to!int(pos.y - camera.y),
					  to!int(size.x),
					  to!int(size.y)};
		SDL_FillRect(s, &r, color);
	}
	
	bool collidesWith(Entity other) {
		bool segInt(float a, float b, float c, float d) { //check if [a,b] intersects [c,d]
			return a < d && b > c;
		}
		return segInt(pos.x, pos.x + size.x, other.pos.x, other.pos.x + other.size.x) &&
			   segInt(pos.y, pos.y + size.y, other.pos.y, other.pos.y + other.size.y);
	}
	
	V2f center() {
		return pos + size/2;
	}
	

	V2f pos;
	V2f size;
	
	int color;
}

class MovingEntity : Entity {
public:
	this (Vec2!float pos_, Vec2!float size_, int color_ = 0, int ghostColor_ = 0xAAAAAA, float inv_mass_ = 1) {
		super(pos_, size_, color_);
		ghostColor = ghostColor_;
		inv_mass = inv_mass_;
	}
	
	void renderGhosts(SDL_Surface *s, V2f camera) {
		for (int i = 0; i <= pastImageNo; i += pastImageInterval) {
			SDL_Rect r = ghostImages[(imageAt + i) % pastImageNo];
			r.x -= to!int(camera.x);
			r.y -= to!int(camera.y);
			SDL_FillRect(s, &r, ghostColor);
		}
	}
	
	void accelerate(Vec2!float a, float dt) {
		v += a * dt;
	}
	
	void applyForce(Vec2!float f, float dt) {
		v += f * inv_mass * dt;
	}
	
	void runTime(float dt) {
		pos += v * dt;
	}
	
	Vec2!float axisOfCollision(Entity other) { //return the depth in one of the four cardinal directions, or 0 if no direction
		float cy = 0; //if this object is above the other, vector is up
		float cx = 0;
		bool segInt(float a, float b, float c, float d) { //check if [a,b] intersects [c,d]
			return a < d && b > c;
		}
		if (segInt(pos.x, pos.x + size.x, other.pos.x, other.pos.x + other.size.x)) {
			if (pos.y < other.pos.y)
				cy = min(other.pos.y - pos.y - size.y, 0);
			 else if (pos.y + size.y > other.pos.y + other.size.y)
				cy = max(other.pos.y + other.size.y - pos.y, 0);
		}
		if (segInt(pos.y, pos.y + size.y, other.pos.y, other.pos.y + other.size.y)) {
			if (pos.x < other.pos.x)
				cx = min(other.pos.x - pos.x - size.x, 0);
			 else if (pos.x + size.x > other.pos.x + other.size.x)
				cx = max(other.pos.x + other.size.x - pos.x, 0);
		}
		if ((cx != 0 && abs(cx) < abs(cy)) || cy == 0) {
			return Vec2!float(cx, 0);
		}
		return Vec2!float(0, cy);
	}
	
	void recordImage() {
		ghostImages[imageAt++] = SDL_Rect(to!int(pos.x),
										  to!int(pos.y),
										  to!int(size.x),
										  to!int(size.y));
		imageAt %= pastImageNo;
	}
	
	Vec2!float v = Vec2!float(0,0);
	float inv_mass; //inverse of mass; 0 means infinite mass
	
	SDL_Rect[pastImageNo] ghostImages;
	int imageAt = 0;
	int ghostColor;
}

class ActiveEntity : MovingEntity {
public:
	this (Vec2!float pos_, Vec2!float size_, int color_ = 0, int ghostColor_ = 0xAAAAAA, float inv_mass = 1) {
		super(pos_, size_, color_, ghostColor_, inv_mass);
	}
	
	int turnsSinceGrounded = 999999; //assuming big enough for all purposes
	bool canJump() {
		return turnsSinceGrounded <= groundJumpTime;
	}
	
	override void render(SDL_Surface *s, V2f camera) {
		super.render(s, camera);
		if (health !is null) {
			health.render(s, pos, size, camera);
		}
		if (ai !is null) {
			ai.render(s, pos, size, camera);
		}
		if (stamina !is null) {
			stamina.render(s, pos, size, camera);
		}
	}
	
	void runAi(World world) {
		if (ai !is null) ai.run(this, world);
	}
	
	HealthComponent health;
	AiComponent ai;
	StaminaComponent stamina;
}

class Player : ActiveEntity {
public:
	this (Vec2!float pos_, Vec2!float size_, int color_ = 0, int ghostColor_ = 0xAAAAAA, float inv_mass = 1) {
		super(pos_, size_, color_, ghostColor_, inv_mass);
	}
}
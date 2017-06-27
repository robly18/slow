import vector;
import std.conv;
import derelict.sdl2.sdl;
import std.algorithm.comparison;
import std.math;

import healthComponent;
import aiComponent;

const int pastImageNo = 100;
const int pastImageInterval = 1;
const float bulletVelocity = 250;
const auto bulletSize = Vec2!float(10, 10);

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
	
	auto center() {
		return pos + size/2;
	}
	

	Vec2!float pos;
	Vec2!float size;
	
	int color;
}

class MovingEntity : Entity {
public:
	this (Vec2!float pos_, Vec2!float size_, int color_ = 0, int ghostColor_ = 0xAAAAAA) {
		super(pos_, size_, color_);
		ghostColor = ghostColor_;
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
	
	SDL_Rect[pastImageNo] ghostImages;
	int imageAt = 0;
	int ghostColor;
}

class ActiveEntity : MovingEntity {
public:
	this (Vec2!float pos_, Vec2!float size_, int color_ = 0, int ghostColor_ = 0xAAAAAA) {
		super(pos_, size_, color_, ghostColor_);
	}
	
	override void render(SDL_Surface *s, V2f camera) {
		MovingEntity.render(s, camera);
		if (health !is null) {
			health.render(s, pos, size, camera);
		}
		if (ai !is null) {
			ai.render(s, pos, size, camera);
		}
	}
	
	void hitWithBullet(Bullet b) {
		v += b.v * 5 / bulletVelocity;
		if (health !is null) {
			health.health--;
		}
	}
	
	void runAi(ActiveEntity player, ref Bullet[] bullets) {
		if (ai !is null) ai.run(this, player, bullets);
	}
	
	//todo add AI and push components; maybe also shoot later
	HealthComponent health;
	AiComponent ai;
}

class Bullet : MovingEntity {
public:
	this(int ownerColor_, Vec2!float pos_, Vec2!float dir_, Entity owner_) {
		super(pos_ - bulletSize/2, bulletSize, 0x111111, 0xb0b0b0);
		ownerColor = ownerColor_;
		owner = owner_;
		v = dir_ * bulletVelocity;
	}
	
	override void render(SDL_Surface* s, V2f camera) {
		if (timeTilDeath == -1) {
			MovingEntity.render(s, camera);
		}
	}
	
	int ownerColor;
	Entity owner;
	int timeTilDeath = -1;
}
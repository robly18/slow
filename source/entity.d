import vector;
import std.conv;
import derelict.sdl2.sdl;
import std.algorithm.comparison;
import std.math;

class Entity { //entity is a rectangle
public:
	this (Vec2!float pos_, Vec2!float size_, int color_ = 0) {
		pos = pos_;
		size = size_;
		color = color_;
	}	

	void render(SDL_Surface* s) {
		SDL_Rect r = {to!int(pos.x),
					  to!int(pos.y),
					  to!int(size.x),
					  to!int(size.y)};
		SDL_FillRect(s, &r, color);
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
		if (abs(cx) < abs(cy))
			return Vec2!float(cx, 0);
		return Vec2!float(0, cy);
	}

	Vec2!float pos;
	Vec2!float size;
	
	Vec2!float v = Vec2!float(0,0);
	
	int color;
}
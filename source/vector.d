import std.math;

struct Vec2 (T) {
	T x, y;
	this(T xx, T yy) {
		x = xx; y = yy;
	}
	
	float norm() {
		return sqrt(x*x + y*y);
	}
	
	auto opOpAssign(string op) (Vec2!T other) {
		this = mixin("this "~op~" other");
	}
	
	auto opBinary(string op) (Vec2!T other) inout { //add and subtract
		static if (op == "+")
			return Vec2(x + other.x, y + other.y);
		else static if (op == "-") 
			return Vec2(x - other.x, y - other.y);
		else static if (op == "*")
			return x*other.x + y*other.y;
	}
	
	auto opUnary(string op) () inout {
		static if (op == "-")
			return (-1) * this;
	}
	
	Vec2!T opBinary(string op) (T scalar) inout { //scalar multiplication
		static if (op == "*")
			return Vec2(x*scalar, y*scalar);
		else static if (op == "/")
			return Vec2(x/scalar, y/scalar);
	}
	Vec2!T opBinaryRight(string op) (T scalar) inout { //scalar multiplication
		static if (op == "*")
			return Vec2(x*scalar, y*scalar);
	}	
}


alias V2f = Vec2!float;

V2f normalizeToLessThan(V2f v, float maxNorm) {
	if (v.norm() <= maxNorm) return v;
	return v/v.norm() * maxNorm;
}
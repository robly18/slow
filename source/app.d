import std.stdio;
import derelict.sdl2.sdl;
import std.conv;
import std.algorithm;
import std.random;

import vector;
import entity;
import healthComponent;
import aiComponent;

const auto g = Vec2!float(0, 10);

const float dt = 0.01;
const int momentsPerTurn = 300;
const int momentsPerSkip = 30;
const int timeBetweenShots = 80;
const int groundJumpTime = 100;

const float secondsPerGameSecond = 0.4;

const float maxJumpForce = 40;
const float maxAirPulsePerMoment = 0.05;
const float pixelsPerForceUnit = 2;

const int levelWidth = 2000;

Entity[] staticEntities;
Bullet[] bullets;
ActiveEntity[] entities; //todo

V2f normalizeToLessThan(V2f v, float maxNorm) {
	if (v.norm() <= maxNorm) return v;
	return v/v.norm() * maxNorm;
}

void main() {
	DerelictSDL2.load();
	
	SDL_Init(SDL_INIT_VIDEO);
	
	SDL_Window *w = SDL_CreateWindow("hi", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_SHOWN);
	SDL_Surface *s = SDL_GetWindowSurface(w);
	
	V2f camera = V2f(0,0);
	
	auto ent = new ActiveEntity(Vec2!float(280, 40), Vec2!float(20, 20), 0xFF0000, 0xFFAAAA);
	ent.health = new HealthComponent(5);
	int prevt = SDL_GetTicks();
	float deltat = 0;
	
	int momentsSinceLastTurn = 0;
	
	bool shooting = false;
	int shotCooldown = 0;
	Vec2!float target;
	int turnsSinceGrounded = 999999;
	
	staticEntities ~= [new Entity(Vec2!float(0, 240), Vec2!float(300, 10))];
	staticEntities ~= [new Entity(Vec2!float(500, 240), Vec2!float(500, 10))];
	staticEntities ~= [new Entity(Vec2!float(1200, 350), Vec2!float(500, 10))];
	staticEntities ~= [new Entity(Vec2!float(200, 440), Vec2!float(400, 10))];
	staticEntities ~= [new Entity(Vec2!float(900, 530), Vec2!float(400, 100))];
	staticEntities ~= [new Entity(Vec2!float(750, 540), Vec2!float(1000, 100))];
	staticEntities ~= [new Entity(Vec2!float(2000 - 50, 0), Vec2!float(50, 600))];
	staticEntities ~= [new Entity(Vec2!float(0, 0), Vec2!float(50, 600))];
	staticEntities ~= [new Entity(Vec2!float(0, 550), Vec2!float(2000, 50))];
	staticEntities ~= [new Entity(Vec2!float(0, 0), Vec2!float(2000, 20))];
	
	entities ~= [new ActiveEntity(Vec2!float(1000, 400), Vec2!float(40, 40))];
	entities[$-1].ai = new BasicAiComponent(1000, uniform(1, 1000));
	entities[$-1].health = new HealthComponent(20);
	entities ~= [new ActiveEntity(Vec2!float(1100, 400), Vec2!float(40, 40))];
	entities[$-1].ai = new BasicAiComponent(1000, uniform(1, 1000));
	entities[$-1].health = new HealthComponent(20);
	entities ~= [new ActiveEntity(Vec2!float(1200, 400), Vec2!float(40, 40))];
	entities[$-1].ai = new BasicAiComponent(1000, uniform(1, 1000));
	entities[$-1].health = new HealthComponent(20);
	entities ~= [new ActiveEntity(Vec2!float(1600, 400), Vec2!float(40, 40))];
	entities[$-1].ai = new BasicAiComponent(1000, uniform(1, 1000));
	entities[$-1].health = new HealthComponent(20);
	
	bool quit = false;
	while (!quit) {
		{
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) quit = true;
		if (e.type == SDL_MOUSEBUTTONDOWN) {
				if (momentsSinceLastTurn == momentsPerTurn) {
					shooting = false;
					auto mpos = Vec2!float(e.button.x, e.button.y) + camera;
					auto com = ent.pos + ent.size/2;
					auto delta = mpos - com;
					if (delta.norm() < 5) continue;
					if (e.button.button == SDL_BUTTON_RIGHT) {
						if (turnsSinceGrounded <= groundJumpTime)
							delta = normalizeToLessThan(delta / pixelsPerForceUnit, max(maxJumpForce, maxAirPulsePerMoment * momentsPerTurn));
						else
							delta = normalizeToLessThan(delta / pixelsPerForceUnit, maxAirPulsePerMoment * momentsPerTurn);
						if (ent.v * delta < 0) ent.v = V2f(0,0);
						else ent.v = delta * (ent.v * delta) / (delta.norm() * delta.norm());
						ent.v += delta;
							
						momentsSinceLastTurn = 0;
						turnsSinceGrounded = 999999;
						deltat = 0;
					}
					if (e.button.button == SDL_BUTTON_LEFT) {
						shooting = true;
						target = mpos;
						
							
						momentsSinceLastTurn = 0;
						deltat = 0;
					}
				}
			}
			if (e.type == SDL_KEYDOWN) {
				if (e.key.keysym.sym == SDLK_SPACE) {
					if (momentsSinceLastTurn == momentsPerTurn) {
						shooting = false;
						momentsSinceLastTurn = momentsPerTurn - momentsPerSkip;
						deltat = 0;
					}
				}
			}
		}
		}
		
		int newt = SDL_GetTicks();
		deltat += (newt - prevt) * dt * secondsPerGameSecond;
		prevt = newt;
		
		
		/** Physics simulation and AI running **/
		
		while (momentsSinceLastTurn < momentsPerTurn && deltat > dt) {
			deltat -= dt;
			momentsSinceLastTurn++;
			turnsSinceGrounded++;
			
			if (shotCooldown > 0) {
				shotCooldown--;
			} else {
				if (shooting) {
					auto delta = target - ent.center();
					if (delta.norm() > 1) {
						bullets ~= new Bullet(0xFF0000, ent.center(), delta/delta.norm(), ent);
						delta = delta/delta.norm() * -5;
						ent.v += delta;
						
						shotCooldown = timeBetweenShots;
					}
				}
			}
			
			ent.accelerate(g, dt);
			foreach (Entity se; staticEntities) {
				auto axis = ent.axisOfCollision(se);
				float coeff = (axis * ent.v < 0) ? 1000 : 200;
				ent.accelerate(ent.axisOfCollision(se) * coeff, dt);
				if (axis.y < 0 || (axis.x != 0 && ent.v.y >= 0)) turnsSinceGrounded = 0;
			}
			foreach (e; entities) {
				auto axis = ent.axisOfCollision(e);
				float coeff = (axis * ent.v < 0) ? 1000 : 200;
				ent.accelerate(ent.axisOfCollision(e) * coeff, dt);
				if (axis.y < 0 || (axis.x != 0 && ent.v.y >= 0)) turnsSinceGrounded = 0;
			}
			ent.recordImage();
			
			int[] removelist;
			foreach (i, b ; bullets) {
				if (b.timeTilDeath >= 0) {
					b.timeTilDeath--;
					if (b.timeTilDeath == 0) {
						removelist ~= [i];
					}
					b.recordImage();
					continue;
				}
				
				b.accelerate(g, dt);
				foreach (Entity se; staticEntities) {
					if (b.collidesWith(se)) {
						b.timeTilDeath = pastImageNo;
						b.v = Vec2!float(0, 0);
					}
				}
				foreach (e; entities) {
					if (e !is b.owner && b.collidesWith(e)) {
						if (e.color != b.ownerColor)
							e.hitWithBullet(b);
						b.timeTilDeath = pastImageNo;
						b.v = Vec2!float(0, 0);
					}
				}
				
				if (b.ownerColor != ent.color && b.collidesWith(ent)) {
					if (ent !is b.owner)
						ent.hitWithBullet(b);
					b.timeTilDeath = pastImageNo;
					b.v = Vec2!float(0, 0);
				}
				
				b.recordImage();
			}
			
			foreach (i, ee ; entities) {
				ee.accelerate(g, dt);
				ee.runAi(ent, bullets);
				
				foreach (Entity se; staticEntities) {
					auto axis = ee.axisOfCollision(se);
					float coeff = (axis * ee.v < 0) ? 1000 : 200;
					ee.accelerate(ee.axisOfCollision(se) * coeff, dt);
					//if (axis.y < 0 || (axis.x != 0 && ent.v.y >= 0)) turnsSinceGrounded = 0;
				}
				foreach (e; entities) {
					if (e is ee) continue;
					auto axis = ee.axisOfCollision(e);
					float coeff = (axis * ee.v < 0) ? 1000 : 200;
					ee.accelerate(ee.axisOfCollision(e) * coeff, dt);
					//if (axis.y < 0 || (axis.x != 0 && ent.v.y >= 0)) turnsSinceGrounded = 0;
				}
				
				auto axis = ee.axisOfCollision(ent);
				float coeff = (axis * ee.v < 0) ? 1000 : 200;
				ee.accelerate(ee.axisOfCollision(ent) * coeff, dt);
				
				ee.recordImage();
			}
			
			foreach_reverse (i ; removelist) {
				bullets[i] = bullets[$-1];
				bullets.length--;
			}
			
			ent.runTime(dt);
			foreach (e ; entities) {
				e.runTime(dt);
			}
			foreach (b ; bullets) {
				b.runTime(dt);
			}
		}
		
		/** Rendering **/
		
		camera.x = ent.pos.x + ent.size.x/2 - 800/2;
		camera.x = max(camera.x, 0);
		camera.x = min(camera.x, levelWidth - 800);
		
		SDL_FillRect(s, null, 0xFFFFFF);
		ent.renderGhosts(s, camera);
		foreach (ActiveEntity e; entities) {
			e.renderGhosts(s, camera);
		}
		foreach (b ; bullets) {
			b.renderGhosts(s, camera);
		}
		ent.render(s, camera);
		foreach (Entity se; staticEntities) {
			se.render(s, camera);
		}
		foreach (ActiveEntity e; entities) {
			e.render(s, camera);
		}
		foreach (Bullet b ; bullets) {
			b.render(s, camera);
		}
		SDL_Rect marker = {10, 10, 20, 20};
		SDL_FillRect(s, &marker, turnsSinceGrounded <= groundJumpTime ? 0x00FF00 : 0xFF0000);
		
		SDL_Rect mouseRect = {0,0,10,10};
		V2f delta;
		SDL_GetMouseState(&mouseRect.x, &mouseRect.y);
		delta.x = to!float(mouseRect.x); delta.y = to!float(mouseRect.y);
		delta = delta - (ent.center() - camera);
		if (turnsSinceGrounded <= groundJumpTime)
			delta = normalizeToLessThan(delta, maxJumpForce * pixelsPerForceUnit);
		else
			delta = normalizeToLessThan(delta, maxAirPulsePerMoment * momentsPerTurn * pixelsPerForceUnit);
		
		mouseRect.x = to!int(ent.center().x + delta.x - camera.x);
		mouseRect.y = to!int(ent.center().y + delta.y - camera.y);
		mouseRect.x -= 5; mouseRect.y -= 5;
		SDL_FillRect(s, &mouseRect, 0x666666);
		
		SDL_UpdateWindowSurface(w);
	}
}

import std.stdio;
import derelict.sdl2.sdl;
import std.conv;
import std.algorithm;
import std.random;

import vector;
import entity;
import healthComponent;
import aiComponent;

import constants;

class Engine {
	Entity[] staticEntities;
	Bullet[] bullets;
	ActiveEntity[] entities; //todo
	
	Player player;
	
	int momentsSinceLastTurn = 0;
	
	bool shooting = false;
	int shotCooldown = 0;
	Vec2!float target;
	int turnsSinceGrounded = 999999;
	
	int prevt;
	float deltat = 0;
	
	void init() {
		DerelictSDL2.load();
		SDL_Init(SDL_INIT_VIDEO);
		
		w = SDL_CreateWindow("hi", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenWidth, screenHeight, SDL_WINDOW_SHOWN);
		s = SDL_GetWindowSurface(w);
		
		player = new Player(Vec2!float(280, 40), Vec2!float(20, 20), 0xFF0000, 0xFFAAAA);
		player.health = new HealthComponent(5);
		
		/** level creation and population **/
		
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
		
		prevt = SDL_GetTicks();
	}
	
	void handleEvents() {
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) quit = true;
			if (e.type == SDL_MOUSEBUTTONDOWN) {
				if (momentsSinceLastTurn == momentsPerTurn) {
					//shooting = false;
					player.attackDirection = V2f(0,0);
					auto mpos = Vec2!float(e.button.x, e.button.y) + camera;
					auto com = player.pos + player.size/2;
					auto delta = mpos - com;
					if (delta.norm() < 5) continue;
					if (e.button.button == SDL_BUTTON_RIGHT) {
						if (turnsSinceGrounded <= groundJumpTime)
							delta = normalizeToLessThan(delta / pixelsPerForceUnit, max(maxJumpForce, maxAirPulsePerMoment * momentsPerTurn));
						else
							delta = normalizeToLessThan(delta / pixelsPerForceUnit, maxAirPulsePerMoment * momentsPerTurn);
						if (player.v * delta < 0) player.v = V2f(0,0);
						else player.v = delta * (player.v * delta) / (delta.norm() * delta.norm());
						player.v += delta;
							
						momentsSinceLastTurn = 0;
						turnsSinceGrounded = 999999;
						deltat = 0;
					}
					if (e.button.button == SDL_BUTTON_LEFT) {
						/*shooting = true;
						target = mpos;*/
						player.attackDirection = delta/delta.norm();
						player.v = player.attackDirection * 130;
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
	
	void tick() {
		int newt = SDL_GetTicks();
		deltat += (newt - prevt) * dt * secondsPerGameSecond;
		prevt = newt;
		
		while (momentsSinceLastTurn < momentsPerTurn && deltat > dt) {
			deltat -= dt;
			momentsSinceLastTurn++;
			turnsSinceGrounded++;
			
			if (shotCooldown > 0) {
				shotCooldown--;
			} else {
				if (shooting) {
					auto delta = target - player.center();
					if (delta.norm() > 1) {
						bullets ~= new Bullet(0xFF0000, player.center(), delta/delta.norm(), player, 10);
						delta = bullets[$-1].v * (-1) * player.inv_mass / bullets[$-1].inv_mass;
						player.v += delta;
						
						shotCooldown = timeBetweenShots;
					}
				}
			}
			
			player.accelerate(g, dt);
			foreach (se; staticEntities) {
				auto axis = player.axisOfCollision(se);
				float coeff = (axis * player.v < 0) ? 1000 : 200;
				player.accelerate(player.axisOfCollision(se) * coeff, dt);
				if (axis != V2f(0,0)) player.attackDirection = V2f(0,0);
				if (axis.y < 0 || (axis.x != 0 && player.v.y >= 0)) turnsSinceGrounded = 0;
			}
			foreach (e; entities) {
				auto axis = player.axisOfCollision(e);
				float coeff = (axis * player.v < 0) ? 1000 : 200;
				player.applyForce(player.axisOfCollision(e) * coeff, dt);
				if (axis != V2f(0,0)) player.attackDirection = V2f(0,0);
				if (axis.y < 0 || (axis.x != 0 && player.v.y >= 0)) turnsSinceGrounded = 0;
			}
			player.recordImage();
			
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
				
				if (b.ownerColor != player.color && b.collidesWith(player)) {
					if (player !is b.owner)
						player.hitWithBullet(b);
					b.timeTilDeath = pastImageNo;
					b.v = Vec2!float(0, 0);
				}
				
				b.recordImage();
			}
			
			foreach (i, ee ; entities) {
				ee.accelerate(g, dt);
				ee.runAi(player, bullets);
				
				foreach (Entity se; staticEntities) {
					auto axis = ee.axisOfCollision(se);
					float coeff = (axis * ee.v < 0) ? 1000 : 200;
					ee.accelerate(ee.axisOfCollision(se) * coeff, dt);
				}
				
				foreach (e; entities) {
					if (e is ee) continue;
					auto axis = ee.axisOfCollision(e);
					float coeff = (axis * ee.v < 0) ? 1000 : 200;
					ee.applyForce(ee.axisOfCollision(e) * coeff, dt);
				}
				
				auto axis = ee.axisOfCollision(player);
				float coeff = (axis * ee.v < 0) ? 1000 : 200;
				ee.applyForce(ee.axisOfCollision(player) * coeff, dt);
				
				ee.recordImage();
			}
			
			foreach_reverse (i ; removelist) {
				bullets[i] = bullets[$-1];
				bullets.length--;
			}
			
			player.runTime(dt);
			foreach (e ; entities) {
				e.runTime(dt);
			}
			foreach (b ; bullets) {
				b.runTime(dt);
			}
		}
	}
	
	void render() {
		camera.x = player.pos.x + player.size.x/2 - 800/2;
		camera.x = max(camera.x, 0);
		camera.x = min(camera.x, levelWidth - 800);
		
		SDL_FillRect(s, null, 0xFFFFFF);
		player.renderGhosts(s, camera);
		foreach (ActiveEntity e; entities) {
			e.renderGhosts(s, camera);
		}
		foreach (b ; bullets) {
			b.renderGhosts(s, camera);
		}
		player.render(s, camera);
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
		delta = delta - (player.center() - camera);
		if (turnsSinceGrounded <= groundJumpTime)
			delta = normalizeToLessThan(delta, maxJumpForce * pixelsPerForceUnit);
		else
			delta = normalizeToLessThan(delta, maxAirPulsePerMoment * momentsPerTurn * pixelsPerForceUnit);
		
		mouseRect.x = to!int(player.center().x + delta.x - camera.x);
		mouseRect.y = to!int(player.center().y + delta.y - camera.y);
		mouseRect.x -= 5; mouseRect.y -= 5;
		SDL_FillRect(s, &mouseRect, 0x666666);
		
		SDL_UpdateWindowSurface(w);
	}
	
	
	V2f camera = V2f(0,0);
	
	
	SDL_Window *w;
	SDL_Surface *s;
	bool quit = false;
}
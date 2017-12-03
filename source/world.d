
import derelict.sdl2.sdl;

public import entity;
import vector;
import constants;

class World {
public:
	Entity[] staticEntities;
	Bullet[] bullets;
	ActiveEntity[] entities;
	
	Player[] players;
	int playerTurn() {
		int j = -1;
		foreach(i, p; players) {
			if (!p.stamina.tired()) j = i;
		}
		return j;
	}
	
	void simulateTick() {
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
			
			
			b.recordImage();
		}
		
		foreach (i, ee ; entities) {
			ee.accelerate(g, dt);
			ee.turnsSinceGrounded++;
			ee.runAi(this);
			
			foreach (Entity se; staticEntities) {
				auto axis = ee.axisOfCollision(se);
				float coeff = (axis * ee.v < 0) ? 1000 : 200;
				ee.accelerate(axis * coeff, dt);
				if (axis.y < 0 || axis.x != 0) {
					ee.turnsSinceGrounded = 0;
				}
			}
			
			foreach (e; entities) {
				if (e is ee) continue;
				auto axis = ee.axisOfCollision(e);
				float coeff = (axis * ee.v < 0) ? 1000 : 200;
				ee.applyForce(axis * coeff, dt);
				if (axis.y < 0 || axis.x != 0) {
					ee.turnsSinceGrounded = 0;
				}
			}
			
			
			ee.recordImage();
		}
		
		foreach_reverse (i ; removelist) {
			bullets[i] = bullets[$-1];
			bullets.length--;
		}
		
		foreach (e ; entities) {
			e.runTime(dt);
		}
		foreach (b ; bullets) {
			b.runTime(dt);
		}
	}
	
	void render(SDL_Surface* s, V2f camera) {
		SDL_FillRect(s, null, 0xFFFFFF);
		foreach (ActiveEntity e; entities) {
			e.renderGhosts(s, camera);
		}
		foreach (b ; bullets) {
			b.renderGhosts(s, camera);
		}
		foreach (Entity se; staticEntities) {
			se.render(s, camera);
		}
		foreach (ActiveEntity e; entities) {
			e.render(s, camera);
		}
		foreach (Bullet b ; bullets) {
			b.render(s, camera);
		}
	}
}
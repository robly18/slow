
import derelict.sdl2.sdl;

public import entity;
import vector;
import constants;

class World {
public:
	Entity[] staticEntities;
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
		
		foreach (e ; entities) {
			e.runTime(dt);
		}
	}
	
	void render(SDL_Surface* s, V2f camera) {
		SDL_FillRect(s, null, 0xFFFFFF);
		foreach (ActiveEntity e; entities) {
			e.renderGhosts(s, camera);
		}
		foreach (Entity se; staticEntities) {
			se.render(s, camera);
		}
		foreach (ActiveEntity e; entities) {
			e.render(s, camera);
		}
	}
	
	void renderTaskbar(SDL_Surface *ts, int playerid, int predictedCost) {
		SDL_FillRect(ts, null, 0x333333);
		Player p = players[playerid];
		p.stamina.renderTaskbar(ts);
		p.stamina.renderSubTaskbar(ts, predictedCost);
		p.health.renderTaskbar(ts);
	}
}
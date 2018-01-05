import std.stdio;
import derelict.sdl2.sdl;
import std.conv;
import std.algorithm;
import std.random;

import vector;
import entity;
import healthComponent;
import aiComponent;
import internetAiComponent;
import staminaComponent;

import action;

import world;

import constants;

class Engine {
	World world = new World;
	
	Player player;
	int playerid = 0;
	
	int prevt;
	float deltat = 0;
	
	Action selectedAction = new Jump(groundJumpTime, maxJumpVelocity, skipStaminaPpt, 1000);
	
	void init() {
		DerelictSDL2.load();
		SDL_Init(SDL_INIT_VIDEO);
		
		
		w = SDL_CreateWindow("hi", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenWidth, screenHeight + taskbarHeight, SDL_WINDOW_SHOWN);
		s = SDL_GetWindowSurface(w);
		taskbarsurface = SDL_CreateRGBSurface(0, screenWidth, taskbarHeight, 32, 0,0,0,0);
		
		player = new Player(Vec2!float(280, 40), Vec2!float(20, 20), 0xFF0000, 0xFFAAAA, playerInvMass);
		player.health = new HealthComponent(10);
		player.stamina = new StaminaComponent(momentsPerTurn);
		
		world.entities ~= [player];
		world.players ~= [player];
		
		player.ai = new PlayerAiComponent(0);
		//other.ai = new InternetAiComponent(c, 1-playerid);
		
		/** level creation and population **/
		
		world.staticEntities ~= [new Entity(Vec2!float(0, 240), Vec2!float(300, 10))];
		world.staticEntities ~= [new Entity(Vec2!float(500, 240), Vec2!float(500, 10))];
		world.staticEntities ~= [new Entity(Vec2!float(1200, 350), Vec2!float(500, 10))];
		world.staticEntities ~= [new Entity(Vec2!float(200, 440), Vec2!float(400, 10))];
		world.staticEntities ~= [new Entity(Vec2!float(900, 530), Vec2!float(400, 100))];
		world.staticEntities ~= [new Entity(Vec2!float(750, 540), Vec2!float(1000, 100))];
		world.staticEntities ~= [new Entity(Vec2!float(2000 - 50, 0), Vec2!float(50, 600))];
		world.staticEntities ~= [new Entity(Vec2!float(0, 0), Vec2!float(50, 600))];
		world.staticEntities ~= [new Entity(Vec2!float(0, 550), Vec2!float(2000, 50))];
		world.staticEntities ~= [new Entity(Vec2!float(0, 0), Vec2!float(2000, 20))];
		
		prevt = SDL_GetTicks();
	}
	
	void handleEvents() {
		SDL_Event e;
		while (SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) quit = true;
			if (e.type == SDL_MOUSEBUTTONDOWN) {
				if (world.playerTurn() == playerid) {
					int x = e.button.x + to!int(camera.x);
					int y = e.button.y + to!int(camera.y);
					if (e.button.button == SDL_BUTTON_RIGHT) {
						/*Input i = Input(InputType.MOVE, x, y);
						actOnPlayerInput(i, world.players[playerid]);
						player.turnsSinceGrounded = 999999;
						deltat = 0;*/
						if (selectedAction.canAct(player, world)) {
							selectedAction.act(player, world, V2f(x,y));
						}
						deltat = 0;
					}
				}
			}
			if (e.type == SDL_KEYDOWN) {
				if (e.key.keysym.sym == SDLK_SPACE) {
					if (world.playerTurn() == playerid) {
						Input i = Input(InputType.SKIP);
						actOnPlayerInput(i, world.players[playerid]);
						deltat = 0;
					}
				}
			}
		}
	}
	
	void handleInternetEvents() {
	/*
		if (world.playerTurn() != -1 && world.playerTurn() != playerid) {
			actOnPlayerInput(c.getInput(), world.players[world.playerTurn()]);
			deltat = 0;
		}*/
	}
	
	void tick() {
		int newt = SDL_GetTicks();
		deltat += (newt - prevt) * dt * secondsPerGameSecond;
		prevt = newt;
		
		while (world.playerTurn() == -1 && deltat > dt) {
			deltat -= dt;
			
			world.simulateTick();
		}
	}
	
	void render() {
		camera.x = player.pos.x + player.size.x/2 - 800/2;
		camera.x = max(camera.x, 0);
		camera.x = min(camera.x, levelWidth - 800);
		
		world.render(s, camera);
		world.renderTaskbar(taskbarsurface, playerid);
		SDL_Rect taskbarRect = {0, screenHeight, screenWidth, taskbarHeight};
		SDL_BlitSurface(taskbarsurface, null, s, &taskbarRect);
		
		SDL_Rect marker = {10, 10, 20, 20};
		SDL_FillRect(s, &marker, player.turnsSinceGrounded <= groundJumpTime ? 0x00FF00 : 0xFF0000);
		marker.x = 10 + 25;
		SDL_FillRect(s, &marker, world.playerTurn() == playerid ? 0x00FF00 : 0xFF0000);
		marker.x = 10 + 25 + 25;
		SDL_FillRect(s, &marker, player.color);
		
		SDL_Rect mouseRect = {0,0,10,10};
		V2f delta;
		SDL_GetMouseState(&mouseRect.x, &mouseRect.y);
		delta.x = to!float(mouseRect.x); delta.y = to!float(mouseRect.y);
		delta = delta - (player.center() - camera);
		/*if (player.canJump())
			delta = normalizeToLessThan(delta, maxJumpVelocity * ghostTime);
		
		mouseRect.x = to!int(player.center().x + delta.x - camera.x);
		mouseRect.y = to!int(player.center().y + delta.y - camera.y);
		mouseRect.x -= 5; mouseRect.y -= 5;
		SDL_FillRect(s, &mouseRect, 0x666666);*/
		if (selectedAction.canAct(player, world))
			selectedAction.renderPreview(s, player, world, delta + player.center(), camera);
		
		SDL_UpdateWindowSurface(w);
	}
	
	
	V2f camera = V2f(0,0);
	
	
	SDL_Window* w;
	SDL_Surface* s, taskbarsurface;
	bool quit = false;
}
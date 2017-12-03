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

import world;

import connection;
import std.socket;

import constants;

class Engine {
	World world = new World;
	
	Player player;
	Player other;
	
	int playerid;
	
	int prevt;
	float deltat = 0;
	
	Connection c;
	char type;
	
	void init() {
		writeln("Server or client? (s/c)");
		string inputStr;
		readf!" %s\n"(inputStr);
		type = inputStr[0];
		writeln("Thanks.");
		if (type == 's') {
			c = new ServerConnection(new InternetAddress(8080));
		} else if (type == 'c') {
			writeln("Please input IP");
			readf!" %s\n"(inputStr);
			c = new ClientConnection(new InternetAddress(inputStr, 8080));
		} else {
			writeln("Error.");
		}
		c.s.blocking(false);
	
		DerelictSDL2.load();
		SDL_Init(SDL_INIT_VIDEO);
		
		
		w = SDL_CreateWindow("hi", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenWidth, screenHeight, SDL_WINDOW_SHOWN);
		s = SDL_GetWindowSurface(w);
		
		Player server, client;
		server = new Player(Vec2!float(280, 40), Vec2!float(20, 20), 0xFF0000, 0xFFAAAA, playerInvMass);
		server.health = new HealthComponent(10);
		server.stamina = new StaminaComponent(momentsPerTurn);
		
		client = new Player(Vec2!float(180, 40), Vec2!float(20, 20), 0x0000FF, 0xAAAAFF, playerInvMass);
		client.health = new HealthComponent(10);
		client.stamina = new StaminaComponent(momentsPerTurn);
		
		if (type == 's') {
			player = server; other = client; playerid = 0;
		} else {
			player = client; other = server; playerid = 1;
		}
		world.entities ~= [server, client];
		world.players ~= [server, client];
		
		player.ai = new PlayerAiComponent(playerid);
		other.ai = new InternetAiComponent(c, 1-playerid);
		
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
						Input i = Input(InputType.MOVE, x, y);
						actOnPlayerInput(i, world.players[playerid]);
						c.sendInput(i);
						player.turnsSinceGrounded = 999999;
						deltat = 0;
					}
				}
			}
			if (e.type == SDL_KEYDOWN) {
				if (e.key.keysym.sym == SDLK_SPACE) {
					if (world.playerTurn() == playerid) {
						Input i = Input(InputType.SKIP);
						actOnPlayerInput(i, world.players[playerid]);
						c.sendInput(i);
						deltat = 0;
					}
				}
			}
		}
	}
	
	void handleInternetEvents() {
		if (world.playerTurn() != -1 && world.playerTurn() != playerid) {
			actOnPlayerInput(c.getInput(), world.players[world.playerTurn()]);
			deltat = 0;
		}
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
		if (player.canJump())
			delta = normalizeToLessThan(delta, maxJumpVelocity * ghostTime);
		
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
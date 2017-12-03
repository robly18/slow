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


import engine;

void main() {
	Engine engine = new Engine;
	
	engine.init();
	
	
	while (!engine.quit) {
		engine.handleEvents();
		engine.handleInternetEvents();
		
		/** Physics simulation and AI running **/
		engine.tick();
		
		/** Rendering **/
		engine.render();
	}
}

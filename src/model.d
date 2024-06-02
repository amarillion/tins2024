module model;

import std.random;
import std.json;
import std.conv;

import helix.util.vec;

import isomap;
import readMap;
import generateMap;

class City
{
public:
	bool isDead = false; // waiting to be re-used
	int id = -1;

	string name = "";
	int population = 0;
	int center_x = 0;
	int center_y = 0;
}

class Model
{
public:	
	int tick = 0;
	int money = 0;
	MyGrid mapTT;
	
	City[] city;

	void initGame(JSONValue node) {
		// mapTT = new MyGrid(64, 64);
		mapTT = readMapFromTiledJSON(node);
		generate(mapTT, this);
	}

	int addCity(int mx, int my, string name) {
		City c = new City();

		c.center_x = mx;
		c.center_y = my;
		c.name = name;

		c.id = to!int(city.length);
		city ~= (c);
		return c.id;
	}
}

module model;

import std.random;
import std.json;
import std.conv;

import helix.util.vec;

import map;
import readMap;
import generateMap;
import tileMapper;
import train;

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
	Node[Edge][Node] links;

public:	
	int tick = 0;
	int money = 0;
	MyGrid mapTT;
	Train[] train;
	City[] city;

	void initGame(JSONValue node) {
		// mapTT = new MyGrid(64, 64);
		mapTT = readMapFromTiledJSON(node);
		generate(mapTT, this);

		TileMapper.mapTrackTiles(this);

		import std.stdio;
		writeln("Trying to find a path");
		Node current = links.keys[0];
		foreach(i; 0..20) {
			if (current !in links) {
				break;
			}
			auto options = links[current].values;
			if (options.length == 0) {
				break;
			}
			auto next = options[0];
			writefln("#%s: Going from %s to %s", i, current, next);
			current = next;
		}

		// create a new Train
		Node start = links.keys[0];
		Edge startDir = links[start].keys[0];
		auto t = new Train(this, start, startDir);
		t.wagons ~= Wagon(0, 0, 0);
		t.wagons ~= Wagon(0, 0, 1);
		t.wagons ~= Wagon(0, 0, 1);
		t.wagons ~= Wagon(0, 0, 1);
		t.wagons ~= Wagon(0, 0, 1);
		train ~= t;
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

	void createEdge(Node src, Node dest, Edge edge) {
		import std.stdio;
		writefln("Creating edge from %s to %s via %s", src, dest, edge);
		links[src][edge] = dest;
	}

	bool canGo(Node src, Edge edge) {
		if (edge in links[src]) {
			return true;
		}
		return false;
	}

	void update() {
		tick++;

		foreach(t; train) {
			t.doMove();
		}
	}
}

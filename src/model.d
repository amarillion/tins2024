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

		/* 
		//  Test pathfinding
		
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
		*/
	}

	void addTrain() {
		// create a new Train
		Node start = choice(links.keys); // random start node
		Edge startDir = choice(links[start].keys); // random direction
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
		links[src][edge] = dest;
	}

	bool canGo(Node src, Edge edge) {
		if (src in links && edge in links[src]) {
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

	int getSubNodeZ(Point p, int subnode) {
		switch(subnode) {
			case SubLoc.NW: return mapTT[p].cell.z;
			case SubLoc.N: return mapTT[p].cell.z; // NOTE: it's actually halfway between NW and NE, but if the surface is slanted we're in trouble anyway.
			case SubLoc.NE: return mapTT[p].cell.z + mapTT[p].cell.dzright;
			case SubLoc.E: return mapTT[p].cell.z + mapTT[p].cell.dzright;
			case SubLoc.SE: return mapTT[p].cell.z + mapTT[p].cell.dzbot;
			case SubLoc.S: return mapTT[p].cell.z + mapTT[p].cell.dzbot;
			case SubLoc.SW: return mapTT[p].cell.z + mapTT[p].cell.dzleft;
			case SubLoc.W: return mapTT[p].cell.z + mapTT[p].cell.dzleft;
			case SubLoc.CENTER: return mapTT[p].cell.z;
			default: return 0;
		}
	}
}

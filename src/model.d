module model;

import std.random;
import std.json;
import std.conv;

import helix.util.vec;

import map;
import readMap;
import generateMap;
import tileMapper;

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

		TileMapper.mapTrackTiles(this);
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

	Node getOrCreateNode(Point p, SubLoc loc) {
		if (loc in mapTT[p].nodes) {
			return mapTT[p].nodes[loc];
		}
		else {
			Node n = new Node(p, loc);
			mapTT[p].nodes[loc] = n;
			return n;
		}
	}

	void createEdge(Node src, Node dest, EdgeType edgeType) {
		src.links[edgeType] = dest;
	}
}

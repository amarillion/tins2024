/*
Module for isometric map initialization and manipulation.
Utility functions.
Does not depend on allegro.
*/
module map;

import std.conv;
import std.algorithm;

import helix.util.grid;
import helix.util.vec;
import helix.util.coordrange;

import isogrid : Cell;

/**
 * the subloc is a sub-tile-location, and it is the starting position of an edge.
 * For example, SubLoc::N means that you are starting from the center-top of a tile, facing south
 * while moving to the next tile.
 */
enum SubLoc { N, E, S, W }

struct EdgeType {
	SubLoc from;
	SubLoc to;
	int dx;
	int dy;
}

class Node {
	Point pos;
	SubLoc subloc;
	Node[EdgeType] links;
	this(Point p, SubLoc loc) {
		pos = p;
		subloc = loc;
	}
}

struct Tile {
	Cell cell;
	Node[SubLoc] nodes;

	/***********************
	 * spefic to this game
	 ***********************/
	
	int terrain_tile = -1;
	int[] track_tile = [];
	//~ int semaphore_tile;
	int building_tile = -1;
	
	bool hasTrack;
	int semaphore_state;
	int idStation; // -1 for none
	int idTrain; // -1 for none
}

alias MyGrid = Grid!(2, Tile);

MyGrid initMap(int dim) {
	MyGrid map = new MyGrid(dim, dim);

	foreach(p; PointRange(map.size))
	{
		map[p].cell.z = 0;
		map[p].cell.dzleft = 0;
		map[p].cell.dzright = 0;
		map[p].cell.dzbot = 0;
	}
	
	// raiseTile(map, 5, 5);
	map[Point(5, 5)].building_tile = 1;
	map[Point(8, 3)].building_tile = 2;
	map[Point(9, 9)].building_tile = 3;

	return map;
}

/** raise one corner in a map */
void raiseCorner(MyGrid map, int x, int y) {
	map[Point(x, y)].cell.z += 1;
	map[Point(x, y)].cell.dzright -=1;
	map[Point(x, y)].cell.dzbot -= 1;
	map[Point(x, y)].cell.dzleft -= 1;
	
	map[Point(x - 1, y)].cell.dzright += 1;
	map[Point(x - 1, y - 1)].cell.dzbot += 1;
	map[Point(x, y - 1)].cell.dzleft += 1;
}

/** raise one tile in a map */
void raiseTile(MyGrid map, int x, int y) {
	raiseCorner(map, x, y);
	raiseCorner(map, x + 1, y);
	raiseCorner(map, x + 1, y + 1);
	raiseCorner(map, x, y + 1);
}


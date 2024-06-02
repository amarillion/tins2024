/*
Module for isometric map initialization and manipulation.
Utility functions.
Does not depend on allegro.
*/
module map;

import std.conv;
import std.algorithm;
import std.math.constants : PI;
import std.math;

import helix.util.grid;
import helix.util.vec;
import helix.util.coordrange;

import isogrid : Cell;

/**
 * the subloc is a sub-tile-location, and it is the starting position of an edge.
 * For example, SubLoc::N means that you are starting from the center-top of a tile, facing south
 * while moving to the next tile.
 */
enum SubLoc { CENTER, N, E, S, W, NE, SE, SW, NW }

struct SubLocInfo {
	SubLoc loc;
	float dx;
	float dy;
	float degrees; // starting from 0 = north, clockwise, because that is how the sprites are drawn
}

enum SubLocInfo[SubLoc] SUBLOC_INFO = [
	SubLoc.CENTER: SubLocInfo(SubLoc.CENTER, 0.5, 0.5, 0),
	SubLoc.N: SubLocInfo(SubLoc.N, 0.5, 0.0, 180), // NB: if we're at subloc N, we're at the top of the tile facing south
	SubLoc.E: SubLocInfo(SubLoc.E, 1.0, 0.5, 270),
	SubLoc.S: SubLocInfo(SubLoc.S, 0.5, 1.0, 0),
	SubLoc.W: SubLocInfo(SubLoc.W, 0.0, 0.5, 90),
	
	SubLoc.NE: SubLocInfo(SubLoc.NE, 1.0, 0.0, 225),
	SubLoc.SE: SubLocInfo(SubLoc.SE, 1.0, 1.0, 315),
	SubLoc.SW: SubLocInfo(SubLoc.SW, 0.0, 1.0, 45),
	SubLoc.NW: SubLocInfo(SubLoc.NW, 0.0, 0.0, 135),
];

struct EdgeInfo {
	Edge type;

	SubLoc from;
	SubLoc to;
	int dx;
	int dy;
	int dz;

	float length = 1.0; // note: flat distance, excluding height difference

	float calc_x(float dist) const {
		if (length > 0.78 && length < 0.79)
			return calc_pivot_x(type, dist);
		else if (length > 1.17 && length < 1.18)
			return calc_pivot2(type, dist).x;
		else return calc_linear_x(type, dist);
	}

	float calc_y(float dist) const {
		if (length > 0.78 && length < 0.79)
			return calc_pivot_y(type, dist);
		else if (length > 1.17 && length < 1.18)
			return calc_pivot2(type, dist).y;
		else return calc_linear_y(type, dist);
	}
}

enum Edge { 
	UNDEFINED,

	// straight:
	N, E, S, W,

	// small turn:
	NE_small, NW_small, SE_small, SW_small, ES_small, WS_small, EN_small, WN_small,

	// diagonal:
	NE, SE, SW, NW,

	// big turn start:
	NE_big_start, NW_big_start, SE_big_start, SW_big_start, ES_big_start, WS_big_start, EN_big_start, WN_big_start,

	// big turn end:
	NE_big_end, NW_big_end, SE_big_end, SW_big_end, ES_big_end, WS_big_end, EN_big_end, WN_big_end,
}

enum EdgeInfo[Edge] EDGE_INFO = [
	Edge.UNDEFINED: EdgeInfo(Edge.UNDEFINED, SubLoc.CENTER, SubLoc.CENTER, 0, 0, 0, 0.0f),

	Edge.N: EdgeInfo(Edge.N, SubLoc.S, SubLoc.S, 0, -1, 0, 1.0f),
	Edge.E: EdgeInfo(Edge.E, SubLoc.W, SubLoc.W, 1,  0, 0, 1.0f),
	Edge.S: EdgeInfo(Edge.S, SubLoc.N, SubLoc.N, 0,  1, 0, 1.0f),
	Edge.W: EdgeInfo(Edge.W, SubLoc.E, SubLoc.E, -1, 0, 0, 1.0f),

	// quarter circle with radius 0.5
	// going from N to E
	Edge.NE_small: EdgeInfo(Edge.NE_small, SubLoc.S, SubLoc.W,  1,  0, 0, 0.25 * PI),
	Edge.NW_small: EdgeInfo(Edge.NW_small, SubLoc.S, SubLoc.E, -1,  0, 0, 0.25 * PI),
	Edge.SE_small: EdgeInfo(Edge.SE_small, SubLoc.N, SubLoc.W,  1,  0, 0, 0.25 * PI),
	Edge.SW_small: EdgeInfo(Edge.SW_small, SubLoc.N, SubLoc.E, -1,  0, 0, 0.25 * PI),

	Edge.EN_small: EdgeInfo(Edge.EN_small, SubLoc.W, SubLoc.S,  0, -1, 0, 0.25 * PI),
	Edge.ES_small: EdgeInfo(Edge.ES_small, SubLoc.W, SubLoc.N,  0,  1, 0, 0.25 * PI),
	Edge.WN_small: EdgeInfo(Edge.WN_small, SubLoc.E, SubLoc.S,  0, -1, 0, 0.25 * PI),
	Edge.WS_small: EdgeInfo(Edge.WS_small, SubLoc.E, SubLoc.N,  0,  1, 0, 0.25 * PI),

	// eighth circle with radius 1.0
	Edge.NE_big_start: EdgeInfo(Edge.NE_big_start, SubLoc.S, SubLoc.SW,  1,  -1, 0, 0.375 * PI),
	Edge.NE_big_end:   EdgeInfo(Edge.NE_big_end,   SubLoc.SW, SubLoc.W,  1,   0, 0, 0.375 * PI),
	Edge.NW_big_start: EdgeInfo(Edge.NW_big_start, SubLoc.S, SubLoc.SE, -1,  -1, 0, 0.375 * PI),
	Edge.NW_big_end:   EdgeInfo(Edge.NW_big_end,   SubLoc.SE, SubLoc.E, -1,   0, 0, 0.375 * PI),
	Edge.SE_big_start: EdgeInfo(Edge.SE_big_start, SubLoc.N, SubLoc.NW,  1,   1, 0, 0.375 * PI),
	Edge.SE_big_end:   EdgeInfo(Edge.SE_big_end,   SubLoc.NW, SubLoc.W,  1,   0, 0, 0.375 * PI),
	Edge.SW_big_start: EdgeInfo(Edge.SW_big_start, SubLoc.N, SubLoc.NE, -1,   1, 0, 0.375 * PI),
	Edge.SW_big_end:   EdgeInfo(Edge.SW_big_end,   SubLoc.NE, SubLoc.E, -1,   0, 0, 0.375 * PI),
	Edge.ES_big_start: EdgeInfo(Edge.ES_big_start, SubLoc.W, SubLoc.NW,  1,   1, 0, 0.375 * PI),
	Edge.ES_big_end:   EdgeInfo(Edge.ES_big_end,   SubLoc.NW, SubLoc.N,  0,   1, 0, 0.375 * PI),
	Edge.WS_big_start: EdgeInfo(Edge.WS_big_start, SubLoc.E, SubLoc.NE, -1,   1, 0, 0.375 * PI),
	Edge.WS_big_end:   EdgeInfo(Edge.WS_big_end,   SubLoc.NE, SubLoc.N,  0,   1, 0, 0.375 * PI),
	Edge.EN_big_start: EdgeInfo(Edge.EN_big_start, SubLoc.W, SubLoc.SW,  1,  -1, 0, 0.375 * PI),
	Edge.EN_big_end:   EdgeInfo(Edge.EN_big_end,   SubLoc.SW, SubLoc.S,  0,  -1, 0, 0.375 * PI),
	Edge.WN_big_start: EdgeInfo(Edge.WN_big_start, SubLoc.E, SubLoc.SE, -1,  -1, 0, 0.375 * PI),
	Edge.WN_big_end:   EdgeInfo(Edge.WN_big_end,   SubLoc.SE, SubLoc.S,  0,  -1, 0, 0.375 * PI),

	// diagonals
	Edge.NW: EdgeInfo(Edge.NW, SubLoc.SE, SubLoc.SE, -1, -1, 0, sqrt(2.0)),
	Edge.NE: EdgeInfo(Edge.NE, SubLoc.SW, SubLoc.SW,  1, -1, 0, sqrt(2.0)),
	Edge.SE: EdgeInfo(Edge.SE, SubLoc.NW, SubLoc.NW,  1,  1, 0, sqrt(2.0)),
	Edge.SW: EdgeInfo(Edge.SW, SubLoc.NE, SubLoc.NE, -1,  1, 0, sqrt(2.0)),
];

// Must be struct, because we want to create instances and do equality checks
struct Node {
	Point pos;
	SubLoc subLoc;

	this(Point p, SubLoc loc) {
		pos = p;
		subLoc = loc;
	}

	/**
	 * In place modification // TODO: make const
	 */
	Node followReverse(Edge e) const {
		auto eInfo = EDGE_INFO[e]; 
		// TODO: assertion fails
		// assert (eInfo.to == subLoc, "followReverse(...) has wrong toSubLoc");
		return Node(
			pos - Point(eInfo.dx, eInfo.dy),
			eInfo.from
		);
	}

	Node following(Edge e) const {
		auto eInfo = EDGE_INFO[e]; 
		assert (eInfo.from == subLoc, "follow(...) has wrong fromSubLoc");
		return Node(
			pos + Point(eInfo.dx, eInfo.dy),
			eInfo.to
		);
	}
}

struct Tile {
	Cell cell;

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

float calc_linear_x(Edge e, float dist) {
	auto eInfo = EDGE_INFO[e];
	if (eInfo.length == 0) return SUBLOC_INFO[eInfo.from].dx;
	float frac = dist / eInfo.length;
	return
		SUBLOC_INFO[eInfo.from].dx * (1.0f - frac) +
		(eInfo.dx + SUBLOC_INFO[eInfo.to].dx) * frac;
}

float calc_linear_y(Edge e, float dist) {
	auto eInfo = EDGE_INFO[e];
	if (eInfo.length == 0) return SUBLOC_INFO[eInfo.from].dy;
	float frac = dist / eInfo.length;
	return
		SUBLOC_INFO[eInfo.from].dy * (1.0f - frac) +
		(eInfo.dy + SUBLOC_INFO[eInfo.to].dy) * frac;
}

vec!(2, float) calc_pivot2(Edge e, float dist) {
	auto eInfo = EDGE_INFO[e];

	float fromAngle = SUBLOC_INFO[eInfo.from].degrees;
	float nextAngle = SUBLOC_INFO[eInfo.to].degrees;

	float deltaAngle = nextAngle - fromAngle;
	if (deltaAngle > 180) deltaAngle -= 360;
	if (deltaAngle < -180) deltaAngle += 360;

	float frac = dist / eInfo.length;
	float currentAngle = fromAngle + ((deltaAngle) * frac);
	float currentRadians = (currentAngle) * PI / 180;
	float startRadians = fromAngle * PI / 180;

	float fromX = SUBLOC_INFO[eInfo.from].dx;
	float fromY = SUBLOC_INFO[eInfo.from].dy;

	return vec!(2, float)(
		// big circle has radius of 1.5
		// we swap sin and cos to get at the derivative of the circle
		fromX + 1.5 * (cos(currentRadians) - cos(startRadians)),
		fromY + 1.5 * (sin(currentRadians) - sin(startRadians)),
		// fromX, fromY
	);
}

float calc_pivot_x(Edge e, float dist) {
	auto eInfo = EDGE_INFO[e];

	float fromX = SUBLOC_INFO[eInfo.from].dx;
	float nextX = eInfo.dx + SUBLOC_INFO[eInfo.to].dx;

	float pivot_x = (fromX == 0.5) ? nextX : fromX;

	float ofst =
			(fromX == 0.5) ? 0.5 * cos(dist * 2) : 0.5 * sin(dist * 2);

	if (pivot_x == 1.0) {
		return 1.0 - ofst;
	}
	else
	return ofst;
}

float calc_pivot_y(Edge e, float dist) {
	auto eInfo = EDGE_INFO[e];

	float fromY = SUBLOC_INFO[eInfo.from].dy;
	float nextY = eInfo.dy + SUBLOC_INFO[eInfo.to].dy;

	float pivot_y = (fromY == 0.5) ? nextY : fromY;

	float ofst = (fromY == 0.5) ? 0.5 * cos(dist * 2) : 0.5 * sin(dist * 2);

	if (pivot_y == 1.0) {
		return 1.0 - ofst;
	}
	else
	return ofst;
}

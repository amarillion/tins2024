/*
Module for isometric map initialization and manipulation.
Utility functions.
Does not depend on allegro.
*/
module isomap;

import std.conv;
import std.algorithm;

import helix.util.grid;
import helix.util.vec;
import helix.util.coordrange;

/**
 * Draw a surface.
 *
 * z is the height, in tile units, of the top corner.
 *
 * dzleft, dzright and dzbot are the z-delta, in tile units, of the left,
 * right and bottom corners
 */
struct Tile
{
	int z = 0;
	short dzleft = 0;
	short dzright = 0;
	short dzbot = 0;

	bool isVerticalSplit() const
	{
		return dzbot == 0;
	}

	/** helper to calculate the z height at any corner of a Cell. */
	int getZ(int dx, int dy)
	{
		assert (dx == 0 || dx == 1);
		assert (dy == 0 || dy == 1);
		
		switch (dx + 2 * dy)
		{
			case 1: return z + dzright;
			case 2: return z + dzleft;
			case 3: return z + dzbot;
			default: return z;
		}
	}

	// lift corner of a single tile
	void liftCorner(int delta, int side)
	{
		switch (side)
		{
		case 0:
			z += delta;
			dzleft -= delta;
			dzright -= delta;
			dzbot -= delta;
			break;
		case 1:
			dzright += delta;
			break;
		case 2:
			dzbot += delta;
			break;
		case 3:
			dzleft += delta;
			break;
		default:
			assert (false);
		}
	}

	void setCorner(int value, int side)
	{
		int delta = value - z;
		switch (side)
		{
		case 0:
			z += delta;
			dzleft -= delta;
			dzright -= delta;
			dzbot -= delta;
			break;
		case 1:
			dzright = to!short(delta);
			break;
		case 2:
			dzbot = to!short(delta);
			break;
		case 3:
			dzleft = to!short(delta);
			break;
		default:
			assert (false);
		}
	}

	// return the z of the highest corner.
	int getMaxHeight()
	{
		return max(z, max (z + dzbot, max (z + dzleft, z + dzright)));
	}

	// return the z of the lowest corner
	int getMinHeight()
	{
		return min(z, min (z + dzbot, min (z + dzleft, z + dzright)));
	}

	bool isFlat()
	{
		return (dzbot == 0 && dzleft == 0 && dzright == 0);
	}

	/***********************
	 * spefic to this game
	 ***********************/
	int building = 0;

}

alias MyGrid = Grid!(2, Tile);

MyGrid initMap(int dim) {
	MyGrid map = new MyGrid(dim, dim);

	foreach(p; PointRange(map.size))
	{
		map[p].z = 0;
		map[p].dzleft = 0;
		map[p].dzright = 0;
		map[p].dzbot = 0;
	}
	
	// raiseTile(map, 5, 5);
	map[Point(5, 5)].building = 1;
	map[Point(8, 3)].building = 2;
	map[Point(9, 9)].building = 3;

	return map;
}

/** raise one corner in a map */
void raiseCorner(MyGrid map, int x, int y) {
	map[Point(x, y)].z += 1;
	map[Point(x, y)].dzright -=1;
	map[Point(x, y)].dzbot -= 1;
	map[Point(x, y)].dzleft -= 1;
	
	map[Point(x - 1, y)].dzright += 1;
	map[Point(x - 1, y - 1)].dzbot += 1;
	map[Point(x, y - 1)].dzleft += 1;
}

/** raise one tile in a map */
void raiseTile(MyGrid map, int x, int y) {
	raiseCorner(map, x, y);
	raiseCorner(map, x + 1, y);
	raiseCorner(map, x + 1, y + 1);
	raiseCorner(map, x, y + 1);
}


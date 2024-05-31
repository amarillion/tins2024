/*
Module for isometric map initialization and manipulation.
Utility functions.
Does not depend on allegro.
*/
module isomap;

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

	int building = 0;


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


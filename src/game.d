module game;

import isometric;

// customized version of isometric.Cell
struct TCell
{
	int z = 0;
	short dzleft = 0;
	short dzright = 0;
	short dzbot = 0;
	
	int building = 0;
}

class Game {
	
	static Map!TCell initMap(int dim)
	{
		Map!TCell map = new Map!TCell(dim, dim);
	
		for (int x = 0; x < dim; ++x)
			for (int y = 0; y < dim; ++y)
		{
			map.get(x, y).z = 1;
			map.get(x, y).dzleft = 0;
			map.get(x, y).dzright = 0;
			map.get(x, y).dzbot = 0;
		}
		
		raiseTile(map, 5, 5);
		map.get(5, 5).building = 1;
		map.get(8, 3).building = 2;
		map.get(9, 9).building = 3;

		return map;
	}

		/** raise one corner in a map */
	static void raiseCorner(Map!TCell map, int x, int y)
	{
		map.get(x, y).z += 1;
		map.get(x, y).dzright -=1;
		map.get(x, y).dzbot -= 1;
		map.get(x, y).dzleft -= 1;
		
		map.get(x - 1, y).dzright += 1;
		map.get(x - 1, y - 1).dzbot += 1;
		map.get(x, y - 1).dzleft += 1;
	}

	/** raise one tile in a map */
	static void raiseTile(Map!TCell map, int x, int y)
	{
		raiseCorner(map, x, y);
		raiseCorner(map, x + 1, y);
		raiseCorner(map, x + 1, y + 1);
		raiseCorner(map, x, y + 1);
	}

}
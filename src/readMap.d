module readMap;

import std.json;
import std.conv;

import helix.util.vec;
import helix.util.coordrange;

import isomap;

struct TileDeltas {
	short dz = 0;
	short dzright = 0;
	short dzbot = 0;
	short dzleft = 0;
}

enum TileDeltas[] TILE_DELTAZ = [
	TileDeltas( 0, 0, 0, 0 ),

	TileDeltas( 0, 1, 0, 0 ),
	TileDeltas( 0, 0, 1, 0 ),
	TileDeltas( 0, 0, 0, 1 ),
	TileDeltas( 1, 0, 0, 0 ),

	TileDeltas( 1, 0, 0, 1 ),
	TileDeltas( 1, 1, 0, 0 ),
	TileDeltas( 0, 1, 1, 0 ),
	TileDeltas( 0, 0, 1, 1 ),

	TileDeltas( 0, 1, 0, -1 ),
	TileDeltas( -1, 0, 1, 0 ),
	TileDeltas( 0, -1, 0, 1 ),
	TileDeltas( 1, 0, -1, 0 ),

	TileDeltas( 1, 0, 1, 1 ),
	TileDeltas( 1, 1, 0, 1 ),
	TileDeltas( 1, 1, 1, 0 ),
	TileDeltas( 0, 1, 1, 1 ),

	TileDeltas( 1, 0, 1, 0 ),
	TileDeltas( 0, 1, 0, 1 ),
];

MyGrid readMapFromTiledJSON(JSONValue node) {
	int width = cast(int)node["width"].integer;
	int height = cast(int)node["height"].integer;

	MyGrid result = new MyGrid(width, height);

	int dl = 0;
	foreach (l; node["layers"].array) {
		if (l["type"].str == "tilelayer") { dl++; }
	}
	assert(dl > 0);

	foreach (l; node["layers"].array) {
		if (l["type"].str != "tilelayer") { continue; }
		if (l["name"].str != "Floor") { continue; }
		
		auto data = l["data"].array;
		foreach (p; PointRange(result.size)) {
			const val = to!int(data[result.toIndex(p)].integer - 1);
			result[p].terrain_tile = val;
		}
	}

	// now let's read the height map
	foreach (l; node["layers"].array) {
		if (l["type"].str != "tilelayer") { continue; }
		if (l["name"].str != "Heightmap") { continue; }
		
		auto data = l["data"].array;
		foreach (p; PointRange(result.size)) {
			
			const tileIdx = to!int(data[result.toIndex(p)].integer - 257); //TODO: hardcoded start value for second tileset
			const tileXX = tileIdx % 32;
			
			// derive height and slant from the tile number
			short dz = TILE_DELTAZ[tileXX].dz;
			result[p].z = ((511 - tileIdx) / 32) + dz;
			result[p].dzbot = to!short(TILE_DELTAZ[tileXX].dzbot - dz);
			result[p].dzleft = to!short(TILE_DELTAZ[tileXX].dzleft - dz);
			result[p].dzright = to!short(TILE_DELTAZ[tileXX].dzright - dz);

			import std.stdio;
		}
	}

	return result;
}
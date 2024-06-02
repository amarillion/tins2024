module readMap;

import std.json;
import std.conv;
import std.algorithm;

import helix.util.vec;
import helix.util.coordrange;

import map;

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


enum int[int] TILE_IDX_TO_BUILDING = [
	241: 9,
	242: 10,
	243: 11,
	244: 12,
	245: 13,
	246: 14,
	247: 15,
	248: 16,
	249: 17,
	250: 18,
	251: 19,
	252: 20,

	225: 9 + 512,
	226: 10 + 512,
	227: 11 + 512,
	228: 12 + 512,
	229: 13 + 512,
	230: 14 + 512,
	231: 15 + 512,
	232: 16 + 512,
	233: 17 + 512,
	234: 18 + 512,
	235: 19 + 512,
	236: 20 + 512,
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
			result[p].cell.z = ((511 - tileIdx) / 32) + dz;
			result[p].cell.dzbot = to!short(TILE_DELTAZ[tileXX].dzbot - dz);
			result[p].cell.dzleft = to!short(TILE_DELTAZ[tileXX].dzleft - dz);
			result[p].cell.dzright = to!short(TILE_DELTAZ[tileXX].dzright - dz);

			import std.stdio;
		}
	}

	// now let's read tracks
	foreach (l; node["layers"].array) {
		if (l["type"].str != "tilelayer") { continue; }
		string name = l["name"].str;
		import std.stdio;
		writeln(name, name.startsWith("Track"));
		if (!name.startsWith("Track")) { continue; }

		auto data = l["data"].array;
		foreach (p; PointRange(result.size)) {
			const tileIdx = to!int(data[result.toIndex(p)].integer - 1);
			if (tileIdx >= 0) {
				result[p].track_tile ~= tileIdx;
			}
		}
	}

	// let's read buildings
	foreach (l; node["layers"].array) {
		if (l["type"].str != "tilelayer") { continue; }
		if (l["name"].str != "Buildings") { continue; }
		
		auto data = l["data"].array;
		foreach (p; PointRange(result.size)) {
			const tileIdx = to!int(data[result.toIndex(p)].integer - 1);
			if (tileIdx >= 0) {
				if (tileIdx in TILE_IDX_TO_BUILDING) {
					result[p].building_tile = TILE_IDX_TO_BUILDING[tileIdx];
				}
			}
		}
	}
	return result;
}
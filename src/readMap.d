module readMap;

import std.json;
import std.conv;

import helix.util.vec;
import helix.util.coordrange;

import isomap;

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

	return result;
}
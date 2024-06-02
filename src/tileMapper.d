module tileMapper;

import helix.util.vec;
import helix.util.coordrange;

import map;
import model;

enum EdgeType[][int] TILE_INDEX_TO_EDGE = [
	// horizontal tracks
	48: [EdgeType(SubLoc.E, SubLoc.E, 1,  0), EdgeType(SubLoc.W, SubLoc.W, -1, 0)],
	49: [EdgeType(SubLoc.N, SubLoc.N, 0, -1), EdgeType(SubLoc.S, SubLoc.S,  0, 1)],
];

class TileMapper {
	static void mapTrackTiles(Model model) {
		foreach (p; PointRange(model.mapTT.size)) {
			foreach(tileIdx; model.mapTT[p].track_tile) {
				if (tileIdx in TILE_INDEX_TO_EDGE) {
					foreach(edgeType; TILE_INDEX_TO_EDGE[tileIdx]) {

						auto src = model.getOrCreateNode(p, edgeType.from);
						auto dest = model.getOrCreateNode(p + Point(edgeType.dx, edgeType.dy), edgeType.to);
						model.createEdge(src, dest, edgeType);
						// adding node and edges to map...
					}
				}
			}
		}
	}
}
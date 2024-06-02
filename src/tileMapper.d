module tileMapper;

import helix.util.vec;
import helix.util.coordrange;

import map;
import model;

enum Edge[][int] TILE_INDEX_TO_EDGE = [
	// horizontal tracks
	48: [Edge.E, Edge.W],
	49: [Edge.N, Edge.S],
];

class TileMapper {
	static void mapTrackTiles(Model model) {
		foreach (p; PointRange(model.mapTT.size)) {
			foreach(tileIdx; model.mapTT[p].track_tile) {
				if (tileIdx in TILE_INDEX_TO_EDGE) {
					foreach(edge; TILE_INDEX_TO_EDGE[tileIdx]) {
						auto eInfo = EDGE_INFO[edge];
						auto src = model.getOrCreateNode(p, eInfo.from);
						auto dest = model.getOrCreateNode(p + Point(eInfo.dx, eInfo.dy), eInfo.to);
						model.createEdge(src, dest, edge);
						// adding node and edges to map...
					}
				}
			}
		}
	}
}
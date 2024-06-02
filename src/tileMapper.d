module tileMapper;

import helix.util.vec;
import helix.util.coordrange;

import map;
import model;

enum Edge[][int] TILE_INDEX_TO_EDGE = [
	// horizontal tracks
	48: [Edge.E, Edge.W],
	49: [Edge.N, Edge.S],

	// tight turns
	16: [Edge.NE_small, Edge.WS_small],
	17: [Edge.ES_small, Edge.NW_small],
	33: [Edge.SW_small, Edge.EN_small],
	32: [Edge.WN_small, Edge.SE_small],

	// big turns
	52: [Edge.NE_big_start, Edge.WS_big_end], 37: [Edge.NE_big_end, Edge.WS_big_start],
	34: [Edge.ES_big_start, Edge.NW_big_end], 51: [Edge.ES_big_end, Edge.NW_big_start],
	 3: [Edge.SW_big_start, Edge.EN_big_end], 18: [Edge.SW_big_end, Edge.EN_big_start],
	21: [Edge.WN_big_start, Edge.SE_big_end],  4: [Edge.WN_big_end, Edge.SE_big_start],

	// diagonals
	67: [Edge.NW, Edge.SE],
	70: [Edge.NE, Edge.SW],
];

class TileMapper {
	static void mapTrackTiles(Model model) {
		foreach (p; PointRange(model.mapTT.size)) {
			foreach(tileIdx; model.mapTT[p].track_tile) {
				if (tileIdx in TILE_INDEX_TO_EDGE) {
					foreach(edge; TILE_INDEX_TO_EDGE[tileIdx]) {
						auto eInfo = EDGE_INFO[edge];
						auto src = Node(p, eInfo.from);
						auto dest = Node(p + Point(eInfo.dx, eInfo.dy), eInfo.to);
						model.createEdge(src, dest, edge);
						// adding node and edges to map...
					}
				}
			}
		}
	}
}
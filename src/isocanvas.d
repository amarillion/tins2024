module isocanvas;

import std.stdio;
import std.conv;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helix.mainloop;
import helix.component;
import helix.util.vec;
import helix.util.coordrange;
import helix.color;
import helix.allegro.bitmap;

import isogrid;
import map;
import model;

void drawMap(const GraphicsContext gc, IsoGrid iso, MyGrid map)
{
	for (int mx = 0; mx < map.size.x; ++mx)
		for (int my = 0; my < map.size.y; ++my)
		{
			auto c = map[Point(mx, my)];
			
			// enable for debugging:
			// iso.drawMapSurfaceWire(gc, mx, my, 0, 1, 1, Color.BLUE);
			
			iso.drawSurface(gc, mx, my, c.cell, c.terrain_tile);
			
			// draw tracks
			foreach(i; c.track_tile) {
				iso.drawSurface(gc, mx, my, c.cell, i);
			}
			
			iso.drawLeftWall(gc, mx, my, c.cell);
			iso.drawRightWall(gc, mx, my, c.cell);
		}
}

class IsoCanvas : Component
{
	override Point getPreferredSize() const { return Point (iso.getw(), iso.geth()); }

	int cursorx = 0;
	int cursory = 0;
	MyGrid map;
	Model model;
	IsoGrid iso;
	
	this(MainLoop window, Model _model)
	{
		super(window, "isocanvas");
		model = _model;
		map = model.mapTT;
		iso = new IsoGrid(map.size.x, map.size.y, 20, TILEX, TILEZ);
		initResources();
	}

	Bitmap[18] tracks;
	Bitmap[8] TL;
	Bitmap[9] buildings;
	Bitmap[16] wagon;
	Bitmap[16] locomotive;
	
	final void initResources() {
		iso.setTexture(window.resources.bitmaps["tileset"], 64, 64);

		// resources already inited at this point.

		//NB tracks 0-15 are obsolete
		tracks[16] = window.resources.bitmaps["station1"];
		tracks[17] = window.resources.bitmaps["station2"];

		TL[ 0] = window.resources.bitmaps["TL3G"];
		TL[ 1] = window.resources.bitmaps["TL3R"];
		TL[ 2] = window.resources.bitmaps["TL1G"];
		TL[ 3] = window.resources.bitmaps["TL1R"];
		TL[ 4] = window.resources.bitmaps["TL4G"];
		TL[ 5] = window.resources.bitmaps["TL4R"];
		TL[ 6] = window.resources.bitmaps["TL2G"];
		TL[ 7] = window.resources.bitmaps["TL2R"];

		Bitmap buildingSheet = window.resources.bitmaps["building"];
		int[] VALID_BUILDINGS = [0,12,14,22,13,15,21,7,8];
		for (int i = 0; i < VALID_BUILDINGS.length; ++i) {
			buildings[i] = buildingSheet.subBitmap(VALID_BUILDINGS[i] * 128, 0, 128, buildingSheet.h);
		}

		Bitmap wagonSheet = window.resources.bitmaps["wagon-iso"];
		Bitmap locomotiveSheet = window.resources.bitmaps["locomotive-iso"];
		for (int i = 0; i < wagon.length; ++i) {
			wagon[i] = wagonSheet.subBitmap(i * 64, 0, 64, 64);
			locomotive[i] = locomotiveSheet.subBitmap(i * 64, 0, 64, 64);
		}
	}

	void done() {
		foreach(i; wagon) i.destroy();
		foreach(i; locomotive) i.destroy();
	}

	void drawCursor (const GraphicsContext gc)
	{
		if (!map) return;
		if (cursorx >= 0 && cursory >= 0 &&
			cursorx < map.size.x && cursory < map.size.y) {
			iso.drawMapSurfaceWire(gc, cursorx, cursory, 0, 1, 1, Color.YELLOW);
		}
	}

	void drawTrains(const GraphicsContext gc) {
		float rx, ry;
		foreach (train; model.train) {
			bool first = true;
			foreach (w; train.wagons) {
				int rotation = to!int((w.angle + 45) * 16.0 / 360.0) % 16;
				Bitmap s = first ? locomotive[rotation] : wagon[rotation];
				iso.canvasFromIso_f(TILEX * w.lx, TILEY * w.ly, TILEZ * 0.0f, rx, ry);
				al_draw_bitmap (s.ptr,
					rx - gc.offset.x - s.w / 2,
					ry - gc.offset.y - s.h / 2,
					0);
				first = false;
			}
		}

	}

	override void draw (GraphicsContext gc)
	{
		if (!map) return;
		
		drawMap(gc, iso, map);
		drawCursor(gc);
		drawTrains(gc);
		
		foreach(p; PointRange(map.size)) {

			float rx, ry;
			Point bottom = p + 1; // add one because we want to match the bottom corner of the tile.
			iso.canvasFromIso_f(bottom.x * TILEX, bottom.y * TILEY, map[p].cell.z * TILEZ, rx, ry);
			rx -= gc.offset.x;
			ry -= gc.offset.y;

			int idx = map[p].building_tile;
			if (idx > 0)
			{
				int ww = buildings[idx].w;
				int hh = buildings[idx].h;
				al_draw_bitmap(buildings[idx].ptr, rx - (ww / 2), ry - hh, 0);
			}
		}
	}
	
	override void onMouseMove(Point p)
	{
		float rx;
		float ry;
		iso.isoFromCanvas(p.x, p.y, rx, ry);
		int ncursorx = cast(int)(rx / TILEX);
		int ncursory = cast(int)(ry / TILEY);
		
		if (ncursorx != cursorx || ncursory != cursory)
		{
			cursorx = ncursorx;
			cursory = ncursory;
		}
	}

	override void update() {
		model.update();
	}

}

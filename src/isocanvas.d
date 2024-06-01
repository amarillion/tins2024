module isocanvas;

import std.stdio;

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
import isomap;

const string[9] BUILDING_NAMES = [
	"casas1", "casas2", "casas3", "casas4",
	"casas5", "casas6", "church", "tree1", "tree2"
];

void drawMap(const GraphicsContext gc, IsoGrid iso, MyGrid map)
{
	for (int mx = 0; mx < map.size.x; ++mx)
		for (int my = 0; my < map.size.y; ++my)
		{
			auto c = map[Point(mx, my)];
			
			// enable for debugging:
			// iso.drawMapSurfaceWire(gc, mx, my, 0, 1, 1, Color.BLUE);
			
			iso.drawSurface(gc, mx, my, c); //TODO <-- not working?
			iso.drawLeftWall(gc, mx, my, c);
			iso.drawRightWall(gc, mx, my, c);
		}
}

class IsoCanvas : Component
{
	override Point getPreferredSize() const { return Point (iso.getw(), iso.geth()); }

	int cursorx = 0;
	int cursory = 0;
	MyGrid map;
	IsoGrid iso;
	
	this(MainLoop window, MyGrid _map)
	{
		super(window, "isocanvas");
		map = _map;
		iso = new IsoGrid(map.size.x, map.size.y, 20, TILEX, TILEZ);
		initResources();
	}

	Bitmap[18] tracks;
	Bitmap[8] TL;
	Bitmap[9] buildings;
	Bitmap[6] wagon;
	
	final void initResources() {
		iso.setTexture(window.resources.bitmaps["tileset"], 32, 32);

		// resources already inited at this point.
		// obtain arrays of tiles

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
		for (int i = 0; i < 9; ++i)
		{
			buildings[i] = buildingSheet.subBitmap(i * 128, 0, 128, buildingSheet.h);
		}

		wagon[0] = window.resources.bitmaps["trein1"];
		wagon[1] = window.resources.bitmaps["trein2"];
		wagon[2] = window.resources.bitmaps["trein3"];
		wagon[3] = window.resources.bitmaps["trein4"];
		wagon[4] = window.resources.bitmaps["trein5"];
		wagon[5] = window.resources.bitmaps["trein6"];

	}

	override void update() {}
	
	void drawCursor (const GraphicsContext gc)
	{
		if (!map) return;
		if (cursorx >= 0 && cursory >= 0 &&
			cursorx < map.size.x && cursory < map.size.y)
		{
			int rx, ry;
			iso.canvasFromMap(cursorx, cursory, &rx, &ry);
			int x = rx - gc.offset.x;
			int y = ry - gc.offset.y;

			al_draw_line (x, y,           x + 32, y + 15, Color.YELLOW, 1.0);
			al_draw_line (x + 32, y + 15, x, y + 31,      Color.YELLOW, 1.0);
			al_draw_line (x, y + 31,      x - 31, y + 15, Color.YELLOW, 1.0);
			al_draw_line (x - 32, y + 15, x, y,           Color.YELLOW, 1.0);
		}
	}

	override void draw (GraphicsContext gc)
	{
		if (!map) return;
		
		drawMap(gc, iso, map);
		drawCursor(gc);
		
		for (int ix = 0; ix < map.size.x; ++ix)
			for (int iy = 0; iy < map.size.y; ++iy)
			{
				// TODO: fill in z coord
				float rx, ry;
				iso.canvasFromIso_f(ix * TILEX, iy * TILEY, 1, rx, ry); // TODO: why 1?
				rx -= gc.offset.x;
				ry -= gc.offset.y;

				int idx = map[Point(ix, iy)].building_tile;
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

}

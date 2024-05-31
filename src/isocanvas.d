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

import isogrid;
import isomap;

void drawMap(const GraphicsContext gc, IsoGrid iso, MyGrid map)
{
	for (int mx = 0; mx < map.size.x; ++mx)
		for (int my = 0; my < map.size.y; ++my)
		{
			auto c = map[Point(mx, my)];
			iso.drawMapSurfaceWire(gc, mx, my, 0, 1, 1, Color.BLUE);
			iso.drawSurface(gc, mx, my, c); //TODO <-- not working?
			iso.drawLeftWall(gc, mx, my, c);
			iso.drawRightWall(gc, mx, my, c);
		}
}

class IsoCanvas : Component
{		
	int cursorx = 0;
	int cursory = 0;
	MyGrid map;
	IsoGrid iso;
	
	this(MainLoop window, MyGrid _map)
	{
		super(window, "isocanvas");
		map = _map;
		iso = new IsoGrid(map.size.x, map.size.y, 20, TILEX, TILEZ);

		iso.setTexture(window.resources.bitmaps["tileset"], 32, 32);
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
			int x = rx + gc.offset.x;
			int y = ry + gc.offset.y;

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
		
		ALLEGRO_BITMAP *[4] bmp;
		bmp[1] = window.resources.bitmaps["church"].ptr;
		bmp[2] = window.resources.bitmaps["casas1"].ptr;
		bmp[3] = window.resources.bitmaps["station1"].ptr;
		 
		for (int ix = 0; ix < map.size.x; ++ix)
			for (int iy = 0; iy < map.size.y; ++iy)
			{
				// TODO: fill in z coord
				float rx, ry;
				iso.canvasFromIso_f(ix * TILEX, iy * TILEY, 1, rx, ry); // TODO: why 1?
				
				int idx = map[Point(ix, iy)].building;
				if (idx > 0)
				{
					int ww = al_get_bitmap_width(bmp[idx]);
					int hh = al_get_bitmap_height(bmp[idx]);
					al_draw_bitmap(bmp[idx], rx - (ww / 2), ry - hh, 0);
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

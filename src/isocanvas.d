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

import isometric;

class IsoCanvas : Component
{		
	int cursorx = 0;
	int cursory = 0;
	MyGrid map;
	IsoCoords iso;
	
	this(MainLoop window, MyGrid _map)
	{
		super(window, "isocanvas");
		map = _map;
		iso = new IsoCoords(map.size.x, map.size.y);
	}
	
	override void update() {}
	
	override void draw (GraphicsContext gc)
	{
		if (!map) return;
		
		drawMap(iso, map);
		
		if (cursorx >= 0 && cursory >= 0)
		{
			// TODO: fill in z coord
			int rx, ry;
			isoToScreen(TILEX * cursorx, TILEY * cursory, 1, rx, ry);
			drawWirePlane(rx + iso.getXorig(), ry + iso.getYorig(), 
				TILEX, TILEY, ALLEGRO_COLOR(1.0, 1.0, 1.0, 0.5));
		}
		
		ALLEGRO_BITMAP *[4] bmp;
		bmp[1] = window.resources.bitmaps["church"].ptr;
		bmp[2] = window.resources.bitmaps["casas1"].ptr;
		bmp[3] = window.resources.bitmaps["station1"].ptr;
		 
		for (int ix = 0; ix < iso.getSizeX(); ++ix)
			for (int iy = 0; iy < iso.getSizeY(); ++iy)
			{
				// TODO: fill in z coord
				int rx, ry;
				isoToScreen(TILEX * ix, TILEY * iy, 1, rx, ry);
				
				rx += iso.getXorig();
				ry += iso.getYorig();
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
		screenToIso(p.x - iso.getXorig(), p.y - iso.getYorig(), rx, ry);
		int ncursorx = cast(int)(rx / TILEX);
		int ncursory = cast(int)(ry / TILEY);
		
		if (ncursorx != cursorx || ncursory != cursory)
		{
			cursorx = ncursorx;
			cursory = ncursory;
		}
	}

}

module isometric;

import allegro5.allegro;
import allegro5.allegro_primitives;

import std.math;
import std.stdio;
import std.conv;

import helix.util.grid;
import helix.util.vec;
import helix.util.coordrange;

const int TILEX = 32;
const int TILEY = 32;
const int TILEZ = 16;

/**
 * Draw a surface.
 *
 * z is the height, in tile units, of the top corner.
 *
 * dzleft, dzright and dzbot are the z-delta, in tile units, of the left,
 * right and bottom corners
 */
struct TCell
{
	int z = 0;
	short dzleft = 0;
	short dzright = 0;
	short dzbot = 0;

	int building = 0;
};

/** helper to calculate the z height at any corner of a Cell. */
int getZ(T)(T c, int dx, int dy)
{
	assert (dx == 0 || dx == 1);
	assert (dy == 0 || dy == 1);
	
	switch (dx + 2 * dy)
	{
		case 1: return c.z + c.dzright;
		case 2: return c.z + c.dzleft;
		case 3: return c.z + c.dzbot;
		default: return c.z;
	}
}

alias MyGrid = Grid!(2, TCell);

class IsoCoords
{
public:
	this(int sizex, int sizey)
	{
		this.sizex = sizex;
		this.sizey = sizey;
	}

	int getSizeX() { return sizex; }
	int getSizeY() { return sizey; }

	int getw() const { return sizex * 64; }
	int geth() const { return sizey * 32; }
	/** distance from the cell at 0,0 to the edge of the virtual screen */
	int getXorig () const { return getw() / 2 + 32; }

	/** distance from the cell at 0,0 to the edge of the virtual screen */
	int getYorig () const { return 64; }



	int canvasFromMapX (int mx, int my) const
	{
		return getXorig() + mx * 32 + my * -32;
	}

	int canvasFromMapY (int mx, int my) const
	{
		return getYorig() + mx * 16 + my * 16;
	}

	int canvasFromMapX (float mx, float my) const
	{
		return cast(int)(getXorig() + mx * 32.0 + my * -32.0);
	}

	int canvasFromMapY (float mx, float my) const
	{
		return cast(int)(getYorig() + mx * 16.0 + my * 16.0);
	}

	int mapFromCanvasX (int x, int y) const
	{
		return ((x - getXorig()) / 2 + (y - getYorig())) / 32;
	}

	int mapFromCanvasY (int x, int y) const
	{
		return  (y - getYorig() - (x - getXorig()) / 2) / 32;
	}

	void canvasFromIso_f (float x, float y, float z, ref float rx, ref float ry)
	{
		rx = getXorig() + (x - y);
		ry = getYorig() + (x * 0.5 + y * 0.5 - z);
	}

private:
	int sizex;
	int sizey;

	//TODO
	void drawSurface(int mx, int my, ref TCell c)
	{
		int[2][] deltas;
		ALLEGRO_COLOR color1;
		ALLEGRO_COLOR color2;
		
		if (c.dzright == c.dzleft)
		{
			deltas = [
				[0, 0], [1, 0], [0, 1], [1, 0], [1, 1], [0, 1]
			];
			//		color for first triangle
			color1 = litColor (0.7, 1.0, 0.7,
					surfaceLighting (1, 0, c.dzright, 0, 1, c.dzleft) );		
			//		color for second triangle
			color2 = litColor (0.7, 1.0, 0.7,
						surfaceLighting (0, -1, c.dzright - c.dzbot, -1, 0, c.dzleft - c.dzbot) );
		}
		else
		{
			deltas = [
				[0, 0], [1, 0], [1, 1], [0, 0], [1, 1], [0, 1]
			];
			//		color for first triangle
			color1 = litColor (0.7, 1.0, 0.7,
						surfaceLighting (0, 1, c.dzbot - c.dzright, -1, 0, -c.dzright) );
			//		color for second triangle
			color2 = litColor (0.7, 1.0, 0.7,
					surfaceLighting (0, -1, -c.dzleft, 1, 0, c.dzbot - c.dzleft) );		
		}
		
		// two triangles
		ALLEGRO_VERTEX[6] coord;
		
		for (int i = 0; i < 6; ++i)
		{
			int dx = deltas[i][0];
			int dy = deltas[i][1];
			
			canvasFromIso_f (	TILEX * (mx + dx),
				TILEY * (my + dy),
				TILEZ * c.getZ(dx, dy),
				coord[i].x, coord[i].y);
			
			//			coord[i].x -= gc.xofst;
			//			coord[i].y -= gc.yofst;
			coord[i].z = 0;
			coord[i].u = 0;
			coord[i].v = 0;
		}

		ALLEGRO_COLOR baseColor = ALLEGRO_COLOR (0.7, 1.0, 0.7, 1.0);

		for (int i = 0; i < 3; ++i)
		{
			coord[i].color = color1;
		}
		for (int i = 3; i < 6; ++i)
		{
			coord[i].color = color2;
		}

		// draw coordinates together.
		// TODO: add texture.
	    al_draw_prim(cast(const(void*))coord, null, null, 0, 6, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);

	}

	void drawLeftWall(/* GraphicsContext *gc, */ int mx, int my, ref TCell c)
	{
		int[4] x;
		int[4] y;
		int[4] z;

		x[0] = TILEX * (mx + 1);
		y[0] = TILEY * (my + 1);
		z[0] = 0;

		x[1] = TILEX * mx;
		y[1] = TILEY * (my + 1);
		z[1] = 0;
		
		x[2] = TILEX * (mx + 1);
		y[2] = TILEY * (my + 1);
		z[2] = TILEZ * (c.z + c.dzbot);

		x[3] = TILEX * mx;
		y[3] = TILEY * (my + 1);
		z[3] = TILEZ * (c.z + c.dzleft);

		ALLEGRO_COLOR color = litColor (0.75, 0.75, 0.75,
					surfaceLighting (0, 1, 0, 0, 0, 1 ));

		drawIsoPoly( /* gc, */ x, y, z, color);
	}

	void drawRightWall(/* GraphicsContext *gc, */ int mx, int my, ref TCell c)
	{
		int[4] x;
		int[4] y;
		int[4] z;

		x[0] = TILEX * (mx + 1);
		y[0] = TILEY * my;
		z[0] = 0;

		x[1] = TILEX * (mx + 1);
		y[1] = TILEY * (my + 1);
		z[1] = 0;

		x[2] = TILEX * (mx + 1);
		y[2] = TILEY * my;
		z[2] = TILEZ * (c.z + c.dzright);

		x[3] = TILEX * (mx + 1);
		y[3] = TILEY * (my + 1);
		z[3] = TILEZ * (c.z + c.dzbot);

		ALLEGRO_COLOR color = litColor (0.75, 0.75, 0.75,
					surfaceLighting (0, 0, 1, -1, 0, 0) );

		drawIsoPoly(/* gc, */ x, y, z, color);
	}

	/** draw two adjoined triangles to form a 4-sided shape */
	void drawIsoPoly (/* GraphicsContext *gc, */ int[4] x, int[4] y, int[4] z, ALLEGRO_COLOR color)
	{
		ALLEGRO_VERTEX[4] coord;

		for (int i = 0; i < 4; ++i)
		{
			canvasFromIso_f (x[i], y[i], z[i], coord[i].x, coord[i].y);
//			coord[i].x -= gc.xofst;
//			coord[i].y -= gc.yofst;
			coord[i].color = color;
			coord[i].z = 0;
			coord[i].u = 0;
			coord[i].v = 0;
		}
		
	    al_draw_prim(cast(const(void*))coord, null, null, 0, 4, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_STRIP);
	}

}


void drawMap(IsoCoords iso, MyGrid map) {

	foreach (p; PointRange(map.size)) {
		auto c = map[p];
		iso.drawSurface(p.x, p.y, c);
		iso.drawLeftWall(p.x, p.y, c);
		iso.drawRightWall(p.x, p.y, c);
	}
}

float LIGHTX = 0.2;
float LIGHTY = -0.8;
float LIGHTZ = -0.6;

/* re-implementation of old allegro 4 function */
void cross_product_f(in float x1, in float y1, in float z1, in float x2, in 
	float y2, in float z2, out float x3, out float y3, out float z3)
{
	x3 = y1 * z2 - z1 * y2;
	y3 = z1 * x2 - x1 * z2;
	z3 = x1 * y2 - y1 * x2;
}

unittest {
	float x, y, z;
	cross_product_f (1, 2, 3, 3, 4, 5, x, y, z);
	assert (x == -2);
	assert (y == 4);
	assert (z == -2);
}

/* re-implementation of old allegro 4 function */
float dot_product_f(in float x1, in float y1, in float z1, in float x2, in float y2, in float z2)
{
	return x1 * x2 + y1 * y2 + z1 * z2;
}

unittest {
	float result = dot_product_f (1, 2, 3, 3, 4, 5);
	assert (result == 26);
}

/**
 * The return value is between -1 and 1.
 */

float surfaceLighting(float x1, float y1, float z1, float x2, float y2, float z2)
{
	float[3] norm; // normal of the plane defined by the two vectors
	cross_product_f (x1, y1, z1, x2, y2, z2, norm[0], norm[1], norm[2]);
	return cos (dot_product_f (LIGHTX, LIGHTY, LIGHTZ, norm[0], norm[1], norm[2]));
}

ALLEGRO_COLOR litColor (float ri, float gi, float bi, float light)
{
	// cutoff below 0.2
	float light2 = light < 0.2 ? 0.2 : light;
	// scale between 0.5 and 1.0
	light2 = 0.5 + (light2 / 2);
	float r = ri * light2;
	float g = gi * light2;
	float b = bi * light2;
	return ALLEGRO_COLOR (r, g, b, 1);
}

unittest {
	ALLEGRO_COLOR col = litColor (1.0, 0.5, 0.0, 0.8);
	float r, g, b;
	al_unmap_rgb_f (col, &r, &g, &b);
	assert (abs (r - 0.9) < 0.01); 
	assert (abs (g - 0.45) < 0.01); 
	assert (abs (b) < 0.01); 
}

/**
	draw wire plane
	could be used for cursor.

	the wirePlane fills the surface from iso (0,0,0) to iso (sx, sy, 0),
	with iso (0, 0, 0) positioned at screen (rx, ry)
*/
void drawWirePlane (/* BITMAP *buffer, */ int rx, int ry, int sx, int sy, ALLEGRO_COLOR color)
{
	int[4] drx;
	int[4] dry;
	drx[0] = 0;
	dry[0] = 0;
	isoToScreen (sx, 0, 0, drx[1], dry[1]);
	isoToScreen (sx, sy, 0, drx[2], dry[2]);
	isoToScreen (0, sy, 0, drx[3], dry[3]);

	al_draw_line (rx + drx[0], ry + dry[0], rx + drx[1], ry + dry[1], color, 1);
	al_draw_line (rx + drx[1], ry + dry[1], rx + drx[2], ry + dry[2], color, 1);
	al_draw_line (rx + drx[2], ry + dry[2], rx + drx[3], ry + dry[3], color, 1);
	al_draw_line (rx + drx[3], ry + dry[3], rx + drx[0], ry + dry[0], color, 1);
}

/**
	draw wire model
	to help testing

	the wireFrame fills the cube from iso (0,0,0) to iso (sx, sy, sz),
	with iso (0, 0, 0) positioned at screen (rx, ry)
*/
void drawWireFrame (/* BITMAP *buffer, */ int rx, int ry, int sx, int sy, int sz, ALLEGRO_COLOR color)
{
	int[7] drx;
	int[7] dry;

	isoToScreen (0, 0, sz, drx[0], dry[0]);
	isoToScreen (sx, 0, sz, drx[1], dry[1]);
	isoToScreen (0, sy, sz, drx[2], dry[2]);
	isoToScreen (sx, sy, sz, drx[3], dry[3]);
	isoToScreen (sx, 0, 0, drx[4], dry[4]);
	isoToScreen (0, sy, 0, drx[5], dry[5]);
	isoToScreen (sx, sy, 0, drx[6], dry[6]);

	al_draw_line (rx + drx[0], ry + dry[0], rx + drx[1], ry + dry[1], color, 1);
	al_draw_line (rx + drx[0], ry + dry[0], rx + drx[2], ry + dry[2], color, 1);
	al_draw_line (rx + drx[3], ry + dry[3], rx + drx[1], ry + dry[1], color, 1);
	al_draw_line (rx + drx[3], ry + dry[3], rx + drx[2], ry + dry[2], color, 1);
	al_draw_line (rx + drx[3], ry + dry[3], rx + drx[6], ry + dry[6], color, 1);
	al_draw_line (rx + drx[1], ry + dry[1], rx + drx[4], ry + dry[4], color, 1);
	al_draw_line (rx + drx[2], ry + dry[2], rx + drx[5], ry + dry[5], color, 1);
	al_draw_line (rx + drx[5], ry + dry[5], rx + drx[6], ry + dry[6], color, 1);
	al_draw_line (rx + drx[4], ry + dry[4], rx + drx[6], ry + dry[6], color, 1);
}

void isoToScreen (float x, float y, float z, ref int rx, ref int ry)
{
	rx = cast(int)(x - y);
	ry = cast(int)(x * 0.5 + y * 0.5 - z);
}

void isoToScreen_f (float x, float y, float z, ref float rx, ref float ry)
{
	rx = (x - y);
	ry = (x * 0.5 + y * 0.5 - z);
}

int isoToScreenX (float x, float y, float z)
{
 	return cast(int)(x - y);
}

int isoToScreenY (float x, float y, float z)
{
	return cast(int)(x * 0.5 + y * 0.5 - z);
}

int isoToScreenZ (float x, float y, float z)
{
	return cast(int)(x + y + z);
}

// assume z == 0
void screenToIso (int rx, int ry, ref float x, ref float y)
{
	x = ry + rx / 2;
	y = ry - rx / 2;
}

static MyGrid initMap(int dim) {
	MyGrid map = new MyGrid(dim, dim);

	foreach(p; PointRange(map.size))
	{
		map[p].z = 0;
		map[p].dzleft = 0;
		map[p].dzright = 0;
		map[p].dzbot = 0;
	}
	
	// raiseTile(map, 5, 5);
	map[Point(5, 5)].building = 1;
	map[Point(8, 3)].building = 2;
	map[Point(9, 9)].building = 3;

	return map;
}

	/** raise one corner in a map */
void raiseCorner(MyGrid map, int x, int y) {
	map[Point(x, y)].z += 1;
	map[Point(x, y)].dzright -=1;
	map[Point(x, y)].dzbot -= 1;
	map[Point(x, y)].dzleft -= 1;
	
	map[Point(x - 1, y)].dzright += 1;
	map[Point(x - 1, y - 1)].dzbot += 1;
	map[Point(x, y - 1)].dzleft += 1;
}

/** raise one tile in a map */
void raiseTile(MyGrid map, int x, int y) {
	raiseCorner(map, x, y);
	raiseCorner(map, x + 1, y);
	raiseCorner(map, x + 1, y + 1);
	raiseCorner(map, x, y + 1);
}


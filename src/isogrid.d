/**
 * Responsible for isometric drawing primitives and coordinate conversion.
 * Refers to Tile. Does not depend on / refer to Map.
 */
module isogrid;

import allegro5.allegro;
import allegro5.allegro_primitives;

import std.math;
import std.stdio;
import std.conv;

import helix.util.grid;
import helix.util.vec;
import helix.util.coordrange;
import helix.allegro.bitmap;
import helix.color;
import helix.component : GraphicsContext;

const int TILEX = 32;
const int TILEY = 32;
const int TILEZ = 16;

import isomap : Tile;

const int DEFAULT_TILEX = 32;
const int DEFAULT_TILEY = 32;
const int DEFAULT_TILEZ = 16;

// default tile size in texture space
const int DEFAULT_TILEU = 16;
const int DEFAULT_TILEV = 16;

// default maximum height of a map. Affects origin and clipping rectangle
const int DEFAULT_DIM_MZ = 20;

/** Used only for drawing polygons atm */
struct Coord3D {
	float x;
	float y;
	float z;
};

/*
 * implements coordinate system for a isometric grid system
 *
 * does not implement draw method, does not contain map.
 * but has handy transformation methods and drawing primitives
 */
class IsoGrid
{
protected:
	int dim_mx;
	int dim_my;
	int dim_mz;

	int tilex;
	int tiley;
	int tilez;

	/* orthogonal transform used throughout */
	ALLEGRO_TRANSFORM t;

	int rx0; // location of origin
	int ry0;

	bool autoOrigin = true;
	bool use30deg = true;

	/*
	 *
	 * coordinate systems:
	 *
	 *    rx, ry     = screen 2D coordinates
	 *    ox, oy     = rx, ry shifted to origin
	 *    ix, iy, iz = isometric pixel coordinates
	 *    cx, cy, cz / mx, my, mz = isometric grid cell coordinates
	 *    px, py, pz = isometric pixel delta against grid
	 *
	 *
	 *    xs, ys, zs = x-size, y-size, z-size
	 *
	 */

	void calculateOrigin()
	{
		if (autoOrigin)
		{
			rx0 = getw() / 2;
			ry0 = dim_mz * tilez;
			t.m[3][0] = rx0;
			t.m[3][1] = ry0;
		}
	}

public:
	this(int sizex, int sizey, int sizez, int tilesizexy, int tilesizez) {
		dim_mx = sizex;
		dim_my = sizey;
		dim_mz = sizez;
		tilex = tilesizexy;
		tiley = tilesizexy;
		tilez = tilesizez;
		// initialize with default 30 degree orthogonal projection.
		set30Deg();
		calculateOrigin();
	}

	void setOrigin (int rx0Val, int ry0Val)
	{
		rx0 = rx0Val;
		ry0 = ry0Val;
		t.m[3][0] = rx0;
		t.m[3][1] = ry0;
		autoOrigin = false;
	}

	this() {
		dim_mx = 0;
		dim_my = 0;
		dim_mz = 0;
		tilex = DEFAULT_TILEX;
		tiley = DEFAULT_TILEY;
		tilez = DEFAULT_TILEZ;
		rx0 = 0;
		ry0 = 0;
		set30Deg();
	}

	int getSize_ix() const { return dim_mx * tilex; }
	int getSize_iy() const { return dim_my * tiley; }
	int getSize_iz() const { return dim_mz * tilez; }

//	void isoDrawWireFrame (int rx, int ry, int ixs, int iys, int izs, ALLEGRO_COLOR color)
//	{
//		drawWireFrame (rx + rx0, ry + ry0, ixs, iys, izs, color);
//	}

	/**
	 * Check that a given grid coordinate is within bounds
	 */
	bool cellInBounds(int cx, int cy, int cz) const
	{
		return
				cx >= 0 && cx < dim_mx &&
				cy >= 0 && cy < dim_my &&
				cz >= 0 && cz < dim_mz;
	}


	int getw() const { return (dim_mx + tilex + dim_my * tiley) * 2; }
	int geth() const { return (dim_mx * tilex + dim_my * tiley) / 2 + dim_mz * tilez; }


	/** distance from the cell at 0,0 to the edge of the virtual screen */
	int getXorig () const { return rx0; }

	/** distance from the cell at 0,0 to the edge of the virtual screen */
	int getYorig () const { return ry0; }

	void set30Deg() {
		use30deg = true;
		al_identity_transform(&t);

		// rx = rx0 + (x - y);
		t.m[0][0] = 1;
		t.m[1][0] = -1;
		t.m[2][0] = 0;
		t.m[3][0] = rx0;

		// ry = ry0 + (x * 0.5 + y * 0.5 - z);
		t.m[0][1] = 0.5;
		t.m[1][1] = 0.5;
		t.m[2][1] = -1;
		t.m[3][1] = ry0;

		// rz = (x + y + z);
		// TODO: not sure about accuracy here.
		t.m[0][2] = 1;
		t.m[1][2] = 1;
		t.m[2][2] = 1;
	}

	void set45Deg() {
		use30deg = false;
		al_identity_transform(&t);

		// rx = rx0 + (x - (0.5 * y));
		t.m[0][0] = 1;
		t.m[1][0] = -0.5;
		t.m[2][0] = 0;
		t.m[3][0] = rx0;

		// ry = ry0 + ((0.5 * y) - z);
		t.m[0][1] = 0;
		t.m[1][1] = 0.5;
		t.m[2][1] = -1;
		t.m[3][1] = ry0;

		// rz = (0.5 * y);
		t.m[0][2] = 0;
		t.m[1][2] = 0.5;
		t.m[2][2] = 0;
	}

	void setTransformationMatrix(ALLEGRO_TRANSFORM *val) {
		al_copy_transform(&t, val);
	}

	void canvasFromIso_f (float *x, float *y, float *z) const {
		al_transform_coordinates_3d(&t, x, y, z);
	}

	void canvasFromIso_f(float x, float y, float z, out float rx, out float ry) const
	{
		float xx = x, yy = y, zz = z;
		al_transform_coordinates_3d(&t, &xx, &yy, &zz);
		rx = xx;
		ry = yy;
	}

	// rz is useful for z-ordering sprites.
	void canvasFromIso_f (float x, float y, float z, out float rx, out float ry, out float rz) const
	{
		float xx = x, yy = y, zz = z;
		al_transform_coordinates_3d(&t, &xx, &yy, &zz);
		rx = xx;
		ry = yy;
		rz = zz;
	}

	int getTilex() const { return tilex; }
	int getTiley() const { return tiley; }
	int getTilez() const { return tilez; }

	void setDimension(int mxVal, int myVal, int mzVal)
	{
		dim_mx = mxVal;
		dim_my = myVal;
		dim_mz = mzVal;
		calculateOrigin();
	}

	void setTileSize(int x, int y, int z)
	{
		tilex = x;
		tiley = y;
		tilez = z;
		calculateOrigin();
	}

	/** get dimension of map in isometric pixel units */
	int getDimIX() const { return dim_my * tiley; }
	int getDimIY() const { return dim_mx * tilex; }

	void canvasFromMap(float mx, float my, int *rx, int *ry) const {
		float xx = mx * tilex, yy = my * tiley, zz = 0;
		al_transform_coordinates_3d(&t, &xx, &yy, &zz);
		*rx = to!int(xx);
		*ry = to!int(yy);
	}

	void canvasFromMap(float mx, float my, float *rx, float *ry) const {
		float xx = mx * tilex, yy = my * tiley, zz = 0;
		al_transform_coordinates_3d(&t, &xx, &yy, &zz);
		*rx = xx;
		*ry = yy;
	}

	// assuming iz = 0...
	// used by Dr. F.
	void isoFromCanvas(float rx, float ry, out float ix, out float iy) {
		isoFromCanvas(0.0f, to!int(rx), to!int(ry), ix, iy);
	}

	/**
	 * given a certain screen coordinate and a isometric z-level,
	 * calculate the isometric x, y
	 *
	 * Because a given point on the screen corresponds to many possible x,y,z points in isometric space,
	 * the caller has to choose the z coordinate (usually, in a loop trying possibilities until a good fit comes up)
	 */
	// used by Usagi
	void isoFromCanvas(float iz, int rx, int ry, out float ix, out float iy) {
		int ox = rx - rx0;
		int oy = ry - ry0;
		if (use30deg) {
			ix = oy + (ox / 2) + (iz / 2);
			iy = oy - (ox / 2) + (iz / 2);
		}
		else {
			//TODO: formula not yet 100% tested
			ix = iz + ox + oy;
			iy = 2 * (iz + oy);
		}
	}

	//TODO: currently only works for standard deg30 transform
	int mapFromCanvasX (int x, int y) const {
		return ((x - rx0) / 2 + (y - ry0)) / tilex;
	}

	//TODO: currently only works for standard deg30 transform
	int mapFromCanvasY (int x, int y) const
	{
		return  (y - ry0 - (x - rx0) / 2) / tiley;
	}

	void drawMapSurfaceWire (const GraphicsContext gc, int mx, int my, int mz, int mxs, int mys, ALLEGRO_COLOR color) const {
		Coord3D[] points = [
			Coord3D(tilex * mx, tiley * my, tilez * mz ),
			Coord3D(tilex * (mx + mxs), tiley * my, tilez * mz ),
			Coord3D(tilex * (mx + mxs), tiley * (my + mys), tilez * mz ),
			Coord3D(tilex * mx, tiley * (my + mys), tilez * mz)
		];
		drawIsoPoly(gc, points, color);
	}

	void drawMapRightWire (const GraphicsContext gc, int mx, int my, int mz, int mxs, int mzs, ALLEGRO_COLOR color) const {
		Coord3D[] points = [
			Coord3D(tilex * mx, tiley * my, tilez * mz ),
			Coord3D(tilex * (mx + mxs), tiley * my, tilez * mz ),
			Coord3D(tilex * (mx + mxs), tiley * my, tilez * (mz + mzs)),
			Coord3D(tilex * mx, tiley * my, tilez * (mz + mzs))
		];
		drawIsoPoly(gc, points, color);
	}

	void drawMapLeftWire (const GraphicsContext gc, int mx, int my, int mz, int mys, int mzs, ALLEGRO_COLOR color) const {
		Coord3D[] points = [
			Coord3D(tilex * mx, tiley * my, tilez * mz ),
			Coord3D(tilex * mx, tiley * (my + mys), tilez * mz ),
			Coord3D(tilex * mx, tiley * (my + mys), tilez * (mz + mzs) ),
			Coord3D(tilex * mx, tiley * my, tilez * (mz + mzs))
		];
		drawIsoPoly(gc, points, color);
	}

	/** using map units */
	void drawMapWireFrame (const GraphicsContext gc, int mx, int my, int mz, int msx, int msy, int msz, ALLEGRO_COLOR color) const
	{
		drawWireFrame (gc, mx * tilex, my * tiley, mz * tilez,
				msx * tilex, msy * tiley, msz * tilez, color);
	}

	/** using pixel units */
	void drawWireFrame (const GraphicsContext gc, int ix, int iy, int iz, int isx, int isy, int isz, ALLEGRO_COLOR color) const
	{
		float[7] drx;
		float[7] dry;

		int x2 = ix + isx;
		int y2 = iy + isy;
		int z2 = iz + isz;

		canvasFromIso_f(ix, iy, z2, drx[0], dry[0]);
		canvasFromIso_f(x2, iy, z2, drx[1], dry[1]);
		canvasFromIso_f(ix, y2, z2, drx[2], dry[2]);
		canvasFromIso_f(x2, y2, z2, drx[3], dry[3]);
		canvasFromIso_f(x2, iy, iz, drx[4], dry[4]);
		canvasFromIso_f(ix, y2, iz, drx[5], dry[5]);
		canvasFromIso_f(x2, y2, iz, drx[6], dry[6]);

		al_draw_line (gc.offset.x + drx[0], gc.offset.y + dry[0], gc.offset.x + drx[1], gc.offset.y + dry[1], color, 1.0);
		al_draw_line (gc.offset.x + drx[0], gc.offset.y + dry[0], gc.offset.x + drx[2], gc.offset.y + dry[2], color, 1.0);
		al_draw_line (gc.offset.x + drx[3], gc.offset.y + dry[3], gc.offset.x + drx[1], gc.offset.y + dry[1], color, 1.0);
		al_draw_line (gc.offset.x + drx[3], gc.offset.y + dry[3], gc.offset.x + drx[2], gc.offset.y + dry[2], color, 1.0);
		al_draw_line (gc.offset.x + drx[3], gc.offset.y + dry[3], gc.offset.x + drx[6], gc.offset.y + dry[6], color, 1.0);
		al_draw_line (gc.offset.x + drx[1], gc.offset.y + dry[1], gc.offset.x + drx[4], gc.offset.y + dry[4], color, 1.0);
		al_draw_line (gc.offset.x + drx[2], gc.offset.y + dry[2], gc.offset.x + drx[5], gc.offset.y + dry[5], color, 1.0);
		al_draw_line (gc.offset.x + drx[5], gc.offset.y + dry[5], gc.offset.x + drx[6], gc.offset.y + dry[6], color, 1.0);
		al_draw_line (gc.offset.x + drx[4], gc.offset.y + dry[4], gc.offset.x + drx[6], gc.offset.y + dry[6], color, 1.0);
	}

	/*
	 * draw a polygon consisting of num lines, between all consecutive points in coords, closing the path back to the beginning.
	 * The coordinates WILL BE CHANGED IN PLACE by this function
	 */
	void drawIsoPoly(const GraphicsContext gc, Coord3D[] coords, ALLEGRO_COLOR color) const {
		for (int i = 0; i < coords.length; ++i) {
			canvasFromIso_f(&coords[i].x, &coords[i].y, &coords[i].z);
		}

		int prev = to!int(coords.length) - 1;
		for (int i = 0; i < coords.length; ++i) {
			al_draw_line (
					gc.offset.x + coords[prev].x, gc.offset.y + coords[prev].y,
					gc.offset.x + coords[i].x,    gc.offset.y + coords[i].y,
					color, 1.0);
			prev = i;
		}
	}


	/*******************************************************
	* Textured drawing routines
	******************************************************/
private:
	// maximum height
	int sizez = 20;

	// dimensions of a texture tile
	int tileu = DEFAULT_TILEU;
	int tilev = DEFAULT_TILEV;

	// number of tiles in a row.
	int tilesPerRow = 1;
	Bitmap tiles = null;

public:

	Bitmap getTiles() { return tiles; }
	/**
	 * @param u: width of a tile in texture pixels
	 * @param v: height of a tile in texture pixels
	 */
	void setTexture(Bitmap _tiles, int u, int v)
	{
		tileu = u;
		tilev = v;
		tiles = _tiles;
		tilesPerRow = al_get_bitmap_width(tiles.ptr) / u;
	}


	void drawSurface(const GraphicsContext gc, int mx, int my, const Tile c) {
		ALLEGRO_VERTEX[6] coord; // hold memory for coordinates

		coord[] = ALLEGRO_VERTEX(0, 0, 0, 0, 0, Color.BLACK); // zero out
		
		// ALLEGRO_COLOR baseColor = al_map_rgb (192, 255, 192);
		ALLEGRO_COLOR baseColor = al_map_rgb (255, 255, 255);

		// TODO hard coded tile indices for use in krampushack for now
		// int tilei = (c.z + c.dzbot > 2 || c.z > 2 || c.z + c.dzright > 2 || c.z + c.dzleft > 2) ? 2 : 1;
		int tilei = 0; // TODO <-- this is a hack for now

		int ubase = tileu * tilei;
		int vbase = 0;

		canvasFromIso_f (tilex * mx,
						tiley * my,
						tilez * c.z,
						coord[0].x, coord[0].y);
		coord[0].u = ubase;
		coord[0].v = vbase;

		canvasFromIso_f (	tilex * (mx + 1),
						tiley * my,
						tilez * (c.z + c.dzright),
						coord[1].x, coord[1].y);
		coord[1].u = ubase + tileu;
		coord[1].v = vbase;

		canvasFromIso_f (	tilex * mx,
						tiley * (my + 1),
						tilez * (c.z + c.dzleft),
						coord[5].x, coord[5].y);
		coord[5].u = ubase;
		coord[5].v = vbase + tilev;

		canvasFromIso_f (	tilex * (mx + 1),
						tiley * (my + 1),
						tilez * (c.z + c.dzbot),
						coord[3].x, coord[3].y);

		coord[3].u = ubase + tileu;
		coord[3].v = vbase + tilev;

		ALLEGRO_COLOR color1, color2;

		/*
		*
		*
		*    y   A
		*   /   / \   x
		*  +   /   \   \
		*     C     B   +
		*      \   /
		*       \ /
		*        D
		*
		*
		*   Coordinate array
		*
		*   0 1 2   3 4 5
		*   A B -   D - C
		* - A B D   D A C   ->  vertical split
		* - A B C   D B C   ->  horizontal split
		*/
		if (c.isVerticalSplit())
		{
			coord[4] = coord[0];
			coord[2] = coord[3];

			/*
			*
			*
			*    y   A
			*   /   /|\   x
			*  +   / | \   \
			*     C  |  B   +
			*      \ | /
			*       \|/
			*        D
			*
			*/
			// lighting for A-B-D
			color1 = litColor(baseColor,
						surfaceLighting (-1, 0, -c.dzright, 0, 1, c.dzbot - c.dzright) );
			// lighting for A-D-C
			color2 = litColor(baseColor,
							surfaceLighting (0, -1, -c.dzleft, 1, 0, c.dzbot - c.dzleft) );
		}
		else
		{
			/*
			*
			*
			*    y   A
			*   /   / \   x
			*  +   /   \   \
			*     C-----B   +
			*      \   /
			*       \ /
			*        D
			*
			*/

			coord[4] = coord[1];
			coord[2] = coord[5];
			// lighting for A-B-C
			color1 = litColor (baseColor,
							surfaceLighting (1, 0, c.dzright, 0, 1, c.dzleft) );

			// lighting for C-B-D
			color2 = litColor (baseColor,
						surfaceLighting (0, -1, c.dzright - c.dzbot, -1, 0, c.dzleft - c.dzbot) );
		}

		for (int i = 0; i < 6; ++i)
		{
			coord[i].x += gc.offset.x;
			coord[i].y += gc.offset.y;
		}


		for (int i = 0; i < 3; ++i)
		{
			coord[i].color = color1;
		}


		for (int i = 3; i < 6; ++i)
		{
			coord[i].color = color2;
		}

		al_draw_prim(&coord[0], null, tiles.ptr, 0, 6, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);

		/*
		// debugging help for interpolation
		for (int xx = 0; xx < 8; xx ++)
		{
			for (int yy = 0; yy < 8; yy ++)
			{
				float jx = (mx * tilex) + (xx * tilex / 8);
				float jy = (my * tiley) + (yy * tiley / 8);
				float jz = getSurfaceIsoz(jx, jy);
				float rx, ry;
				canvasFromIso_f(jx, jy, jz, rx, ry);

				al_draw_filled_circle(rx + gc.xofst, ry + gc.yofst, 2.0, MAGENTA);
			}
		}
		*/

	}

	// get the iso z coordinate in pixels, at a given isometric x, y coordinate
	/*
	double getSurfaceIsoz(double ix, double iy) {
		// cell
		int mx = to!int(ix / getTilex());
		int remx = to!int(ix - (mx * getTilex()));

		int my = to!int(iy / getTiley());
		int remy = to!int(iy - (my * getTiley()));

		if (!map.inBounds(mx, my)) return -Infinity;

		auto c = map.get(mx, my);

		double result = 0;
		// interpolate

		if (c.isVerticalSplit())
		{
			// NOTE: this comparison assumes grid.getTilex() == grid.getTiley()
			if (remx < remy)
			{
				// left half
				result = c.z * grid.getTilez();
				result += remx * (- c.dzleft + c.dzbot) * grid.getTilez() / grid.getTilex();
				result += remy * c.dzleft * grid.getTilez() / grid.getTiley();
			}
			else
			{
				// right half
				result = c.z * grid.getTilez();
				result += remx * c.dzright * grid.getTilez() / grid.getTilex();
				result += remy * (- c.dzright + c.dzbot) * grid.getTilez() / grid.getTiley();
			}
		}
		else
		{
			// NOTE: this comparison assumes grid.getTilex() == grid.getTiley()
			if (remx + remy < grid.getTilex())
			{
				// top half
				result = c.z * grid.getTilez();
				result += remx * c.dzright * grid.getTilez() / grid.getTilex();
				result += remy * c.dzleft * grid.getTilez() / grid.getTiley();
			}
			else
			{
				// bottom half
				result = (c.z + c.dzbot) * grid.getTilez();
				result += (grid.getTilex() - remx) * (- c.dzbot + c.dzleft) * grid.getTilez() / grid.getTilex();
				result += (grid.getTiley() - remy) * (- c.dzbot + c.dzright) * grid.getTilez() / grid.getTiley();
			}
		}

		return result;
	}
	*/

	void drawSurfaceTile(const GraphicsContext gc, int mx, int my, const Tile c, int tilei, ALLEGRO_VERTEX *coord) {
		// ALLEGRO_COLOR baseColor = al_map_rgb (192, 255, 192);
		ALLEGRO_COLOR baseColor = al_map_rgb (255, 255, 255);

		int ubase = tileu * (tilei % tilesPerRow);
		int vbase = tilev * (tilei / tilesPerRow);

		canvasFromIso_f (tilex * mx,
						tiley * my,
						tilez * c.z,
						coord[0].x, coord[0].y);
		coord[0].u = ubase;
		coord[0].v = vbase;

		canvasFromIso_f (	tilex * (mx + 1),
						tiley * my,
						tilez * (c.z + c.dzright),
						coord[1].x, coord[1].y);
		coord[1].u = ubase + tileu;
		coord[1].v = vbase;

		canvasFromIso_f (	tilex * mx,
						tiley * (my + 1),
						tilez * (c.z + c.dzleft),
						coord[5].x, coord[5].y);
		coord[5].u = ubase;
		coord[5].v = vbase + tilev;

		canvasFromIso_f (	tilex * (mx + 1),
						tiley * (my + 1),
						tilez * (c.z + c.dzbot),
						coord[3].x, coord[3].y);

		coord[3].u = ubase + tileu;
		coord[3].v = vbase + tilev;

		ALLEGRO_COLOR color1, color2;

		/*
		*
		*
		*    y   A
		*   /   / \   x
		*  +   /   \   \
		*     C     B   +
		*      \   /
		*       \ /
		*        D
		*
		*
		*   Coordinate array
		*
		*   0 1 2   3 4 5
		*   A B -   D - C
		* - A B D   D A C   ->  vertical split
		* - A B C   D B C   ->  horizontal split
		*/
		if (c.isVerticalSplit())
		{
			coord[4] = coord[0];
			coord[2] = coord[3];

			/*
			*
			*
			*    y   A
			*   /   /|\   x
			*  +   / | \   \
			*     C  |  B   +
			*      \ | /
			*       \|/
			*        D
			*
			*/
			// lighting for A-B-D
			color1 = litColor (baseColor,
						surfaceLighting (-1, 0, -c.dzright, 0, 1, c.dzbot - c.dzright) );
			// lighting for A-D-C
			color2 = litColor (baseColor,
							surfaceLighting (0, -1, -c.dzleft, 1, 0, c.dzbot - c.dzleft) );
		}
		else
		{
			/*
			*
			*
			*    y   A
			*   /   / \   x
			*  +   /   \   \
			*     C-----B   +
			*      \   /
			*       \ /
			*        D
			*
			*/

			coord[4] = coord[1];
			coord[2] = coord[5];
			// lighting for A-B-C
			color1 = litColor (baseColor,
							surfaceLighting (1, 0, c.dzright, 0, 1, c.dzleft) );

			// lighting for C-B-D
			color2 = litColor (baseColor,
						surfaceLighting (0, -1, c.dzright - c.dzbot, -1, 0, c.dzleft - c.dzbot) );
		}

		for (int i = 0; i < 6; ++i)
		{
			coord[i].x += gc.offset.x;
			coord[i].y += gc.offset.y;
		}


		for (int i = 0; i < 3; ++i)
		{
			coord[i].color = color1;
		}


		for (int i = 3; i < 6; ++i)
		{
			coord[i].color = color2;
		}

		/*
		// debugging help for interpolation
		for (int xx = 0; xx < 8; xx ++)
		{
			for (int yy = 0; yy < 8; yy ++)
			{
				float jx = (mx * tilex) + (xx * tilex / 8);
				float jy = (my * tiley) + (yy * tiley / 8);
				float jz = getSurfaceIsoz(jx, jy);
				float rx, ry;
				canvasFromIso_f(jx, jy, jz, rx, ry);

				al_draw_filled_circle(rx + gc.xofst, ry + gc.yofst, 2.0, MAGENTA);
			}
		}
		*/
	}

	void drawLeftWall(const GraphicsContext gc, int mx, int my, const Tile c) {
		int[4] x;
		int[4] y;
		int[4] z;

		x[0] = tilex * (mx + 1);
		y[0] = tiley * (my + 1);
		z[0] = 0;

		x[1] = tilex * mx;
		y[1] = tiley * (my + 1);
		z[1] = 0;

		x[2] = tilex * mx;
		y[2] = tiley * (my + 1);
		z[2] = tilez * (c.z + c.dzleft);

		x[3] = tilex * (mx + 1);
		y[3] = tiley * (my + 1);
		z[3] = tilez * (c.z + c.dzbot);

		ALLEGRO_COLOR color = litColor (al_map_rgb (192, 192, 192),
					surfaceLighting (0, 1, 0, 0, 0, 1 ));

		drawIsoPoly(gc, 4, x, y, z, color);
	}

	void drawRightWall(const GraphicsContext gc, int mx, int my, const Tile c) {
		int[4] x;
		int[4] y;
		int[4] z;

		x[0] = tilex * (mx + 1);
		y[0] = tiley * my;
		z[0] = 0;

		x[1] = tilex * (mx + 1);
		y[1] = tiley * (my + 1);
		z[1] = 0;

		x[2] = tilex * (mx + 1);
		y[2] = tiley * (my + 1);
		z[2] = tilez * (c.z + c.dzbot);

		x[3] = tilex * (mx + 1);
		y[3] = tiley * my;
		z[3] = tilez * (c.z + c.dzright);

		ALLEGRO_COLOR color = litColor (al_map_rgb (192, 192, 192),
					surfaceLighting (0, 0, 1, -1, 0, 0) );

		drawIsoPoly(gc, 4, x, y, z, color);
	}

	void drawIsoPoly (const GraphicsContext gc, int num, int[] x, int[] y, int[] z, ALLEGRO_COLOR color)
	{
		const int BUF_SIZE = 20; // max 20 points
		assert (num <= BUF_SIZE);

		ALLEGRO_VERTEX[BUF_SIZE] coord; // hold actual objects
		ALLEGRO_VERTEX*[BUF_SIZE] pcoord; // hold array of pointers

		// initialize pointers to point to objects
		for (int i = 0; i < BUF_SIZE; ++i) { pcoord[i] = &coord[i]; }

		for (int i = 0; i < num; ++i)
		{
			canvasFromIso_f (x[i], y[i], z[i], coord[i].x, coord[i].y);
			coord[i].x += gc.offset.x;
			coord[i].y += gc.offset.y;
			coord[i].color = color;
		}

		// al_set_target_bitmap (gc.buffer); // TODO???
		al_draw_prim(&coord[0], null, null, 0, num, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_FAN);
	}

}

ALLEGRO_COLOR litColor (ALLEGRO_COLOR color, float light)
{
	float light2 = light < 0.2 ? 0.2 : light;
	light2 = 0.5 + (light2 / 2);

	ubyte rr, gg, bb;
	al_unmap_rgb(color, &rr, &gg, &bb);

	float r = light2 * rr;
	float g = light2 * gg;
	float b = light2 * bb;
	return al_map_rgb(to!ubyte(r), to!ubyte(g), to!ubyte(b));
}


// copied from allegro4
float dot_product_f (float x1, float y_1, float z1, float x2, float y2, float z2)
{
   return (x1 * x2) + (y_1 * y2) + (z1 * z2);
}

/* cross_productf:
 *  Floating point version of cross_product().
 */
// copied from allegro4
void cross_product_f(float x1, float y1, float z1, float x2, float y2, float z2, float *xout, float *yout, float *zout)
{
   assert(xout);
   assert(yout);
   assert(zout);

   *xout = (y1 * z2) - (z1 * y2);
   *yout = (z1 * x2) - (x1 * z2);
   *zout = (x1 * y2) - (y1 * x2);
}

float LIGHTX = 0.2;
float LIGHTY = -0.8;
float LIGHTZ = -0.6;

/**
 * The return value is between -1 and 1.
 */
float surfaceLighting(float x1, float y1, float z1, float x2, float y2, float z2)
{
	float[3] norm; // normal of the plane defined by the two vectors
	cross_product_f (x1, y1, z1, x2, y2, z2, &norm[0], &norm[1], &norm[2]);
	return cos (dot_product_f (LIGHTX, LIGHTY, LIGHTZ, norm[0], norm[1], norm[2]));
}

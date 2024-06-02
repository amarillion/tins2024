#!/usr/bin/env -S rdmd -I../dtwist/src -I~/prg/alleg/DAllegro5/ -L-L/home/martijn/prg/alleg/DAllegro5

import std.string;

import allegro5.allegro;
import allegro5.allegro_image;

import helix.allegro.bitmap;

import std.math.constants : PI;

Bitmap readSpriteSheet(string filename) {
	auto file = Bitmap.load(filename);
	assert(file !is null, "Could not load file: " ~ filename);
	return file;
}

Bitmap convertStack(Bitmap images, int num) {
	int tileHeight = images.h;
	int tileWidth = tileHeight; // assuming square tiles
	int tileNum = images.w / images.h;

	// create a new bitmap with extra margin
	Bitmap result = Bitmap.create(tileWidth * 4 * num, tileHeight * 4);
	al_set_target_bitmap(result.ptr);
	al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));

	Bitmap temp = Bitmap.create(tileWidth * 4, tileHeight * 4);

	float angle = 0.0f;
	foreach(a; 0..num) {	
		Bitmap dest = result.subBitmap(tileWidth * 4 * a, 0, tileWidth * 4, tileHeight * 4);

		foreach(i; 0..tileNum) {
			Bitmap tile = images.subBitmap(i * tileWidth, 0, tileWidth, tileHeight);
			al_set_target_bitmap(temp.ptr);
			al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));

			// rotate and make scale double size
			al_draw_scaled_rotated_bitmap(tile.ptr, 
				tileWidth / 2, tileHeight / 2, 
				tileWidth * 2, tileHeight * 2, 
				2.0f, 2.0f,
				angle * PI / 180.0, 0);
			
			// now scale by 50% vertically with offset:
			al_set_target_bitmap(dest.ptr);
			al_draw_scaled_bitmap(temp.ptr, 
				0, 0, 
				tileWidth * 4, tileHeight * 4, 
				0, (tileNum - i) * 2, 
				tileWidth * 4, tileHeight * 2, 
				0);
			al_draw_scaled_bitmap(temp.ptr, 
				0, 0, 
				tileWidth * 4, tileHeight * 4, 
				0, (tileNum - i) * 2 - 1, 
				tileWidth * 4, tileHeight * 2, 
				0);

			tile.destroy();
		}
		angle += (360.0f / num);

		dest.destroy();
	}
	temp.destroy();
	return result;
}

int main(string[] args) {
	assert(args.length == 3, "Usage: ./isoConverter.d <infile> <outfile>");
	string infile = args[1];
	string outfile = args[2];

	al_run_allegro(
	{
		al_init();
		al_init_image_addon();

		Bitmap spriteSheet = readSpriteSheet(infile);

		Bitmap result = convertStack(spriteSheet, 16);
		al_save_bitmap(toStringz(outfile), result.ptr);
		return 0;
	});
	return 0;
}
#!/usr/bin/env -S rdmd -Idtwist/src -I~/prg/alleg/DAllegro5/ -L-L/home/martijn/prg/alleg/DAllegro5

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
	Bitmap result = Bitmap.create(tileWidth * 2 * num, tileHeight * 2);
	al_set_target_bitmap(result.ptr);
	al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));

	Bitmap temp = Bitmap.create(tileWidth * 2, tileHeight * 2);

	float angle = 0.0f;
	foreach(a; 0..num) {	
		Bitmap dest = result.subBitmap(tileWidth * 2 * a, 0, tileWidth * 2, tileHeight * 2);

		foreach(i; 0..tileNum) {
			Bitmap tile = images.subBitmap(i * tileWidth, 0, tileWidth, tileHeight);
			al_set_target_bitmap(temp.ptr);
			al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));
			al_draw_rotated_bitmap(tile.ptr, tileWidth / 2, tileHeight / 2, tileWidth, tileHeight, angle * PI / 180.0, 0);
			
			// now scale by 50% vertically with offset:
			al_set_target_bitmap(dest.ptr);
			al_draw_scaled_bitmap(temp.ptr, 
				0, 0, 
				tileWidth * 2, tileHeight * 2, 
				0, tileNum - i, 
				tileWidth * 2, tileHeight, 
				0);

			// Doesn't give the right effect...
			// al_draw_scaled_rotated_bitmap(tile.ptr, 
			// 	tileWidth / 2, tileHeight / 2, 
			// 	tileWidth, tileHeight - i, 
			// 	1.0f, 0.5f, 
			// 	angle * PI / 180.0, 0);

			tile.destroy();
		}
		angle += (360.0f / num);

		dest.destroy();
	}
	temp.destroy();
	return result;
}

int main(string[] args) {
	assert(args.length == 2, "Usage: ./isoConverter.d <infile>");
	string infile = args[1];

	al_run_allegro(
	{
		al_init();
		al_init_image_addon();

		Bitmap spriteSheet = readSpriteSheet(infile);

		Bitmap result = convertStack(spriteSheet, 16);
		al_save_bitmap("output.png", result.ptr);
		return 0;
	});
	return 0;
}
module generateMap;

import helix.util.vec;
import std.random;
import map;
import model;

void generate(MyGrid mapTT, Model model) {
	// add trees
	int num_trees = mapTT.size.x * mapTT.size.y / 10;
	for (int i = 0; i < num_trees; ++i) {
		Point p = Point(uniform(0, mapTT.size.x), uniform(0, mapTT.size.y));
		if (mapTT[p].track_tile.length > 0 || mapTT[p].building_tile > 0 || mapTT[p].terrain_tile > 0) {
			continue;
		}
		mapTT[p].building_tile = uniform(7, 9);
	}
	return;
	/*
	//~ // add cities
	int radius = 10;
	string[] cityNames = [
		"Amsterdam", "Rotterdam", "Den Haag", "Maastricht",
		"Wageningen", "Groningen", "Utrecht", "Delft",
		"Leeuwarden", "Arnhem", "Nijmegen",
		"Eindhoven", "Tilburg", "Zwolle", "Bergen op Zoom",
		"Breda", "Enschede", "Almelo", "Venlo",
		"Leiden", "Zaandam", "Alkmaar", "Dordrecht",
		"Assen", "Hengelo", "Sittard", "Vlissingen",
		"Middelburg", "Roermond", "Gouda", "Almere",
		"Lelystad", "Kampen", "Deventer", "Woerden",
		"Zwijndrecht", "Schiedam", "Zoetermeer",
		"Weert", "Heerlen", "Helmond", "Oss", "Uden",
		"Goes", "Hoogeveen", "Sneek", "Delfzijl",
		"Rozendaal"
	];

	string[] suffixes = [
		"berg", "drecht", "veen", "daal",
		"zijl", "dam", "dijk", "huizen", "wijk",
		"burg", "stad", "mond", "meer", "hoven",
		"dorp", "hof", "waard", "wetering",
		"wege", "brugge", "sloot", "hout",
		"koop", "woude", "kapelle", "heem", "luiden",
		"heuvel", "beek", "schoten", "broek", "driel",
		"veer", "doorn", "vaart", "horn", "kamp", "borg",
		"voort", "loon", "zaal", "velde", "terp", "woude", "kerk",
		"sluis", "kantje"

		// "lo",
	];
	string[] prefixes = [
		"Roer", "Rotter", "Schie", "Zaan", "IJssel",
		"Zoeter", "Zwijn", "Lutje", "Hooge", "Dommel",
		"Rozen", "Bloemen", "Leeuwen", "Middel",
		"Maas", "Rijn", "Willems", "Dorre",
		"Zwanen", "Rijp", "Roelofarends", "Ooster", "Wester",
		"Zuider", "Noorder", "Moer", "Voor", "Rijs", "Schip",
		"Kaats", "Prinsen", "Oude", "Zeven", "Vijf", "Acht", "Nieuwe",
		"Lage", "Keizers", "Waal", "Barne", "Apel",
		"Dedems", "Heeren", "Heerhugo", "Zand", "Naald", "Over",
		"Winter", "Olden", "Hellen", "Buiten", "Harder",
		"Bakke", "Gorre", "Klaziena", "Groes", "Valken",
		"Uden", "Amster", "Zalt", "Bemmel", "Wormer", "Purmer",
		"Beemster", "Schering",
	];
	
	// randomShuffle(cityNames);
	randomShuffle(prefixes);
	randomShuffle(suffixes);

	for (int i = 0; i < 8; ++i)
	{
		int x;
		int y;
		bool valid = false;
		while (!valid)
		{
			x = uniform(10, mapTT.size.x - 10);
			y = uniform(10, mapTT.size.y - 10);

			valid = true;
			foreach(j; model.city) {
				int dx = j.center_x - x;
				int dy = j.center_y - y;
				dx *= dx;
				dy *= dy;
				if (dx + dy < radius * radius)
				{
					valid = false;
					break;
				}
			}
		}

		int idCity = model.addCity(x, y, prefixes[i] ~ suffixes[i]);
		model.city[idCity].population = uniform(50_000, 100_000);
		int p = model.city[idCity].population;
		while (p > 0)
		{
			int nx = x + uniform(0, 5) + uniform(0, 3) + uniform(0, 3) - 4;
			int ny = y + uniform(0, 5) + uniform(0, 3) + uniform(0, 3) - 4;

			if (nx < 0) nx = 0;
			if (nx >= mapTT.size.x) nx = mapTT.size.x -1;
			if (ny < 0) ny = 0;
			if (ny >= mapTT.size.y) ny = mapTT.size.y - 1;

			mapTT[Point(nx, ny)].building_tile = uniform(1, 7);
			p -= 3000;

		}
		mapTT[Point(x, y)].building_tile = 0; // church in the center
	}
	*/
}

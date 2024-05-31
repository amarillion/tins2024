module mainState;

import std.json;
import std.conv;

import allegro5.shader;

import helix.resources;
import helix.mainloop;
import helix.richtext;
import helix.component;

import dialog;
import dialogBuilder;
import isometric;
import isocanvas;
import game;

class MainState : DialogBuilder {

	class MapScreen : Component
	{		
		override void update() {}
		
		this(MainLoop window, Map!TCell map)
		{
			super(window, "mapscreen");
			// add (new ClearScreen(window, ALLEGRO_COLOR(0.25, 1, 0.25, 1)));
			add (new IsoCanvas(window, map));
		}		
	}

	ResourceManager userResources;

	this(MainLoop window) {
		super(window);

		userResources = new ResourceManager();

		window.onClose.add(() { destroy(userResources); });
		
		window.onDisplaySwitch.add((switchIn) { 
			if (switchIn) { userResources.refreshAll(); }
		});

		/* MENU */
		buildDialog(window.resources.jsons["title-layout"]);
		
		auto map = Game.initMap(10);

		auto canvas = getElementById("canvas");
		canvas.addChild(new MapScreen(window, map));

		getElementById("btn_credits").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("TINS 2024 game")
				.text("This was made by ").b("Amarillion, Max and AniCator")
				.text(" during the TINS 2024 Game Jam!").p();
			openDialog(window, builder.build());
		});
	}

}
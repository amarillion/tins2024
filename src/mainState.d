module mainState;

import std.json;
import std.conv;

import allegro5.shader;

import helix.resources;
import helix.mainloop;
import helix.richtext;

import dialog;
import dialogBuilder;

class MainState : DialogBuilder {

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
		
		// auto canvas = getElementById("canvas");
		
		getElementById("btn_credits").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("TINS 2024 game")
				.text("This was made by ").b("Amarillion, Max and AniCator")
				.text(" during the TINS 2024 Game Jam!").p();
			openDialog(window, builder.build());
		});
	}

}

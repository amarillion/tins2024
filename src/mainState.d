module mainState;

import std.json;
import std.conv;

import allegro5.shader;

import helix.resources;
import helix.mainloop;
import helix.richtext;
import helix.component;
import helix.scroll;
import helix.layout;

import dialog;
import dialogBuilder;
import isocanvas;
import map;
import model;

class MainState : DialogBuilder {

	ResourceManager userResources;
	Model model = new Model();
	IsoCanvas isoCanvas;

	this(MainLoop window) {
		super(window);

		userResources = new ResourceManager();

		window.onClose.add(() { 
			isoCanvas.done();
			destroy(userResources); 
		});
		
		window.onDisplaySwitch.add((switchIn) { 
			if (switchIn) { userResources.refreshAll(); }
		});

		/* MENU */
		buildDialog(window.resources.jsons["title-layout"]);
		
		auto mapData = window.resources.jsons["themap"];
		model.initGame(mapData);

		auto canvas = getElementById("canvas");

		isoCanvas = new IsoCanvas(window, model);
		
		// auto vp = new ViewPort(window);
		// vp.setRelative(0,0,16,16,0,0,LayoutRule.STRETCH,LayoutRule.STRETCH);
		// vp.setScrollable(isoCanvas);
		// vp.setOffsetX(-isoCanvas.iso.getw() / 2);
		// vp.setOffsetY(-isoCanvas.iso.geth() / 2);
		// canvas.addChild(vp);

		auto sp = new ScrollPane(window, isoCanvas);
		//TODO: get layout from dialog json
		sp.setRelative(0,0,176,0,0,0,LayoutRule.STRETCH,LayoutRule.STRETCH);
		canvas.addChild(sp);

		getElementById("btn_credits").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("TINS 2024 game")
				.text("This was made by ").b("Amarillion, Max and AniCator")
				.text(" during the TINS 2024 Game Jam!").p();
			openDialog(window, builder.build());
		});
	}

}

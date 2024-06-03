module mainState;

import std.json;
import std.conv;
import std.format;

import allegro5.shader;

import helix.resources;
import helix.mainloop;
import helix.richtext;
import helix.component;
import helix.scroll;
import helix.layout;
import helix.util.vec;

import dialog;
import dialogBuilder;
import isocanvas;
import map;
import model;

class MainState : DialogBuilder {

	ResourceManager userResources;
	Model model = new Model();
	IsoCanvas isoCanvas;
	ScrollPane sp;
	Component canvas;

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

		canvas = getElementById("canvas");

		isoCanvas = new IsoCanvas(window, model);
		
		sp = new ScrollPane(window, isoCanvas);
		//TODO: get layout from dialog json
		sp.setRelative(0,0,176,0,0,0,LayoutRule.STRETCH,LayoutRule.STRETCH);
		canvas.addChild(sp);

		sp.scrollTo(Point(isoCanvas.iso.getw() / 2, isoCanvas.iso.geth() / 2));

		getElementById("btn_credits").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("TINS 2024 game")
				.text("This was made by ").b("Amarillion, Max and AniCator")
				.text(" during the TINS 2024 Game Jam!").p();
			openDialog(window, builder.build());
		});

		isoCanvas.selectedTrain.onChange.add((e) {
			getElementById("lbl_train_id").text = format("Selected train: %s", e.newValue + 1);
			sp.scrollTo(isoCanvas.getSelectedTrainPosition() - (canvas.shape.size / 2));
		});

		getElementById("btn_add_train").onAction.add((e) {
			isoCanvas.addTrain();
		});

		getElementById("btn_next").onAction.add((e) {
			isoCanvas.nextTrain();
		});

		getElementById("btn_locate").onAction.add((e) {
			moveCameraToSelectedTrain();
		});

		getElementById("btn_stop").onAction.add((e) {
			isoCanvas.stopTrain();
		});

		getElementById("btn_accelerate").onAction.add((e) {
			isoCanvas.accelerateTrain();
		});

		getElementById("btn_follow").onAction.add((e) {
			followMode = !followMode;
		});

		getElementById("btn_config").onAction.add((e) {
			// TODO
		});

	}

	void moveCameraToSelectedTrain() {
		sp.scrollTo(isoCanvas.getSelectedTrainPosition() - (canvas.shape.size / 2));
	}

	bool followMode = true;
	
	override void update() {
		super.update();
		if (followMode && isoCanvas.selectedTrain >= 0) {
			moveCameraToSelectedTrain();
		}
	}

}

module app;

import std.stdio;
import std.conv;

import allegro5.allegro;
import allegro5.allegro_audio;

import helix.mainloop;
import helix.richtext;

import dialog;
import mainState;

void main(string[] args)
{
	al_run_allegro(
	{
		al_init();
		auto mainloop = new MainLoop(MainConfig.of
			.appName("tins24")
			.targetFps(60)
		);
		mainloop.init();

		void showErrorDialog(Exception e) {
			writeln(e.info);
			RichTextBuilder builder = new RichTextBuilder()
				.h1("Error")
				.text(to!string(e.message)).p();
			openDialog(mainloop, builder.build());
		}

		mainloop.onException.add((e) {
			showErrorDialog(e);
		});

		mainloop.resources.addFile("data/DejaVuSans.ttf");
		mainloop.resources.addFile("data/style.json");
		mainloop.resources.addFile("data/title-layout.json");
		mainloop.resources.addFile("data/dialog-layout.json");
		mainloop.resources.addFile("data/themap.json");
		mainloop.resources.addMusicFile("data/Chattanooga_wip2_loop.ogg");
		
		mainloop.resources.addGlob("data/test-map*.json");

		mainloop.resources.addGlob("data/*.png");

		mainloop.styles.applyResource("style");

		mainloop.onDisplaySwitch.add((switchIn) { if (switchIn) { writeln("Window switched in event called"); mainloop.resources.refreshAll(); }});

		mainloop.addState("MainState", new MainState(mainloop));
		mainloop.switchState("MainState");
		
		mainloop.audio.playMusic(mainloop.resources.music["Chattanooga_wip2_loop"].ptr, 1.0);
		mainloop.run();

		return 0;
	});

}
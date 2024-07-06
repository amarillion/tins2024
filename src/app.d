module app;

import std.stdio;
import std.conv;

import allegro5.allegro;
import allegro5.allegro_audio;

import helix.mainloop;
import helix.richtext;

import dialog;
import mainState;
import std.stdio;

import core.thread;

extern (C) void rt_moduleTlsCtor();
extern (C) void rt_moduleTlsDtor();

// suggestion by SiegeLord https://discord.com/channels/993415281244393504/1013128461319159932/1259228267173515417
// to solve problems with creating an app bundle on Mac OS X
// Should eventually make its way to DAllegro...
int al_run_allegro2(scope int delegate() user_main)
{
    __gshared int delegate() user_main2;
    user_main2 = user_main;
    extern(C) static int main_runner(int argc, char** argv)
    {
        version(OSX)
        {
            thread_attachThis();
            rt_moduleTlsCtor();
        }

        auto main_ret = user_main2();

        version(OSX)
        {
            thread_detachThis();
            rt_moduleTlsDtor();
        }

        return main_ret;
    }

    return al_run_main(0, null, &main_runner);
}

void main(string[] args)
{
	al_run_allegro2(
	{
		al_init();

		// look up resources directory for Mac OS X,
		// after: https://github.com/liballeg/allegro_wiki/wiki/Creating-macOS-bundles
		al_change_directory(al_path_cstr(al_get_standard_path(ALLEGRO_RESOURCES_PATH), '/'));
 
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
		mainloop.resources.addFile("data/customize-dialog.json");
		mainloop.resources.addFile("data/themap.json");
		mainloop.resources.addFile("data/color-replace.glsl");
		mainloop.resources.addGlob("data/*.ogg");
		mainloop.resources.addMusicFile("data/music/Chattanooga_wip3_loop.ogg");
		
		mainloop.resources.addGlob("data/test-map*.json");

		mainloop.resources.addGlob("data/*.png");

		mainloop.styles.applyResource("style");

		mainloop.onDisplaySwitch.add((switchIn) { if (switchIn) { writeln("Window switched in event called"); mainloop.resources.refreshAll(); }});

		mainloop.addState("MainState", new MainState(mainloop));
		mainloop.switchState("MainState");
		
		mainloop.audio.playMusic(mainloop.resources.music["Chattanooga_wip3_loop"].ptr, 1.0);
		mainloop.run();

		return 0;
	});

}
## How to Play

Fole and Raul return to their favorite youth pasttime: playing with a toy train set!
Raul likes to design and build miniature buildings.
Fole especially likes to see how fast the trains can go, and make them crash!

Using the buttons on the right side, you can control the trains.
Start by adding your first train with the "Add Train" button.
Press "Next" to cycle through your available trains.

You can customize the color of each train.
You can make the train go faster, or stop.
The direction the trains will take on switch tracks is random - you can't control this.

Scroll using the scroll bars on the side. You can also Toggle "Follow mode", so the screen stays centered on the currently selected train.

## Special rules

This game was made during the TINS 2024 game jam.
For the game jam, we had to adhere to the following additional rules:

```
genre rule #99: Trains.
```

The game is centered around trains. I've taken inspiration from the great DOS classic "Transport Tycoon Deluxe" for the visuals.

```
art rule #155: Art Nouveau.
```

Your trains travel through cities full of hand-pixelated art nouveau architecture.

```
tech rule #117: Custom Paint Job. Something, be it characters, controls, graphics, or anything else you can think of, can be customized by the player.
```

In the game, you can configure the color of each train. Colors of the train are replaced on-the-fly by a custom GLSL Shader.

```
tech rule #98: use a quadratic formula (i.e. ax^2 + bx + c) somewhere in the game.
```

You can accelerate your trains indefinitely. When you accelerate, your distance travelled increases following a quadratic formula.

```
bonus rule #22: Act of "Cool Story, Bro": skip one rule by explaining how totally awesome the idea was that you were going to implement but unfortunately didn't have time for...
```

## Credits

Art by Max
Programming and additional Art by Amarillion
Music by AniCator

I have re-used a lot of code from from earlier game jam entries. The overall project structure came from [Allegro Shader Toy from Krampushack 2023](https://tins.amarillion.org/entry/308) and the isometric code was ported from [Usagi from KrampusHack 2021](https://tins.amarillion.org/entry/251). The original isometric gfx code was written in C++, for this competition I rewrote it all in D.

Github Copilot was used to assist programming of this submission, and it has been really helpful in a few instances.

Other than that, no AI-generated assets were used. The music, and nearly all art, was hand-crafted during the competition.

Collision sound effect derived from: https://freesound.org/people/LPHypeR/sounds/646185/ (CC0)

Toot sound effect derived from: https://freesound.org/people/NLM/sounds/267986/ (CC BY 4.0 NC)

## Source code & Dependencies

You can find the source code for this program on github:

https://github.com/amarillion/tins2024

To compile you'll also need my experimental D+Allegro Game engine called Dtwist:

https://github.com/amarillion/dtwist/

Other dependencies are [D](https://dlang.org), [Allegro](https://liballeg.org), and [DAllegro](https://github.com/SiegeLord/DAllegro5)

The official page for this entry is on https://tins.amarillion.org/entry/313/
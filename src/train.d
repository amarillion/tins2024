module train;

import std.random;
import std.algorithm;
import std.range;
// TODO: remove dependency on allegro here.
import allegro5.allegro;

import helix.util.vec;
import helix.color;

import model;
import map;

struct Wagon {
	float lx = 0.0;
	float ly = 0.0;
	float lz = 0.0;
	float angle = 0.0;
	int spriteIdx = 0;
}

class Train {
private:
	Model model;
public:
	ALLEGRO_COLOR color = Color.RED;
	Edge[] trail;
	Wagon[] wagons;

	bool isDead = false; // after collision...

	int id = -1;
	static int nextId = 1;

	Edge dir;

	float speed = 0.0f;
	float acceleration = 0.0005f;
	float max_speed = 0.03f;

	Node node;

	float steps = 1.0f; // after steps > 1.0, we arrive at the next node

	this(Model _model, Node startNode, Edge startDir) {
		this.id = nextId++;
		this.model = _model;
		this.node = startNode;
		this.dir = startDir;
		import std.stdio;
		writefln("Created train with id: %s", id);
	}

	static float getAngle(Edge dir, float steps) {
		auto eInfo = EDGE_INFO[dir];
		float frac = steps / eInfo.length;

		float dAngle = SUBLOC_INFO[eInfo.to].degrees - SUBLOC_INFO[eInfo.from].degrees;
		if (dAngle > 180) dAngle -= 360;
		if (dAngle < -180) dAngle += 360;

		float result = SUBLOC_INFO[eInfo.from].degrees + (dAngle * frac);
		if (result < 0) result += 360;
		return result;
	}

	float getLx() {
		return node.pos.x + EDGE_INFO[dir].calc_x(steps);
	}

	float getLy() {
		return node.pos.y + EDGE_INFO[dir].calc_y(steps);
	}

	static float getLz(Model model, Node node, Edge dir, float steps) {
		float fromz = model.getSubNodeZ(node.pos, EDGE_INFO[dir].from);
		float toz = model.getSubNodeZ(node.pos + Point(EDGE_INFO[dir].dx, EDGE_INFO[dir].dy), EDGE_INFO[dir].to);
		return fromz + (toz - fromz) * (steps / EDGE_INFO[dir].length);
	}

	void recalcWagons() {

		const float DISTANCE_UNIT = 0.4; // distance between wagons as a fraction of a tile

		float wagLx = getLx();
		float wagLy = getLy();

		Node wagLoc = node;
		Edge wagDir = dir;
		float wagSteps = steps;

		auto trailIt = 0;

		// skip first, we read it from current train pos
		//	if (trailIt != trail.end()) trailIt++;

		foreach (ref wagon; wagons) {
			wagon.lx = wagLx;
			wagon.ly = wagLy;
			
			// collision test
			if (!isDead && wagLoc.pos in model.collisionMap) {
				auto otherId = model.collisionMap[wagLoc.pos];
				if (otherId != id) {
					auto otherTrain = model.train.find!(a => a.id == otherId)();
					if (!otherTrain.empty) {
						model.onCollision(this, otherTrain.front);
					}
					
				}
				
			}
			// we still want to update collision map, even if dead...
			model.collisionMap[wagLoc.pos] = id;

			wagon.lz = getLz(model, wagLoc, wagDir, wagSteps);

			// if (isDead) {
			// 	// quick hack to make it appear jumbled up
			// 	wagon.angle = wagSteps;
			// }
			// else {
				wagon.angle = getAngle(wagDir, wagSteps);
			// }
			// import std.stdio;
			// writeln("wagon angle: ", wagon.angle);

			if (trailIt < trail.length) {
				// advance on trail...
				wagSteps -= DISTANCE_UNIT;
				if (wagSteps < 0.0) {
					trailIt++;
					if (trailIt < trail.length) {
						wagDir = trail[trailIt];
						wagSteps += EDGE_INFO[wagDir].length;
						wagLoc = wagLoc.followReverse(wagDir);
					}
				}

				wagLx = wagLoc.pos.x + EDGE_INFO[wagDir].calc_x(wagSteps);
				wagLy = wagLoc.pos.y + EDGE_INFO[wagDir].calc_y(wagSteps);
			}
		}
	}

	/** random movement in case we can't get a suitable path */
	Edge findRandomValidDir() {
		if (node !in model.links) {
			return Edge.UNDEFINED; // Will lead to a stop...
		}
		auto options = model.links[node];
		if (options.length == 0) {
			return Edge.UNDEFINED; // Will lead to a stop...
		}

		// now we pick the first option available.
		// TODO: random choice?
		return choice(options.keys);
	}

	void doMove() {
		if (!isDead) {
			speed += acceleration;
			if (speed > max_speed)
			{
				speed = max_speed;
			}
		}
		else {
			speed = 0;
		}

		// we still want to update collision map, even if dead...
		recalcWagons();

		if (steps + speed >= EDGE_INFO[dir].length)
		{
			steps -= EDGE_INFO[dir].length;

			// update map status
			model.mapTT[node.pos].idTrain = -1;

			if (dir != Edge.UNDEFINED) {
				node = node.following(dir);
			}

			// update map status
			model.mapTT[node.pos].idTrain = id;
			// TODO: check for collisions

			// now decide to change direction...
			Edge d = findRandomValidDir();
			if (dir != d) {
				dir = d;
			}

			if (!model.canGo(node, dir))
			{
				speed = 0;
			}

			trail = dir ~ trail;
			if (trail.length > 10) trail = trail[0..9];
		}

		steps += speed;
	}

	void stop() {
		speed = 0;
		max_speed = 0.0f;
	}

	void accelerate() {
		max_speed += 0.01f;
		// No limit. Why would we set a limit? :-D
	}

}
module train;

import helix.util.vec;

import model;
import map;

struct Wagon {
	float lx;
	float ly;
	int spriteIdx;
}

class Train {
private:
	Model model;
public:
	Edge[] trail;
	Wagon[] wagons;

	int id = -1;
	Edge dir;

	float speed = 0.0f;
	float acceleration = 0.0005f;
	float max_speed = 0.03f;

	Node node;

	float steps = 1.0f; // after steps > 1.0, we arrive at the next node

	this(Model _model, Node startNode, Edge startDir) {
		this.model = _model;
		this.node = startNode;
		this.dir = startDir;
	}

	float getLx() {
		return node.pos.x + EDGE_INFO[dir].calc_x(steps);
	}

	float getLy() {
		return node.pos.y + EDGE_INFO[dir].calc_y(steps);
	}

	float getLz() {
		return 0.0f; //TODO
	}

	void recalcWagons() {

		const float DISTANCE_UNIT = 0.5;

		float wagLx = getLx();
		float wagLy = getLy();
		Node wagLoc = node;
		Edge wagDir = dir;
		float wagSteps = steps;

		auto trailIt = 0;

		// skip first, we read it from current train pos
		//	if (trailIt != trail.end()) trailIt++;

		foreach (wagon; wagons) {
			wagon.lx = wagLx;
			wagon.ly = wagLy;

			auto nextSubLoc = EDGE_INFO[wagDir].to;
			if (trailIt < trail.length) {
				// advance on trail...
				wagSteps -= DISTANCE_UNIT;
				if (wagSteps < 0.0) {
					trailIt++;
					if (trailIt < trail.length) {
						wagDir = trail[trailIt];
						wagSteps += EDGE_INFO[wagDir].length;
						wagLoc.followReverse(wagDir);
					}
				}

				wagLx = wagLoc.pos.x + EDGE_INFO[wagDir].calc_x(wagSteps);
				wagLy = wagLoc.pos.y + EDGE_INFO[wagDir].calc_y(wagSteps);
			}
		}
	}

	/** random movement in case we can't get a suitable path */
	Edge findRandomValidDir() {

		auto options = model.links[node];
		if (options.length == 0) {
			return Edge.UNDEFINED; // Will lead to a stop...
		}

		// now we pick the first option available.
		// TODO: random choice?
		return options.keys[0];
	}

	void doMove() {
		speed += acceleration;
		if (speed > max_speed)
		{
			speed = max_speed;
		}

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

}
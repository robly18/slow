import aiComponent;
import connection;
import vector;
import constants;
import std.algorithm;

class InternetAiComponent : PCAiComponent {
public:
	this(Connection co, int playerid) {
		c = co;
		id = playerid;
	}
	
	Connection c;
	int id;
	
	override void run(ActiveEntity it, World w) {
		it.stamina.rest(1);
	}
}
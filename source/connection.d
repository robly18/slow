import std.socket;
import vector;
import std.conv;
import std.outbuffer;

import aiComponent;


ubyte[] inputToBuffer(Input i) {
	OutBuffer buf = new OutBuffer();
	buf.write(cast(int)i.type);
	buf.write(i.x);
	buf.write(i.y);
	return buf.toBytes();
}

Input bufferToInput(ubyte[12] buffer) {
	//lets hope endianness doesnt affect anything
	return Input(*cast(InputType*)buffer[0..3],
				*cast(int*)buffer[4..7],
				*cast(int*)buffer[8..11]);
}

abstract class Connection {
public:
	Input getInput() {
		import std.stdio;
		
		ubyte[12] buf;
		int received = s.receive(buf);
		if (received == 12) {
			return bufferToInput(buf);
		} else if (received == Socket.ERROR) {
			if (wouldHaveBlocked()) {
				return Input(InputType.NOP);
			} else {
				writeln("An error has occurred! :(");
				return Input(InputType.NOP);
			}
		} else {
			writeln("Error: expected 12 bytes, got ", received);
			return Input(InputType.NOP);
		}
	}
	void sendInput(Input i) {
		import std.stdio;
		writeln("Sending turn");
		s.send(inputToBuffer(i));
	}
	//todo: synchronize
	
	Socket s;
	
	~this() {
		s.shutdown(SocketShutdown.BOTH);
		s.close();
	}
}

class ServerConnection : Connection {
public:
	this(Address addr) {
		s = new Socket(AddressFamily.INET, SocketType.STREAM);
		s.bind(addr);
		import std.stdio;
		writeln("Listening.");
		s.listen(1);
		s = s.accept();
		writeln("Found client.");
	}
}

class ClientConnection : Connection {
public:
	this(Address addr) {
		s = new Socket(AddressFamily.INET, SocketType.STREAM);
		import std.stdio;
		writeln("Connecting.");
		s.connect(addr);
		writeln("Found server.");
	}
}
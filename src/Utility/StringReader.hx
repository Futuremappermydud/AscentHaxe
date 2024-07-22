package utility;

class StringReader {
	public var _string:String;
	public var _position:Int;
	public var _length:Int;

	public function new(string:String) {
		_string = string;
		_length = string.length;
		_position = 0;
	}

	public function Peek():String {
		if (_position >= _string.length) {
			return null;
		}
		return _string.charAt(_position);
	}

	public function PeekChar():Int {
		if (_position >= _string.length) {
			return -1;
		}
		return _string.charCodeAt(_position);
	}

	public function Read():String {
		if (_position >= _string.length) {
			return null;
		}
		return _string.charAt(_position++);
	}

	public function ReadLen(len:Int):String {
		var stringBuf:StringBuf = new StringBuf();
		for (i in 0...len) {
			if (_position + i >= _string.length) {
				break;
			}
			stringBuf.add(Read());
		}
		return stringBuf.toString();
	}
}

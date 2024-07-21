package utility;

class StringReader {
    public var _string:String;
    public var _position:Int;

    public function new(string:String) {
        _string = string;
        _position = 0;
    }

    public function Peek():String {
        if (_position >= _string.length) {
            return null;
        }
        return _string.charAt(_position);
    }

    public function Read():String {
        if (_position >= _string.length) {
            return null;
        }
        return _string.charAt(_position++);
    }
}
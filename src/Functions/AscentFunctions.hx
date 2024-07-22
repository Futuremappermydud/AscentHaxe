package functions;

class AscentFunctions {
    public static function GetFunction(name: String): Function {
        return null;
    }
    
    public static function SearchAnyFunctions(char: Int): Bool {
        return false;
    }
}

abstract class Function {
    public abstract function Evaluate(args: Array<Float>): Float;
}
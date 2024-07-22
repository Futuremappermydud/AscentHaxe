package parser;

class FunctionDefinition {
    public var name: String;
    public var args: Array<String> = new Array<String>();
    public var contents: Array<Expression>;
    public var defined: Bool;

    public function new(name: String) {
        this.name = name;
    }
}
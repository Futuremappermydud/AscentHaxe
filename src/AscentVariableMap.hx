package;

import parser.FunctionDefinition;

class AscentVariableMap {
    public function new(queryVariables: Map<String, Float>) {
        QueryVariables = queryVariables;
    }

    public function Clone() {
        var clone = new AscentVariableMap(QueryVariables);
        clone.Variables = Variables.copy();
        clone.Functions = Functions.copy();
        return clone;
    }

    public var QueryVariables: Map<String, Float>;
    public var Variables: Map<String, Float> = new Map<String, Float>();
    public var Functions: Map<String, FunctionDefinition> = new Map<String, FunctionDefinition>();
}
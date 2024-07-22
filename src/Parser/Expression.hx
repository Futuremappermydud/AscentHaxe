package parser;

import functions.AscentFunctions;
import utility.Utility;
import tokenizer.Token;

abstract class Expression {
	public abstract function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float>;
}

class BinaryExpression extends Expression {
	public var left:Expression;
	public var operation:Token;
	public var right:Expression;

	public function new(left:Expression, right:Expression, operation:Token) {
		this.left = left;
		this.right = right;
		this.operation = operation;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		var leftValue = left.Evaluate(ascentVariableMap);
		var rightValue = right.Evaluate(ascentVariableMap);

		if (operation.type == TokenType.Multiplication) {
			return leftValue * rightValue;
		}

		if (operation.type == TokenType.Division) {
			return leftValue / rightValue;
		}

		if (operation.type == TokenType.Addition) {
			return leftValue + rightValue;
		}

		if (operation.type == TokenType.Subtraction) {
			return leftValue - rightValue;
		}

		if (operation.type == TokenType.Pow) {
			return Math.pow(leftValue ?? 0, rightValue ?? 0);
		}

		if (operation.type == TokenType.Modulus) {
			return leftValue % rightValue;
		}

		if (operation.type == TokenType.GreaterThan) {
			return (leftValue > rightValue) ? 1 : 0;
		}

		if (operation.type == TokenType.LesserThen) {
			return (leftValue < rightValue) ? 1 : 0;
		}

		throw "Unknown operation: ${operation.type}";
	}
}

class NumberExpression extends Expression {
	public var token:Token;

	public function new(token:Token) {
		this.token = token;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (token.type == TokenType.Constant) {
			return Utility.convertToFloat(token.tokenBuffer);
		} else if (token.type == TokenType.Query) {
			var buffer = token.tokenBuffer;
			if (ascentVariableMap != null && Utility.searchMapKeysForString(buffer, ascentVariableMap.QueryVariables.keys())) {
				return ascentVariableMap.QueryVariables[buffer];
			} else {
				Sys.println('Variable ${buffer} (${buffer.length}) not found in variable map');
			}
		}

		return 0;
	}
}

class FunctionDefinitionExpression extends Expression {
	public var functionToken:Token;
	public var contents:Array<Expression>;

	public function new(functionToken:Token, contents:Array<Expression>) {
		this.functionToken = functionToken;
		this.contents = contents;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		var name = functionToken.tokenBuffer;
		if (Utility.searchMapKeysForString(name, ascentVariableMap.Functions.keys())) {
			var definition = ascentVariableMap.Functions[name];
			definition.contents = contents;
			definition.defined = true;
		}

		return null;
	}
}

class ForLoopExpression extends Expression {
	public var definition:Expression;
	public var condition:Expression;
	public var suffix:Expression;
	public var contents:Array<Expression>;

	public function new(definition:Expression, condition:Expression, suffix:Expression, contents:Array<Expression>) {
		this.definition = definition;
		this.condition = condition;
		this.suffix = suffix;
		this.contents = contents;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		definition.Evaluate(ascentVariableMap);

		while (condition.Evaluate(ascentVariableMap) > 0.5) {
			for (expression in contents) {
				var map = ascentVariableMap?.Clone();
				expression.Evaluate(map);
				for (key in map.Variables.keys()) {
					ascentVariableMap.Variables[key] = map.Variables[key];
				}
			}
			suffix.Evaluate(ascentVariableMap);
		}
		return null;
	}
}

class WhileLoopExpression extends Expression {
	public var condition:Expression;
	public var contents:Array<Expression>;

	public function new(condition:Expression, contents:Array<Expression>) {
		this.condition = condition;
		this.contents = contents;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		while (condition.Evaluate(ascentVariableMap) > 0.5) {
			for (expression in contents) {
				var map = ascentVariableMap?.Clone();
				expression.Evaluate(map);
				for (key in map.Variables.keys()) {
					ascentVariableMap.Variables[key] = map.Variables[key];
				}
			}
		}
		return null;
	}
}

class TernaryExpression extends Expression {
	public var condition:Expression;
	public var trueExpression:Expression;
	public var falseExpression:Expression;

	public function new(condition:Expression, trueExpression:Expression, falseExpression:Expression) {
		this.condition = condition;
		this.trueExpression = trueExpression;
		this.falseExpression = falseExpression;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (condition.Evaluate(ascentVariableMap) > 0.5) {
			return trueExpression.Evaluate(ascentVariableMap);
		} else {
			return falseExpression.Evaluate(ascentVariableMap);
		}
	}
}

class FunctionExpression extends Expression {
	public var functionToken:Token;
	public var arguments:Array<Expression>;

	public function new(functionToken:Token, arguments:Array<Expression>) {
		this.functionToken = functionToken;
		this.arguments = arguments;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		var name = functionToken.tokenBuffer;
		var func:Function = AscentFunctions.GetFunction(name);
		var args = arguments.map(function(arg) {
			return arg.Evaluate(ascentVariableMap);
		});
		if (func == null) {
			if (ascentVariableMap != null && Utility.searchMapKeysForString(name, ascentVariableMap.Functions.keys())) {
				var expressions = ascentVariableMap.Functions[name];
				for (i in 0...expressions.args.length) {
					ascentVariableMap.Variables[expressions.args[i]] = args[i];
				}
				var result:Float = 0;
				for (expression in expressions.contents) {
					var res:Null<Float> = expression.Evaluate(ascentVariableMap);
					if (res != null)
						result = res;
				}
				var expressions = ascentVariableMap.Functions[name];
				for (i in 0...expressions.args.length) {
					ascentVariableMap.Variables.remove(expressions.args[i]);
				}
				return result;
			}
			return null;
		}
		return func.Evaluate(args);
	}
}

class AssignmentExpression extends Expression {
	public var variable:Token;
	public var assignment:Expression;

	public function new(variable:Token, assignment:Expression) {
		this.variable = variable;
		this.assignment = assignment;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (ascentVariableMap == null) {
			throw "Variable map cannot be null";
		}
		if (Assignment == null) {
			throw "Assignment Expression cannot be null";
		}
		var value = assignment.Evaluate(ascentVariableMap);
		ascentVariableMap.Variables[variable.tokenBuffer] = value ?? 0;
		return null;
	}
}

class VariableExpression extends Expression {
	public var variableToken:Token;

	public function new(variableToken:Token) {
		this.variableToken = variableToken;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (ascentVariableMap == null) {
			throw "Variable map cannot be null";
		}
		if (Utility.searchMapKeysForString(variableToken.tokenBuffer, ascentVariableMap.Variables.keys())) {
			return ascentVariableMap.Variables[variableToken.tokenBuffer];
		}
		return null;
	}
}

class IncrementVariableExpression extends Expression {
	public var variableToken:Token;

	public function new(variableToken:Token) {
		this.variableToken = variableToken;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (ascentVariableMap == null) {
			throw "Variable map cannot be null";
		}
		if (Utility.searchMapKeysForString(variableToken.tokenBuffer, ascentVariableMap.Variables.keys())) {
			return ascentVariableMap.Variables[variableToken.tokenBuffer]++;
		}
		return null;
	}
}

class DecrementVariableExpression extends Expression {
	public var variableToken:Token;

	public function new(variableToken:Token) {
		this.variableToken = variableToken;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (ascentVariableMap == null) {
			throw "Variable map cannot be null";
		}
		if (Utility.searchMapKeysForString(variableToken.tokenBuffer, ascentVariableMap.Variables.keys())) {
			return ascentVariableMap.Variables[variableToken.tokenBuffer]--;
		}
		return null;
	}
}

class AdditionAssignmentExpression extends Expression {
	public var variableToken:Token;
	public var assignment:Expression;

	public function new(variableToken:Token, assignment:Expression) {
		this.variableToken = variableToken;
		this.assignment = assignment;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (ascentVariableMap == null) {
			throw "Variable map cannot be null";
		}
		if (Utility.searchMapKeysForString(variableToken.tokenBuffer, ascentVariableMap.Variables.keys())) {
			var value = assignment.Evaluate(ascentVariableMap);
			return ascentVariableMap.Variables[variableToken.tokenBuffer] += value ?? 0;
		}
		return null;
	}
}

class SubtractionAssignmentExpression extends Expression {
	public var variableToken:Token;
	public var assignment:Expression;

	public function new(variableToken:Token, assignment:Expression) {
		this.variableToken = variableToken;
		this.assignment = assignment;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		if (ascentVariableMap == null) {
			throw "Variable map cannot be null";
		}
		if (Utility.searchMapKeysForString(variableToken.tokenBuffer, ascentVariableMap.Variables.keys())) {
			var value = assignment.Evaluate(ascentVariableMap);
			return ascentVariableMap.Variables[variableToken.tokenBuffer] -= value ?? 0;
		}
		return null;
	}
}

class NilExpression extends Expression {
	public var token:Token;

	public function new(token:Token) {
		this.token = token;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		return null;
	}
}

class ReturnExpression extends Expression {
	public var expression:Expression;

	public function new(expression:Expression) {
		this.expression = expression;
	}

	public function Evaluate(ascentVariableMap:AscentVariableMap):Null<Float> {
		return expression.Evaluate(ascentVariableMap);
	}
}

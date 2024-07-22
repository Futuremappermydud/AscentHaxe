package utility;

import parser.Expression;
import parser.Expression.NumberExpression;
import parser.Expression.BinaryExpression;
import parser.Expression.TernaryExpression;
import tokenizer.Token.TokenType;
import splitter.TokenContainer;
import splitter.TokenContainer.MultipleTokenContainer;
import splitter.TokenContainer.SingleTokenContainer;

class Utility {
	public static function searchForPotential(c:Int, strings:List<String>):Bool {
		return Lambda.exists(strings, function(x) {
			return StringTools.startsWith(x, String.fromCharCode(c));
		});
	}

	public static function searchForPotentialArray(c:Int, strings:Array<String>):Bool {
		return Lambda.exists(strings, function(x) {
			return StringTools.startsWith(x, String.fromCharCode(c));
		});
	}

	public static function searchMapKeysForString(c:String, map:Iterator<String>):Bool {
		var arr:Array<String> = new Array<String>();
		for (key in map)
			arr.push(key);
		return Lambda.exists(arr, function(x) {
			return x == c;
		});
	}

	public static function searchMapKeysForTokenType(c:TokenType, map:Iterator<TokenType>):Bool {
		var arr:Array<TokenType> = new Array<TokenType>();
		for (key in map)
			arr.push(key);
		return Lambda.exists(arr, function(x) {
			return x == c;
		});
	}

	public static function convertToFloat(value:String):Float {
		if (value == null || value.length == 0) {
			throw "Input string is null or empty.";
		}

		var isNegative = value.charAt(0) == '-';
		var startIndex = isNegative ? 1 : 0;
		var valueLength = value.length;

		if (startIndex == valueLength) {
			throw "Input string contains only a negative sign.";
		}

		var result:Float = 0;
		var isFractionalPart = false;
		var fractionalDivisor:Float = 10;

		for (i in startIndex...valueLength) {
			var c = value.charAt(i);

			if (c == '.') {
				if (isFractionalPart) {
					throw "Input string contains multiple decimal points.";
				}
				isFractionalPart = true;
				continue;
			}

			if (c < '0' || c > '9') {
				throw "Invalid character '${c}' in input string.";
			}

			var digit = c.charCodeAt(0) - '0'.charCodeAt(0);

			if (isFractionalPart) {
				result += digit / fractionalDivisor;
				fractionalDivisor *= 10;
			} else {
				result = result * 10 + digit;
			}
		}

		return isNegative ? -result : result;
	}

	private static function GetIndent(indentLevel:Int):String {
		return StringTools.rpad("", " ", indentLevel * 2);
	}

	public static function PrintTokenContainer(container:TokenContainer, indentLevel:Int = 0) {
		if (container is SingleTokenContainer) {
			var single:SingleTokenContainer = cast container;
			Sys.println('${GetIndent(indentLevel)}SingleTokenContainer:');
			Sys.print('${GetIndent(indentLevel + 2)}');
			for (i in 0...single.expression.length) {
				Sys.print('${single.expression[i].type}, ');
			}
			Sys.print("\n");
		} else if (container is MultipleTokenContainer) {
			var multiple:MultipleTokenContainer = cast container;
			Sys.println('${GetIndent(indentLevel)}MultipleTokenContainer: ${multiple.tokenContainers.length}');
			for (i in 0...multiple.tokenContainers.length) {
				PrintTokenContainer(multiple.tokenContainers[i], indentLevel + 2);
			}
		} else {
			throw "Invalid container type";
		}
	}

	public static function PrintExpression(expr:Expression, indentLevel:Int) {
		if (expr is NumberExpression) {
			var numberExpr:NumberExpression = cast expr;
			var type = numberExpr.token.type == TokenType.Constant ? "Number" : "Query";
			Sys.println('${GetIndent(indentLevel)}${type}: ${numberExpr.token.tokenBuffer}');
		} else if (expr is BinaryExpression) {
			var binaryExpr:BinaryExpression = cast expr;
			Sys.println('${GetIndent(indentLevel)}Binary Expression:');
			Sys.println('${GetIndent(indentLevel + 2)}Operator: ${binaryExpr.operation.tokenBuffer}');
			PrintExpression(binaryExpr.left, indentLevel + 2);
			PrintExpression(binaryExpr.right, indentLevel + 2);
		} else if (expr is TernaryExpression) {
			var ternaryExpr:TernaryExpression = cast expr;
			Sys.println('${GetIndent(indentLevel)}Ternary Expression:');
			PrintExpression(ternaryExpr.condition, indentLevel + 2);
			Sys.println('${GetIndent(indentLevel + 2)}True Expression:');
			PrintExpression(ternaryExpr.trueExpression, indentLevel + 4);
			Sys.println('${GetIndent(indentLevel + 2)}False Expression:');
			PrintExpression(ternaryExpr.falseExpression, indentLevel + 4);
		} else if (expr is FunctionExpression) {
			var functionExpr:FunctionExpression = cast expr;
			Sys.println('${GetIndent(indentLevel)}Function:');
			Sys.println('${GetIndent(indentLevel + 4)}Type: ${functionExpr.functionToken.tokenBuffer}');
			Sys.println('${GetIndent(indentLevel + 2)}Argument Expression:');
			for (arg in functionExpr.arguments) {
				PrintExpression(arg, indentLevel + 4);
			}
		} else if (expr is FunctionDefinitionExpression) {
			var functionDefExpr:FunctionDefinitionExpression = cast expr;
			Sys.println('${GetIndent(indentLevel)}Function Definition:');
			Sys.println('${GetIndent(indentLevel + 4)}Name: ${functionDefExpr.functionToken.tokenBuffer}');
			Sys.println('${GetIndent(indentLevel + 2)}Expressions:');
			for (expr in functionDefExpr.contents) {
				PrintExpression(expr, indentLevel + 4);
			}
		} else if (expr is AssignmentExpression) {
			var assignmentExpr:AssignmentExpression = cast expr;
			Sys.println('${GetIndent(indentLevel)}Assignment:');
			Sys.println('${GetIndent(indentLevel + 4)}Variable: ${assignmentExpr.variable.tokenBuffer}');
			Sys.println('${GetIndent(indentLevel + 2)}Setting Expression:');
			PrintExpression(assignmentExpr.assignment, indentLevel + 4);
		} else if (expr is VariableExpression) {
			var variableExpr:VariableExpression = cast expr;
			Sys.println('${GetIndent(indentLevel)}GrabVariable:');
			Sys.println('${GetIndent(indentLevel + 4)}Variable: ${variableExpr.variableToken.tokenBuffer}');
		} else if (expr is ReturnExpression) {
			var returnExpr:ReturnExpression = cast expr;
			Sys.println('${GetIndent(indentLevel)}Return:');
			PrintExpression(returnExpr.expression, indentLevel + 2);
		} else {
			throw 'Invalid expression type ${expr}';
		}
	}
}

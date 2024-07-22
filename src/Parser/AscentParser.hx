package parser;

import parser.Expression.WhileLoopExpression;
import parser.Expression.AssignmentExpression;
import parser.Expression.IncrementVariableExpression;
import parser.Expression.DecrementVariableExpression;
import parser.Expression.SubtractionAssignmentExpression;
import parser.Expression.VariableExpression;
import parser.Expression.NilExpression;
import parser.Expression.ReturnExpression;
import parser.Expression.ForLoopExpression;
import parser.Expression.FunctionDefinitionExpression;
import parser.Expression.FunctionExpression;
import parser.Expression.NumberExpression;
import parser.Expression.TernaryExpression;
import parser.Expression.AdditionAssignmentExpression;
import utility.Utility;
import parser.Expression.BinaryExpression;
import AscentVariableMap;
import tokenizer.Token;
import splitter.TokenContainer;

class AscentParser {
	private var _currentContainer:TokenContainer;
	private var _position:Int;
	private var _containerStack:Array<TokenContainer>;
	private var _currentTokens:Array<Token>;

	public function new(rootContainer:TokenContainer) {
		_currentContainer = rootContainer;
		_position = 0;
		_containerStack = new Array<TokenContainer>();
		_containerStack.push(rootContainer);
		_currentTokens = [];
	}

	static var Precedence:Map<TokenType, Int> = [
		TokenType.Pow => 9,
		TokenType.TernaryConditional => 5,
		TokenType.GreaterThan => 6,
		TokenType.LesserThen => 6,
		TokenType.Modulus => 3,
		TokenType.Multiplication => 3,
		TokenType.Division => 3,
		TokenType.Addition => 2,
		TokenType.Subtraction => 2
	];

	private function LoadNextContainer() {
		while (_position >= _currentTokens.length && _containerStack.length > 0) {
			var currentContainer = _containerStack[0];
			_containerStack = _containerStack.filter(function(x) {
                return _containerStack.indexOf(x) != 0;
            });

			if (currentContainer is SingleTokenContainer) {
				var single:SingleTokenContainer = cast currentContainer;
				_currentTokens = single.expression;
				_position = 0;
			} else if (currentContainer is MultipleTokenContainer) {
				var multiple:MultipleTokenContainer = cast currentContainer;
				for (i in 0...multiple.tokenContainers.length) {
					_containerStack.insert(i, multiple.tokenContainers[i]);
				}
			}
		}
	}

	public function Parse(variableMap:AscentVariableMap):Array<Expression> {
		var expressions = new Array<Expression>();

		while (_containerStack.length > 0 || _currentTokens.length > 0) {
			LoadNextContainer();
			while (_position < _currentTokens.length) {
				var expression = ParseExpression(variableMap);
				if (expression != null) {
					expressions.insert(0, expression);
				}
				_currentTokens = [];
				_position++;
			}
		}

		return expressions;
	}

	public function ParseExpression(variableMap:AscentVariableMap):Expression {
		return ParseBinary(0, variableMap);
	}

	private function ParseBinary(precedence:Int, variableMap:AscentVariableMap):Expression {
		var left = ParsePrimary(variableMap);

		while (true) {
			if (_position >= _currentTokens.length
				|| !Utility.searchMapKeysForTokenType(_currentTokens[_position].type, Precedence.keys())) {
				break;
			}

			var operatorToken = _currentTokens[_position];
			var tokenPrecedence = Precedence[operatorToken.type];
			if (tokenPrecedence < precedence) {
				break;
			}

			_position++;
			if (operatorToken.type == TokenType.TernaryConditional) {
				var condition = left;
				var trueExpression = ParseExpression(variableMap);

				if (!CurrentTokenIs(TokenType.Colon)) {
					throw "Expected ':' in ternary expression";
				}
				_position++; // consume ':'

				var falseExpression = ParseExpression(variableMap);

				return new TernaryExpression(condition, trueExpression, falseExpression);
			} else {
				var right = ParseBinary(tokenPrecedence + 1, variableMap);
				left = new BinaryExpression(left, right, operatorToken);
			}
		}

		return left;
	}

	private function ParsePrimary(variableMap:AscentVariableMap):Expression {
		if (CurrentTokenIs(TokenType.Constant) || CurrentTokenIs(TokenType.Query)) {
			var numberToken = _currentTokens[_position++];
			return new NumberExpression(numberToken);
		}

		if (CurrentTokenIs(TokenType.LeftParenthesis)) {
			_position++; // consume '('
			var expression = ParseExpression(variableMap);
			if (!CurrentTokenIs(TokenType.RightParenthesis)) {
				throw "Missing closing parenthesis";
			}
			_position++; // consume ')'
			return expression;
		}

		if (CurrentTokenIs(TokenType.LeftBracket)) {
			_position++; // consume '['
			var expression = ParseExpression(variableMap);
			if (!CurrentTokenIs(TokenType.RightBracket)) {
				throw "Missing closing Bracket";
			}
			_position++; // consume ']'
			return expression;
		}

		if (CurrentTokenIs(TokenType.Function)) {
			var functionToken = _currentTokens[_position++]; // Get the function token
            
			if (!CurrentTokenIs(TokenType.LeftParenthesis)) {
				throw "Expected '(' after function";
			}
			_position++; // consume '('

			// Parse function arguments
			var arguments = ParseFunctionArguments(false, variableMap);

			if (!CurrentTokenIs(TokenType.RightParenthesis)) {
				throw "Missing closing parenthesis for function call";
			}
			_position++; // consume ')'

			return new FunctionExpression(functionToken, arguments);
		}

		if (CurrentTokenIs(TokenType.FunctionDefinition)) {
			var functionToken = _currentTokens[_position++]; // Get the function token

			if (CurrentTokenIs(TokenType.LeftParenthesis)) {
				_position++; // consume '('
				var arguments = ParseDefinitionArguments();
				var name = functionToken.tokenBuffer;
				var definition = new FunctionDefinition(name);
				variableMap.Functions[name] = definition;
				definition.args = arguments;
				_position++; // consume ')'
			}

			if (!CurrentTokenIs(TokenType.LeftScope)) {
				throw "Expected '{' after function";
			}
			_position++; // consume '{'

			// Parse function contents
			var contents = ParseFunctionArguments(true, variableMap);

			if (!CurrentTokenIs(TokenType.RightScope)) {
				throw "Missing closing scope for function call";
			}
			_position++; // consume '}'

			return new FunctionDefinitionExpression(functionToken, contents);
		}

		if (CurrentTokenIs(TokenType.ForLoop)) {
			_position++; // consume 'for'
			var definition:Expression;
			var condition:Expression;
			var suffix:Expression;
			if (CurrentTokenIs(TokenType.LeftParenthesis)) {
				_position++; // consume '('
				definition = ParseExpression(variableMap);
				if (CurrentTokenIs(TokenType.SemiColon)) {
					_position++; // consume ';'
				}
				condition = ParseExpression(variableMap);
				if (CurrentTokenIs(TokenType.SemiColon)) {
					_position++; // consume ';'
				}
				suffix = ParseExpression(variableMap);
				_position++; // consume ')'
			} else {
				throw "Expected '(' after for loop. Missing definition, condition, and suffix!";
			}

			if (!CurrentTokenIs(TokenType.LeftScope)) {
				throw "Expected '{' after for loop";
			}
			_position++; // consume '{'

			// Parse function contents
			var contents = ParseFunctionArguments(true, variableMap);

			if (!CurrentTokenIs(TokenType.RightScope)) {
				throw "Missing closing scope for loop";
			}
			_position++; // consume '}'

			return new ForLoopExpression(definition, condition, suffix, contents);
		}

		if (CurrentTokenIs(TokenType.WhileLoop)) {
			_position++; // consume 'while'
			var condition:Expression;
			if (CurrentTokenIs(TokenType.LeftParenthesis)) {
				_position++; // consume '('
				condition = ParseExpression(variableMap);
				_position++; // consume ')'
			} else {
				throw "Expected '(' after while loop. Missing condition!";
			}

			if (!CurrentTokenIs(TokenType.LeftScope)) {
				throw "Expected '{' after while loop";
			}
			_position++; // consume '{'

			// Parse function contents
			var contents = ParseFunctionArguments(true, variableMap);

			if (!CurrentTokenIs(TokenType.RightScope)) {
				throw "Missing closing scope for loop";
			}
			_position++; // consume '}'

			return new WhileLoopExpression(condition, contents);
		}

		if (CurrentTokenIs(TokenType.Definition) || CurrentTokenIs(TokenType.Assignment)) {
			var definitionToken = _currentTokens[_position];
			_position++;
			var assignment = ParseExpression(variableMap);
			return new AssignmentExpression(definitionToken, assignment);
		}

		if (CurrentTokenIs(TokenType.Variable)) {
			var variableToken = _currentTokens[_position];
			_position++;

			switch (_position >= _currentTokens.length ? TokenType.Variable : _currentTokens[_position].type) {
				case TokenType.Increment:
					_position++; // Consume Increment
					return new IncrementVariableExpression(variableToken);

				case TokenType.Decrement:
					_position++; // Consume Decrement
					return new DecrementVariableExpression(variableToken);

				case TokenType.AdditionAssignment:
					_position++; // Consume +=
					var addExpression = ParseExpression(variableMap);
					return new AdditionAssignmentExpression(variableToken, addExpression);

				case TokenType.SubtractionAssignment:
					_position++; // Consume +=
					var subExpression = ParseExpression(variableMap);
					return new SubtractionAssignmentExpression(variableToken, subExpression);

				default:
					return new VariableExpression(variableToken);
			}
		}

		if (CurrentTokenIs(TokenType.FunctionArgument)) {
			var token = _currentTokens[_position];
			_position++;
			return new NilExpression(token);
		}

		if (CurrentTokenIs(TokenType.Return)) {
			_position++;
			var ret = ParseExpression(variableMap);
			return new ReturnExpression(ret);
		}

		throw 'Unexpected token ${_currentTokens[_position].type}';
	}

	private function ParseDefinitionArguments():Array<String> {
		var arguments = new Array<String>();

		var checks:Int = 0;

		// Parse comma-separated list of arguments
		while (_position < _currentTokens.length && !CurrentTokenIs(TokenType.RightParenthesis) && checks < 30) {
			checks++;
			var argument = _currentTokens[_position++];
			arguments.push(argument.tokenBuffer);

			if (CurrentTokenIs(TokenType.Comma)) {
				_position++; // consume ','
			}
		}

		return arguments;
	}

	private function ParseFunctionArguments(scoped:Bool, variableMap:AscentVariableMap):Array<Expression> {
		var arguments = new Array<Expression>();

		var checks:Int = 0;

		// Parse comma-separated list of arguments
		while (!CurrentTokenIs(scoped ? TokenType.RightScope : TokenType.RightParenthesis) && checks < 30) {
			LoadNextContainer();
			if (CurrentTokenIs(scoped ? TokenType.RightScope : TokenType.RightParenthesis))
				break;
			checks++;
			var argument = ParseExpression(variableMap);
			arguments.push(argument);

			if (CurrentTokenIs(TokenType.Comma)) {
				_position++; // consume ','
			}
		}

		return arguments;
	}

	private function CurrentTokenIs(type:TokenType):Bool {
		return _position < _currentTokens.length && _currentTokens[_position].type == type;
	}

	private function NextTokenIs(type:TokenType):Bool {
		return _position + 1 < _currentTokens.length && _currentTokens[_position + 1].type == type;
	}
}

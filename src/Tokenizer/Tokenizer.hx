package tokenizer;

import haxe.xml.Access;
import haxe.MainLoop.MainEvent;
import haxe.display.JsonModuleTypes.JsonFunctionArgument;
import functions.AscentFunctions;
import utility.Utility;
import utility.StringReader;
import parser.FunctionDefinition;
import tokenizer.Token.TokenType;

abstract class Tokenizer {
	public abstract function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
		scope:String):Token;

	public abstract function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
		scope:String, existingTokens:List<Token>):Bool;
}

class SingleCharTokenizer extends Tokenizer {
	public var tokenType:TokenType;
	public var tokenChar:Int;
	public var hasOperand:Bool;

	public function new(tokenChar:Int, tokenType:TokenType, hasOperand:Bool = false) {
		this.tokenType = tokenType;
		this.tokenChar = tokenChar;
		this.hasOperand = hasOperand;
	}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		if (this.hasOperand && reader._position >= reader._length) {
			throw "Expected operand after " + String.fromCharCode(this.tokenChar);
		}
		return new Token(this.tokenType, reader.Read());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		return peekChar == tokenChar;
	}
}

class SubtractionTokenizer extends Tokenizer {
	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		if (reader._position >= reader._length) {
			throw "Expected operand after -";
		}
		return new Token(TokenType.Subtraction, reader.Read());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		if (existingTokens != null && existingTokens.length > 0) {
			var lastToken:Token = existingTokens.last();
			if (lastToken.type == TokenType.Constant || lastToken.type == TokenType.Variable || lastToken.type == TokenType.Query) {
				return peekChar == '-'.charCodeAt(0);
			}
		}
		return false;
	}
}

class NumberTokenizer extends Tokenizer {
	public function new() {}

	private function IsNumber(peekChar:Int):Bool {
		return peekChar >= '0'.charCodeAt(0) && peekChar <= '9'.charCodeAt(0);
	}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		var stringBuf:StringBuf = new StringBuf();
		while (IsNumber(reader.PeekChar())) {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		return new Token(TokenType.Constant, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		return IsNumber(peekChar);
	}
}

class WordMatchTokenizer extends Tokenizer {
	public var tokenType:TokenType;
	public var word:String;

	public function new(word:String, tokenType:TokenType) {
		this.word = word;
		this.tokenType = tokenType;
	}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		return new Token(this.tokenType, reader.ReadLen(word.length));
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		if (peekChar == word.charCodeAt(0) && reader._position < reader._length) {
			var stringBuf:StringBuf = new StringBuf();

			for (i in 0...word.length) {
				if (word.charCodeAt(i) == reader.PeekChar()) {
					stringBuf.add(reader.Read());
					continue;
				}
				break;
			}

			if (stringBuf.toString() == word) {
				return true;
			}
		}
		return false;
	}
}

class QueryTokenizer extends Tokenizer {
	var qTokenizer:Tokenizer = new SingleCharTokenizer('q'.charCodeAt(0), TokenType.Query, false);
	var queryTokenizer:Tokenizer = new WordMatchTokenizer('query', TokenType.Query);

	public static function ContinueFeedingQuery(char:Int):Bool {
		return (char >= 'a'.charCodeAt(0) && char <= 'z'.charCodeAt(0)) || (char >= 'A'.charCodeAt(0) && char <= 'Z'.charCodeAt(0));
	}

	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		var stringBuf:StringBuf = new StringBuf();
		while (ContinueFeedingQuery(reader.PeekChar())) {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		return new Token(TokenType.Query, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		var qMatch:Bool = qTokenizer.IsMatch(peekChar, reader, variableDefintions, functionDefinitions, scope, existingTokens);
		var queryMatch:Bool = queryTokenizer.IsMatch(peekChar, reader, variableDefintions, functionDefinitions, scope, existingTokens);
		if ((queryMatch || qMatch) && reader.Read() == '.') {
			return true;
		}
		return false;
	}
}

class DefinitionTokenizer extends Tokenizer {
	var letTokenizer:Tokenizer = new WordMatchTokenizer('let', TokenType.Definition);

	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		reader.ReadLen(3);

		var stringBuf:StringBuf = new StringBuf();
		while (reader.Peek() != "=") {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		variableDefintions.add(stringBuf.toString());
		return new Token(TokenType.Definition, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		return letTokenizer.IsMatch(peekChar, reader, variableDefintions, functionDefinitions, scope, existingTokens);
	}
}

class AssignmentTokenizer extends Tokenizer {
	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		var stringBuf:StringBuf = new StringBuf();
		while (reader.Peek() != "=") {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		return new Token(TokenType.Assignment, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		if (!Utility.searchForPotential(peekChar, variableDefintions))
			return false;

		var stringBuf:StringBuf = new StringBuf();
		while (reader.Peek() != "=") {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		return return Lambda.exists(variableDefintions, function(x:String) {
			return x == stringBuf.toString();
		});
	}
}

class VariableTokenizer extends Tokenizer {
	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		var functionDefinition = Lambda.find(functionDefinitions, function(x:FunctionDefinition) {
			return x.name == scope;
		});
		var args = functionDefinition?.args == null ? [] : functionDefinition.args;

		var stringBuf:StringBuf = new StringBuf();
		Sys.println(reader.Peek());
		while (Utility.searchForPotential(reader.PeekChar(), variableDefintions)
			|| Utility.searchForPotentialArray(reader.PeekChar(), args)) {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		return new Token(TokenType.Variable, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		var functionDefinition = Lambda.find(functionDefinitions, function(x:FunctionDefinition) {
			return x.name == scope;
		});
		var args = functionDefinition?.args == null ? [] : functionDefinition.args;
		if (!Utility.searchForPotential(peekChar, variableDefintions) && !Utility.searchForPotentialArray(peekChar, args))
			return false;

		var stringBuf:StringBuf = new StringBuf();
		var check:Int = 0;
		while (!Lambda.exists(variableDefintions, function(x:String) {
			return x == stringBuf.toString();
		}) && !Lambda.exists(args, function(x:String) {
			return x == stringBuf.toString();
		}) && check < 25) {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}

		return Lambda.exists(variableDefintions, function(x:String) {
			return x == stringBuf.toString();
		}) || Lambda.exists(args, function(x:String) {
			return x == stringBuf.toString();
		});
	}
}

class FunctionTokenizer extends Tokenizer {
	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		var functionNames = functionDefinitions.map(function(x:FunctionDefinition) {
			return x.name;
		});
		var stringBuf:StringBuf = new StringBuf();
		while (reader.Peek() != "(") {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
        Sys.println(stringBuf.toString() + ' ' + reader.Peek());
		return new Token(TokenType.Function, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		var functionNames = functionDefinitions.map(function(x:FunctionDefinition) {
			return x.name;
		});
		if (!AscentFunctions.SearchAnyFunctions(peekChar) && !Utility.searchForPotential(peekChar, functionNames))
			return false;

		var stringBuf:StringBuf = new StringBuf();
		while (reader.Peek() != "(") {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}

		return AscentFunctions.GetFunction(stringBuf.toString()) != null || Lambda.exists(functionNames, function(f:String) {
			return f == stringBuf.toString();
		});
	}
}

class FunctionDefinitionTokenizer extends Tokenizer {
	var functionTokenizer:Tokenizer = new WordMatchTokenizer('function', TokenType.FunctionDefinition);

	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		functionTokenizer.GetToken(peekChar, reader, variableDefintions, functionDefinitions, scope);
		var stringBuf:StringBuf = new StringBuf();
		while (reader.Peek() != "(" && reader.Peek() != "{") {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		functionDefinitions.add(new FunctionDefinition(stringBuf.toString()));
		return new Token(TokenType.FunctionDefinition, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		return functionTokenizer.IsMatch(peekChar, reader, variableDefintions, functionDefinitions, scope, existingTokens);
	}
}

class ForLoopTokenizer extends Tokenizer {
	var forTokenizer:Tokenizer = new WordMatchTokenizer('for', TokenType.ForLoop);

	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		return forTokenizer.GetToken(peekChar, reader, variableDefintions, functionDefinitions, scope);
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		return forTokenizer.IsMatch(peekChar, reader, variableDefintions, functionDefinitions, scope, existingTokens);
	}
}

class WhileLoopTokenizer extends Tokenizer {
	var whileTokenizer:Tokenizer = new WordMatchTokenizer('while', TokenType.WhileLoop);

	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		return whileTokenizer.GetToken(peekChar, reader, variableDefintions, functionDefinitions, scope);
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		return whileTokenizer.IsMatch(peekChar, reader, variableDefintions, functionDefinitions, scope, existingTokens);
	}
}

class FunctionArgumentTokenizer extends Tokenizer {
	var name:String = "";

	public function new() {}

	public function GetToken(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>,
			scope:String):Token {
		var stringBuf:StringBuf = new StringBuf();
		while (reader.Peek() != "," && reader.Peek() != ")") {
			stringBuf.add(reader.Read());
			if (reader._position >= reader._length) {
				break;
			}
		}
		var functionDefinition = Lambda.find(functionDefinitions, function(x:FunctionDefinition) {
			return x.name == name;
		});
		functionDefinition.args.push(stringBuf.toString());
		name = stringBuf.toString();
		return new Token(TokenType.FunctionArgument, stringBuf.toString());
	}

	public function IsMatch(peekChar:Int, reader:StringReader, variableDefintions:List<String>, functionDefinitions:List<FunctionDefinition>, scope:String,
			existingTokens:List<Token>):Bool {
		var toks:Array<Token> = [];
		for (token in existingTokens) {
			toks.push(token);
		}

		var allowedTokens:Array<TokenType> = [TokenType.LeftParenthesis, TokenType.Comma, TokenType.FunctionArgument];
		var back = 0;

		while (toks != null && toks.length > back && allowedTokens.indexOf(toks[toks.length - back - 1].type) != -1) {
			back++;
		}

		if (toks == null || toks.length < back + 1)
			return false;

		var def = toks[toks.length - back - 1];
		if (def.type == TokenType.FunctionDefinition) {
			// Assuming `name` is a field in your class
			this.name = def.tokenBuffer;
			return true;
		}

		return false;
	}
}

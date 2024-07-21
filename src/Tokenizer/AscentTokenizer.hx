package tokenizer;

import utility.StringReader;
import haxe.ds.GenericStack;

class AscentTokenizer {
    static var tokenizers: List<Tokenizer>;

    public static function Tokenize(expression: String): List<Token> {
        var variableDefinitions: List<String> = new List<String>();
        var tokens: List<Token> = new List<Token>();
        var scope: GenericStack<String> = new GenericStack<String>();
        scope.add("GLOBAL");

        var trimmedExpression: String = expression; //TODO - trim

        var reader: StringReader = new StringReader(trimmedExpression);

        

        return tokens;
    }
}

abstract class Tokenizer {
    public abstract function GetToken(): Token;
    public abstract function IsMatch(): Bool;
}

class SingleCharTokenizer extends Tokenizer {
    public var tokenType: TokenType;
    public var tokenChar: String;
    public var hasOperand: Bool;

    public function new(tokenChar: String, tokenType: TokenType, hasOperand: Bool = false) {
        this.tokenType = tokenType;
        this.tokenChar = tokenChar;
        this.hasOperand = hasOperand;
    }

    public function GetToken(): Token {
        return new Token(this.tokenType, this.tokenChar);
    }

    public function IsMatch(): Bool {
        return false;
    }
}

enum TokenType {
    Query();
    Constant();
    Increment();
    Decrement();
    AdditionAssignment();
    SubtractionAssignment();
    Addition();
    Subtraction();
    Multiplication();
    Division();
    Modulus();
    LeftParenthesis();
    RightParenthesis();
    LeftBracket();
    RightBracket();
    Pow();
    LesserThen();
    GreaterThan();
    TernaryConditional();
    Colon();
    Comma();
    Definition();
    Assignment();
    Variable();
    SemiColon();
    Function();
    FunctionDefinition();
    LeftScope();
    RightScope();
    FunctionArgument();
    ForLoop();
    WhileLoop();
    Return();
}

class Token {
    public var type: TokenType;
    public var tokenBuffer: String = "";

    public function new(type: TokenType, tokenBuffer: String) {
        this.type = type;
        this.tokenBuffer = tokenBuffer;
    }
}
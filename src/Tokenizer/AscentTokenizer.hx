package tokenizer;

import tokenizer.Tokenizer.WhileLoopTokenizer;
import tokenizer.Tokenizer.ForLoopTokenizer;
import tokenizer.Tokenizer.SingleCharTokenizer;
import tokenizer.Tokenizer.SubtractionTokenizer;
import tokenizer.Tokenizer.NumberTokenizer;
import tokenizer.Tokenizer.QueryTokenizer;
import tokenizer.Tokenizer.WordMatchTokenizer;
import tokenizer.Tokenizer.AssignmentTokenizer;
import tokenizer.Tokenizer.DefinitionTokenizer;
import tokenizer.Tokenizer.ForLoopTokenizer;
import tokenizer.Tokenizer.WhileLoopTokenizer;
import tokenizer.Tokenizer.FunctionDefinitionTokenizer;
import tokenizer.Tokenizer.FunctionTokenizer;
import tokenizer.Tokenizer.FunctionArgumentTokenizer;
import tokenizer.Tokenizer.VariableTokenizer;
import tokenizer.Token.TokenType;
import parser.FunctionDefinition;
import utility.StringReader;
import haxe.ds.GenericStack;

class AscentTokenizer {

    static function cc(char: String): Int {
        return char.charCodeAt(0);
    }

    static var tokenizers: Array<Tokenizer> = [
        new QueryTokenizer(),
        new WordMatchTokenizer("++", TokenType.Increment),
        new WordMatchTokenizer("--", TokenType.Decrement),
        new WordMatchTokenizer("+=", TokenType.AdditionAssignment),
        new WordMatchTokenizer("-=", TokenType.SubtractionAssignment),
        new SingleCharTokenizer(cc("+"), TokenType.Addition, true),
        new SubtractionTokenizer(),
        new SingleCharTokenizer(cc("*"), TokenType.Multiplication, true),
        new SingleCharTokenizer(cc("/"), TokenType.Division, true),
        new SingleCharTokenizer(cc("^"), TokenType.Pow, true),
        new SingleCharTokenizer(cc("%"), TokenType.Modulus, true),
        new SingleCharTokenizer(cc("("), TokenType.LeftParenthesis, true),
        new SingleCharTokenizer(cc(")"), TokenType.RightParenthesis, true),
        new SingleCharTokenizer(cc("["), TokenType.LeftBracket, true),
        new SingleCharTokenizer(cc("]"), TokenType.RightBracket, true),
        new SingleCharTokenizer(cc("<"), TokenType.LesserThen, true),
        new SingleCharTokenizer(cc(">"), TokenType.GreaterThan, true),
        new SingleCharTokenizer(cc("?"), TokenType.TernaryConditional, true),
        new SingleCharTokenizer(cc(":"), TokenType.Colon, true),
        new SingleCharTokenizer(cc(";"), TokenType.SemiColon, false),
        new SingleCharTokenizer(cc(","), TokenType.Comma, false),
        new SingleCharTokenizer(cc("{"), TokenType.LeftScope, false),
        new SingleCharTokenizer(cc("}"), TokenType.RightScope, false),
        new WordMatchTokenizer("return", TokenType.Return),
        new ForLoopTokenizer(),
        new WhileLoopTokenizer(),
        new FunctionDefinitionTokenizer(),
        new FunctionArgumentTokenizer(),
        new FunctionTokenizer(),
        new DefinitionTokenizer(),
        new AssignmentTokenizer(),
        new VariableTokenizer(),
        new NumberTokenizer(),
    ];

    public static function Tokenize(expression: String): List<Token> {
        var variableDefinitions: List<String> = new List<String>();
        var functionDefinitions: List<FunctionDefinition> = new List<FunctionDefinition>();
        var tokens: List<Token> = new List<Token>();
        var scope: GenericStack<String> = new GenericStack<String>();
        scope.add("GLOBAL");

        var trimmedExpression = expression.split('').filter(x -> !StringTools.isSpace(x, 0)).join('');
        var strLength: Int = trimmedExpression.length;
        var reader: StringReader = new StringReader(trimmedExpression);

        while (reader._position < strLength) {
            var peek: Int = reader.PeekChar();
            var succeeded: Bool = false;
            for (tokenizer in tokenizers) {
                var position: Int = reader._position;
                if (tokenizer.IsMatch(peek, reader, variableDefinitions, functionDefinitions, scope.first(), tokens)) {
                    reader._position = position;
                    tokens.add(tokenizer.GetToken(peek, reader, variableDefinitions, functionDefinitions, scope.first()));
                    succeeded = true;
                    break;
                }
                reader._position = position;
            }
            if (!succeeded) {
                reader.Read();
            }
        }

        return tokens;
    }
}
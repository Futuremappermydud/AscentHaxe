import parser.AscentParser;
import parser.FunctionDefinition;
import parser.Expression;
import utility.Utility;
import splitter.AscentSplitter;
import tokenizer.AscentTokenizer;

@:keep
class AscentEvaluator {
	private static var cachedExpressions: Map<String, CacheData> = new Map<String, CacheData>();

	public static function Evaluate(expression: String, ascentVariableMap: AscentVariableMap, cache: Bool = true, debug: Bool = false): Float {
		if (ascentVariableMap == null) {
			ascentVariableMap = new AscentVariableMap(new Map<String, Float>());
		}
		ascentVariableMap.Variables.clear();
		ascentVariableMap.Functions.clear();
		var toEvaluate: Array<Expression> = new Array<Expression>();
		if (cache && Utility.searchMapKeysForString(expression, cachedExpressions.keys())) {
			toEvaluate = cachedExpressions[expression].expressions;
			ascentVariableMap.Functions = cachedExpressions[expression].functions;
		} else {
			var tokens = AscentTokenizer.Tokenize(expression);

			if (debug) {
				for (token in tokens) {
					Sys.println('Token: ${token.type} - ${token.tokenBuffer}');
				}
			}

			var container = AscentSplitter.Split(tokens);
			if (debug) {
				Utility.PrintTokenContainer(container);
				Sys.println("\n");
			}

			var parser = new AscentParser(container);

			var parsedExpressions = parser.Parse(ascentVariableMap);

			if (debug) {
				Sys.println('Parsed ${parsedExpressions.length} Expressions');
			}
			
			for (parsedExpression in parsedExpressions) {
				if (debug) {

				}

				toEvaluate.push(parsedExpression);
			}

			if (cache) {
				cachedExpressions.set(expression, new CacheData(toEvaluate, ascentVariableMap.Functions));
			}
		}
		var result: Float = 0;
		for (expression in toEvaluate) {
			var eval = expression.Evaluate(ascentVariableMap);
			if (eval != null) {
				result = eval;
			}
		}
        return result;
	}
}

class CacheData {
	public var expressions: Array<Expression>;
	public var functions: Map<String, FunctionDefinition>;

	public function new(expressions: Array<Expression>, functions: Map<String, FunctionDefinition>) {
		this.expressions = expressions;
		this.functions = functions;
	}
}
import tokenizer.AscentTokenizer;

@:keep
class AscentEvaluator {
	public static function Evaluate(expression:String):Float {
		Sys.println('Running Expression... [${expression}]');
		AscentTokenizer.Tokenize(expression);
        return 0;
	}
}
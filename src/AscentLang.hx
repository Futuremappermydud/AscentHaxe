import AscentEvaluator;

class AscentLang {
	static function main() {
		#if hl
		Sys.println("Haxe is great!");
		Sys.println(AscentEvaluator.Evaluate("2 * 2", null, true, true));
		#end
	}
}
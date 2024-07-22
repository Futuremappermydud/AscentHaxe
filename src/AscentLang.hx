import AscentEvaluator;

class AscentLang {
	static function main() {
		#if hl
		Sys.println("Haxe is great!");
		Sys.println(AscentEvaluator.Evaluate("
function add(a, b) {
	return a + b;
}
function add2(a, b) {
	return a + b;
}
add(1, 2) + add2(5, 7);
		", null, true, true));
		#end
	}
}

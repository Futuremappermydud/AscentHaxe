import haxe.Timer;
import AscentEvaluator;

class AscentLang {
	static function main() {
		#if (hl || cpp)
		var expression = "
		function test(add1, add2) {
			return add1 + add2
		};
		
		function k(a) {
			return a * 2
		};
		
		return k(test(test(2, 1), 2)) ^ 3";
		
		Sys.println(AscentEvaluator.Evaluate(expression, null, true, false));
		#end
	}
}

package utility;

import tokenizer.Token.TokenType;
import splitter.TokenContainer;
import splitter.TokenContainer.MultipleTokenContainer;
import splitter.TokenContainer.SingleTokenContainer;

class Utility {
    public static function searchForPotential(c: Int, strings: List<String>): Bool {
        return Lambda.exists(strings, function(x) {
            return StringTools.startsWith(x, String.fromCharCode(c));
        });
    }

    public static function searchForPotentialArray(c: Int, strings: Array<String>): Bool {
        return Lambda.exists(strings, function(x) {
            return StringTools.startsWith(x, String.fromCharCode(c));
        });
    }

    public static function searchMapKeysForString(c: String, map: Iterator<String>): Bool {
        var arr: Array<String> = new Array<String>();
        for (key in map)
            arr.push(key);
        return Lambda.exists(arr, function(x) {
            return x == c;
        });
    }

    public static function searchMapKeysForTokenType(c: TokenType, map: Iterator<TokenType>): Bool {
        var arr: Array<TokenType> = new Array<TokenType>();
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

    private static function GetIndent(indentLevel: Int): String
	{
		return StringTools.rpad("", " ", indentLevel*2);
	}

	public static function PrintTokenContainer(container: TokenContainer, indentLevel: Int = 0)
	{
		if (container is SingleTokenContainer)
		{
            var single: SingleTokenContainer = cast container;
			Sys.println('${GetIndent(indentLevel)}SingleTokenContainer:');
			Sys.print('${GetIndent(indentLevel + 2)}');
			for (i in 0...single.expression.length)
            {
                Sys.print('${single.expression[i].type}, ');
            }
			Sys.print("\n");
		}
		else if (container is MultipleTokenContainer)
		{
            var multiple: MultipleTokenContainer = cast container;
			Sys.println('${GetIndent(indentLevel)}MultipleTokenContainer: ${multiple.tokenContainers.length}');
			for (i in 0...multiple.tokenContainers.length)
			{
				PrintTokenContainer(multiple.tokenContainers[i], indentLevel + 2);
			}
		}
		else
		{
			throw "Invalid container type";
		}
	}
}
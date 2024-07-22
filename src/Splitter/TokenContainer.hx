package splitter;

import tokenizer.Token;

abstract class TokenContainer {
	public var parentContainer:TokenContainer;

	public function new(parentContainer:TokenContainer) {
		this.parentContainer = parentContainer;
	}
}

class SingleTokenContainer extends TokenContainer {
	public var expression:Array<Token>;

	public function new(parentContainer:TokenContainer, expression:Array<Token>) {
		super(parentContainer);
		this.expression = expression;
	}
}

class MultipleTokenContainer extends TokenContainer {
	public var tokenContainers:Array<TokenContainer> = new Array<TokenContainer>();

	public function new(parentContainer:TokenContainer) {
		super(parentContainer);
	}
}

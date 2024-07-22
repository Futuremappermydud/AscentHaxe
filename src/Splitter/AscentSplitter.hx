package splitter;

import splitter.TokenContainer.MultipleTokenContainer;
import splitter.TokenContainer.SingleTokenContainer;
import tokenizer.Token;

class AscentSplitter {
    public static function Split(tokens: List<Token>): TokenContainer {
        var arrayTokens: Array<Token> = [];
        for (token in tokens) {
            arrayTokens.push(token);
        }

        var rootContainer = new MultipleTokenContainer(null);
        var _position = 0;
        var buffer = new Array<Token>();
        var currentScope: MultipleTokenContainer = rootContainer;
        var split = true;
        while (_position < arrayTokens.length) {
            var token = arrayTokens[_position];
            if (token.type == TokenType.LeftScope) {
                if (buffer.length > 0) {
                    buffer.push(token);
                    _position++;
                    token = arrayTokens[_position];
                    currentScope?.tokenContainers.push(new SingleTokenContainer(currentScope, buffer));
                    buffer = [];
                }
            }

            if (token.type == TokenType.RightScope) {
                if (buffer.length > 0) {
                    currentScope?.tokenContainers.push(new SingleTokenContainer(currentScope, buffer));
                    buffer = [];
                }
                currentScope.tokenContainers.push(new SingleTokenContainer(currentScope, [token]));
                currentScope = cast currentScope.parentContainer;
            }

            if (token.type == TokenType.FunctionDefinition) {
                var newScope = new MultipleTokenContainer(currentScope);
                currentScope.tokenContainers.push(newScope);
                currentScope = newScope;
            }

            if (token.type == TokenType.ForLoop) {
                var newScope = new MultipleTokenContainer(currentScope);
                currentScope.tokenContainers.push(newScope);
                currentScope = newScope;
            }

            if (token.type == TokenType.WhileLoop) {
                var newScope = new MultipleTokenContainer(currentScope);
                currentScope.tokenContainers.push(newScope);
                currentScope = newScope;
            }

            if (token.type == TokenType.LeftParenthesis) {
                split = false;
            }
            
            if (token.type == TokenType.RightParenthesis) {
                split = true;
            }

            if (token.type != TokenType.SemiColon) {
                if (token.type != RightScope) {
                    buffer.push(token);
                }
            } else {
                if (split) {
                    currentScope.tokenContainers.push(new SingleTokenContainer(currentScope, buffer));
                    buffer = [];
                } else {
                    buffer.push(token);
                }
            }
            _position++;
        }
        if (buffer.length > 0) {
            currentScope.tokenContainers.push(new SingleTokenContainer(currentScope, buffer));
        }
        return rootContainer;
    }
}
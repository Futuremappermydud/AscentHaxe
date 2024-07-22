package tokenizer;

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
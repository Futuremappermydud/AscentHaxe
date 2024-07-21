#include "AscentLanguage.hpp"
#include "AscentLang.h"
#include "AscentEvaluator.h"

extern "C" void __hxcpp_lib_main();

void AscentLanguage::initAscent() {
    __hxcpp_lib_main();
}

float AscentLanguage::Evaluate(std::string expression) {
    auto result = AscentEvaluator_obj::Evaluate(String::create(expression.c_str()));
    return result;
}
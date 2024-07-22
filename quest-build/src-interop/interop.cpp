#include "AscentLanguage.hpp"
#include "AscentLang.h"
#include "AscentEvaluator.h"
#include "AscentVariableMap.h"
#include <haxe/ds/StringMap.h>
#include <hxcpp.h>

extern "C" void __hxcpp_lib_main();

static bool init = false;
void initAscent() {
    if (init) return;
    init = true;
    __hxcpp_lib_main();
}

float AscentLanguage::Evaluate(std::string expression) {
    initAscent();
    auto result = AscentEvaluator_obj::Evaluate(String::create(expression.c_str()), null(), true, true);
    return result;
}
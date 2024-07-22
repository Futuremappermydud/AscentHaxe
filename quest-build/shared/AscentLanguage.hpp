#pragma once
#include "AscentVariableMap.hpp"

#include <string>
namespace AscentLanguage {
    float Evaluate(std::string expression, AscentVariableMap* variableMap, bool cache, debug);
}
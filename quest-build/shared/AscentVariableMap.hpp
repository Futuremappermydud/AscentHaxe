#pragma once
#include <map>
#include <string>

namespace AscentLanguage {
    class AscentVariableMap {
    public:
        std::map<std::string, float> queryVariables;
        std::map<std::string, float> variables;
    };
}
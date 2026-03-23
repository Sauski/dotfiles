#pragma once

#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <regex>
#include <optional>
#include <iostream>
#include "../lib/json/json.hpp"

namespace quickbuild {

enum class Scope {
    LINE,
    FILE,
    PROJECT
};

struct Pattern {
    std::regex regex;
    std::map<std::string, int> groups;
    Scope scope;
};

class Config {
public:
    static std::optional<std::vector<Pattern>> load(const std::string& json_path) {
        std::ifstream file(json_path);
        if (!file.is_open()) {
            std::cerr << "Error: Failed to open config file: " << json_path << std::endl;
            return std::nullopt;
        }

        nlohmann::json config;
        try {
            file >> config;
        } catch (const nlohmann::json::exception& e) {
            std::cerr << "Error: Failed to parse JSON: " << e.what() << std::endl;
            return std::nullopt;
        }

        return parse_patterns(config);
    }

private:
    static std::optional<std::vector<Pattern>> parse_patterns(const nlohmann::json& config) {
        if (!config.contains("patterns")) {
            std::cerr << "Error: No 'patterns' key in config" << std::endl;
            return std::nullopt;
        }

        if (!config["patterns"].is_array()) {
            std::cerr << "Error: 'patterns' must be an array" << std::endl;
            return std::nullopt;
        }

        const auto& patterns_array = config["patterns"];
        if (patterns_array.empty()) {
            std::cerr << "Error: No patterns defined in config" << std::endl;
            return std::nullopt;
        }

        std::vector<Pattern> patterns;
        for (const auto& pattern_obj : patterns_array) {
            auto pattern = parse_pattern(pattern_obj);
            if (!pattern) {
                return std::nullopt;
            }
            patterns.push_back(*pattern);
        }

        return patterns;
    }

    static std::optional<Pattern> parse_pattern(const nlohmann::json& obj) {
        Pattern pattern;

        // Extract regex
        if (!obj.contains("regex")) {
            std::cerr << "Error: Pattern missing 'regex' field" << std::endl;
            return std::nullopt;
        }
        if (!obj["regex"].is_string()) {
            std::cerr << "Error: 'regex' must be a string" << std::endl;
            return std::nullopt;
        }

        std::string regex_str = obj["regex"].get<std::string>();
        try {
            pattern.regex = std::regex(regex_str, std::regex::ECMAScript);
        } catch (const std::regex_error& e) {
            std::cerr << "Error: Invalid regex: " << e.what() << std::endl;
            return std::nullopt;
        }

        // Extract scope (default: line-level)
        pattern.scope = Scope::LINE;
        if (obj.contains("scope")) {
            if (!obj["scope"].is_string()) {
                std::cerr << "Error: 'scope' must be a string" << std::endl;
                return std::nullopt;
            }
            std::string scope_str = obj["scope"].get<std::string>();
            if (scope_str == "line") {
                pattern.scope = Scope::LINE;
            } else if (scope_str == "file") {
                pattern.scope = Scope::FILE;
            } else if (scope_str == "project") {
                pattern.scope = Scope::PROJECT;
            } else {
                std::cerr << "Error: Invalid scope '" << scope_str
                          << "' (must be 'line', 'file', or 'project')" << std::endl;
                return std::nullopt;
            }
        }

        // Extract groups
        if (!obj.contains("groups")) {
            std::cerr << "Error: Pattern missing 'groups' field" << std::endl;
            return std::nullopt;
        }
        if (!obj["groups"].is_object()) {
            std::cerr << "Error: 'groups' must be an object" << std::endl;
            return std::nullopt;
        }

        const auto& groups_obj = obj["groups"];
        for (auto it = groups_obj.begin(); it != groups_obj.end(); ++it) {
            if (!it.value().is_number_integer()) {
                std::cerr << "Error: Group value must be an integer: " << it.key() << std::endl;
                return std::nullopt;
            }
            pattern.groups[it.key()] = it.value().get<int>();
        }

        // Validate required fields based on scope
        std::vector<std::string> required_fields;
        if (pattern.scope == Scope::LINE) {
            required_fields = {"file", "line", "severity", "message"};
        } else if (pattern.scope == Scope::FILE) {
            required_fields = {"file", "severity", "message"};
        } else if (pattern.scope == Scope::PROJECT) {
            required_fields = {"severity", "message"};
        }

        for (const auto& field : required_fields) {
            if (pattern.groups.find(field) == pattern.groups.end()) {
                std::cerr << "Error: Pattern missing required group: " << field << std::endl;
                return std::nullopt;
            }
        }

        return pattern;
    }
};

} // namespace quickbuild

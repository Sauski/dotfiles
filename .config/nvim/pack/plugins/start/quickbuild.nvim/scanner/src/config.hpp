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

struct MultilineConfig {
    std::regex block_start;
    std::regex block_end;
    std::string join;
    std::optional<std::string> severity;
    std::vector<int> message_parts;
};

struct Pattern {
    std::regex regex;
    std::map<std::string, int> groups;
    std::optional<MultilineConfig> multiline;
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
            std::cerr << "Error: Pattern missing 'regex' field"
                      << std::endl;
            return std::nullopt;
        }
        if (!obj["regex"].is_string()) {
            std::cerr << "Error: 'regex' must be a string" << std::endl;
            return std::nullopt;
        }

        std::string regex_str = obj["regex"].get<std::string>();
        try {
            pattern.regex = std::regex(regex_str,
                                       std::regex::ECMAScript);
        } catch (const std::regex_error& e) {
            std::cerr << "Error: Invalid regex: " << e.what()
                      << std::endl;
            return std::nullopt;
        }

        // Extract groups
        if (!obj.contains("groups")) {
            std::cerr << "Error: Pattern missing 'groups' field"
                      << std::endl;
            return std::nullopt;
        }
        if (!obj["groups"].is_object()) {
            std::cerr << "Error: 'groups' must be an object"
                      << std::endl;
            return std::nullopt;
        }

        const auto& groups_obj = obj["groups"];
        for (auto it = groups_obj.begin(); it != groups_obj.end();
             ++it) {
            if (!it.value().is_number_integer()) {
                std::cerr << "Error: Group value must be an integer: "
                          << it.key() << std::endl;
                return std::nullopt;
            }
            pattern.groups[it.key()] = it.value().get<int>();
        }

        // Parse optional multiline config
        if (obj.contains("multiline")) {
            auto ml = parse_multiline(obj["multiline"], pattern.groups);
            if (!ml) {
                return std::nullopt;
            }
            pattern.multiline = *ml;
        }

        // Validate required fields
        const std::vector<std::string> required_fields =
            {"file", "line", "severity", "message"};
        for (const auto& field : required_fields) {
            bool in_groups = pattern.groups.find(field) !=
                             pattern.groups.end();
            bool in_multiline = pattern.multiline &&
                                field == "severity" &&
                                pattern.multiline->severity.has_value();

            if (!in_groups && !in_multiline) {
                std::cerr << "Error: Pattern missing required group: "
                          << field << std::endl;
                return std::nullopt;
            }
        }

        return pattern;
    }

    static std::optional<MultilineConfig> parse_multiline(
        const nlohmann::json& obj,
        const std::map<std::string, int>& groups) {

        MultilineConfig config;

        // Required: block_start regex
        if (!obj.contains("block_start")) {
            std::cerr << "Error: Multiline missing 'block_start' field"
                      << std::endl;
            return std::nullopt;
        }
        if (!obj["block_start"].is_string()) {
            std::cerr << "Error: Multiline 'block_start' must be string"
                      << std::endl;
            return std::nullopt;
        }

        try {
            config.block_start = std::regex(
                obj["block_start"].get<std::string>(),
                std::regex::ECMAScript);
        } catch (const std::regex_error& e) {
            std::cerr << "Error: Invalid block_start regex: "
                      << e.what() << std::endl;
            return std::nullopt;
        }

        // Required: block_end regex
        if (!obj.contains("block_end")) {
            std::cerr << "Error: Multiline missing 'block_end' field"
                      << std::endl;
            return std::nullopt;
        }
        if (!obj["block_end"].is_string()) {
            std::cerr << "Error: Multiline 'block_end' must be string"
                      << std::endl;
            return std::nullopt;
        }

        try {
            config.block_end = std::regex(
                obj["block_end"].get<std::string>(),
                std::regex::ECMAScript);
        } catch (const std::regex_error& e) {
            std::cerr << "Error: Invalid block_end regex: "
                      << e.what() << std::endl;
            return std::nullopt;
        }

        // Optional: join string (default: " ")
        config.join = obj.value("join", " ");

        // Optional: severity (required if not in groups)
        if (obj.contains("severity")) {
            if (!obj["severity"].is_string()) {
                std::cerr << "Error: Multiline 'severity' must be string"
                          << std::endl;
                return std::nullopt;
            }
            config.severity = obj["severity"].get<std::string>();
        } else if (groups.find("severity") == groups.end()) {
            std::cerr << "Error: Multiline needs 'severity' field or "
                      << "severity in groups" << std::endl;
            return std::nullopt;
        }

        // Optional: message_parts
        if (obj.contains("message_parts")) {
            if (!obj["message_parts"].is_array()) {
                std::cerr << "Error: Multiline 'message_parts' must be "
                          << "array" << std::endl;
                return std::nullopt;
            }
            for (const auto& part : obj["message_parts"]) {
                if (!part.is_number_integer()) {
                    std::cerr << "Error: message_parts values must be "
                              << "integers" << std::endl;
                    return std::nullopt;
                }
                config.message_parts.push_back(part.get<int>());
            }
        }

        return config;
    }
};

} // namespace quickbuild

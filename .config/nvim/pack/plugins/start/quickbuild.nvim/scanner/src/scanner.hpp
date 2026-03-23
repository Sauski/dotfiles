#pragma once

#include <string>
#include <vector>
#include <regex>
#include <filesystem>
#include "config.hpp"

namespace quickbuild {

class Scanner {
public:
    explicit Scanner(std::vector<Pattern> patterns, const std::filesystem::path& working_dir)
        : patterns_(std::move(patterns)), working_dir_(working_dir) {}

    std::string scan_line(const std::string& line) {
        for (const auto& pattern : patterns_) {
            std::smatch match;
            if (std::regex_match(line, match, pattern.regex)) {
                return format_diagnostic(match, pattern);
            }
        }
        return "";
    }

private:
    std::vector<Pattern> patterns_;
    std::filesystem::path working_dir_;

    std::string format_diagnostic(const std::smatch& match,
                                  const Pattern& pattern) {
        std::string severity = extract_group(match, pattern.groups, "severity");
        std::string message = extract_group(match, pattern.groups, "message");

        if (pattern.scope == Scope::PROJECT) {
            return "PROJECT:0:0:" + severity + ":" + message;
        }

        std::string file = extract_group(match, pattern.groups, "file");
        std::string col = extract_group(match, pattern.groups, "col", "0");

        // Normalize path
        std::filesystem::path file_path(file);
        if (file_path.is_relative()) {
            file_path = working_dir_ / file_path;
        }
        file_path = std::filesystem::absolute(file_path);
        std::string normalized_path = file_path.generic_string();

        if (pattern.scope == Scope::FILE) {
            return normalized_path + ":0:" + col + ":" + severity + ":" + message;
        }

        // Scope::LINE
        std::string line = extract_group(match, pattern.groups, "line");
        return normalized_path + ":" + line + ":" + col + ":" + severity + ":" + message;
    }

    std::string extract_group(const std::smatch& match,
                              const std::map<std::string, int>& groups,
                              const std::string& key,
                              const std::string& default_value = "") {
        auto it = groups.find(key);
        if (it == groups.end()) {
            return default_value;
        }

        int index = it->second;
        if (index < 0 || static_cast<size_t>(index) >= match.size()) {
            return default_value;
        }

        return match[index].str();
    }
};

} // namespace quickbuild

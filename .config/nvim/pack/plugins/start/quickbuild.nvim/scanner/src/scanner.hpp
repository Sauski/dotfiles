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
                return format_diagnostic(match, pattern.groups);
            }
        }
        return "";
    }

private:
    std::vector<Pattern> patterns_;
    std::filesystem::path working_dir_;

    std::string format_diagnostic(const std::smatch& match,
                                  const std::map<std::string, int>& groups) {
        std::string file = extract_group(match, groups, "file");
        std::string line = extract_group(match, groups, "line");
        std::string col = extract_group(match, groups, "col", "0");
        std::string severity = extract_group(match, groups, "severity");
        std::string message = extract_group(match, groups, "message");

        // Normalize path
        std::filesystem::path file_path(file);
        if (file_path.is_relative()) {
            file_path = working_dir_ / file_path;
        }
        file_path = std::filesystem::absolute(file_path);

        // Convert to forward slashes
        std::string normalized_path = file_path.generic_string();

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

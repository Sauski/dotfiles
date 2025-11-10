#pragma once

#include <string>
#include <vector>
#include <regex>
#include <filesystem>
#include "config.hpp"

namespace quickbuild {

class Scanner {
public:
    explicit Scanner(std::vector<Pattern> patterns,
                     const std::filesystem::path& working_dir)
        : patterns_(std::move(patterns)),
          working_dir_(working_dir),
          state_(State::IDLE),
          active_pattern_(nullptr) {}

    std::string scan_line(const std::string& line) {
        // Multiline state machine
        if (state_ == State::IDLE) {
            // Try to start multiline collection
            if (try_start_multiline(line)) {
                return "";
            }
            // Try single-line match
            return try_single_line_match(line);
        } else {
            // COLLECTING state
            // Try to finish multiline with anchor match
            auto result = try_finish_multiline(line);
            if (!result.empty()) {
                return result;
            }
            // Continue accumulating
            accumulator_.lines.push_back(line);
            return "";
        }
    }

    std::vector<std::string> flush() {
        std::vector<std::string> results;
        if (state_ == State::COLLECTING && active_pattern_) {
            // Try matching block_end against all buffered lines
            for (const auto& line : accumulator_.lines) {
                std::smatch end_match;
                if (std::regex_search(line, end_match,
                                      active_pattern_->multiline->block_end)) {
                    // Found block_end, join and match
                    std::string joined = join_strings(accumulator_.lines,
                        active_pattern_->multiline->join);
                    std::smatch match;
                    if (std::regex_search(joined, match,
                                          active_pattern_->regex)) {
                        results.push_back(
                            format_multiline_diagnostic(match,
                                                        *active_pattern_));
                    }
                    break;
                }
            }
            // Reset state
            state_ = State::IDLE;
            active_pattern_ = nullptr;
            accumulator_.lines.clear();
        }
        return results;
    }

private:
    enum class State { IDLE, COLLECTING };

    struct Accumulator {
        std::vector<std::string> lines;
    };

    std::vector<Pattern> patterns_;
    std::filesystem::path working_dir_;
    State state_;
    const Pattern* active_pattern_;
    Accumulator accumulator_;

    bool try_start_multiline(const std::string& line) {
        for (const auto& pattern : patterns_) {
            if (!pattern.multiline) {
                continue;
            }
            std::smatch match;
            if (std::regex_search(line, match,
                                  pattern.multiline->block_start)) {
                state_ = State::COLLECTING;
                active_pattern_ = &pattern;
                accumulator_.lines.clear();
                accumulator_.lines.push_back(line);
                return true;
            }
        }
        return false;
    }

    std::string try_single_line_match(const std::string& line) {
        for (const auto& pattern : patterns_) {
            if (pattern.multiline) {
                continue;
            }
            std::smatch match;
            if (std::regex_match(line, match, pattern.regex)) {
                return format_diagnostic(match, pattern);
            }
        }
        return "";
    }

    std::string try_finish_multiline(const std::string& line) {
        if (!active_pattern_) {
            return "";
        }

        // Check if line matches block_end regex
        std::smatch end_match;
        if (!std::regex_search(line, end_match,
                               active_pattern_->multiline->block_end)) {
            return "";
        }

        // Add block_end line to buffer
        accumulator_.lines.push_back(line);

        // Join all lines into single string
        std::string joined = join_strings(accumulator_.lines,
                                          active_pattern_->multiline->join);

        // Match pattern.regex against joined block
        std::smatch match;
        if (!std::regex_search(joined, match, active_pattern_->regex)) {
            // Reset state - block complete but regex didn't match
            state_ = State::IDLE;
            active_pattern_ = nullptr;
            accumulator_.lines.clear();
            return "";
        }

        // Extract diagnostic from joined match
        std::string result = format_multiline_diagnostic(match,
                                                         *active_pattern_);

        // Reset state
        state_ = State::IDLE;
        active_pattern_ = nullptr;
        accumulator_.lines.clear();

        return result;
    }

    std::string format_multiline_diagnostic(const std::smatch& match,
                                            const Pattern& pattern) {
        std::string file = extract_group(match, pattern.groups, "file");
        std::string line = extract_group(match, pattern.groups, "line");
        std::string col = extract_group(match, pattern.groups, "col",
                                        "0");

        // Extract severity
        std::string severity;
        if (pattern.multiline->severity) {
            severity = *pattern.multiline->severity;
        } else {
            severity = extract_group(match, pattern.groups, "severity");
        }

        // Extract message
        std::string message;
        if (pattern.multiline->message_parts.empty()) {
            // Use message from anchor line
            message = extract_group(match, pattern.groups, "message");
        } else {
            // Combine message parts from buffer
            std::vector<std::string> parts;
            int buffer_size = static_cast<int>(accumulator_.lines.size());

            for (int idx : pattern.multiline->message_parts) {
                // Negative indices count from end
                if (idx < 0) {
                    idx = buffer_size + idx;
                }
                if (idx >= 0 && idx < buffer_size) {
                    parts.push_back(accumulator_.lines[idx]);
                }
            }

            message = join_strings(parts, pattern.multiline->join);
        }

        // Normalize path
        std::filesystem::path file_path(file);
        if (file_path.is_relative()) {
            file_path = working_dir_ / file_path;
        }
        file_path = std::filesystem::absolute(file_path);

        std::string normalized_path = file_path.generic_string();

        return normalized_path + ":" + line + ":" + col + ":" +
               severity + ":" + message;
    }

    std::string format_diagnostic(const std::smatch& match,
                                  const Pattern& pattern) {
        std::string file = extract_group(match, pattern.groups, "file");
        std::string line = extract_group(match, pattern.groups, "line");
        std::string col = extract_group(match, pattern.groups, "col",
                                        "0");
        std::string severity = extract_group(match, pattern.groups,
                                             "severity");
        std::string message = extract_group(match, pattern.groups,
                                            "message");

        // Normalize path
        std::filesystem::path file_path(file);
        if (file_path.is_relative()) {
            file_path = working_dir_ / file_path;
        }
        file_path = std::filesystem::absolute(file_path);

        std::string normalized_path = file_path.generic_string();

        return normalized_path + ":" + line + ":" + col + ":" +
               severity + ":" + message;
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

    std::string join_strings(const std::vector<std::string>& strings,
                             const std::string& separator) {
        if (strings.empty()) {
            return "";
        }
        std::string result = strings[0];
        for (size_t i = 1; i < strings.size(); ++i) {
            result += separator + strings[i];
        }
        return result;
    }
};

} // namespace quickbuild

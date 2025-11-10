#include <iostream>
#include <string>
#include <filesystem>
#include <csignal>
#include <cstdlib>
#include <optional>
#include "scanner.hpp"
#include "config.hpp"

namespace {
    volatile std::sig_atomic_t signal_received = 0;
}

void signal_handler(int signal) {
    signal_received = signal;
}

std::optional<std::filesystem::path> find_git_root() {
    std::filesystem::path current = std::filesystem::current_path();

    while (!current.empty() && current.has_parent_path()) {
        if (std::filesystem::exists(current / ".git")) {
            return current;
        }
        if (current == current.parent_path()) {
            break;
        }
        current = current.parent_path();
    }

    std::cerr << "Error: Not in a git repository" << std::endl;
    return std::nullopt;
}

int main(int argc, char* argv[]) {
    // Setup signal handling
    std::signal(SIGINT, signal_handler);
    std::signal(SIGTERM, signal_handler);

    // Find git root
    auto git_root = find_git_root();
    if (!git_root) {
        return 1;
    }

    // Load config
    std::filesystem::path config_path = *git_root / ".quickbuild.json";
    auto patterns = quickbuild::Config::load(config_path.string());
    if (!patterns) {
        return 1;
    }

    // Create scanner
    quickbuild::Scanner scanner(*patterns, *git_root);

    // Process stdin line by line
    std::string line;
    while (!signal_received && std::getline(std::cin, line)) {
        std::string diagnostic = scanner.scan_line(line);
        if (!diagnostic.empty()) {
            std::cout << diagnostic << std::endl;
        }
    }

    // Flush any remaining multiline diagnostics at EOF
    std::vector<std::string> remaining = scanner.flush();
    for (const auto& diagnostic : remaining) {
        std::cout << diagnostic << std::endl;
    }

    return 0;
}

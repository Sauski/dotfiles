#include <gtest/gtest.h>
#include <filesystem>
#include <fstream>
#include "../src/scanner.hpp"
#include "../src/config.hpp"

class ScannerTest : public ::testing::Test {
protected:
    void SetUp() override {
        test_dir_ = std::filesystem::temp_directory_path() / "qb_scanner_test";
        std::filesystem::create_directories(test_dir_);
    }

    void TearDown() override {
        std::filesystem::remove_all(test_dir_);
    }

    void write_config(const std::string& json) {
        std::ofstream file(test_dir_ / "test_config.json");
        file << json;
    }

    std::filesystem::path test_dir_;
};

TEST_F(ScannerTest, ConfigLoadBasic) {
    write_config(R"({
        "patterns": [
            {
                "regex": "^(.+?):(\\d+):(\\d+): (error|warning): (.+)$",
                "groups": {"file": 1, "line": 2, "col": 3, "severity": 4, "message": 5}
            }
        ]
    })");

    auto patterns_opt = quickbuild::Config::load((test_dir_ / "test_config.json").string());
    ASSERT_TRUE(patterns_opt.has_value());
    auto patterns = *patterns_opt;
    ASSERT_EQ(patterns.size(), 1);
    EXPECT_EQ(patterns[0].groups.at("file"), 1);
    EXPECT_EQ(patterns[0].groups.at("line"), 2);
    EXPECT_EQ(patterns[0].groups.at("col"), 3);
    EXPECT_EQ(patterns[0].groups.at("severity"), 4);
    EXPECT_EQ(patterns[0].groups.at("message"), 5);
}

TEST_F(ScannerTest, ConfigMissingFile) {
    auto result = quickbuild::Config::load((test_dir_ / "nonexistent.json").string());
    EXPECT_FALSE(result.has_value());
}

TEST_F(ScannerTest, ConfigMissingPatternsKey) {
    write_config(R"({"commands": []})");
    auto result = quickbuild::Config::load((test_dir_ / "test_config.json").string());
    EXPECT_FALSE(result.has_value());
}

TEST_F(ScannerTest, ConfigEmptyPatterns) {
    write_config(R"({"patterns": []})");
    auto result = quickbuild::Config::load((test_dir_ / "test_config.json").string());
    EXPECT_FALSE(result.has_value());
}

TEST_F(ScannerTest, ConfigMissingRequiredGroup) {
    write_config(R"({
        "patterns": [
            {
                "regex": "^(.+?):(\\d+): (.+)$",
                "groups": {"file": 1, "line": 2, "message": 3}
            }
        ]
    })");
    auto result = quickbuild::Config::load((test_dir_ / "test_config.json").string());
    EXPECT_FALSE(result.has_value());
}

TEST_F(ScannerTest, ScannerMatchGccFormat) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex("^(.+?):(\\d+):(\\d+): (error|warning): (.+)$");
    p.groups = {{"file", 1}, {"line", 2}, {"col", 3}, {"severity", 4}, {"message", 5}};
    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    std::string line = "src/main.cpp:42:10: error: expected ';'";
    std::string result = scanner.scan_line(line);

    EXPECT_FALSE(result.empty());
    EXPECT_NE(result.find("src/main.cpp"), std::string::npos);
    EXPECT_NE(result.find(":42:"), std::string::npos);
    EXPECT_NE(result.find(":10:"), std::string::npos);
    EXPECT_NE(result.find(":error:"), std::string::npos);
    EXPECT_NE(result.find("expected ';'"), std::string::npos);
}

TEST_F(ScannerTest, ScannerNoMatch) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex("^(.+?):(\\d+):(\\d+): (error|warning): (.+)$");
    p.groups = {{"file", 1}, {"line", 2}, {"col", 3}, {"severity", 4}, {"message", 5}};
    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    std::string line = "This is not an error message";
    std::string result = scanner.scan_line(line);

    EXPECT_TRUE(result.empty());
}

TEST_F(ScannerTest, ScannerMatchMsvcFormat) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex("^(.+?)\\((\\d+)\\): (error|warning) C\\d+: (.+)$");
    p.groups = {{"file", 1}, {"line", 2}, {"severity", 3}, {"message", 4}};
    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    std::string line = "C:\\project\\src\\main.cpp(42): error C2143: syntax error";
    std::string result = scanner.scan_line(line);

    EXPECT_FALSE(result.empty());
    EXPECT_NE(result.find("main.cpp"), std::string::npos);
    EXPECT_NE(result.find(":42:"), std::string::npos);
    EXPECT_NE(result.find(":error:"), std::string::npos);
    EXPECT_NE(result.find("syntax error"), std::string::npos);
}

TEST_F(ScannerTest, ScannerMultiplePatterns) {
    std::vector<quickbuild::Pattern> patterns;

    quickbuild::Pattern p1;
    p1.regex = std::regex("^(.+?):(\\d+):(\\d+): (error|warning): (.+)$");
    p1.groups = {{"file", 1}, {"line", 2}, {"col", 3}, {"severity", 4}, {"message", 5}};
    patterns.push_back(p1);

    quickbuild::Pattern p2;
    p2.regex = std::regex("^(.+?)\\((\\d+)\\): (error|warning) C\\d+: (.+)$");
    p2.groups = {{"file", 1}, {"line", 2}, {"severity", 3}, {"message", 4}};
    patterns.push_back(p2);

    quickbuild::Scanner scanner(patterns, test_dir_);

    std::string gcc_line = "src/main.cpp:42:10: error: expected ';'";
    std::string gcc_result = scanner.scan_line(gcc_line);
    EXPECT_FALSE(gcc_result.empty());

    std::string msvc_line = "C:\\project\\src\\main.cpp(42): error C2143: syntax error";
    std::string msvc_result = scanner.scan_line(msvc_line);
    EXPECT_FALSE(msvc_result.empty());
}

TEST_F(ScannerTest, ScannerDefaultColValue) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex("^(.+?):(\\d+): (error|warning): (.+)$");
    p.groups = {{"file", 1}, {"line", 2}, {"severity", 3}, {"message", 4}};
    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    std::string line = "src/main.cpp:42: error: expected ';'";
    std::string result = scanner.scan_line(line);

    EXPECT_FALSE(result.empty());
    EXPECT_NE(result.find(":42:0:"), std::string::npos);
}

// Multiline: TLA+ parse error
TEST_F(ScannerTest, MultilineTLAParseError) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex(
      "Encountered \".*\" at line (\\d+), column (\\d+).*file (.+?)$");
    p.groups = {{"file", 3}, {"line", 1}, {"col", 2}};

    quickbuild::MultilineConfig ml;
    ml.block_start = std::regex("^\\*\\*\\*Parse Error\\*\\*\\*$");
    ml.block_end = std::regex("^Encountered");
    ml.join = " ";
    ml.severity = "error";
    ml.message_parts = {0, 1};
    p.multiline = ml;

    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    std::string line1 = "***Parse Error***";
    EXPECT_TRUE(scanner.scan_line(line1).empty());

    std::string line2 = "Was expecting \"====\" ";
    EXPECT_TRUE(scanner.scan_line(line2).empty());

    std::string line3 =
      "Encountered \"pple\" at line 12, column 1 and token \"N\" in file "
      ".\\deadlock.tla";
    std::string result = scanner.scan_line(line3);

    EXPECT_FALSE(result.empty());
    EXPECT_NE(result.find("deadlock.tla"), std::string::npos);
    EXPECT_NE(result.find(":12:"), std::string::npos);
    EXPECT_NE(result.find(":1:"), std::string::npos);
    EXPECT_NE(result.find(":error:"), std::string::npos);
    EXPECT_NE(result.find("***Parse Error***"), std::string::npos);
    EXPECT_NE(result.find("Was expecting"), std::string::npos);
}

// Regression: single-line patterns still work with state machine
TEST_F(ScannerTest, SingleLineBackwardCompatibility) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex("^(.+?):(\\d+):(\\d+): (error|warning): (.+)$");
    p.groups = {{"file", 1}, {"line", 2}, {"col", 3},
                {"severity", 4}, {"message", 5}};
    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    std::string line1 = "src/main.cpp:42:10: error: expected ';'";
    std::string result1 = scanner.scan_line(line1);
    EXPECT_FALSE(result1.empty());

    std::string line2 = "src/test.cpp:10:5: warning: unused variable";
    std::string result2 = scanner.scan_line(line2);
    EXPECT_FALSE(result2.empty());

    // Flush should return nothing for single-line
    auto remaining = scanner.flush();
    EXPECT_TRUE(remaining.empty());
}

// Mixed: interleaved single-line and multiline patterns
TEST_F(ScannerTest, MixedSingleAndMultilinePatterns) {
    std::vector<quickbuild::Pattern> patterns;

    // Single-line GCC pattern
    quickbuild::Pattern p1;
    p1.regex = std::regex("^(.+?):(\\d+):(\\d+): (error|warning): (.+)$");
    p1.groups = {{"file", 1}, {"line", 2}, {"col", 3},
                 {"severity", 4}, {"message", 5}};
    patterns.push_back(p1);

    // Multiline TLA+ pattern
    quickbuild::Pattern p2;
    p2.regex = std::regex(
      "Encountered \".*\" at line (\\d+), column (\\d+).*file (.+?)$");
    p2.groups = {{"file", 3}, {"line", 1}, {"col", 2}};
    quickbuild::MultilineConfig ml;
    ml.block_start = std::regex("^\\*\\*\\*Parse Error\\*\\*\\*$");
    ml.block_end = std::regex("^Encountered");
    ml.join = " ";
    ml.severity = "error";
    ml.message_parts = {0};
    p2.multiline = ml;
    patterns.push_back(p2);

    quickbuild::Scanner scanner(patterns, test_dir_);

    // GCC error
    std::string gcc1 = "src/main.cpp:10:5: error: undeclared";
    EXPECT_FALSE(scanner.scan_line(gcc1).empty());

    // TLA+ multiline error
    EXPECT_TRUE(scanner.scan_line("***Parse Error***").empty());
    EXPECT_TRUE(scanner.scan_line("Expected something").empty());
    std::string tla_result = scanner.scan_line(
      "Encountered \"x\" at line 20, column 3 in file test.tla");
    EXPECT_FALSE(tla_result.empty());
    EXPECT_NE(tla_result.find("test.tla"), std::string::npos);

    // Another GCC error
    std::string gcc2 = "src/test.cpp:5:1: warning: unused";
    EXPECT_FALSE(scanner.scan_line(gcc2).empty());
}

// Edge case: block_end matches and emits immediately
TEST_F(ScannerTest, MultilineBlockEndMatchEmitsImmediately) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex(
      "Encountered \".*\" at line (\\d+), column (\\d+).*file (.+?)$");
    p.groups = {{"file", 3}, {"line", 1}, {"col", 2}};

    quickbuild::MultilineConfig ml;
    ml.block_start = std::regex("^\\*\\*\\*Parse Error\\*\\*\\*$");
    ml.block_end = std::regex("^Encountered");
    ml.join = " ";
    ml.severity = "error";
    ml.message_parts = {0};
    p.multiline = ml;

    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    // Start multiline collection
    EXPECT_TRUE(scanner.scan_line("***Parse Error***").empty());
    EXPECT_TRUE(scanner.scan_line("Some message").empty());

    // block_end matches - emits immediately
    std::string result = scanner.scan_line(
      "Encountered \"x\" at line 5, column 1 in file test.tla");
    EXPECT_FALSE(result.empty());
    EXPECT_NE(result.find("test.tla"), std::string::npos);
    EXPECT_NE(result.find(":5:"), std::string::npos);
    EXPECT_NE(result.find("***Parse Error***"), std::string::npos);

    // EOF - flush should return nothing (already emitted)
    auto remaining = scanner.flush();
    EXPECT_TRUE(remaining.empty());
}

// Edge case: incomplete multiline at EOF (no block_end match)
TEST_F(ScannerTest, MultilineIncompleteAtEOF) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex(
      "Encountered \".*\" at line (\\d+), column (\\d+).*file (.+?)$");
    p.groups = {{"file", 3}, {"line", 1}, {"col", 2}};

    quickbuild::MultilineConfig ml;
    ml.block_start = std::regex("^\\*\\*\\*Parse Error\\*\\*\\*$");
    ml.block_end = std::regex("^Encountered");
    ml.join = " ";
    ml.severity = "error";
    ml.message_parts = {};
    p.multiline = ml;

    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_);

    // Start multiline but never match block_end
    EXPECT_TRUE(scanner.scan_line("***Parse Error***").empty());
    EXPECT_TRUE(scanner.scan_line("Some message").empty());
    EXPECT_TRUE(scanner.scan_line("More text").empty());

    // EOF - flush should return nothing (incomplete)
    auto remaining = scanner.flush();
    EXPECT_TRUE(remaining.empty());
}

TEST_F(ScannerTest, VerboseModeNoOutputInNonVerbose) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex("^(.+?):(\\d+):(\\d+): (error|warning): (.+)$");
    p.groups = {{"file", 1}, {"line", 2}, {"col", 3},
                {"severity", 4}, {"message", 5}};
    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_, false);

    scanner.scan_line("src/main.cpp:42:10: error: expected ';'");
    scanner.scan_line("random line");
}

TEST_F(ScannerTest, VerboseModeEnabled) {
    std::vector<quickbuild::Pattern> patterns;
    quickbuild::Pattern p;
    p.regex = std::regex("^(.+?):(\\d+):(\\d+): (error|warning): (.+)$");
    p.groups = {{"file", 1}, {"line", 2}, {"col", 3},
                {"severity", 4}, {"message", 5}};
    patterns.push_back(p);

    quickbuild::Scanner scanner(patterns, test_dir_, true);

    scanner.scan_line("src/main.cpp:42:10: error: expected ';'");
    scanner.scan_line("random line");
}


int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}

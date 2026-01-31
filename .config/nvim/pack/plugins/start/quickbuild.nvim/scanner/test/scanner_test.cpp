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

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}

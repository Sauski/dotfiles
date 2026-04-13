-- Basic tests for simplecomplete.nvim

describe('cache', function()
  local cache = require('simplecomplete.cache')
  local config = require('simplecomplete.config').defaults

  it('extracts words from buffer', function()
    -- Create test buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'testing testCase',
      'another_word finalWord',
    })

    local words = cache.get_words(bufnr, config)

    -- Should extract 4+ character words
    assert.is_true(vim.tbl_contains(words, 'testing'))
    assert.is_true(vim.tbl_contains(words, 'testCase'))
    assert.is_true(vim.tbl_contains(words, 'another_word'))
    assert.is_true(vim.tbl_contains(words, 'finalWord'))

    vim.api.nvim_buf_delete(bufnr, {force = true})
  end)
end)

describe('matcher', function()
  local matcher = require('simplecomplete.matcher')
  local config = require('simplecomplete.config').defaults

  it('finds prefix matches case-insensitive', function()
    local keyword = 'test'
    local words = {'testing', 'testCase', 'myTest', 'Test', 'another'}

    local matches = matcher.find_matches(keyword, words, config)

    -- Should match: testing, testCase, Test (prefix matches)
    assert.is_true(vim.tbl_contains(matches, 'testing'))
    assert.is_true(vim.tbl_contains(matches, 'testCase'))
    assert.is_true(vim.tbl_contains(matches, 'Test'))

    -- Should NOT match: myTest (not prefix), another (no match)
    assert.is_false(vim.tbl_contains(matches, 'myTest'))
    assert.is_false(vim.tbl_contains(matches, 'another'))
  end)

  it('filters out paths', function()
    local keyword = 'test'
    local words = {'testing', 'test/path', 'test\\path'}

    local matches = matcher.find_matches(keyword, words, config)

    assert.is_true(vim.tbl_contains(matches, 'testing'))
    assert.is_false(vim.tbl_contains(matches, 'test/path'))
    assert.is_false(vim.tbl_contains(matches, 'test\\path'))
  end)

  it('filters out file extensions', function()
    local keyword = 'test'
    local words = {'testing', 'test.lua', 'test.txt'}

    local matches = matcher.find_matches(keyword, words, config)

    assert.is_true(vim.tbl_contains(matches, 'testing'))
    assert.is_false(vim.tbl_contains(matches, 'test.lua'))
    assert.is_false(vim.tbl_contains(matches, 'test.txt'))
  end)

  it('extracts keyword correctly', function()
    assert.equals('test', matcher.get_keyword('hello test', 10))
    assert.equals('test', matcher.get_keyword('test', 4))
    assert.equals('', matcher.get_keyword('hello ', 6))
  end)

  it('detects mid-word correctly', function()
    assert.is_true(matcher.is_mid_word('testWord', 4))
    assert.is_false(matcher.is_mid_word('test ', 4))
    assert.is_false(matcher.is_mid_word('test', 4))
  end)

  it('counts completion changes correctly', function()
    -- New chars only
    assert.equals(4, matcher.count_completion_changes('func', 'function'))
    assert.equals(1, matcher.count_completion_changes('functio', 'function'))
    assert.equals(0, matcher.count_completion_changes('function', 'function'))

    -- Case differences
    assert.equals(1, matcher.count_completion_changes('Func', 'func'))

    -- New chars + case diffs
    assert.equals(5, matcher.count_completion_changes('Func', 'function'))
  end)

  it('returns empty string when keyword equals LCP', function()
    local matches = {'function'}
    local completion = matcher.get_unambiguous_completion('function', matches)

    -- Should return empty string (truthy), not nil
    assert.is_not_nil(completion)
    assert.equals('', completion)
  end)

  it('returns completion text when keyword is prefix of LCP', function()
    local matches = {'function'}
    local completion = matcher.get_unambiguous_completion('func', matches)

    assert.equals('tion', completion)
  end)
end)

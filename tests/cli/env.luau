local env = require "@cli/env"
local spec = {} :: { [string]: any }

function spec.should_read_name_value_pairs()
	local values = env.parse "ROBLOX_API_KEY=abc\nOTHER=1\n"
	assert(values.ROBLOX_API_KEY == "abc" and values.OTHER == "1")
end

function spec.should_strip_quotes_and_spaces()
	local values = env.parse "A = \"x y\"\nB='z'\r\nexport C=3"
	assert(values.A == "x y" and values.B == "z" and values.C == "3")
end

function spec.should_ignore_comments_and_blank_lines()
	local values = env.parse "# note\n\nKEY=v\n"
	assert(values.KEY == "v" and values["# note"] == nil)
end

function spec.should_read_a_variable_from_the_file_content()
	assert(env.get("SCRIM_TEST_UNSET_VARIABLE", "SCRIM_TEST_UNSET_VARIABLE=from_file") == "from_file")
end

function spec.should_return_nil_when_the_variable_is_missing_or_empty()
	assert(env.get("SCRIM_TEST_UNSET_VARIABLE", "OTHER=1") == nil)
	assert(env.get("SCRIM_TEST_UNSET_VARIABLE", "SCRIM_TEST_UNSET_VARIABLE=") == nil)
end

return spec

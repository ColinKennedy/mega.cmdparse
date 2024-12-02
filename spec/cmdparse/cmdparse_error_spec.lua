--- Make sure that `cmdparse` errors when it should.
---
---@module 'cmdparse.cmdparse_error_spec'
---

local cmdparse = require("cmdparse._cli.cmdparse")
local mock_vim = require("test_utilities.mock_vim")
local top_cmdparse = require("cmdparse")

local _COMMAND_NAME = "Test"

describe("bad auto-complete input", function()
    it("errors if an incorrect flag is given", function()
        local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

        parser:add_parameter({ "--bar", action = "store_true", help = "The -bar flag." })
        parser:add_parameter({ "--foo", action = "store_true", help = "The -foo flag." })

        assert.same({}, parser:get_completion("--does-not-exist "))
        assert.same({}, parser:get_completion("--bar --does-not-exist "))
        assert.same({}, parser:get_completion("--does-not-exist"))
        assert.same({}, parser:get_completion("--bar --does-not-exist"))
    end)

    describe("named arguments", function()
        it("errors if an unknown named argument is given", function()
            local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

            parser:add_parameter({ "--bar", help = "The -bar flag." })
            parser:add_parameter({ "--foo", action = "store_true", help = "The -foo flag." })

            assert.same({}, parser:get_completion("--unknown=thing "))
            assert.same({}, parser:get_completion("--unknown=thing"))

            assert.same({}, parser:get_completion("--bar=thing --unknown=thing "))
            assert.same({}, parser:get_completion("--bar=thing --unknown=thing"))

            assert.same({}, parser:get_completion("--unknown=thing --bar=thing"))
            assert.same({}, parser:get_completion("--unknown=thing --bar=thing "))
        end)
    end)
end)

describe("bad definition input", function()
    describe("parsers definition issues", function()
        it("errors if you define a flag argument with choices", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "--foo", action = "store_true", choices = { "f" }, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" cannot use action "store_true" and choices at the same time.', result)
        end)

        it("errors if you define a nargs=0 + position argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "foo", nargs = 0, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" cannot be nargs=0.', result)
        end)

        it("errors if you define a nargs + flag argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "--foo", action = "store_true", nargs = 2, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
        end)

        it("errors if you define a position parameter + action store_true", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "ɧelp", action = "store_true", help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "ɧelp" cannot use action="store_true".', result)
        end)

        it("errors if a custom type=foo doesn't return a value - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--foo", type = tonumber, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo=not_a_number")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "--foo" failed to find a value. Please check your `type` parameter and fix it!',
                result
            )

            success, result = pcall(function()
                return parser:parse_arguments("--foo=123")
            end)

            assert.is_true(success)
            assert.same({ foo = 123 }, result)
        end)

        it("errors if a custom type=foo doesn't return a value - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({
                "--foo",
                nargs = 1,
                type = function(_)
                    return nil
                end,
                help = "Test.",
            })

            local success, result = pcall(function()
                parser:parse_arguments("--foo=not_a_number")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "--foo" failed to find a value. Please check your `type` parameter and fix it!',
                result
            )

            success, result = pcall(function()
                return parser:parse_arguments("--foo=123")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "--foo" failed to find a value. Please check your `type` parameter and fix it!',
                result
            )
        end)

        it("errors if no name is give", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({
                    nargs = 1,
                    type = function(_)
                        return nil
                    end,
                    help = "Test.",
                })
            end)

            assert.is_false(success)
            assert.equal(
                [[Options "{
  help = "Test.",
  nargs = 1,
  type = <function 1>
}" is missing a "name" key.]],
                result
            )
        end)

        it("includes named argument choices", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--foo", choices = { "aaa", "bbb", "zzz" }, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo=not_a_valid_choice")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "--foo" got invalid "not_a_valid_choice" value. Expected one of { "aaa", "bbb", "zzz" }.',
                result
            )
        end)

        it("includes nested subparsers argument choices - 001 required", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "thing", help = "Test." })

            local subparsers = parser:add_subparsers({ "commands", help = "Test." })
            subparsers.required = true

            local inner_parser = subparsers:add_parser({ "inner_command", help = "Test." })
            local inner_subparsers = inner_parser:add_subparsers({ "commands", help = "Test." })
            inner_subparsers.required = true
            inner_subparsers:add_parser({ "child", choices = { "foo", "bar", "thing" }, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("some_text inner_command does_not_exist")
            end)

            assert.is_false(success)
            assert.equal(
                [[Got unexpected "does_not_exist" value. Did you mean one of these incomplete parameters?
foo
bar
thing]],
                result
            )
        end)

        it("includes position argument choices", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "foo", choices = { "aaa", "bbb", "zzz" }, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("not_a_valid_choice")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "foo" got invalid "not_a_valid_choice" value. Expected one of { "aaa", "bbb", "zzz" }.',
                result
            )
        end)

        it("includes subparsers argument choices - 001 required", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "thing", help = "Test." })
            local subparsers = parser:add_subparsers({ "commands", help = "Test." })
            subparsers.required = true
            subparsers:add_parser({ "inner_command", choices = { "foo", "bar", "thing" } })

            local success, result = pcall(function()
                parser:parse_arguments("foo")
            end)

            assert.is_false(success)
            assert.equal('Parameter "thing" must be defined.', result)

            success, result = pcall(function()
                parser:parse_arguments("something not_valid")
            end)

            assert.is_false(success)
            assert.equal(
                [[Got unexpected "not_valid" value. Did you mean one of these incomplete parameters?
foo
bar
thing]],
                result
            )
        end)

        it("includes subparsers argument choices - 002 - required", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "thing", help = "Test." })
            local subparsers = parser:add_subparsers({ "commands", help = "Test." })
            subparsers.required = false
            subparsers:add_parser({ "inner_command", choices = { "foo", "bar", "thing" } })

            local success, result = pcall(function()
                parser:parse_arguments("something not_valid_subparser")
            end)

            assert.is_false(success)
            assert.equal(
                [[Got unexpected "not_valid_subparser" value. Did you mean one of these incomplete parameters?
foo
bar
thing]],
                result
            )
        end)

        describe("nargs", function()
            describe("nargs number", function()
                it("errors if not enough values are given", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })
                    parser:add_parameter({ "--foo", nargs = 2, help = "Test." })
                    parser:add_parameter({ "--bar", nargs = 2, help = "Test." })

                    local command = "--foo thing --bar something else"
                    local success, result = pcall(function()
                        parser:parse_arguments(command)
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)

                    success, result = pcall(function()
                        parser:get_completion(command)
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)
                end)

                it("works with nargs=2 + count", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = 2, action = "count", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "count" and nargs at the same time.', result)
                end)

                it("works with nargs=2 + store_false", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = 2, action = "store_false", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal(
                        'Parameter "--foo" cannot use action "store_false" and nargs at the same time.',
                        result
                    )
                end)

                it("works with nargs=2 + store_true", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = 2, action = "store_true", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
                end)
            end)

            describe("nargs *", function()
                it("works with nargs=* + count", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "*", action = "count", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "count" and nargs at the same time.', result)
                end)

                it("works with nargs=* + store_false", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "*", action = "store_false", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal(
                        'Parameter "--foo" cannot use action "store_false" and nargs at the same time.',
                        result
                    )
                end)

                it("works with nargs=* + store_true", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "*", action = "store_true", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
                end)
            end)

            describe("nargs +", function()
                it("works with nargs=+ + count", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "+", action = "count", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "count" and nargs at the same time.', result)
                end)

                it("works with nargs=+ + store_false", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "+", action = "store_false", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal(
                        'Parameter "--foo" cannot use action "store_false" and nargs at the same time.',
                        result
                    )
                end)

                it("works with nargs=+ + store_true", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "+", action = "store_true", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
                end)
            end)

            describe("nargs + --foo=bar named argument syntax", function()
                it("errors with nargs=2 and --foo=bar syntax", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    parser:add_parameter({ "--foo", nargs = 2, help = "Test." })

                    local success, result = pcall(function()
                        parser:parse_arguments("--foo=thing")
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)
                end)

                it("works with nargs=* and --foo=bar syntax", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    parser:add_parameter({ "--foo", nargs = "*", help = "Test." })

                    assert.same({ foo = "thing" }, parser:parse_arguments("--foo=thing"))
                end)

                it("works with nargs=+ and --foo=bar syntax", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    parser:add_parameter({ "--foo", nargs = "+", help = "Test." })

                    assert.same({ foo = "thing" }, parser:parse_arguments("--foo=thing"))
                end)
            end)
        end)
    end)

    describe("simple", function()
        it("does not error if there is no text and all arguments are optional", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", required = false, help = "Test." })

            parser:parse_arguments("")
        end)

        it("errors if a flag is given instead of an expected position", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "foo", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--not=a_position")
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" must be defined.', result)
        end)

        it("errors if nargs doesn't get enough expected values", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "--foo", nargs = 3, required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo thing another")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires "3" values. Got "2" values.', result)
        end)

        it("errors if the user is #missing a required flag argument - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "--foo", action = "store_true", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required flag argument - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "thing", help = "Test." })
            parser:add_parameter({ "--foo", action = "store_true", required = true, help = "Test." })

            assert.same({ foo = true, thing = "blah" }, parser:parse_arguments("blah --foo"))

            local success, result = pcall(function()
                parser:parse_arguments("blah ")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required named argument - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--foo", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required named argument - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--foo", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo= ")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires 1 value.', result)
        end)

        it("errors if the user is #missing a required position argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" must be defined.', result)
        end)

        it("ignores an optional position argument", function()
            local parser_1 = cmdparse.ParameterParser.new({ help = "Test" })
            parser_1:add_parameter({ name = "foo", required = false, help = "Test." })
            parser_1:parse_arguments("")

            local parser_2 = cmdparse.ParameterParser.new({ help = "Test" })
            parser_2:add_parameter({ name = "foo", required = true, help = "Test." })
            local success = pcall(function()
                parser_2:parse_arguments("")
            end)
            assert.is_false(success)
        end)

        it("errors if the user is #missing one of several arguments - 003 - position argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ name = "foo", nargs = 2, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("thing")
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" requires "2" values. Got "1" value.', result)
        end)

        it("errors if the user is #missing one of several arguments - 004 - flag-value argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", nargs = 2, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo blah")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)
        end)

        it("errors if a named argument in the middle of parse that is not given a value", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", required = true, help = "Test." })
            parser:add_parameter({ name = "--bar", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo= --bar=thing")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires 1 value.', result)
        end)

        it("errors if a position argument in the middle of parse that is not given a value", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", help = "Test." })
            parser:add_parameter({ name = "bar", help = "Test." })
            parser:add_parameter({ name = "--fizz", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("some --fizz=thing")
            end)

            assert.is_false(success)
            assert.equal('Parameter "bar" must be defined.', result)
        end)

        it("errors if a position argument at the end of a parse that is not given a value", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", help = "Test." })
            parser:add_parameter({ name = "bar", help = "Test." })
            parser:add_parameter({ name = "thing", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("some fizz")
            end)

            assert.is_false(success)
            assert.equal('Parameter "thing" must be defined.', result)
        end)
    end)
end)

describe("bugs", function()
    describe("auto-complete", function()
        it("works with arbitrary-thing's flags", function()
            local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

            parser:add_parameter({ "-a", action = "store_true", help = "The -a flag." })
            parser:add_parameter({ "-b", action = "store_true", help = "The -b flag." })
            parser:add_parameter({ "-c", action = "store_true", help = "The -c flag." })
            parser:add_parameter({ "-f", action = "store_true", count = "*", help = "The -f flag." })
            parser:add_parameter({
                "-v",
                action = "store_true",
                count = "*",
                destination = "verbose",
                help = "The -v flag.",
            })

            assert.same({ "-c", "-f", "-v", "--help" }, parser:get_completion("-a -b "))
        end)

        it("works with arbitrary-thing's flags - 002", function()
            local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

            parser:add_parameter({ "--bar", action = "store_true", help = "The -bar flag." })
            parser:add_parameter({ "--foo", action = "store_true", help = "The -foo flag." })

            assert.same({}, parser:get_completion("-a -b "))
        end)
    end)

    describe("parsing arguments", function()
        it("forces flag arguments to not take any arguments", function()
            local parser = cmdparse.ParameterParser.new({ "top", help = "Test." })
            parser:add_parameter({"--thing", action="store_true", help="Test."})

            local success, message = pcall(function() parser:parse_arguments("--thing=foo") end)
            assert.is_false(success)
            assert.equal("TTTT", message)

            success, message = pcall(function() parser:parse_arguments("--thing foo") end)
            assert.equal("TTTT", message)

            assert.is_true(parser:parse_arguments("--thing").thing)
        end)
    end)
end)

describe("README.md examples", function()
    before_each(function()
        pcall(function()
            vim.cmd.delcommand(_COMMAND_NAME)
        end)

        mock_vim.mock_print()
        mock_vim.mock_vim_notify()
    end)

    after_each(function()
        mock_vim.reset_vim_notify()
        mock_vim.reset_print()
    end)

    it('works with the "Automated value type conversions" example', function()
        local parser = cmdparse.ParameterParser.new({ name = _COMMAND_NAME, help = "Hello, World!" })
        parser:add_parameter({ name = "thing", type = tonumber, help = "Test." })
        parser:add_parameter({ name = "another", type = "number", help = "Test." })
        top_cmdparse.create_user_command(parser)

        local namespace = parser:parse_arguments('10 "-123"')
        assert.same({ another = -123, thing = 10 }, namespace)
    end)

    it('works with the "Dynamic Plug-ins" example', function()
        ---@return cmdparse.ParameterParser # Some example parser.
        local function make_example_plugin_a()
            local parser = cmdparse.ParameterParser.new({ name = "plugin-a", help = "Test plugin-a." })
            parser:add_parameter({ name = "--foo", action="store_true", help="A required value for plugin-a." })

            parser:set_execute(function()
                print("Running plugin-a")
            end)

            return parser
        end

        ---@return cmdparse.ParameterParser # Another example parser.
        local function make_example_plugin_b()
            local parser = cmdparse.ParameterParser.new({ name = "plugin-b", help = "Test plugin-b." })
            parser:add_parameter({ name = "foo", help="A required value for plugin-b." })

            parser:set_execute(function()
                print("Running plugin-b")
            end)

            return parser
        end

        ---@return cmdparse.ParameterParser # A parser whose auto-complete and executer uses auto-found plugins.
        local function create_parser()
            local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Test." })
            local subparsers = parser:add_subparsers({ destination = "commands", help = "All main commands." })

            -- NOTE: These functions would normally be "automatically discovered"
            -- somehow, not hard-coded. But the purpose is the same, it's to add some
            -- name and callable function so we can refer to it later in the parser.
            --
            subparsers:add_parser(make_example_plugin_a())
            subparsers:add_parser(make_example_plugin_b())

            return parser
        end

        local parser = create_parser()
        top_cmdparse.create_user_command(parser)

        vim.cmd[[Test plugin-a --foo]]
        vim.cmd[[Test plugin-b 1234]]

        assert.same({ "Running plugin-a", "Running plugin-b" }, mock_vim.get_prints())

        vim.cmd[[Test --help]]

        assert.same(
            {
[[
Usage: Test {plugin-a,plugin-b} [--help]

Commands:
    plugin-a    Test plugin-a.
    plugin-b    Test plugin-b.

Options:
    --help -h    Show this help message and exit.
]]
            },
            mock_vim.get_vim_notify_messages()
        )
    end)

    it('works with the "Position, flag, and named arguments support" example', function()
        local parser = cmdparse.ParameterParser.new({
            name = "Test",
            help = "Position, flag, and named arguments support.",
        })
        parser:add_parameter({ name = "items", nargs="*", help="non-flag arguments." })
        parser:add_parameter({ name = "--fizz", help="A word." })
        parser:add_parameter({ name = "-d", action="store_true", help="Delta single-word." })
        parser:add_parameter({ names = {"--beta", "-b"}, action="store_true", help="Beta single-word." })
        parser:add_parameter({ name = "-z", action="store_true", help="Zulu single-word." })

        parser:set_execute(function(data)
            local namespace = data.namespace
            local items = namespace.items
            print(vim.fn.join(vim.fn.sort(items), ", "))
            print(string.format('-d: %s, -b: %s, -z: %s', namespace.d, namespace.beta, namespace.z))
        end)

        top_cmdparse.create_user_command(parser)

        vim.cmd[[Test foo bar --fizz=buzz -dbz]]

        assert.same({"bar, foo", "-d: true, -b: true, -z: true"}, mock_vim.get_prints())
    end)

    it('works with the "Nested Subparsers" example', function()
        local parser = top_cmdparse.ParameterParser.new({ name = _COMMAND_NAME, help = "Nested Subparsers" })
        local top_subparsers = parser:add_subparsers({ destination = "commands" })
        local view = top_subparsers:add_parser({ name = "view", help = "View some data." })
        local view_subparsers = view:add_subparsers({ destination = "view_commands" })

        local log = view_subparsers:add_parser({ name = "log" })
        log:add_parameter({ name = "path", help = "Open a log path file." })
        log:add_parameter({ name = "--relative", action = "store_true", help = "A relative log path." })
        log:set_execute(function(data)
            print(string.format('Opening "%s" log path.', data.namespace.path))
        end)

        top_cmdparse.create_user_command(parser)

        local success, message = pcall(function()
            vim.cmd(string.format("%s view log", _COMMAND_NAME))
        end)
        assert.is_false(success)
        assert.equal('vim/_editor.lua:0: nvim_exec2(): Vim:Parameter "path" must be defined.', message)
    end)

    it('works with the "Static Auto-Complete Values" example', function()
        local parser = cmdparse.ParameterParser.new({ name = _COMMAND_NAME, help = "Hello, World!" })
        parser:add_parameter({ name = "thing", choices = { "aaa", "apple", "apply" }, help = "Test." })
        parser:set_execute(function(data) print(data.namespace.thing) end)
        top_cmdparse.create_user_command(parser)

        vim.cmd(string.format("%s apple", _COMMAND_NAME))

        assert.same({"apple"}, mock_vim.get_prints())
    end)

    it('works with the "Supports Required / Optional Arguments" example', function()
        local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Unicode Parameters." })
        parser:add_parameter({ name = "required_thing", help = "Test." })
        parser:add_parameter({ name = "optional_thing", required=false, help = "Test." })
        parser:add_parameter({ name = "--optional-flag", help = "Test." })
        parser:add_parameter({ name = "--required-flag", required=true, help = "Test." })

        local output = {}

        parser:set_execute(function(data)
            local namespace = data.namespace
            output.optional_thing = namespace.optional_thing
            output.required_thing = namespace.required_thing
            output["optional-flag"] = namespace["optional-flag"]
            output["required-flag"] = namespace["required-flag"]
        end)

        top_cmdparse.create_user_command(parser)

        vim.cmd[[Test foo bar --required-flag=aaa]]

        assert.same(
            { ["required-flag"]="aaa", optional_thing="bar", required_thing="foo" },
            output
        )
    end)

    it('works with the "Unicode Parameters" example', function()
        local parser = cmdparse.ParameterParser.new({ name = _COMMAND_NAME, help = "Unicode Parameters." })
        parser:add_parameter({ name = "𝒻ⓡ𝓊𝒾🅃🆂", nargs="+", help = "Test." })
        parser:add_parameter({ name = "--😊", help = "Test." })

        parser:set_execute(function(data)
            print(vim.fn.join(data.namespace["𝒻ⓡ𝓊𝒾🅃🆂"], ", "))
            print(data.namespace["😊"])
        end)

        top_cmdparse.create_user_command(parser)

        vim.cmd(string.format("%s apple 🄱🄰🄽🄰🄽🄰 --😊=ttt", _COMMAND_NAME))

        assert.same({ "apple, 🄱🄰🄽🄰🄽🄰", "ttt" }, mock_vim.get_prints())
    end)
end)

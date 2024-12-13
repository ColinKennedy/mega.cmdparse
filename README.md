# mega.cmdparse

A [Python argparse-inspired](https://docs.python.org/3/library/argparse.html)
command mode parser for Neovim.

This library is for people who have to define a command like `:Foo` and it
takes arguments. This library supports customizable arguments and subcommands
so no more needing to define `:FooToggle` `:FooOpen /path/to/file.txt`
`:FooClose 2`, etc commands. You can easily create one command with completely
separate interfaces like `:Foo toggle`, `:Foo open /path/to/file.txt`, and
`:Foo close --buffer=2`.

There's a lot of features. Whatever you need, `mega.cmdparse` has you covered!


| <!-- -->     | <!-- -->                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Build Status | [![unittests](https://img.shields.io/github/actions/workflow/status/ColinKennedy/mega.cmdparse/test.yml?branch=main&style=for-the-badge&label=Unittests)](https://github.com/ColinKennedy/mega.cmdparse/actions/workflows/test.yml)  [![documentation](https://img.shields.io/github/actions/workflow/status/ColinKennedy/mega.cmdparse/documentation.yml?branch=main&style=for-the-badge&label=Documentation)](https://github.com/ColinKennedy/mega.cmdparse/actions/workflows/documentation.yml)  [![luacheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/mega.cmdparse/luacheck.yml?branch=main&style=for-the-badge&label=Luacheck)](https://github.com/ColinKennedy/mega.cmdparse/actions/workflows/luacheck.yml) [![llscheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/mega.cmdparse/llscheck.yml?branch=main&style=for-the-badge&label=llscheck)](https://github.com/ColinKennedy/mega.cmdparse/actions/workflows/llscheck.yml) [![stylua](https://img.shields.io/github/actions/workflow/status/ColinKennedy/mega.cmdparse/stylua.yml?branch=main&style=for-the-badge&label=Stylua)](https://github.com/ColinKennedy/mega.cmdparse/actions/workflows/stylua.yml)  [![urlchecker](https://img.shields.io/github/actions/workflow/status/ColinKennedy/mega.cmdparse/urlchecker.yml?branch=main&style=for-the-badge&label=URLChecker)](https://github.com/ColinKennedy/mega.cmdparse/actions/workflows/urlchecker.yml)  |
| License      | [![License-MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](https://github.com/ColinKennedy/mega.cmdparse/blob/main/LICENSE)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Social       | [![RSS](https://img.shields.io/badge/rss-F88900?style=for-the-badge&logo=rss&logoColor=white)](https://github.com/ColinKennedy/mega.cmdparse/commits/main/doc/news.txt.atom)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |


# Features
- Position, flag, and named arguments support. e.g. `foo bar --fizz=buzz -z`
- Parser / Parameter paradigm
- Builtin auto-complete
- Auto-generated `--help` parameter support.
- Auto-complete any argument in any cursor position
- Auto-complete a flag argument's values
- Non-standard arguments support. e.g. `--foo`, `++bar`, `-f`, etc
- Automated value type conversions.
- Multi-argument-per-parameter support
- Multi-parameter support
- Basic unicode parameter / value support
- Merged flag support. e.g. `-fbt` flags parse as `{f=true, b=true, t=true}`.
- Automated parameter validation. e.g. "foo parameter requires 2 arguments, got 1", etc.
- Supports required / optional arguments
- 2 flag formats support. `--foo bar` and `--foo=bar`
- Dynamic parsers (supports plugin-like interfaces like Telescope and more)
- This plugin is defer-evaluated (<1 ms plugin start-up time)


## Demos
### Builtin auto-complete

https://github.com/user-attachments/assets/49cb410c-b49d-435a-ac8b-5cb46999f7f7


### Auto-generated `--help` parameter support
If you want details on what to type, add `-h` or `--help` to any command and
the automated help message will show.

https://github.com/user-attachments/assets/da01f274-87d5-4768-8719-54a72fb5627c

A summarized version may also show if you make a mistake in your input.

https://github.com/user-attachments/assets/9be524e3-fccd-4cd0-8626-a2dc6c096518


### Automated parameter validation
Parameters know how many arguments they need and in what order.

https://github.com/user-attachments/assets/29f57c5c-c977-47a0-82c8-423250e26688


### 2 flag formats support
`--foo bar` and `--foo=bar` are both supported styles.

https://github.com/user-attachments/assets/a4467230-c1c6-49a0-8405-5c4be40dcba2


## Examples
<details>
<summary>Hello, World! Parser</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Hello, World!"})
parser:set_execute(function(data) print("Hello, World!") end)
cmdparse.create_user_command(parser)
```
Run: `:Test`
</details>

<details>
<summary>Automated value type conversions</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Automated value type conversions" })
parser:add_parameter({ name = "thing", type = tonumber, help = "Test." })
parser:add_parameter({ name = "another", type = "number", help = "Test." })
parser:set_execute(function(data)
    print(string.format('Thing: "%d"', data.namespace.thing + 10))
    print(string.format('Another: "%d"', data.namespace.another + 10))
end)

cmdparse.create_user_command(parser)
```
Run: `:Test 10 -123`
</details>

<details>
<summary>Multi-argument-per-parameter</summary>

In this example, the "thing" parameter takes exactly `2` arguments, indicated
by `nargs=2`.

- `nargs="*"` = 0-or-more
- `nargs="+"` = 1-or-more

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Multi-argument-per-parameter" })
parser:add_parameter({ name = "thing", nargs=2, type=tonumber, help = "Test." })
parser:set_execute(function(data)
    local values = data.namespace.thing
    local first = values[1]
    local second = values[2]
    local total = first + second

    print(string.format('Thing: "%f + %f = %f"', first, second, total))
end)

cmdparse.create_user_command(parser)
```
Run: `:Test 123 54545.1231`
</details>

<details>
<summary>Position, flag, and named arguments support. e.g. `foo bar --fizz=buzz -dbz`</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Position, flag, and named arguments support." })
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

cmdparse.create_user_command(parser)
```
Run: `:Test foo bar --fizz=buzz -dbz`
</details>

<details>
<summary>Supports Required / Optional Arguments</summary>

By default, flag / named arguments like `--foo` or `--foo=bar` are optional.
By default, position arguments like `thing` are required.

But you can explicitly make flag / named arguments required or position
arguments optional, using `required=true` and `required=false`.

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Unicode Parameters." })
parser:add_parameter({ name = "required_thing", help = "Test." })
parser:add_parameter({ name = "optional_thing", required=false, help = "Test." })
parser:add_parameter({ name = "--optional-flag", help = "Test." })
parser:add_parameter({ name = "--required-flag", required=true, help = "Test." })

parser:set_execute(function(data)
    print(vim.inspect(data.namespace))
end)

cmdparse.create_user_command(parser)
```
Run: `:Test foo bar --required-flag=aaa`
</details>

<details>
<summary>Nested Subparsers</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Nested Subparsers" })
local top_subparsers = parser:add_subparsers({ destination = "commands" })
local view = top_subparsers:add_parser({ name = "view", help = "View some data." })
local view_subparsers = view:add_subparsers({ destination = "view_commands" })

local log = view_subparsers:add_parser({ name = "log" })
log:add_parameter({ name = "path", help = "Open a log path file." })
log:add_parameter({ name = "--relative", action="store_true", help = "A relative log path." })
log:set_execute(function(data)
    print(string.format('Opening "%s" log path.', data.namespace.path))
end)

cmdparse.create_user_command(parser)
```
Run: `:Test view log /some/path.txt`
</details>

<details>
<summary>Static Auto-Complete Values</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Static Auto-Complete Values."})
parser:add_parameter({ name = "thing", choices={ "aaa", "apple", "apply" }, help="Test word."})
parser:set_execute(function(data) print(data.namespace.thing) end)
cmdparse.create_user_command(parser)
```
Run: `:Test apply`
</details>

<details>
<summary>Dynamic Auto-Complete Values</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Dynamic Auto-Complete Values."})
local choices = function(data)
    local output = {}
    local value = data.value or 0

    for index = 1, 5 do
        table.insert(output, "text " .. tostring(value + index))
    end

    return output
end
parser:add_parameter({ name = "--thing", choices=choices, help="Test word."})
parser:set_execute(
    function(data) print(data.namespace.thing) end,
)
cmdparse.create_user_command(parser)
```
Run: `:Test --thing=4`
</details>

<details>
<summary>Dynamic Plug-ins</summary>

Subparsers are not static, you can create dynamic subparsers with dynamic names
and dynamic contents if you'd like. This makes `mega.cmdparse` great for
writing a plugin that supports CLI hooks, like how
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) behaves.

```lua
---@return mega.cmdparse.ParameterParser # Some example parser.
local function make_example_plugin_a()
    local parser = cmdparse.ParameterParser.new({ name = "plugin-a", help = "Test plugin-a." })
    parser:add_parameter({ name = "--foo", action="store_true", help="A required value for plugin-a." })

    parser:set_execute(function(data)
        print("Running plugin-a")
    end)

    return parser
end

---@return mega.cmdparse.ParameterParser # Another example parser.
local function make_example_plugin_b()
    local parser = cmdparse.ParameterParser.new({ name = "plugin-b", help = "Test plugin-b." })
    parser:add_parameter({ name = "foo", help="A required value for plugin-b." })

    parser:set_execute(function(data)
        print("Running plugin-b")
    end)

    return parser
end

---@return mega.cmdparse.ParameterParser # A parser whose auto-complete and executer uses auto-found plugins.
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
cmdparse.create_user_command(parser)
```
Run: `Test plugin-a --foo`
Run: `Test plugin-b 12345`
</details>

<details>
<summary>Customizable / Automated `--help` flag</summary>

The help message is automatically generated but you can influence the output
a bit, using `value_hint`.

For example this code below:
```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Position, flag, and named arguments support." })
parser:add_parameter({ name = "items", nargs="*", help="non-flag arguments." })
parser:add_parameter({ name = "--fizz", nargs="+", help="A word." })
parser:add_parameter({ name = "-b", action="store_true", help="Zulu single-word." })

parser:set_execute(function(data)
    print("Ran it")
end)

cmdparse.create_user_command(parser)
```

Creates this help message:
```
Usage: Test [ITEMS ...] [--fizz FIZZ [FIZZ ...]] [-b] [--help]

Positional Arguments:
    [ITEMS ...]    non-flag arguments.

Options:
    --fizz FIZZ [FIZZ ...]    A word.
    -b    Zulu single-word.
    --help -h    Show this help message and exit.
```

If you don't like the auto-generated value text, you can change it. For example

`parser:add_parameter({ name = "--fizz", nargs="+", help="A word." })`

can be changed to
`parser:add_parameter({ name = "--fizz", nargs="+", value_hint="/path/to/file.txt", help="A word." })`

And the help message becomes

`--fizz /path/to/file.txt [/path/to/file.txt ...]    A word.`
</details>


<details>
<summary>Non-standard arguments support. e.g. `--foo`, `++bar`, `-f`, etc</summary>

The difference between a position parameter and a flag / named parameter is
just the prefix. Position parameters must start with alphanumeric text. But
this means that anything else can be a flag. e.g. `++foo` is a valid flag name
and so is `--bar`. It's all allowed.

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Position, flag, and named arguments support." })
parser:add_parameter({ name = "--fizz", action="store_true", help="A word." })
parser:add_parameter({ name = "++buzz", help="Some argument." })

parser:set_execute(function(data)
    print(string.format('--fizz: %s', data.namespace.fizz))
    print(string.format('++buzz: "%s"', data.namespace.buzz))
end)

cmdparse.create_user_command(parser)
```
Run: `:Test --fizz ++buzz "some text here"`
</details>

<details>
<summary>Unicode Parameters</summary>

You can use unicode for position / flag / named parameters if you want to.
```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Unicode Parameters." })
parser:add_parameter({ name = "𝒻ⓡ𝓊𝒾🅃🆂", nargs="+", help = "Test." })
parser:add_parameter({ name = "--😊", help = "Test." })

parser:set_execute(function(data)
    print(vim.fn.join(data.namespace["𝒻ⓡ𝓊𝒾🅃🆂"], ", "))
    print(data.namespace["--😊"])
end)

cmdparse.create_user_command(parser)
```
Run: `:Test apple 🄱🄰🄽🄰🄽🄰 --😊=ttt`
</details>


## API
Most people will use `mega.cmdparse` to create Neovim user commands but if you
want to use the Lua API directly, here are the most common cases.


### get_completions
You can query the available auto-complete values whenever you want.

<details>
<summary>Expand to show more</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new(
    { name = "Test", help = "Unicode Parameters." }
)
parser:add_parameter(
    { name = "--foo", choices = {"apple", "apply", "banana"}, help = "Test." }
)

print(vim.inspect(parser:get_completion("-")))
print(vim.inspect(parser:get_completion("--")))
print(vim.inspect(parser:get_completion("--f")))
print(vim.inspect(parser:get_completion("--fo")))
-- Result: {"--foo="}

print(vim.inspect(parser:get_completion("--foo=")))
-- Result: { "--foo=apple", "--foo=apply", "--foo=banana" }

print(vim.inspect(parser:get_completion("--foo=appl")))
-- Result: { "--foo=apple", "--foo=apply" }

print(vim.inspect(parser:get_completion("--foo appl")))
-- Result: { "apple", "apply" }
```

This also supports a cursor column position (starting at 1-or-more).

```lua
print(vim.inspect(parser:get_completion("--foo=appl", 4)))
-- Result: { "--foo=" }
```

</details>


### parse_arguments
You can compute the final values with `parse_arguments`.

<details>
<summary>Expand to show more</summary>

```lua
local cmdparse = require("mega.cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Unicode Parameters." })
parser:add_parameter({ name = "--foo", choices = {"apple", "apply", "banana"}, help = "Test." })
print(vim.inspect(parser:parse_arguments("--foo=apple")))
-- Result: { foo = "apple" }
```
</details>


# Installation
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/mega.cmdparse",
    dependencies = { "ColinKennedy/mega.logging" },
    version = "v1.*",
}
```


# Configuration
(These are default values)

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/mega.cmdparse",
    config = function()
        vim.g.cmdparse_configuration = {
            cmdparse = {
                auto_complete = { display = { help_flag = true } },  -- If `false`, don't show the `--help` flag anywhere.
            },
            logging = {
                level = "info", -- "trace" | "debug" | "info" | "warning" | "error" | "fatal"
                use_console = false,  -- Print to Neovim as the user is working
                use_file = false, -- Write to-disk as loggers run
            },
        }
    end
}
```


# Tests
## Initialization
Run this line once before calling any `busted` command

```sh
eval $(luarocks path --lua-version 5.1 --bin)
```


## Running
Run all tests
```sh
luarocks test --test-type busted
# Or manually
busted --helper spec/minimal_init.lua .
# Or with Make
make test
```

Run test based on tags
```sh
busted --helper spec/minimal_init.lua . --tags=simple
```


# Tracking Updates
See [doc/news.txt](doc/news.txt) for updates.

You can watch this plugin for changes by adding this URL to your RSS feed:
```
https://github.com/ColinKennedy/mega.cmdparse/commits/main/doc/news.txt.atom
```


# Other Plugins
This template is full of various features. But if your plugin is only meant to
be a simple plugin and you don't want the bells and whistles that this template
provides, consider instead using
[nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template)

# cmdparse.nvim

| <!-- -->     | <!-- -->                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Build Status | [![unittests](https://img.shields.io/github/actions/workflow/status/ColinKennedy/cmdparse.nvim/test.yml?branch=main&style=for-the-badge&label=Unittests)](https://github.com/ColinKennedy/cmdparse.nvim/actions/workflows/test.yml)  [![documentation](https://img.shields.io/github/actions/workflow/status/ColinKennedy/cmdparse.nvim/documentation.yml?branch=main&style=for-the-badge&label=Documentation)](https://github.com/ColinKennedy/cmdparse.nvim/actions/workflows/documentation.yml)  [![luacheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/cmdparse.nvim/luacheck.yml?branch=main&style=for-the-badge&label=Luacheck)](https://github.com/ColinKennedy/cmdparse.nvim/actions/workflows/luacheck.yml) [![llscheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/cmdparse.nvim/llscheck.yml?branch=main&style=for-the-badge&label=llscheck)](https://github.com/ColinKennedy/cmdparse.nvim/actions/workflows/llscheck.yml) [![stylua](https://img.shields.io/github/actions/workflow/status/ColinKennedy/cmdparse.nvim/stylua.yml?branch=main&style=for-the-badge&label=Stylua)](https://github.com/ColinKennedy/cmdparse.nvim/actions/workflows/stylua.yml)  [![urlchecker](https://img.shields.io/github/actions/workflow/status/ColinKennedy/cmdparse.nvim/urlchecker.yml?branch=main&style=for-the-badge&label=URLChecker)](https://github.com/ColinKennedy/cmdparse.nvim/actions/workflows/urlchecker.yml)  |
| License      | [![License-MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](https://github.com/ColinKennedy/cmdparse.nvim/blob/main/LICENSE)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Social       | [![RSS](https://img.shields.io/badge/rss-F88900?style=for-the-badge&logo=rss&logoColor=white)](https://github.com/ColinKennedy/cmdparse.nvim/commits/main/doc/news.txt.atom)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

A [Python argparse-inspired](https://docs.python.org/3/library/argparse.html)
command mode parser for Neovim.


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
- TODO: Make a GIF


### Auto-generated `--help` parameter support
- TODO: Make a GIF


### Automated parameter validation
- TODO: Make a GIF


### 2 flag formats support
- TODO: Make a GIF


## Examples
- TODO: Finish this later
 - Add GIFs for each of these

<details>
<summary>Hello, World! Parser</summary>

```lua
local cmdparse = require("cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Hello, World!"})
parser:set_execute(function(data) print("Hello, World!") end)
cmdparse.create_user_command(parser)
```
Run: `:Test`
</details>

<details>
<summary>Automated value type conversions</summary>

```lua
local cmdparse = require("cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Hello, World!" })
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
local cmdparse = require("cmdparse")

local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Hello, World!" })
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

TODO: Finish
<details>
<summary>Position, flag, and named arguments support. e.g. `foo bar --fizz=buzz -z`</summary>
</details>

TODO: Finish
<details>
<summary>Supports required / optional arguments</summary>

By default, flag / named arguments like `--foo` or `--foo=bar` are optional.
By default, position arguments like `thing` are required.

But you can explicitly make flag / named arguments required or position
arguments optional, using `required=true` and `required=false`.

TODO Finish
```lua
```
</details>

<details>
<summary>Nested Subparsers</summary>

```lua
local cmdparse = require("cmdparse")

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

TODO: Why does this not error if a choice is not selected? FIX
<details>
<summary>Static Auto-Complete Values</summary>

```lua
local cmdparse = require("cmdparse")

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
local cmdparse = require("cmdparse")

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

TODO: Finish
<details>
<summary>Dynamic Plug-ins</summary>

Subparsers are not static, you can create dynamic subparsers with dynamic names
and dynamic contents if you'd like. This makes `cmdparse.nvim` great for
writing a plugin that supports CLI hooks, like how
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) behaves.

```lua
```
</details>

TODO: Finish
<details>
<summary>Customizable / Automated `--help` flag</summary>

```lua
```
</details>


TODO: Make sur to explain that ++ / etc flags are just considered a regular flag
<details>
<summary>Non-standard arguments support. e.g. `--foo`, `++bar`, `-f`, etc</summary>

```lua
```
</details>

TODO: Add unicode characters
<details>
<summary>Non-Standard Flags. e.g. `++foo`, `--unicode-thing`</summary>

```lua
```
</details>


## API
Most people will use `cmdparse.nvim` to create Neovim user commands but if you
want to use the Lua API directly, here are the most common cases.


### get_completions
You can query the available auto-complete values whenever you want.

```lua
TODO
```

This also supports a cursor column position (starting at 1-or-more).

TODO


### parse_arguments
TODO: Finish



# Installation
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/cmdparse.nvim",
    version = "v1.*",
}
```


# Configuration
(These are default values)

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/cmdparse.nvim",
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
https://github.com/ColinKennedy/cmdparse.nvim/commits/main/doc/news.txt.atom
```


# Other Plugins
This template is full of various features. But if your plugin is only meant to
be a simple plugin and you don't want the bells and whistles that this template
provides, consider instead using
[nvim-cmdparse](https://github.com/ellisonleao/nvim-plugin-template)

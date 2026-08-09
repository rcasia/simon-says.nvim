# simon-says.nvim

Classic Simon Says memory game for Neovim, built with [ascii-ui.nvim](https://github.com/rcasia/ascii-ui.nvim).

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "rcasia/simon-says.nvim",
    dependencies = { "rcasia/ascii-ui.nvim" },
}
```

## Usage

Run `:SimonSays` to start the game.

## Controls

- Arrow keys or h/j/k/l to navigate
- Enter to select
- q to quit

## Development

### Running tests

```bash
make test
```

Tests require `plenary.nvim` (cloned automatically by the test script).

## License

MIT

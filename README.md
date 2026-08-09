# simon-says.nvim

Classic Simon Says memory game for Neovim, built with [ascii-ui.nvim](https://github.com/rcasia/ascii-ui.nvim).

![Simon Says gameplay](https://via.placeholder.com/400x300.png?text=Simon+Says+Screenshot)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "rcasia/simon-says.nvim",
    dependencies = { "rcasia/ascii-ui.nvim" },
    config = function()
        -- Optional: set keymap
        vim.keymap.set("n", "<leader>sg", ":SimonSays<CR>", { desc = "Simon Says game" })
    end,
}
```

## Usage

Run `:SimonSays` to start the game.

## How to Play

Simon Says is a memory game where you repeat an increasingly long sequence of colors.

1. **Watch**: The game shows a sequence of colored quadrants lighting up
2. **Repeat**: Press the same sequence using the colored quadrants
3. **Progress**: Each successful round adds one more color to the sequence
4. **Game Over**: Press the wrong color and the game ends

## Controls

| Action | Keys |
|--------|------|
| Navigate quadrants | Arrow keys or `h`/`j`/`k`/`l` |
| Select quadrant | `Enter` |
| Direct select | `1`-`4` (top-left, top-right, bottom-left, bottom-right) |
| Quit | `q` |

## Quadrant Layout

```
╔════════════╦════════════╗
║            ║            ║
║   GREEN    ║    RED     ║
║  (top-left)║ (top-right)║
║            ║            ║
╠════════════╬════════════╣
║            ║            ║
║  YELLOW    ║    BLUE    ║
║(bottom-left)║(bottom-right)
║            ║            ║
╚════════════╩════════════╝
```

## Scoring

- **Score**: Increments for each completed round
- **High Score**: Persists across games in the same session

## Development

### Running tests

```bash
make test
```

Tests require `plenary.nvim` (cloned automatically by the test script).

### Linting

```bash
make lint
```

Requires `luacheck`.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Ensure tests pass (`make test`)
4. Ensure linting passes (`make lint`)
5. Submit a pull request

## License

MIT © 2026 Ricardo Casaria

## Credits

Built with [ascii-ui.nvim](https://github.com/rcasia/ascii-ui.nvim) — a React-like UI framework for Neovim.

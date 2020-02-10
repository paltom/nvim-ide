# Features & Requirements

This document describes features that Neovim-based IDE will have. It also
specifies requirements.

# Document conventions

File locations are relative to Neovim's configuration home directory
(`$HOME/.config/nvim` on Linux).

Used abbreviations:
- Ext-Req: External requirement

  Requirement that has to be fulfilled outside of Neovim configuration.
  Example: Installing tool used by Neovim.

- Req: Requirement

  Requirement that is fulfilled by this project.

- Int-Req: Internal requirement

  Requirement that has to be fulfilled by Neovim software. Example: floating
  windows.

- How: How the feature is implemented (e.g. mapping, autocommand, function,
  plugin)

- Where: Which pack(s) / plugin(s) / file(s) / function(s) / augroup(s), etc.
  implement given feature.

# Feature Sets

Feature set hierarchy that this project aims for.

## Configuration

Features and requirements for configuration.

- Where: All static configuration (settings, mappings, autocommands, without
functions) are located in `init.vim` file.

1.  Clipboard

    Ext-Req: Clipboard tool is available in the system (:help clipboard-tool)

    1.  Yank text into clipboard

        1.  Yank line (Normal mode)

            - Req: Convenient way to yank current line into clipboard
            - How: mapping, `gY`

        2.  Yank text (Normal mode)

            - Req: Convenient way to yank text into clipboard
            - Req: It should allow motions (:help movement)
            - Req: It should allow text objects (:help text-objects)
            - How: mapping, `gy`

        3.  Yank text (Visual mode)

            - Req: Convenient way to yank visually selected text into clipboard
            - How: mapping (visual), `gy`

    2.  Put text from clipboard

        1.  Put text (Normal mode)

            - Req: Convenient way to put text from clipboard after cursor
            - How: mapping, `gp`
            - Req: It should preserve a way to put and move cursor after new
              text (:help gP)
            - How: mapping, `gap`
            - Req: Convenient way to put text from clipboard before cursor
            - How: mapping, `gP`
            - Req: It should preserve a way to put and move cursor after new
              text (:help gP)
            - How: mapping, `gaP`

        2.  Put line (Normal mode)

            - Req: Convenient way to put line from clipboard above current line
            - How: mapping, `gOp`
            - Req: Convenient way to put line from clipboard below current line
            - How: mapping, `gop`

        3.  Put text (Insert mode)

            - Req: Convenient way to put text from clipboard after cursor and
              stay in insert mode (cursor after put text)
            - How: mapping (insert), `<c-v>`
            - Req: It should preserve a way to put special characters in insert
              mode (:help i_ctrl-v)
            - How: mapping (insert), `<c-g><c-v>`

        4.  Put text (Visual mode)

            - Req: Convenient way to put text from clipboard in place of
              visually selected text
            - How: mapping (visual), `gp`

## Plugins

### Basic

### IDE

<!-- vim:set textwidth=80 sts=2 ts=2 sw=2: -->

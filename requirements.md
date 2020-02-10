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

- Int-Req: Internal requirement

  Requirement that has to be fulfilled by Neovim software. Example: floating
  windows.

- Where: Which pack(s) / plugin(s) / file(s), etc. implement given feature.

# Feature Sets

Feature set hierarchy that this project aims for.

## Configuration

Features and requirements for configuration.

- Where: All static configuration (settings, mappings, autocommands, without
functions) are located in `init.vim` file, unless specified otherwise.

1.  Clipboard

    Ext-Req: Clipboard tool is available in the system (:help clipboard-tool)

    1.  Text can be conveniently yanked into clipboard

        - Yank current line into clipboard: `gY` mapping
        - Yank text into clipboard: `gy` mapping
          - allow motions (:help movement)
          - allow text objects (:help text-objects)
        - Yank visually selected text into clipboard: `gy` mapping

    2.  Text can be conveniently put from clipboard

        - Put text from clipboard after cursor: `gp` mapping
          - Preserve a way to put text with cursor left at the end of new text:
            `gap` mapping
        - Put text from clipboard before cursor: `gP` mapping
          - Preserve a way to put text with cursor left at the end of new text:
            `gaP` mapping
        - Put line from clipboard above current line: `gOp` mapping
        - Put line from clipboard below current line: `gop` mapping
        - Put text from clipboard in insert mode: `<c-v>` mapping
          - Stay in insert mode
          - Cursor just after new text
          - Preserve a way to insert special characters: `<c-g><c-v>` mapping
        - Put text from clipboard in place of visually selected text: `gp`
          mapping

2.  Basic text auto-formatting

    1.  Tabulation

        1.  Req: Always insert spaces instead of tabs
            - How: option, `expandtab`

        2.  Req: Tabs are represented as 4 spaces by default
            - How: option, `tabstop`
            - How: option, `softtabstop`

        3.  Req: Existing tab characters are replaced by spaces
  <!-- change autocommand name -->
            - How: autocommand, `format_white_characters` augroup

    2.  Indentation

        1.  Req: Indent lines automatically after opening and before closing
            braces
            - How: option, `smartindent`
        2.  Req: Preserve indentation when continuing inserting text in next
            line
            - How: option, `autoindent`
        3.  Req: Indent/dedent lines by tab-width equivalent (4 spaces by
            default)
            - How: option, `shiftwidth`
        4.  Req: Indent/dedent lines rounding to nearest multiple of tab-width
            equivalent
            - How: option, `shiftround`

    3.  Whitespace characters formatting

        1.  Req: Remove trailing whitespaces automatically when writing file
  <!-- change autocommand name -->
            - How: autocommand, `format_white_characters` augroup

        2.  Req: Provide a way to disable automatic trailing whitespaces removal
            - How: variable, `g:remove_trailing_whitespaces`
            - How: function, `config#toggle_trail_whitespaces_removal`
              - Where: `autoload/config.vim`

## Plugins

### Basic

### IDE

<!-- vim:set textwidth=80 sts=2 ts=2 sw=2 fdm=indent: -->

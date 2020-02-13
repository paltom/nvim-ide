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

    1.  Tab characters are replaced by spaces

        - Tab character is replaced by 4 spaces by default when entering new
          text: `expandtab`, `tabstop`, `softtabstop` options
        - Tab characters existing already in edited file are replaced on file
          write: `config_replace_tabs` augroup

    2.  Indentation is done automatically

        - Lines are indented automatically after opening and before closing
          braces or a line starting with specific keyword (if, for example):
          `smartindent` option
        - Indentation is preserved when text in inserted in next line:
          `autoindent` option
        - Lines can be indented/dedented by tab-width equivalent: `shiftwidth`
          option
          - Indentation/dedentation is rounded to the nearest multiple of
            tab-width equivalent: `shiftround` option

    3.  Whitespace characters formatting

        - Trailing whitespaces are removed automatically:
          `config_remove_trailing_whitespaces` augroup
          - When file is written
          - There is a way to turn it off: `g:remove_trailing_whitespaces`
            variable, `config#toggle_trailing_whitespaces_removal` function
            (`autoload/config.vim`)

3.  Moving around

    1.  Moving between windows

        - Move to another window: `<a-h>`, `<a-j>`, `<a-k>`, `<a-l>` mappings
          - Move also when in insert mode
          - Move also when in visual mode
          - Move also from terminal window without going out of terminal mode
        - Switch between current/alternate (:help alternate-file) buffer:
          `<backspace>` mapping

    2.  Moving between tabpages

        - Move to previous tabpage: `[t` mapping
        - Move to next tabpage: `]t` mapping
          - Cycle through tabpages: `<c-t>t`, `<c-t><c-t>` mappings
        - [ ] Move to the first, last tabpage: `[T`, `]T` mappings

    3.  Moving inside window

        - Easily move to the beginning, end of line: `H`, `L` mappings
          - Work also as text-object (motion target): operator type mapping

    4.  Moving between search results

        - Move to the next/previous search result
          - Use location list/quickfix list
          - If there are both location list and quicklist for current window,
            location list has precedence

    5.  Selecting completions

        - Trigger/select popupmenu with completions: `<c-j>`, `<c-k>` mappings
        - Trigger wildmenu: `<tab>` character, `wildcharm` option
        - Move up/down (same directory) in wildmenu options: `<c-j>`, `<c-k>`,
          `<down>`, `<up>` mappings
        - Move between directories in wildmenu list: `<c-h>`, `<c-l>`, `<left>`,
          `<right>` mappings

4.  Mode switching

    1.  Switch out from terminal mode

        - Easily switch out of terminal mode: `<c-w>` mapping

5.  Searching

    1.  Search command

        - Case is ignored when only lower-cased characters are used:
          `ignorecase`, `smartcase` options

    2.  Search highlighting

        - Search results are highlighted only during entering search pattern:
          `nohlsearch`, `incsearch` options, `config_highlight_searches` augroup

    3.  Search visual selection

        - Search visually selected text: `/` visual mapping
          - Preserve a way to go to search in visual mode: `g/` visual mapping
          - Text is also available in unnamed register after searching for it

[ ] Colorscheme: allow switching between dark/light backgrounds (update
statusline highlights)

## Plugins

### Basic

### IDE

<!-- vim:set textwidth=80 sts=2 ts=2 sw=2 fdm=indent: -->

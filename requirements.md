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

1. Clipboard
   
   Ext-Req: Clipboard tool is available in the system (:help clipboard-tool)
   1. Yank text into clipboard
      1. Yank line (Normal mode)
         
         There is convenient mapping that yanks current line into
         clipboard
         - How: mapping, `gY`
            
      2. Yank text (Normal mode)
         
         There is convenient mapping that yanks text into clipboard.
         - Req: It should allow motions (:help movement)
         - Req: It should allow text objects (:help text-objects)
         - How: mapping, `gy`
            
      3. Yank text (Visual mode)
         
         There is a convenient mapping that yanks visually selected text.
         - How: mapping (visual), `gy`

## Plugins

### Basic

### IDE

<!-- vim:set textwidth=80: -->

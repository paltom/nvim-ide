local configs = require "nvim_lsp/configs"
local util = require "nvim_lsp/util"

local root_pattern = util.root_pattern("project.clj", ".git")
configs.clojure_lsp = {
  default_config = {
    cmd = {"clojure-lsp"};
    filetypes = {"clojure"};
    root_dir = function(fname)
      return root_pattern(fname) or util.path.dirname(fname)
    end;
  };
  docs = {
    description = [[
https://github.com/snoe/clojure-lsp

Language Server (LSP) for Clojure
    ]];
  }
}

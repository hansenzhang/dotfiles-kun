-- Rex config. Reload with `rex config reload`; check with `rex config check`.

-- Opens `cmd` in a large floating pane at the focused pane's working directory. The pane closes
-- when cmd exits. zsh -ic because Rex starts with the GUI PATH, which lacks the Nix profile and Homebrew.
local function tool_float(ctx, cmd, bounds)
  local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
  local fg = proc and proc.foreground
  local _, err = rex.session.new_layer{
    bounds = bounds,
    focus  = true,
    layout = {
      block = {
        flavor  = "com.superlogical.terminal.shell",
        label   = cmd,
        options = { cwd = fg and fg.cwd, command = { "zsh", "-ic", "exec " .. cmd } },
      },
    },
  }
  if err ~= nil then error(err, 0) end
end

rex.action{
  name  = "git_float",
  title = "Git: lazygit in a Floating Pane",
  run   = function(ctx) tool_float(ctx, "lazygit", { 0.03, 0.03, 0.94, 0.94 }) end,
}

rex.action{
  name  = "nvim_float",
  title = "Neovim in a Floating Pane",
  run   = function(ctx) tool_float(ctx, "nvim", { 0.6, 0.0, 0.4, 1.0 }) end,
}

-- tmux-style bindings with ctrl+s as the leader. Shifted tmux keys assume a US layout.
-- ctrl+s starts a sequence, so it no longer reaches the terminal alone. Press it twice to send it.
local leader = "ctrl+s>"

local function bind(key, action, args)
  rex.bind(leader .. key, action, args)
end

bind("ctrl+s", "pane.send_key", { key = "ctrl+s" })

-- Tabs (tmux windows)
bind("c", "client.tab.new")
bind("n", "client.tab.next")
bind("p", "client.tab.previous")
bind("shift+7", "client.tab.close")    -- &
bind(",", "client.tab.rename")
for i = 1, 9 do
  bind(tostring(i), "client.tab.goto", { index = i })
end

-- Panes
bind("shift+5", "pane.split", { direction = "right" })  -- %
bind("shift+'", "pane.split", { direction = "down" })   -- "
bind("left", "pane.focus.left")
bind("right", "pane.focus.right")
bind("up", "pane.focus.up")
bind("down", "pane.focus.down")
bind("o", "pane.focus_next")
bind("z", "pane.zoom")
bind("x", "pane.close")
bind("shift+1", "pane.move_to_new_tab")  -- !
bind("space", "pane.balance")
bind("ctrl+left", "pane.resize", { direction = "left" })
bind("ctrl+right", "pane.resize", { direction = "right" })
bind("ctrl+up", "pane.resize", { direction = "up" })
bind("ctrl+down", "pane.resize", { direction = "down" })

-- Sessions
bind("s", "session.switch")
bind("shift+4", "session.rename")  -- $
bind("shift+9", "session.previous")  -- (
bind("shift+0", "session.next")  -- )

-- Tools
bind("g", "git_float")
bind("e", "nvim_float")

-- Misc
bind("shift+;", "client.palette.toggle")  -- :

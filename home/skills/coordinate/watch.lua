-- Watch one worker block's program status and print a line only when the
-- coordinator should look. Run under Monitor:
--   rex do -s <session> --for 30m ~/.claude/skills/coordinate/watch.lua block=<block-id>
-- Prints one line per wake:
--   blocked/permission: <msg>    blocked/question, blocked/auth
--   idle: <msg>                  only after working or blocked (a cancelled turn)
--   done: <msg>, error: <msg>
--   gone: program exited | block closed   (then stops)
-- `working` updates and repeats of the same state print nothing.

local block = (rex.args or {}).block
if not block then
  error("pass block=<block-id>")
end
-- Events carry the prefixed form, and program_status returns nothing for a
-- bare UUID, so accept both.
if not block:find("^block:") then
  block = "block:" .. block
end

local last = nil -- "state/kind" of the last record seen

local function line(state, kind, msg)
  local head = state
  if kind and kind ~= "" then
    head = state .. "/" .. kind
  end
  msg = tostring(msg or ""):gsub("[\r\n\t]", " ")
  print(head .. ": " .. msg)
  io.stdout:flush()
end

-- The root record has no id; records with an id are sub-records such as
-- progress marks and do not describe the worker's own state.
local function observe(record, initial)
  if not record or record.id then
    return
  end
  local state = record.state or "idle"
  local key = state .. "/" .. (record.kind or "")
  if key == last then
    return
  end
  local prev = last
  last = key
  if state == "blocked" or state == "done" or state == "error" then
    line(state, record.kind, record.msg)
  elseif state == "idle" and not initial and prev and (prev:sub(1, 8) == "working/" or prev:sub(1, 8) == "blocked/") then
    line(state, nil, record.msg)
  end
end

local function gone(why)
  line("gone", nil, why)
  rex.stop(0)
end

rex.on("terminal.program_status_changed", function(ctx, ev)
  if ctx.block_id == block then
    observe(ev.record, false)
  end
end)

rex.on("terminal.child_exited", function(ctx)
  if ctx.block_id == block then
    gone("program exited")
  end
end)

rex.on("block_closed", function(_, ev)
  if ev.block_id == block then
    gone("block closed")
  end
end)

-- Read the current status once the handlers listen, so an edge between the
-- two is not lost.
rex.after(0, function()
  local ok, res = pcall(rex.call, "com.superlogical.terminal.program_status", {
    session_id = rex.session_id,
    block_id = block,
    args = {},
  })
  if not ok or not res then
    gone("status read failed: " .. tostring(res or "no such block"))
    return
  end
  for _, record in ipairs(res.records or {}) do
    observe(record, true)
  end
end)

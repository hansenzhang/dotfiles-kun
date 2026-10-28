-- Counts normal/visual-mode keys to track practice (see practice.md in the repo root).
-- Insert and command-line keys are never seen, and only counts are stored, not text.
-- Written per day to stdpath('state')/keystats.json on exit.

local path = vim.fn.stdpath('state') .. '/keystats.json'
local session = { keys = {}, leader = {}, long_runs = {} }
local prev, run_key, run_len = nil, nil, 0
local RUN_KEYS = { h = true, j = true, k = true, l = true, w = true, b = true }
local LONG_RUN = 4  -- pressing the same key this many times in a row counts as a long run

local function bump(t, k, n)
  t[k] = (t[k] or 0) + (n or 1)
end

local function end_run()
  if run_key and run_len >= LONG_RUN then
    bump(session.long_runs, run_key)
  end
  run_key, run_len = nil, 0
end

-- The next key after these is an argument (f{char}, ma, qa, @a), not a command.
local ARG_KEYS = { f = true, F = true, t = true, T = true, r = true, m = true,
  ["'"] = true, ['`'] = true, q = true, ['@'] = true }

-- which-key reads the keys after a prefix itself, then replays prefix + keys as typed
-- input (key by key, or as one chunk for its own mappings). wk_seq holds what it read,
-- replay the part of that replay still to skip.
local wk_seq, replay = '', ''

local function wk_active()
  local ok, st = pcall(require, 'which-key.state')
  return ok and st.state ~= nil
end

vim.on_key(function(_, typed)
  -- typed is empty for keys that come from mappings or macros
  if not typed or typed == '' then return end
  local mode = vim.api.nvim_get_mode().mode
  if not (mode:find('^n') or mode:find('^[vV\22]')) then
    prev, wk_seq, replay = nil, '', ''
    return
  end

  local key = vim.fn.keytrans(typed)
  if wk_active() then
    if wk_seq == '' then wk_seq = prev or '' end
    wk_seq = wk_seq .. key
  else
    if wk_seq ~= '' then replay, wk_seq = wk_seq, '' end
    if replay ~= '' and replay:sub(1, #key) == key then
      replay = replay:sub(#key + 1)
      return
    end
    replay = ''
  end

  if ARG_KEYS[prev] then
    prev = nil
    return
  end
  -- a whole mapping typed faster than which-key triggers arrives as one chunk
  local chord = key:match('^<Space>(.+)')
  if chord then
    bump(session.keys, '<Space>')
    bump(session.leader, key)
    prev = nil
    return
  end

  bump(session.keys, key)
  if prev == '<Space>' then bump(session.leader, '<Space>' .. key) end

  if RUN_KEYS[key] and key == run_key then
    run_len = run_len + 1
  else
    end_run()
    if RUN_KEYS[key] then run_key, run_len = key, 1 end
  end
  prev = key
end, vim.api.nvim_create_namespace('keystats'))

local function merge(into, from)
  for k, n in pairs(from) do bump(into, k, n) end
end

vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    end_run()
    if next(session.keys) == nil then return end
    local all = {}
    local f = io.open(path, 'r')
    if f then
      local ok, data = pcall(vim.json.decode, f:read('*a'))
      f:close()
      if ok and type(data) == 'table' then all = data end
    end
    local today = os.date('%Y-%m-%d')
    all[today] = all[today] or { keys = {}, leader = {}, long_runs = {}, sessions = 0 }
    local day = all[today]
    for _, field in ipairs({ 'keys', 'leader', 'long_runs' }) do
      day[field] = day[field] or {}
      merge(day[field], session[field])
    end
    day.sessions = (day.sessions or 0) + 1
    f = io.open(path, 'w')
    if f then
      f:write(vim.json.encode(all))
      f:close()
    end
  end,
})

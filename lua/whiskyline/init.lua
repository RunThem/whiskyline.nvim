local whk = { bg = '#202328' }

local co, api = coroutine, vim.api
local p = require('whiskyline.provider')
local S = p.sep

local funs = {
  p.sk,
  S,

  S,
  p.mode,
  S,

  S,
  p.lsp,
  S,

  S,
  p.diag,
  S,

  S,
  p.filesize,
  p.fileicon,
  p.fileinfo,
  S,

  p.pad,

  S,
  p.lnumcol,
  S,

  S,
  p.encoding,
  S,

  S,
  p.sk,
}

local function stl_format(name, val)
  return '%#Whisky' .. name .. '#' .. val .. '%*'
end

local function stl_hl(name, attr)
  if attr.fn then
    attr = attr.fn()
  end

  if name ~= 'sk' then
    attr.bg = whk.bg
  end

  api.nvim_set_hl(0, 'Whisky' .. name, attr)
end

local function default()
  local comps, events, pieces = {}, {}, {}

  for idx, fun in ipairs(funs) do
    local item = fun()

    comps[idx] = item
    pieces[idx] = type(item.stl) == 'string' and stl_format(item.name, item.stl) or ''

    if type(item.stl) == 'function' or item.attr['fn'] then
      for _, event in ipairs(item.event or {}) do
        if not events[event] then
          events[event] = {}
        end

        table.insert(events[event], idx)
      end
    end

    stl_hl(item.name, item.attr)
  end

  return comps, events, pieces
end

local function render(comps, events, pieces)
  return co.create(function(args)
    while true do
      local event = args.event

      for _, idx in ipairs(events[event]) do
        if type(comps[idx].stl) == 'function' then
          pieces[idx] = stl_format(comps[idx].name, comps[idx].stl(args))
        end

        if comps[idx].attr['fn'] then
          stl_hl(comps[idx].name, comps[idx].attr)
        end
      end

      vim.opt.stl = table.concat(pieces)
      args = co.yield()
    end
  end)
end

function whk.setup()
  local comps, events, pieces = default()
  local stl_render = render(comps, events, pieces)

  for _, event in ipairs(vim.tbl_keys(events)) do
    api.nvim_create_autocmd(event, {
      callback = function(args)
        vim.schedule(function()
          local ok, res = co.resume(stl_render, args)
          if not ok then
            vim.notify('[Whisky] render failed ' .. res, vim.log.levels.ERROR)
          end
        end)
      end,
    })
  end
end

return whk

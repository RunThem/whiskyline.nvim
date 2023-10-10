local co, api = coroutine, vim.api
local whk = {}

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
  local p = require('whiskyline.provider')
  local s = require('whiskyline.separator')

  local S = s.sep

  return {
    s.sk,
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
    s.sk,
  }
end

local function whk_init(event, pieces)
  whk.cache = {}
  for i, e in ipairs(whk.elements) do
    local res = e()

    if res.event and vim.tbl_contains(res.event, event) then
      local val = type(res.stl) == 'function' and res.stl() or res.stl
      pieces[#pieces + 1] = stl_format(res.name, val)
    elseif type(res.stl) == 'string' then
      pieces[#pieces + 1] = stl_format(res.name, res.stl)
    else
      pieces[#pieces + 1] = stl_format(res.name, '')
    end

    if res.attr then
      stl_hl(res.name, res.attr)
    end

    whk.cache[i] = {
      event = res.event,
      name = res.name,
      stl = res.stl,
    }
  end

  require('whiskyline.provider').initialized = true
  return table.concat(pieces, '')
end

local stl_render = co.create(function(event)
  local pieces = {}
  while true do
    if not whk.cache then
      whk_init(event, pieces)
    else
      for i, item in ipairs(whk.cache) do
        if item.event and vim.tbl_contains(item.event, event) and type(item.stl) == 'function' then
          local comp = whk.elements[i]
          local res = comp()
          if res.attr then
            stl_hl(item.name, res.attr)
          end
          pieces[i] = stl_format(item.name, res.stl(event))
        end
      end
    end

    vim.opt.stl = table.concat(pieces)
    event = co.yield()
  end
end)

function whk.setup(opt)
  opt = opt or { bg = '#202328' }
  whk.bg = opt.bg
  whk.elements = default()

  local events = {
    'LspProgress',
    'DiagnosticChanged',
    'ModeChanged',
    'BufEnter',
    'BufWritePost',
    'LspAttach',
    'LspDetach',
  }

  api.nvim_create_autocmd(events, {
    callback = function(arg)
      vim.schedule(function()
        co.resume(stl_render, arg.event)
      end)
    end,
  })
end

return whk

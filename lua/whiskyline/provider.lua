local api, uv = vim.api, vim.uv
local pd = {}

local function stl_attr(group)
  local color = api.nvim_get_hl_by_name(group, true)
  return { fg = color.foreground }
end

function pd.mode()
  local result = {
    stl = function()
      return ' '
    end,
    name = 'mode',
    event = { 'ModeChanged', 'BufEnter' },
    attr = {
      fn = function()
        local colors = {
          ['n'] = '#ec5f67',
          ['no'] = '#51afef',
          ['v'] = '#51afef',
          ['V'] = '#51afef',
          ['i'] = '#98be65',
          ['\x16'] = '#51afef',
        }

        local mode = api.nvim_get_mode().mode

        return {
          fg = colors[mode] or colors[1],
        }
      end,
    },
  }

  return result
end

local function path_sep()
  return uv.os_uname().sysname == 'Windows_NT' and '\\' or '/'
end

local resolve

local function init_devicon()
  if resolve then
    return
  end
  local ok, devicon = pcall(require, 'nvim-web-devicons')
  if not ok then
    return
  end
  resolve = devicon
end

function pd.filesize()
  local stl_size = function()
    local size = vim.fn.getfsize(api.nvim_buf_get_name(0))

    if size == 0 or size == -1 or size == -2 then
      return ''
    end

    if size < 1024 then
      size = size .. 'b'
    elseif size < 1024 * 1024 then
      size = string.format('%.1f', size / 1024) .. 'k'
    elseif size < 1024 * 1024 * 1024 then
      size = string.format('%.1f', size / 1024 / 1024) .. 'm'
    else
      size = string.format('%.1f', size / 1024 / 1024 / 1024) .. 'g'
    end
    return size .. ' '
  end

  return {
    stl = stl_size,
    name = 'filesize',
    event = { 'BufEnter' },
    attr = {
      fg = 'NONE',
    },
  }
end

function pd.fileicon()
  if not resolve then
    init_devicon()
  end

  local icon, color = resolve.get_icon_color_by_filetype(vim.bo.filetype, { default = true })
  return {
    stl = function()
      return icon .. ' '
    end,
    name = 'fileicon',
    event = { 'BufEnter' },
    attr = {
      fg = color,
    },
  }
end

function pd.fileinfo()
  local function stl_file()
    local fname = api.nvim_buf_get_name(0)
    local sep = path_sep()
    local parts = vim.split(fname, sep, { trimempty = true })
    local index = #parts - 1 <= 0 and 1 or #parts - 1
    fname = table.concat({ unpack(parts, index) }, sep)
    if #fname == 0 then
      fname = 'UNKNOWN'
    end
    return fname .. '%m'
  end

  return {
    stl = stl_file,
    name = 'fileinfo',
    event = { 'BufEnter' },
    attr = stl_attr('Comment'),
  }
end

function pd.lsp()
  local function lsp_stl(event)
    local msg = vim.lsp.status()
    if (#msg == 0 or not msg:find('^%d')) and event ~= 'LspDetach' then
      local client = vim.lsp.get_active_clients({ bufnr = 0 })
      if #client ~= 0 then
        msg = client[1].name
      end
    end

    if msg ~= '' then
      msg = ' '
    end

    return '%.40{"' .. msg .. '"}'
  end

  return {
    stl = lsp_stl,
    name = 'Lsp',
    event = { 'LspProgress', 'LspAttach', 'LspDetach' },
    attr = stl_attr('Function'),
  }
end

function pd.pad()
  return {
    stl = '%=',
    name = 'pad',
    attr = {
      bg = 'NONE',
      fg = 'NONE',
    },
  }
end

function pd.lnumcol()
  return {
    stl = '%-4.(%l:%c%) %P',
    name = 'linecol',
    event = { 'CursorHold' },
    attr = stl_attr('Label'),
  }
end

function pd.encoding()
  return {
    stl = '%{&fileencoding?&fileencoding:&encoding}',
    name = 'filencode',
    event = { 'BufEnter' },
    attr = stl_attr('Type'),
  }
end

local function get_diag_sign(type)
  local prefix = 'DiagnosticSign'
  for _, item in ipairs(vim.fn.sign_getdefined()) do
    if item.name == prefix .. type then
      return item.text
    end
  end
end

local function diagnostic_info(severity)
  if vim.diagnostic.is_disabled(0) then
    return ''
  end

  local tbl = { 'Error', 'Warn', 'Info', 'Hint' }
  local count = #vim.diagnostic.get(0, { severity = severity })
  return count == 0 and '' or get_diag_sign(tbl[severity]) .. tostring(count) .. ' '
end

function pd.diagError()
  return {
    stl = function()
      return diagnostic_info(1)
    end,
    name = 'diagError',
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = stl_attr('DiagnosticError'),
  }
end

function pd.diagWarn()
  return {
    stl = function()
      return diagnostic_info(2)
    end,
    name = 'diagWarn',
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = stl_attr('DiagnosticWarn'),
  }
end

function pd.diagInfo()
  return {
    stl = function()
      return diagnostic_info(3)
    end,
    name = 'diaginfo',
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = stl_attr('DiagnosticInfo'),
  }
end

function pd.diagHint()
  return {
    stl = function()
      return diagnostic_info(4)
    end,
    name = 'diaghint',
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = stl_attr('DiagnosticHint'),
  }
end

return pd

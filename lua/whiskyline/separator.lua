local pd = require('whiskyline.provider')
local sp = {}

function sp.sk()
  return {
    stl = ' ',
    name = 'sk',
    attr = {
      background = '#51afef',
      foreground = 'NONE',
    },
  }
end

function sp.sep()
  return {
    stl = ' ',
    name = 'sep',
    attr = {
      bg = 'NONE',
      fg = 'NONE',
    },
  }
end

return sp

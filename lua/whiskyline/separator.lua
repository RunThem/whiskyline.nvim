local pd = require('whiskyline.provider')
local sp = {}

function sp.sk()
  return {
    stl = ' ',
    name = 'sk',
    attr = {
      bg = '#51afef',
      fg = 'NONE',
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

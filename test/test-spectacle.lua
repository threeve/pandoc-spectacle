local lu = require('test.luaunit')
local spectacle = require('spectacle')

local t = {}

function t.testHeader()
  local result = spectacle.Header(1, "text", {})
  local expected = "<Header size={1}>text</Header>"
  lu.assertEquals(result, expected)
end

return t

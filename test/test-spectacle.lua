local lu = require('test.luaunit')
local spectacle = require('spectacle')

local t = {}

function t.testHeader()
  local result = spectacle.Header(1, 'text', {id='meh'})
  local expected = '<Header size={1} id="meh">text</Header>'
  lu.assertEquals(result, expected)
end

function t.testPara()
  local result = spectacle.Para('paragraph')
  local expected = '<Text>paragraph</Text>'
  lu.assertEquals(result, expected)
end

function t.testImage()
  local result = spectacle.Image('', 'image.png', 'an image')
  local expected = '<Image src="image.png" />'
  lu.assertEquals(result, expected)
end

function t.testBlockQuote()
  local result = spectacle.BlockQuote('Be excellent to each other.')
  local expected = [[
<BlockQuote>
<Quote>Be excellent to each other.</Quote>
</BlockQuote>]]
  lu.assertEquals(result, expected)
end

function t.testCode()
  local result = spectacle.Code('let x = 10', {})
  local expected = '<Code>let x = 10</Code>'
  lu.assertEquals(result, expected)
end

function t.testCodeBlock()
  local result = spectacle.CodeBlock('let x = 10', {})
  local expected = '<CodePane>let x = 10</CodePane>'
  lu.assertEquals(result, expected)
end

function t.testLink()
  local result = spectacle.Link('spectacle',
                                'http://github.com/formidablelabs/spectacle',
                                '')
  local expected = '<Link href="http://github.com/formidablelabs/spectacle">spectacle</Link>'
  lu.assertEquals(result, expected)
end

function t.testOrderedList()
  local result = spectacle.OrderedList({"one", "two", "three"})
  local expected = [[
<List>
<ListItem>one</ListItem>
<ListItem>two</ListItem>
<ListItem>three</ListItem>
</List>]]
  lu.assertEquals(result, expected)
end

function t.testUnorderedList()
  local result = spectacle.BulletList({"one", "two", "three"})
  local expected = [[
<List>
<ListItem>one</ListItem>
<ListItem>two</ListItem>
<ListItem>three</ListItem>
</List>]]
  lu.assertEquals(result, expected)
end

return t

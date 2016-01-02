-- This is a spectacle custom writer for pandoc.  It produces output
-- for use as a slide show.
--
-- http://github.com/formidablelabs/spectacle
--
-- Invoke with: pandoc -t spectacle.lua
--
-- Note:  you need not have lua installed on your system to use this
-- custom writer.  However, if you do have lua installed, you can
-- use it to test changes to the script.  'lua spectacle.lua' will
-- produce informative error messages if your code contains
-- syntax errors.

local spectacle = {}

-- Character escaping
local function escape(s, in_attribute)
  return s:gsub("[<>&\"']",
    function(x)
      if x == '<' then
        return '&lt;'
      elseif x == '>' then
        return '&gt;'
      elseif x == '&' then
        return '&amp;'
      elseif x == '"' then
        return '&quot;'
      elseif x == "'" then
        return '&#39;'
      else
        return x
      end
    end)
end

-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
local function attributes(attr)
  local attr_table = {}
  for x,y in pairs(attr) do
    if y and y ~= "" then
      table.insert(attr_table, ' ' .. x .. '="' .. escape(y,true) .. '"')
    end
  end
  return table.concat(attr_table)
end

-- Run cmd on a temporary file containing inp and return result.
local function pipe(cmd, inp)
  local tmp = os.tmpname()
  local tmph = io.open(tmp, "w")
  tmph:write(inp)
  tmph:close()
  local outh = io.popen(cmd .. " " .. tmp,"r")
  local result = outh:read("*all")
  outh:close()
  os.remove(tmp)
  return result
end

-- Table to store footnotes, so they can be included at the end.
local notes = {}

-- Blocksep is used to separate block elements.
function spectacle.Blocksep()
  return "\n\n"
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will add do the template processing as
-- usual.
function spectacle.Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add(body)
  if #notes > 0 then
    add('<ol class="footnotes">')
    for _,note in pairs(notes) do
      add(note)
    end
    add('</ol>')
  end
  return table.concat(buffer,'\n') .. '\n'
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function spectacle.Str(s)
  return escape(s)
end

function spectacle.Space()
  return " "
end

function spectacle.LineBreak()
  return "<br/>"
end

function spectacle.Emph(s)
  return "<em>" .. s .. "</em>"
end

function spectacle.Strong(s)
  return "<strong>" .. s .. "</strong>"
end

function spectacle.Subscript(s)
  return "<sub>" .. s .. "</sub>"
end

function spectacle.Superscript(s)
  return "<sup>" .. s .. "</sup>"
end

function spectacle.SmallCaps(s)
  return '<span style="font-variant: small-caps;">' .. s .. '</span>'
end

function spectacle.Strikeout(s)
  return '<del>' .. s .. '</del>'
end

function spectacle.Link(s, src, tit)
  return "<a href='" .. escape(src,true) .. "' title='" ..
         escape(tit,true) .. "'>" .. s .. "</a>"
end

function spectacle.Image(s, src, tit)
  return "<img src='" .. escape(src,true) .. "' title='" ..
         escape(tit,true) .. "'/>"
end

function spectacle.Code(s, attr)
  return "<code" .. attributes(attr) .. ">" .. escape(s) .. "</code>"
end

function spectacle.InlineMath(s)
  return "\\(" .. escape(s) .. "\\)"
end

function spectacle.DisplayMath(s)
  return "\\[" .. escape(s) .. "\\]"
end

function spectacle.Note(s)
  local num = #notes + 1
  -- insert the back reference right before the final closing tag.
  s = string.gsub(s,
          '(.*)</', '%1 <a href="#fnref' .. num ..  '">&#8617;</a></')
  -- add a list item with the note to the note table.
  table.insert(notes, '<li id="fn' .. num .. '">' .. s .. '</li>')
  -- return the footnote reference, linked to the note.
  return '<a id="fnref' .. num .. '" href="#fn' .. num ..
            '"><sup>' .. num .. '</sup></a>'
end

function spectacle.Span(s, attr)
  return "<span" .. attributes(attr) .. ">" .. s .. "</span>"
end

function spectacle.Cite(s, cs)
  local ids = {}
  for _,cit in ipairs(cs) do
    table.insert(ids, cit.citationId)
  end
  return "<span class=\"cite\" data-citation-ids=\"" .. table.concat(ids, ",") ..
    "\">" .. s .. "</span>"
end

function spectacle.Plain(s)
  return s
end

function spectacle.Para(s)
  return "<p>" .. s .. "</p>"
end

-- lev is an integer, the header level.
function spectacle.Header(lev, s, attr)
  return "<Header size={" .. lev .. "}" .. attributes(attr) ..  ">" .. s .. "</Header>"
end

function spectacle.BlockQuote(s)
  return "<blockquote>\n" .. s .. "\n</blockquote>"
end

function spectacle.HorizontalRule()
  return "<hr/>"
end

function spectacle.CodeBlock(s, attr)
  -- If code block has class 'dot', pipe the contents through dot
  -- and base64, and include the base64-encoded png as a data: URL.
  if attr.class and string.match(' ' .. attr.class .. ' ',' dot ') then
    local png = pipe("base64", pipe("dot -Tpng", s))
    return '<img src="data:image/png;base64,' .. png .. '"/>'
  -- otherwise treat as code (one could pipe through a highlighter)
  else
    return "<pre><code" .. attributes(attr) .. ">" .. escape(s) ..
           "</code></pre>"
  end
end

function spectacle.BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<li>" .. item .. "</li>")
  end
  return "<ul>\n" .. table.concat(buffer, "\n") .. "\n</ul>"
end

function spectacle.OrderedList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<li>" .. item .. "</li>")
  end
  return "<ol>\n" .. table.concat(buffer, "\n") .. "\n</ol>"
end

-- Revisit association list STackValue instance.
function spectacle.DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer,"<dt>" .. k .. "</dt>\n<dd>" ..
                        table.concat(v,"</dd>\n<dd>") .. "</dd>")
    end
  end
  return "<dl>\n" .. table.concat(buffer, "\n") .. "\n</dl>"
end

-- Convert pandoc alignment to something HTML can use.
-- align is AlignLeft, AlignRight, AlignCenter, or AlignDefault.
local function html_align(align)
  if align == 'AlignLeft' then
    return 'left'
  elseif align == 'AlignRight' then
    return 'right'
  elseif align == 'AlignCenter' then
    return 'center'
  else
    return 'left'
  end
end

function spectacle.CaptionedImage(src, tit, caption)
   return '<div class="figure">\n<img src="' .. escape(src,true) ..
      '" title="' .. escape(tit,true) .. '"/>\n' ..
      '<p class="caption">' .. caption .. '</p>\n</div>'
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function spectacle.Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add("<table>")
  if caption ~= "" then
    add("<caption>" .. caption .. "</caption>")
  end
  if widths and widths[1] ~= 0 then
    for _, w in pairs(widths) do
      add('<col width="' .. string.format("%d%%", w * 100) .. '" />')
    end
  end
  local header_row = {}
  local empty_header = true
  for i, h in pairs(headers) do
    local align = html_align(aligns[i])
    table.insert(header_row,'<th align="' .. align .. '">' .. h .. '</th>')
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
    add('<tr class="header">')
    for _,h in pairs(header_row) do
      add(h)
    end
    add('</tr>')
  end
  local class = "even"
  for _, row in pairs(rows) do
    class = (class == "even" and "odd") or "even"
    add('<tr class="' .. class .. '">')
    for i,c in pairs(row) do
      add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. '</td>')
    end
    add('</tr>')
  end
  add('</table')
  return table.concat(buffer,'\n')
end

function spectacle.Div(s, attr)
  return "<div" .. attributes(attr) .. ">\n" .. s .. "</div>"
end

local module = ...
if module == nil then
  -- if the module name is nil we were simply loaded as a script.
  -- this is how pandoc loads it, so we do two things:
  -- - set a metatable index method to bark about missing functions
  -- - copy the spectacle module table to the global namespace

  -- The following code will produce runtime warnings when you haven't defined
  -- all of the functions you need for the custom writer, so it's useful
  -- to include when you're working on a writer.
  local meta = {}
  meta.__index =
    function(_, key)
      io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
      return function() return "" end
    end
  setmetatable(_G, meta)
  for k,v in pairs(spectacle) do _G[k] = v end
else
  -- if required as a module simply return the module table
  return spectacle
end

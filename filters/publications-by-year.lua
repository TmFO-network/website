-- Reads a .bib file, groups entries by year (newest first) and renders each
-- year as a level-2 heading followed by its formatted reference list.
-- The result replaces the div with id "publications-by-year" (or is appended
-- to the end of the document if no such div exists).

local function read_file(path)
  local f = io.open(path, "r")
  if not f then error("publications-by-year: cannot open " .. path) end
  local s = f:read("a")
  f:close()
  return s
end

local function year_of(ref)
  local issued = ref.issued
  if issued then
    local dp = issued["date-parts"]
    if dp and dp[1] and dp[1][1] then
      local y = pandoc.utils.stringify(dp[1][1]):match("%d%d%d%d")
      if y then return y end
    end
    local y = pandoc.utils.stringify(issued):match("%d%d%d%d")
    if y then return y end
  end
  return nil
end

local function render_year(refs, csl, lang)
  local meta = pandoc.Meta({})
  meta.references = pandoc.MetaList(refs)
  meta.nocite = pandoc.MetaInlines(pandoc.read("@*", "markdown").blocks[1].content)
  if csl then meta.csl = csl end
  if lang then meta.lang = lang end
  local sub = pandoc.Pandoc({ pandoc.Div({}, pandoc.Attr("refs")) }, meta)
  local out = pandoc.utils.citeproc(sub)
  for _, b in ipairs(out.blocks) do
    if b.t == "Div" and b.identifier == "refs" then return b end
  end
  return pandoc.Div({})
end

function Pandoc(doc)
  local bibfile = doc.meta["publications-bib"]
      and pandoc.utils.stringify(doc.meta["publications-bib"]) or "references.bib"
  local csl = doc.meta.csl
  local lang = doc.meta.lang

  local bib = pandoc.read(read_file(bibfile), "bibtex")
  local refs = bib.meta.references or pandoc.MetaList({})

  -- group by year
  local groups, years = {}, {}
  for _, ref in ipairs(refs) do
    local y = year_of(ref) or "n.d."
    if not groups[y] then groups[y] = {}; table.insert(years, y) end
    table.insert(groups[y], ref)
  end
  table.sort(years, function(a, b)
    if a == "n.d." then return false end
    if b == "n.d." then return true end
    return a > b
  end)

  local blocks = {}
  for _, y in ipairs(years) do
    local id = "year-" .. y:gsub("%.", "")
    table.insert(blocks, pandoc.Header(2, y, pandoc.Attr(id)))
    local div = render_year(groups[y], csl, lang)
    div.identifier = "refs-" .. y:gsub("%.", "")
    table.insert(blocks, div)
  end

  -- place the output
  local placed = false
  local new = doc:walk({
    Div = function(el)
      if el.identifier == "publications-by-year" and not placed then
        placed = true
        return blocks
      end
    end
  })
  if not placed then
    for _, b in ipairs(blocks) do table.insert(new.blocks, b) end
  end
  return new
end

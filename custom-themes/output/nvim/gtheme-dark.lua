local M = {}

M.setup = function()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "tradester"

  local palette = {
    dark = {
  bg = "#101316",
  bg_panel = "#262838",
  bg_element = "#101316",
  fg = "#D9DAEC",
  fg_muted = "#656675",
  border = "#262838",
  border_active = "#C6C7D8",
  primary = "#83A598",
  secondary = "#689D6A",
  accent = "#FABD2F",
  error = "#CC241D",
  warning = "#D79921",
  success = "#B8BB26",
  info = "#458588",
  comment = "#7F858B",
  keyword = "#FB4934",
  fn = "#8EC07C",
  method = "#689D6A",
  string = "#B8BB26",
  number = "#D3869B",
  type = "#FABD2F",
  variable = "#83A598",
  operator = "#8EC07C",
  punctuation = "#BAB09E",
  cursor = "#D9DAEC",
  selection = "#262838"
},
    light = {
  bg = "#F4F4F9",
  bg_panel = "#FDFDFD",
  bg_element = "#D9DAEC",
  fg = "#101316",
  fg_muted = "#656675",
  border = "#C6C7D8",
  border_active = "#262838",
  primary = "#5F8F8E",
  secondary = "#5A8D60",
  accent = "#C99824",
  error = "#BE2F27",
  warning = "#C36A10",
  success = "#8B9120",
  info = "#4F7F83",
  comment = "#7A7068",
  keyword = "#C43B2D",
  fn = "#6FA05A",
  method = "#5A8D60",
  string = "#8B9120",
  number = "#AD6E88",
  type = "#C99824",
  variable = "#5F8F8E",
  operator = "#6FA05A",
  punctuation = "#4A4440",
  cursor = "#050607",
  selection = "#D9DAEC"
}
  }

  local c = palette["dark"]
  local set = vim.api.nvim_set_hl

  set(0, "Normal", { fg = c.fg, bg = c.bg })
  set(0, "NormalFloat", { fg = c.fg, bg = c.bg_panel })
  set(0, "FloatBorder", { fg = c.border_active, bg = c.bg_panel })
  set(0, "Cursor", { fg = c.bg, bg = c.cursor })
  set(0, "Visual", { fg = c.fg, bg = c.selection })
  set(0, "Comment", { fg = c.comment, italic = true })
  set(0, "Keyword", { fg = c.keyword, bold = true })
  set(0, "Function", { fg = c.fn, bold = true })
  set(0, "Identifier", { fg = c.variable })
  set(0, "String", { fg = c.string })
  set(0, "Number", { fg = c.number })
  set(0, "Type", { fg = c.type })
  set(0, "Operator", { fg = c.operator })
  set(0, "Delimiter", { fg = c.punctuation })
  set(0, "Error", { fg = c.error })
  set(0, "WarningMsg", { fg = c.warning })
  set(0, "DiffAdd", { fg = c.success, bg = c.bg_element })
  set(0, "DiffDelete", { fg = c.error, bg = c.bg_element })
  set(0, "DiffChange", { fg = c.info, bg = c.bg_element })
  set(0, "DiffText", { fg = c.accent, bg = c.bg_panel })

  set(0, "@comment", { link = "Comment" })
  set(0, "@keyword", { link = "Keyword" })
  set(0, "@function", { link = "Function" })
  set(0, "@function.method", { fg = c.method })
  set(0, "@variable", { link = "Identifier" })
  set(0, "@string", { link = "String" })
  set(0, "@number", { link = "Number" })
  set(0, "@type", { link = "Type" })
  set(0, "@operator", { link = "Operator" })
  set(0, "@punctuation", { link = "Delimiter" })
end

M.setup()

return M

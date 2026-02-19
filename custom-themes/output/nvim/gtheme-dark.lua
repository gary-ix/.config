local M = {}

M.setup = function()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "tradester"

  local palette = {
    dark = {
  bg = "#1e1e1e",
  bg_panel = "#2C2C2E",
  bg_element = "#1e1e1e",
  fg = "#D9DAEC",
  fg_muted = "#7c7d8d",
  border = "#2C2C2E",
  border_active = "#2C2C2E",
  primary = "#83A598",
  secondary = "#8EC07C",
  accent = "#FABD2F",
  error = "#CC241D",
  warning = "#af3b02",
  success = "#B8BB26",
  info = "#458588",
  comment = "#7c7d8d",
  keyword = "#CC241D",
  fn = "#8EC07C",
  method = "#8EC07C",
  string = "#B8BB26",
  number = "#bb627a",
  type = "#FABD2F",
  variable = "#83A598",
  operator = "#8EC07C",
  punctuation = "#cec7ba",
  cursor = "#D9DAEC",
  selection = "#7c7d8d"
},
    light = {
  bg = "#ffffff",
  bg_panel = "#f4f4f9",
  bg_element = "#ffffff",
  fg = "#101316",
  fg_muted = "#7c7d8d",
  border = "#D1D1D6",
  border_active = "#7c7d8d",
  primary = "#5F8F8E",
  secondary = "#5A8D60",
  accent = "#C99824",
  error = "#a2261f",
  warning = "#C36A10",
  success = "#8B9120",
  info = "#4F7F83",
  comment = "#7c7d8d",
  keyword = "#a2261f",
  fn = "#5A8D60",
  method = "#5A8D60",
  string = "#8B9120",
  number = "#AD6E88",
  type = "#C99824",
  variable = "#5F8F8E",
  operator = "#6FA05A",
  punctuation = "#33302e",
  cursor = "#050607",
  selection = "#7c7d8d"
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

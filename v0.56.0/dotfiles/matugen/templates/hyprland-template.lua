HLDE = HLDE or {}
HLDE.colors = HLDE.colors or {}

local colors = HLDE.colors

<* for name, value in colors *>
colors["{{name}}"] = "rgba({{value.default.hex_stripped}}ff)"
<* endfor *>

<* for name, value in colors *>
colors["{{name}}_raw"] = "{{value.default.hex_stripped}}"
<* endfor *>

return colors

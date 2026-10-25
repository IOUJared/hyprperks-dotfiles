hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })

for _, workspace in ipairs({ "w[tv1]", "f[1]" }) do
    hl.workspace_rule({ workspace = workspace, gaps_out = 0, gaps_in = 0 })
end

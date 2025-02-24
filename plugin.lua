local Selection = game:GetService("Selection")
local HttpService = game:GetService("HttpService")

local Interface = plugin:CreateToolbar("VM")

local Button = Interface:CreateButton("Virtualize", "", "http://www.roblox.com/asset/?id=72875773659485")
Button.ClickableWhenViewportHidden = true




Button.Click:Connect(function()
	local main = Selection:Get()[1]
	
	local Success, VM = pcall(function()
		return HttpService:GetAsync("https://raw.githubusercontent.com/SentryLN/lua-virtual-env/refs/heads/main/main.lua")
	end)
	assert(Success, "failed to read virtual env")
	VM ..= "\n\n"
	
	for index, value in pairs({main, unpack(main:GetDescendants())}) do
		if value:IsA("Script") or value:IsA("ModuleScript") then
			local code = value.Source:gsub("%-%-%[.-%]%]", "")
			local len = #code
			if len >= 200000-#VM then
				warn( 200000-#VM)
				warn(value:GetFullName(), "len:", len, ", length issue. virtualize skipped")
				continue
			end
			value.Source = VM .. code
		end
	end
	warn("all done!")
end)

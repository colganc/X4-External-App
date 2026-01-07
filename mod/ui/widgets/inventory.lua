-- Inventory widget reporter
-- Returns best-effort player/ship metadata and normalized inventory array


local output = {
    -- Properties to exclude from hash calculation (frequently changing non-essential data)
    hashExclusions = { "currentGameTime" }
}

function output.handle()
    local playerInventory = GetPlayerInventory()
    return playerInventory
end

return output

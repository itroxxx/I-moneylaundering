Config = {}

Config.Framework = 'ESX' -- Change this to 'QBCore' if you are using QBCore framework

Config.Washers = {
    {
        id = 1,
        coords = vector4(-309.072540, -1318.180176, 42.254272, 283.464569),
        prop = 'prop_washer_01',
        job = 'police', -- Set to nil for public washer
        showBlip = true, -- Set to true to show blip, false to hide blip
        blipSettings = {
            sprite = 500,
            scale = 0.8,
            color = 2,
            name = "Money Laundering"
        }
    },
    {
        id = 2,
        coords = vector4(-299.024170, -1308.896729, 42.254272, 342.992126),
        prop = 'prop_washer_01',
        job = nil, -- Set to nil for public washer
        showBlip = false, -- Set to true to show blip, false to hide blip
        blipSettings = {
            sprite = 500,
            scale = 0.8,
            color = 2,
            name = "Money Laundering"
        }
    },
}

Config.DirtyMoneyAmount = 1000 -- Amount of dirty money to wash each cycle
Config.CleanMoneyAmount = 800 -- Amount of clean money received each cycle
Config.WashTime = 5000 -- Time in milliseconds to wash money
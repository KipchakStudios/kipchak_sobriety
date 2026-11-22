Items = {}

local function matchPrefix(prefixes, name)
    for prefix, value in pairs(prefixes) do
        if name:sub(1, #prefix) == prefix then
            return value
        end
    end
end

function Items.Match(name)
    if type(name) ~= 'string' then return end
    local amount = Config.Alcohol.Items[name] or matchPrefix(Config.Alcohol.Prefixes, name)
    if amount then return 'alcohol', amount end
    local category = Config.Drugs.Items[name] or matchPrefix(Config.Drugs.Prefixes, name)
    if category then return 'drug', category end
end

function Items.IsTracked(name)
    return Items.Match(name) ~= nil
end

function Items.Consume(src, name)
    local kind, value = Items.Match(name)
    if kind == 'alcohol' then
        Levels.AddAlcohol(src, value)
    elseif kind == 'drug' then
        Levels.AddDrug(src, value)
    end
end

function Items.CheckDefinitions()
    if not InventoryBridge or not InventoryBridge.ItemExists then return end
    for name in pairs(Config.Alcohol.Items) do
        if not InventoryBridge.ItemExists(name) then
            print(("^3[kipchak_sobriety] Item '%s' not found in inventory, check Config.Alcohol.Items^7"):format(name))
        end
    end
    for name, category in pairs(Config.Drugs.Items) do
        if not InventoryBridge.ItemExists(name) then
            print(("^3[kipchak_sobriety] Item '%s' not found in inventory, check Config.Drugs.Items^7"):format(name))
        end
        if not Levels.IsCategory(category) then
            print(("^3[kipchak_sobriety] Item '%s' uses unknown category '%s', check Config.Drugs.Categories^7"):format(name, category))
        end
    end
    for prefix, category in pairs(Config.Drugs.Prefixes) do
        if not Levels.IsCategory(category) then
            print(("^3[kipchak_sobriety] Prefix '%s' uses unknown category '%s', check Config.Drugs.Categories^7"):format(prefix, category))
        end
    end
end

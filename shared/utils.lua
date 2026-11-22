function L(key, ...)
    local dict = Locales[Config.Locale] or Locales.en
    local str = dict[key] or Locales.en[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

function DebugPrint(...)
    if Config.Debug then
        print('^5[kipchak_sobriety]^7', ...)
    end
end

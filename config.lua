Config = {}

Config.Framework = 'auto'
Config.Inventory = 'auto'
Config.Locale = 'en'
Config.Debug = false

Config.Commands = {
    alcohol = 'alcoholtest',
    drug = 'drugtest'
}

Config.AutoNearest = true
Config.AllowSelfTest = false
Config.AllowedJobs = {
    police = 0,
    sheriff = 0
}
Config.RequireOnDuty = true
Config.MaxDistance = 3.0
Config.Cooldown = 30
Config.ShowResultToTarget = false

Config.Consent = {
    Enabled = true,
    Timeout = 15
}

Config.Animation = {
    Enabled = true,
    Emote = false,
    Duration = 5000,
    MaxMove = 1.0,
    Dict = 'cellphone@',
    Clip = 'cellphone_text_read_base',
    Prop = {
        model = 'prop_cs_hand_radio',
        bone = 28422,
        pos = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0)
    }
}

Config.Result = {
    Position = 'top-right',
    Duration = 10000,
    CloseKey = 'BACK',
    Branding = true
}

Config.AutoMe = {
    Enabled = false,
    Duration = 5000,
    Range = 15.0
}

Config.DrunkEffect = {
    Enabled = false,
    Levels = {
        { min = 0.30, walk = 'move_m@drunk@slightlydrunk', shake = 0.3, strength = 0.2 },
        { min = 1.00, walk = 'move_m@drunk@moderatedrunk', shake = 0.8, strength = 0.5 },
        { min = 2.00, walk = 'move_m@drunk@verydrunk', shake = 1.5, strength = 0.9 }
    }
}

Config.Logs = {
    Enabled = false,
    Username = 'Kipchak Sobriety'
}

Config.AdminCommands = {
    Enabled = false,
    SetAlcohol = 'setalcohol',
    AddDrug = 'adddrug',
    Reset = 'resetsobriety'
}

Config.Persistence = false
Config.StartupItemCheck = true

Config.ItemDetection = {
    Enabled = true,
    ConfirmWindow = 20
}

Config.Alcohol = {
    Items = {
        beer = 0.20,
        whiskey = 0.35,
        vodka = 0.40,
        wine = 0.25
    },
    Prefixes = {},
    DecayPerMinute = 0.01,
    Max = 4.0,
    LegalLimit = 0.50,
    Unit = 'permille',
    Precision = 2,
    RandomVariance = 0.02
}

Config.Drugs = {
    Categories = {
        { name = 'cannabis', minutes = 120 },
        { name = 'cocaine', minutes = 60 },
        { name = 'meth', minutes = 90 },
        { name = 'opioids', minutes = 90 },
        { name = 'ecstasy', minutes = 60 }
    },
    Items = {
        joint = 'cannabis',
        cokebaggy = 'cocaine',
        crack_baggy = 'cocaine',
        meth = 'meth',
        oxy = 'opioids',
        xtcbaggy = 'ecstasy'
    },
    Prefixes = {}
}

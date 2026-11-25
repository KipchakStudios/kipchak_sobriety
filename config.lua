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

-- Enabled is the main switch: true = progress bar with animation, false = instant result.
-- Alcohol / Drug: officer animation per test. Set the entry to false to keep the progress bar without animation.
-- Prop is optional: false, or { model, bone, pos, rot }. No animation is played inside a vehicle.
-- Target: optional short animation for the tested person (default off).
Config.Animation = {
    Enabled = true,
    Duration = 5000,
    MaxMove = 1.0,
    Alcohol = {
        Dict = 'cellphone@',
        Clip = 'cellphone_text_read_base',
        Flag = 49,
        Prop = {
            model = 'prop_npc_phone_02',
            bone = 28422,
            pos = vec3(0.0, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0)
        }
    },
    Drug = {
        Dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
        Clip = 'weed_stand_checkingleaves_idle_01_inspector',
        Flag = 49,
        Prop = false
    },
    Target = {
        Enabled = false,
        Alcohol = { Dict = 'mp_player_intdrink', Clip = 'loop_bottle', Flag = 49 },
        Drug = { Dict = 'mp_player_inteat@burger', Clip = 'mp_player_int_eat_burger_fp', Flag = 49 }
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

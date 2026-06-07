--[[
    Ketamine Script Hub - Universal Loader
    
    Features:
      - Auto-detects game via PlaceId
      - Key verification system
      - Animated loading UI
      - Loads correct script for detected game from GitHub
      - Supports 30+ FPS and other games
    
    Upload this single file to jnkie.com - works for all supported games.
]]

----------------------------------------------------------------------
-- CONFIGURATION
----------------------------------------------------------------------
local CONFIG = {
    LOADER_NAME = "Ketamine Hub",
    VERSION     = "v3.0",
    
    -- Authentication settings
    -- Raw GitHub URL to your keys JSON file
    -- Format: {"keys": ["KEY-ONE", "KEY-TWO", ...]}
    -- Raw GitHub URL to your database.json file on GitHub
    DB_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/database.json",
    
    KEY_LINK = "https://work.ink/2BB6/ketamine-scripts",
    
    -- GitHub raw base URL for scripts
    GITHUB_BASE = "https://raw.githubusercontent.com/GuysServices/Ketamine-Scripts/refs/heads/main/scripts/",
    
    LOAD_DURATION = 3,
    
    ACCENT       = Color3.fromRGB(155, 89, 255),
    ACCENT_DARK  = Color3.fromRGB(115, 55, 215),
    BG_PRIMARY   = Color3.fromRGB(14, 10, 22),
    BG_SECONDARY = Color3.fromRGB(22, 16, 35),
    BG_INPUT     = Color3.fromRGB(32, 24, 52),
    TEXT_PRIMARY  = Color3.fromRGB(230, 220, 250),
    TEXT_DIM      = Color3.fromRGB(120, 100, 160),
    SUCCESS      = Color3.fromRGB(140, 100, 255),
    ERROR        = Color3.fromRGB(180, 60, 120),
}

----------------------------------------------------------------------
-- GAME DATABASE (PlaceId -> Script filename on GitHub)
----------------------------------------------------------------------
local GAMES = {
    -- FPS Games
    [301549746]  = {name = "Counter Blox",      file = "CounterBlox.lua"},
    [12144402492] = {name = "Deadline",          file = "Deadline.lua"},
    [72258920367796] = {name = "Recoil",            file = "Recoil.lua"},
    [3527629287] = {name = "BIG Paintball",     file = "BigPaintball.lua"},
    [286090429]  = {name = "Arsenal",           file = "Arsenal.lua"},
    [17625359962] = {name = "Rivals",           file = "Rivals.lua"},
    [16404660684] = {name = "Bodycam",          file = "Bodycam.lua"},
    [3214114884] = {name = "Flag Wars",         file = "FlagWars.lua"},
    [88454318405193] = {name = "Havok",             file = "Havok.lua"},
    [136801880565837] = {name = "Flick",             file = "Flick.lua"},
    [107205390939183] = {name = "Strafe",            file = "Strafe.lua"},
    [17516596118] = {name = "HyperShot",        file = "HyperShot.lua"},
    [3297964905] = {name = "Weaponry",          file = "Weaponry.lua"},
    [135648408848758] = {name = "One Scope",        file = "OneScope.lua"},
    [90568084448279] = {name = "OneTap",           file = "OneTap.lua"},
    [140636953470579] = {name = "FPS Duels",        file = "FPSDuels.lua"},
    [114234929420007] = {name = "Blox Strike",       file = "BloxStrike.lua"},
    [12137249458] = {name = "Gun Grounds FFA",  file = "GunGroundsFFA.lua"},
    [15694891095] = {name = "Combat Arena",     file = "CombatArena.lua"},
    [14518422161] = {name = "Gunfight Arena",   file = "GunfightArena.lua"},
    [122446657157717] = {name = "Sniper Arena",     file = "SniperArena.lua"},
    [109397169461300] = {name = "Sniper Duels",     file = "SniperDuels.lua"},
    [87018676608089] = {name = "Pistol Arena",     file = "PistolArena.lua"},
    [8664150532] = {name = "FFA Headshot",     file = "FFAHeadshot.lua"},
    [16261605398] = {name = "Airsoft Battles",  file = "AirsoftBattles.lua"},
    [131964389958213] = {name = "Reloaded Guns",    file = "ReloadedGuns.lua"},
    [12673840215] = {name = "Realistic Hood",   file = "RealisticHood.lua"},
    [6172932937] = {name = "Energy Assault",    file = "EnergyAssault.lua"},
    [3233893879] = {name = "Bad Business",      file = "BadBusiness.lua"},
    

    [99362936871032] = {name = "The Bronx Duels",    file = "TheBronxDuels.lua"},
    
    -- Other Games
    [142823291]  = {name = "Murder Mystery 2",  file = "MurderMystery2.lua"},
    [96574878340154] = {name = "Murder For Brainrots", file = "MurderForBrainrots.lua"},
    [140582629911298] = {name = "Deathshot",         file = "Deathshot.lua"},
    [129256170300917] = {name = "Bullet Storm",      file = "BulletStorm.lua"},
    [3297964905] = {name = "Weaponry",          file = "Weaponry.lua"},
    [107205390939183] = {name = "Strafe",            file = "Strafe.lua"},
    
    -- Universal fallback
    [0] = {name = "Universal",         file = "KetamineUniversal.lua"},
}

----------------------------------------------------------------------
-- Services
----------------------------------------------------------------------
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------
-- Utility
----------------------------------------------------------------------
local function tween(obj, props, duration, style, direction)
    local t = TweenService:Create(obj, TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

-- HWID Fetcher using executor specific functions
local function getHWID()
    local hwid = "UNKNOWN_HWID"
    pcall(function()
        if gethwid then hwid = gethwid()
        elseif syn and syn.request then hwid = "SYN_" .. tostring(game:GetService("RbxAnalyticsService"):GetClientId())
        else hwid = game:GetService("RbxAnalyticsService"):GetClientId() end
    end)
    return hwid
end

local function validateKey(input, callback)
    -- Fetch database.json from GitHub
    local success, body = pcall(function()
        return game:HttpGet(CONFIG.DB_URL, true)
    end)

    if not success or not body or body == "" then
        callback(false, "Failed to fetch key database. Check your internet or DB_URL.")
        return
    end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodeSuccess or not data or not data.keys then
        callback(false, "Database format invalid.")
        return
    end

    local inputTrimmed = input:gsub("^%s+", ""):gsub("%s+$", "")
    local keyData = data.keys[inputTrimmed]

    if not keyData then
        callback(false, "Invalid key. Get a key or try again.")
        return
    end

    -- Check status field if present
    if keyData.status and keyData.status ~= "active" then
        callback(false, "Key is inactive or revoked.")
        return
    end

    -- Check expiry if present
    if keyData.expires_at and keyData.expires_at ~= nil and keyData.expires_at ~= "" then
        -- expires_at format: "YYYY-MM-DD HH:MM:SS" — compare as string (lexicographic works for this format)
        local now = os.date("!%Y-%m-%d %H:%M:%S")
        if now > keyData.expires_at then
            callback(false, "Key has expired.")
            return
        end
    end

    -- HWID locking logic
    if keyData.hwid_locked then
        local hwid = getHWID()

        if keyData.hwid == nil or keyData.hwid == "" or keyData.hwid == "null" then
            -- First use: lock the key to this HWID by noting it locally
            -- (GitHub JSON is read-only, so we just allow it and warn in console)
            warn("[Ketamine Hub] HWID lock: key not yet bound. Allowing first use. Update database.json with HWID: " .. hwid)
            callback(true, "Premium key verified! (HWID: " .. hwid .. ")")
        elseif keyData.hwid == hwid then
            callback(true, "Premium key verified!")
        else
            callback(false, "HWID mismatch. This key is locked to another device.")
        end
    else
        -- Non-HWID key, just let them in
        callback(true, "Key verified!")
    end
end

----------------------------------------------------------------------
-- GUI Creation
----------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KetamineHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Full-screen dim background
local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
Backdrop.BackgroundTransparency = 1
Backdrop.BorderSizePixel = 0
Backdrop.Parent = ScreenGui

tween(Backdrop, {BackgroundTransparency = 0.5}, 0.5)

----------------------------------------------------------------------
-- Main Card
----------------------------------------------------------------------
local Card = Instance.new("Frame")
Card.Name = "Card"
Card.Size = UDim2.new(0, 380, 0, 320)
Card.Position = UDim2.new(0.5, -190, 0.5, -160)
Card.BackgroundColor3 = CONFIG.BG_PRIMARY
Card.BorderSizePixel = 0
Card.BackgroundTransparency = 1
Card.Parent = ScreenGui

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 14)
CardCorner.Parent = Card

local CardStroke = Instance.new("UIStroke")
CardStroke.Color = CONFIG.ACCENT
CardStroke.Thickness = 1.5
CardStroke.Transparency = 1
CardStroke.Parent = Card

-- Animate card in
tween(Card, {BackgroundTransparency = 0}, 0.5)
tween(CardStroke, {Transparency = 0.3}, 0.6)

----------------------------------------------------------------------
-- Title Section
----------------------------------------------------------------------
local TitleContainer = Instance.new("Frame")
TitleContainer.Size = UDim2.new(1, 0, 0, 70)
TitleContainer.BackgroundColor3 = CONFIG.BG_SECONDARY
TitleContainer.BorderSizePixel = 0
TitleContainer.Parent = Card

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 14)
TitleCorner.Parent = TitleContainer

-- Clip bottom corners of title
local TitleClip = Instance.new("Frame")
TitleClip.Size = UDim2.new(1, 0, 0, 16)
TitleClip.Position = UDim2.new(0, 0, 1, -16)
TitleClip.BackgroundColor3 = CONFIG.BG_SECONDARY
TitleClip.BorderSizePixel = 0
TitleClip.Parent = TitleContainer

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 0, 30)
TitleLabel.Position = UDim2.new(0, 16, 0, 12)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = CONFIG.LOADER_NAME
TitleLabel.TextColor3 = CONFIG.ACCENT
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleContainer

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 60, 0, 20)
VersionLabel.Position = UDim2.new(1, -70, 0, 16)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = CONFIG.VERSION
VersionLabel.TextColor3 = CONFIG.TEXT_DIM
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.TextSize = 13
VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
VersionLabel.Parent = TitleContainer

-- Detect game
local currentPlaceId = game.PlaceId
local detectedGame = GAMES[currentPlaceId]
local detectedName = detectedGame and detectedGame.name or "Unknown Game"
local detectedFile = detectedGame and detectedGame.file or nil

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Size = UDim2.new(1, -20, 0, 18)
SubtitleLabel.Position = UDim2.new(0, 16, 0, 42)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = detectedGame and ("Detected: " .. detectedName) or "Game not supported - Universal will load"
SubtitleLabel.TextColor3 = detectedGame and CONFIG.SUCCESS or CONFIG.ERROR
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextSize = 13
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Parent = TitleContainer

----------------------------------------------------------------------
-- Key Input
----------------------------------------------------------------------
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, -40, 0, 42)
InputFrame.Position = UDim2.new(0, 20, 0, 90)
InputFrame.BackgroundColor3 = CONFIG.BG_INPUT
InputFrame.BorderSizePixel = 0
InputFrame.Parent = Card
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 10)

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(60, 60, 80)
InputStroke.Thickness = 1
InputStroke.Parent = InputFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -16, 1, 0)
KeyInput.Position = UDim2.new(0, 8, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Text = ""
KeyInput.PlaceholderText = "Paste your key here..."
KeyInput.PlaceholderColor3 = CONFIG.TEXT_DIM
KeyInput.TextColor3 = CONFIG.TEXT_PRIMARY
KeyInput.Font = Enum.Font.GothamMedium
KeyInput.TextSize = 14
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.ClearTextOnFocus = false
KeyInput.Parent = InputFrame

KeyInput.Focused:Connect(function()
    tween(InputStroke, {Color = CONFIG.ACCENT}, 0.2)
end)
KeyInput.FocusLost:Connect(function()
    tween(InputStroke, {Color = Color3.fromRGB(60, 60, 80)}, 0.2)
end)

----------------------------------------------------------------------
-- Status Label
----------------------------------------------------------------------
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -40, 0, 20)
StatusLabel.Position = UDim2.new(0, 20, 0, 140)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = CONFIG.ERROR
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Card

----------------------------------------------------------------------
-- Buttons
----------------------------------------------------------------------
local function makeButton(text, posY, color, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, posY)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    -- Hover effects
    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.new(
            math.min(color.R + 0.08, 1),
            math.min(color.G + 0.08, 1),
            math.min(color.B + 0.08, 1)
        )}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = color}, 0.15)
    end)

    return btn
end

local SubmitBtn  = makeButton("Verify Key", 170, CONFIG.ACCENT, Card)              -- Uses ACCENT
local GetKeyBtn  = makeButton("Get Key", 220, Color3.fromRGB(45, 32, 72), Card)    -- Dark purple
local DiscordBtn = makeButton("Copy Discord Invite", 268, Color3.fromRGB(90, 60, 160), Card)  -- Medium purple

----------------------------------------------------------------------
-- Loading Screen (hidden initially)
----------------------------------------------------------------------
local LoadFrame = Instance.new("Frame")
LoadFrame.Name = "LoadFrame"
LoadFrame.Size = UDim2.new(0, 380, 0, 200)
LoadFrame.Position = UDim2.new(0.5, -190, 0.5, -100)
LoadFrame.BackgroundColor3 = CONFIG.BG_PRIMARY
LoadFrame.BorderSizePixel = 0
LoadFrame.Visible = false
LoadFrame.Parent = ScreenGui
Instance.new("UICorner", LoadFrame).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", LoadFrame).Color = CONFIG.ACCENT

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 40)
LoadTitle.Position = UDim2.new(0, 0, 0, 20)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = CONFIG.LOADER_NAME
LoadTitle.TextColor3 = CONFIG.ACCENT
LoadTitle.Font = Enum.Font.GothamBold
LoadTitle.TextSize = 22
LoadTitle.Parent = LoadFrame

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1, 0, 0, 20)
LoadStatus.Position = UDim2.new(0, 0, 0, 60)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "Loading modules..."
LoadStatus.TextColor3 = CONFIG.TEXT_DIM
LoadStatus.Font = Enum.Font.Gotham
LoadStatus.TextSize = 13
LoadStatus.Parent = LoadFrame

-- Progress bar
local ProgressBG = Instance.new("Frame")
ProgressBG.Size = UDim2.new(1, -60, 0, 8)
ProgressBG.Position = UDim2.new(0, 30, 0, 100)
ProgressBG.BackgroundColor3 = CONFIG.BG_INPUT
ProgressBG.BorderSizePixel = 0
ProgressBG.Parent = LoadFrame
Instance.new("UICorner", ProgressBG).CornerRadius = UDim.new(1, 0)

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = CONFIG.ACCENT
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressBG
Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(1, 0)

local PercentLabel = Instance.new("TextLabel")
PercentLabel.Size = UDim2.new(1, 0, 0, 20)
PercentLabel.Position = UDim2.new(0, 0, 0, 116)
PercentLabel.BackgroundTransparency = 1
PercentLabel.Text = "0%"
PercentLabel.TextColor3 = CONFIG.TEXT_DIM
PercentLabel.Font = Enum.Font.GothamBold
PercentLabel.TextSize = 14
PercentLabel.Parent = LoadFrame

local CreditLabel = Instance.new("TextLabel")
CreditLabel.Size = UDim2.new(1, 0, 0, 20)
CreditLabel.Position = UDim2.new(0, 0, 1, -30)
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "Powered by " .. CONFIG.LOADER_NAME
CreditLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
CreditLabel.Font = Enum.Font.Gotham
CreditLabel.TextSize = 11
CreditLabel.Parent = LoadFrame

----------------------------------------------------------------------
-- Key Verification Logic
----------------------------------------------------------------------
local function showStatus(text, color)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color
    tween(StatusLabel, {TextTransparency = 0}, 0.2)
    task.delay(4, function()
        tween(StatusLabel, {TextTransparency = 1}, 0.5)
    end)
end

local function startLoading()
    -- Hide key card, show loader
    tween(Card, {BackgroundTransparency = 1}, 0.3)
    for _, child in ipairs(Card:GetDescendants()) do
        if child:IsA("GuiObject") then
            pcall(function() tween(child, {BackgroundTransparency = 1}, 0.3) end)
        end
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            pcall(function() tween(child, {TextTransparency = 1}, 0.3) end)
        end
    end

    task.wait(0.4)
    Card.Visible = false
    LoadFrame.Visible = true

    -- Determine which script to load
    local scriptFile = detectedFile
    if not scriptFile then
        -- Fallback to universal
        scriptFile = GAMES[0] and GAMES[0].file or "KetamineUniversal.lua"
    end
    local scriptURL = CONFIG.GITHUB_BASE .. scriptFile
    local gameName = detectedGame and detectedGame.name or "Universal"

    -- Loading steps
    local steps = {
        {text = "Verifying license...",                  pct = 0.10},
        {text = "Detected: " .. gameName,                pct = 0.20},
        {text = "Connecting to GitHub...",               pct = 0.35},
        {text = "Downloading " .. scriptFile .. "...",   pct = 0.55},
        {text = "Injecting script...",                   pct = 0.75},
        {text = "Initializing " .. gameName .. "...",    pct = 0.90},
        {text = "Done!",                                 pct = 1.00},
    }

    local stepDuration = CONFIG.LOAD_DURATION / #steps

    for i, step in ipairs(steps) do
        LoadStatus.Text = step.text
        tween(ProgressFill, {Size = UDim2.new(step.pct, 0, 1, 0)}, stepDuration * 0.8)
        PercentLabel.Text = tostring(math.floor(step.pct * 100)) .. "%"
        task.wait(stepDuration)
    end

    -- Done - close loader
    task.wait(0.5)
    tween(LoadFrame, {BackgroundTransparency = 1}, 0.4)
    tween(Backdrop, {BackgroundTransparency = 1}, 0.4)
    for _, child in ipairs(LoadFrame:GetDescendants()) do
        if child:IsA("GuiObject") then
            pcall(function() tween(child, {BackgroundTransparency = 1}, 0.3) end)
        end
        if child:IsA("TextLabel") then
            pcall(function() tween(child, {TextTransparency = 1}, 0.3) end)
        end
    end

    task.wait(0.5)
    ScreenGui:Destroy()

    -- Load the correct game script from GitHub
    local success, err = pcall(function()
        loadstring(game:HttpGet(scriptURL))()
    end)

    if success then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = CONFIG.LOADER_NAME,
                Text = gameName .. " loaded successfully!",
                Duration = 5
            })
        end)
    else
        warn("[Ketamine Hub] Failed to load " .. gameName .. ": " .. tostring(err))
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = CONFIG.LOADER_NAME,
                Text = "Failed to load " .. gameName .. ". Check GitHub URL.",
                Duration = 8
            })
        end)
    end
end

----------------------------------------------------------------------
-- Button Connections
----------------------------------------------------------------------
SubmitBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace

    if key == "" then
        showStatus("Please enter a key.", CONFIG.ERROR)
        return
    end

    SubmitBtn.Text = "Verifying..."
    
    validateKey(key, function(isValid, msg)
        if isValid then
            showStatus(msg or "Key verified!", CONFIG.SUCCESS)
            SubmitBtn.Text = "Verified!"
            SubmitBtn.BackgroundColor3 = CONFIG.SUCCESS
            task.wait(1)
            startLoading()
        else
            showStatus(msg or "Invalid key. Try again or get a new key.", CONFIG.ERROR)
            SubmitBtn.Text = "Verify Key"
            -- Shake animation on input
            local origPos = InputFrame.Position
            for i = 1, 4 do
                tween(InputFrame, {Position = origPos + UDim2.new(0, 6 * (i % 2 == 0 and 1 or -1), 0, 0)}, 0.05)
                task.wait(0.05)
            end
            tween(InputFrame, {Position = origPos}, 0.05)
        end
    end)
end)

GetKeyBtn.MouseButton1Click:Connect(function()
    -- Open key link
    if setclipboard then
        setclipboard(CONFIG.KEY_LINK)
        showStatus("Key link copied to clipboard!", CONFIG.ACCENT)
    else
        showStatus("Visit: " .. CONFIG.KEY_LINK, CONFIG.ACCENT)
    end
end)

DiscordBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(CONFIG.KEY_LINK)
        showStatus("Discord invite copied!", Color3.fromRGB(88, 101, 242))
    else
        showStatus("Join: " .. CONFIG.KEY_LINK, Color3.fromRGB(88, 101, 242))
    end
end)

----------------------------------------------------------------------
-- Allow pressing Enter to submit key
----------------------------------------------------------------------
KeyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        SubmitBtn.MouseButton1Click:Fire()
    end
end)

----------------------------------------------------------------------
-- Draggable card
----------------------------------------------------------------------
local dragging, dragStart, startPos

Card.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Card.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Card.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

----------------------------------------------------------------------
-- Startup notification
----------------------------------------------------------------------
pcall(function()
    local msg = detectedGame 
        and ("Detected: " .. detectedName .. ". Enter key to load.")
        or "Game not in database. Universal script will load."
    StarterGui:SetCore("SendNotification", {
        Title = CONFIG.LOADER_NAME,
        Text = msg,
        Duration = 5
    })
end)

print("[Ketamine Hub] " .. CONFIG.VERSION .. " | Game: " .. detectedName .. " (PlaceId: " .. tostring(currentPlaceId) .. ")")

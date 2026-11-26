--[[
    Onyx UI Library  v1.1.0
    Roblox executor UI library. Built-in Settings (hide key, themes, unload) and Credits pages.
    1.1.0: scrollable sidebar (tabs never overlap the user card), Card:AddCycle, Card:AddColor.

    local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/onyx.lua"))()
    local Window = Onyx:CreateWindow({ Title = "My Hub", Credits = { Name = "Me" } })
    local Tab    = Window:AddTab("Main")
    local Card   = Tab:AddCard({ Title = "Modules", Subtitle = "Enable or disable features" })
    Card:AddToggle({ Label = "Speed", Default = true, Callback = function(on) end })
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer

local Onyx = { Version = "1.1.0" }

local C         = Color3.fromRGB
local WHITE     = C(255, 255, 255)
local BLUE      = C(59, 130, 246)
local BLUE_DARK = C(30, 64, 175)
local CYAN      = C(56, 189, 248)
local STS_BG    = C(10, 30, 90)

Onyx.Colors = { Ok = C(80, 255, 120), Warn = C(255, 200, 60), Bad = C(255, 80, 80) }

-- ═══════════════════════════════════════
-- THEMES  (every theme must define every token below)
-- ═══════════════════════════════════════
local THEME_TOKENS = {
    "winA", "winB", "winC", "sideA", "sideB", "cardA", "cardB", "cardT", "line", "row",
    "ink", "dim", "swOff", "input", "inputTxt", "segBg", "titleA", "titleB", "navOn", "navOnTxt",
    "winStroke", "snow", "snowStroke", "snowStrokeT", "stars", "accent",
}

Onyx.Themes = {
    light = {
        winA = C(250, 253, 255); winB = C(196, 222, 255); winC = C(138, 182, 255);
        sideA = C(29, 78, 216);  sideB = C(96, 165, 250);
        cardA = C(255, 255, 255); cardB = C(226, 238, 255); cardT = 0.10;
        line = C(196, 216, 248); row = C(236, 243, 255);
        ink = C(15, 35, 75);     dim = C(84, 108, 150);
        swOff = C(184, 198, 222);
        input = C(255, 255, 255); inputTxt = C(30, 64, 175); segBg = C(212, 226, 250);
        titleA = C(30, 64, 175); titleB = C(56, 189, 248);
        navOn = C(255, 255, 255); navOnTxt = C(30, 64, 175);
        winStroke = C(255, 255, 255);
        snow = C(255, 255, 255); snowStroke = C(150, 185, 240); snowStrokeT = 0.3;
        stars = 0; accent = BLUE;
    };
    dark = {
        winA = C(30, 46, 86);    winB = C(38, 60, 108);   winC = C(48, 78, 134);
        sideA = C(22, 38, 80);   sideB = C(42, 74, 138);
        cardA = C(50, 76, 128);  cardB = C(40, 64, 110);  cardT = 0.04;
        line = C(92, 126, 190);  row = C(62, 92, 150);
        ink = C(242, 247, 255);  dim = C(184, 204, 238);
        swOff = C(88, 112, 156);
        input = C(32, 52, 98);   inputTxt = C(176, 216, 255); segBg = C(32, 52, 98);
        titleA = C(140, 190, 255); titleB = C(140, 228, 255);
        navOn = C(64, 112, 204); navOnTxt = C(255, 255, 255);
        winStroke = C(96, 140, 214);
        snow = C(240, 246, 255); snowStroke = C(240, 246, 255); snowStrokeT = 1;
        stars = 1; accent = BLUE;
    };
    winter = {
        winA = C(246, 251, 253); winB = C(210, 232, 242); winC = C(164, 200, 222);
        sideA = C(18, 66, 98);   sideB = C(56, 128, 168);
        cardA = C(255, 255, 255); cardB = C(228, 242, 249); cardT = 0.08;
        line = C(190, 216, 230); row = C(232, 243, 249);
        ink = C(14, 40, 58);     dim = C(70, 100, 122);
        swOff = C(176, 196, 208);
        input = C(255, 255, 255); inputTxt = C(18, 66, 98); segBg = C(206, 226, 236);
        titleA = C(18, 86, 128); titleB = C(40, 150, 190);
        navOn = C(255, 255, 255); navOnTxt = C(18, 66, 98);
        winStroke = C(255, 255, 255);
        snow = C(255, 255, 255); snowStroke = C(140, 180, 205); snowStrokeT = 0.3;
        stars = 0; accent = C(32, 120, 168);
    };
    mono = {
        winA = C(30, 30, 32);    winB = C(42, 42, 46);   winC = C(56, 56, 60);
        sideA = C(22, 22, 24);   sideB = C(54, 54, 58);
        cardA = C(62, 62, 66);   cardB = C(48, 48, 52);  cardT = 0.04;
        line = C(104, 104, 110); row = C(76, 76, 82);
        ink = C(250, 250, 250);  dim = C(192, 192, 198);
        swOff = C(70, 70, 76);
        input = C(36, 36, 40);   inputTxt = C(240, 240, 240); segBg = C(36, 36, 40);
        titleA = C(255, 255, 255); titleB = C(190, 190, 196);
        navOn = C(240, 240, 244); navOnTxt = C(20, 20, 22);
        winStroke = C(140, 140, 146);
        snow = C(255, 255, 255); snowStroke = C(255, 255, 255); snowStrokeT = 1;
        stars = 1; accent = C(118, 118, 126);
    };
    autumn = {
        winA = C(255, 248, 238); winB = C(252, 224, 190); winC = C(236, 178, 122);
        sideA = C(110, 38, 16);  sideB = C(186, 84, 28);
        cardA = C(255, 252, 246); cardB = C(253, 236, 214); cardT = 0.08;
        line = C(232, 200, 164); row = C(252, 240, 224);
        ink = C(62, 28, 12);     dim = C(124, 84, 54);
        swOff = C(214, 190, 164);
        input = C(255, 255, 255); inputTxt = C(140, 56, 16); segBg = C(246, 222, 192);
        titleA = C(160, 58, 14); titleB = C(214, 118, 24);
        navOn = C(255, 250, 242); navOnTxt = C(120, 44, 14);
        winStroke = C(255, 236, 208);
        snow = C(232, 128, 36);  snowStroke = C(150, 64, 16); snowStrokeT = 0.55;
        stars = 0; accent = C(190, 84, 24);
    };
    sakura = {
        winA = C(255, 248, 251); winB = C(254, 226, 238); winC = C(248, 190, 214);
        sideA = C(158, 38, 92);  sideB = C(212, 82, 134);
        cardA = C(255, 255, 255); cardB = C(254, 234, 243); cardT = 0.08;
        line = C(244, 200, 220); row = C(254, 238, 246);
        ink = C(72, 20, 48);     dim = C(138, 78, 108);
        swOff = C(224, 196, 210);
        input = C(255, 255, 255); inputTxt = C(150, 34, 88); segBg = C(250, 216, 230);
        titleA = C(176, 36, 100); titleB = C(232, 96, 150);
        navOn = C(255, 255, 255); navOnTxt = C(150, 34, 88);
        winStroke = C(255, 255, 255);
        snow = C(255, 196, 218); snowStroke = C(226, 110, 155); snowStrokeT = 0.3;
        stars = 0; accent = C(198, 58, 118);
    };
    forest = {
        winA = C(20, 52, 42);    winB = C(28, 68, 54);   winC = C(38, 88, 68);
        sideA = C(16, 48, 38);   sideB = C(34, 110, 78);
        cardA = C(40, 92, 72);   cardB = C(30, 76, 58);  cardT = 0.04;
        line = C(70, 138, 108);  row = C(50, 108, 84);
        ink = C(236, 252, 244);  dim = C(172, 214, 194);
        swOff = C(84, 124, 106);
        input = C(24, 64, 50);   inputTxt = C(176, 246, 208); segBg = C(24, 64, 50);
        titleA = C(130, 236, 176); titleB = C(200, 252, 140);
        navOn = C(46, 140, 100); navOnTxt = C(255, 255, 255);
        winStroke = C(84, 160, 124);
        snow = C(210, 255, 180); snowStroke = C(210, 255, 180); snowStrokeT = 1;
        stars = 1; accent = C(46, 160, 108);
    };
}

Onyx.ThemeOrder = {
    { "winter", "Winter" }, { "light", "Light" }, { "dark", "Dark" },
    { "mono", "Black & White" }, { "autumn", "Autumn" }, { "sakura", "Sakura" }, { "forest", "Forest" },
}

-- Register a custom theme before creating a window. `theme` needs every token in THEME_TOKENS.
function Onyx.RegisterTheme(key, displayName, theme)
    for _, token in ipairs(THEME_TOKENS) do
        if theme[token] == nil then
            error("Onyx.RegisterTheme: theme '" .. tostring(key) .. "' is missing token '" .. token .. "'", 2)
        end
    end
    Onyx.Themes[key] = theme
    for _, entry in ipairs(Onyx.ThemeOrder) do
        if entry[1] == key then entry[2] = displayName; return end
    end
    table.insert(Onyx.ThemeOrder, { key, displayName })
end

-- ═══════════════════════════════════════
-- SMALL HELPERS
-- ═══════════════════════════════════════
local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
    return c
end

local function stroke(inst, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Thickness = th or 1
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function guiParent()
    if gethui then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui then return coreGui end
    return lp:WaitForChild("PlayerGui")
end

local function safe(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[Onyx] callback error: " .. tostring(err)) end
end

local function lerpVal(a, b, t)
    if typeof(a) == "Color3" then return a:Lerp(b, t) end
    return a + (b - a) * t
end

local function easeOutQuint(a) return 1 - (1 - a) ^ 5 end
local function easeOutCubic(a) return 1 - (1 - a) ^ 3 end

-- "RRGGBB" <-> Color3. fromHex accepts an optional leading "#" and returns nil for anything else.
local function toHex(color)
    return string.format("%02X%02X%02X",
        math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end
local function fromHex(text)
    if type(text) ~= "string" then return nil end
    local r, g, b = string.match(text, "^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
    if not r then return nil end
    return C(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end
Onyx.ColorToHex, Onyx.HexToColor = toHex, fromHex

-- layout constants
local W, H, SIDE, TOP, RAD = 580, 380, 150, 44, 14
local COL_W, COL_GAP, PAD = 195, 12, 14
local WIDE_W = COL_W * 2 + COL_GAP
local ROW_GAP, CARD_HEAD, CARD_FOOT = 6, 50, 10
-- Sidebar nav region: starts under the MENU label, ends above the user card (which starts at H - 88).
local NAV_TOP, NAV_BOTTOM, NAV_STEP = 92, 96, 40

-- ═══════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════
function Onyx:CreateWindow(opts)
    opts = opts or {}
    local credits = opts.Credits or {}
    local cfg = {
        Id        = opts.Id or "Onyx",
        Title     = opts.Title or "Onyx Hub",
        Subtitle  = opts.Subtitle or "",
        Logo      = string.sub(opts.Logo or "O", 1, 1),
        Splash    = opts.Splash,                 -- string, false to skip the star splash, nil = Title
        Intro     = opts.Intro ~= false,
        ToggleKey = opts.ToggleKey or Enum.KeyCode.RightAlt,
        Theme     = Onyx.Themes[opts.Theme or "winter"] and (opts.Theme or "winter") or "winter",
        LoadedNotice = opts.LoadedNotice ~= false,
        OnUnload  = opts.OnUnload,
        Credits   = {
            Title   = credits.Title or opts.Title or "Onyx Hub",
            Label   = credits.Label or "CREDITS BY",
            Name    = credits.Name or "",
            Version = credits.Version or "",
            Logo    = string.sub(credits.Logo or opts.Logo or "O", 1, 1),
        },
    }
    if cfg.Splash == nil then cfg.Splash = cfg.Title end

    local Window = { Flags = {}, Alive = true, Tabs = {} }
    local function isCurrent() return Window.Alive end

    -- one live window per Id: re-running a script replaces the old one
    local env = (getgenv and getgenv()) or _G
    env.__OnyxWindows = env.__OnyxWindows or {}
    local previous = env.__OnyxWindows[cfg.Id]
    if previous and previous.Destroy then pcall(previous.Destroy, previous) end
    env.__OnyxWindows[cfg.Id] = Window

    local conns = {}
    local function connect(signal, callback)
        local c = signal:Connect(callback)
        table.insert(conns, c)
        return c
    end

    -- ── theme engine ───────────────────────
    local cur = {}
    for k, v in pairs(Onyx.Themes[cfg.Theme]) do cur[k] = v end
    local bindings, gradBindings, refreshers = {}, {}, {}

    local function bind(inst, prop, token)
        inst[prop] = cur[token]
        table.insert(bindings, { inst, prop, token })
    end

    local function seqOf(tokens)
        local n, kp = #tokens, {}
        for i, tk in ipairs(tokens) do
            kp[i] = ColorSequenceKeypoint.new((i - 1) / (n - 1), cur[tk])
        end
        return ColorSequence.new(kp)
    end

    local function themedGradient(inst, tokens, rot)
        local g = Instance.new("UIGradient")
        g.Rotation = rot or 0
        g.Color = seqOf(tokens)
        g.Parent = inst
        table.insert(gradBindings, { g, tokens })
        return g
    end

    local function applyCur()
        for _, b in ipairs(bindings) do b[1][b[2]] = cur[b[3]] end
        for _, g in ipairs(gradBindings) do g[1].Color = seqOf(g[2]) end
        for _, r in ipairs(refreshers) do r() end
    end

    local themeGen = 0
    local function tweenTheme(name)
        themeGen += 1
        local gen = themeGen
        local from = {}
        for k, v in pairs(cur) do from[k] = v end
        local to = Onyx.Themes[name]
        local t0 = tick()
        task.spawn(function()
            while isCurrent() and gen == themeGen do
                local a = math.clamp((tick() - t0) / 0.35, 0, 1)
                local e = a * a * (3 - 2 * a)
                for k, tv in pairs(to) do cur[k] = lerpVal(from[k], tv, e) end
                applyCur()
                if a >= 1 then break end
                RunService.Heartbeat:Wait()
            end
        end)
    end

    local function makeDraggable(handle, frame)
        local dragging, dragStart, startPos = false, nil, nil
        connect(handle.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, frame.Position
                local c; c = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        c:Disconnect()
                    end
                end)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end)
    end

    -- ── sky (snow + stars) ─────────────────
    local flakes, starList = {}, {}
    local function makeSky(parent, x, y, w, h, nSnow, nStars)
        local layer = make("Frame", {
            Name = "Sky"; Position = UDim2.fromOffset(x, y); Size = UDim2.fromOffset(w, h);
            BackgroundTransparency = 1; BorderSizePixel = 0; ClipsDescendants = true;
        }, parent)
        for _ = 1, nStars do
            local sz = math.random(1, 2)
            local s = make("Frame", {
                Size = UDim2.fromOffset(sz, sz);
                Position = UDim2.fromOffset(math.random() * w, math.random() * h * 0.85);
                BackgroundColor3 = WHITE; BackgroundTransparency = 1; BorderSizePixel = 0;
            }, layer)
            corner(s, 2)
            table.insert(starList, { inst = s, phase = math.random() * 6.28, speed = 0.8 + math.random() * 1.8 })
        end
        for _ = 1, nSnow do
            local sz = math.random(2, 4)
            local f = make("Frame", {
                Size = UDim2.fromOffset(sz, sz);
                BackgroundTransparency = 0.1 + math.random() * 0.3; BorderSizePixel = 0;
            }, layer)
            corner(f, sz)
            bind(f, "BackgroundColor3", "snow")
            local st = stroke(f, cur.snowStroke, 1, cur.snowStrokeT)
            bind(st, "Color", "snowStroke")
            bind(st, "Transparency", "snowStrokeT")
            table.insert(flakes, {
                inst = f; size = sz; w = w; h = h; x = math.random() * w; y = math.random() * h;
                vy = 14 + sz * 7 + math.random() * 8; amp = 4 + math.random() * 10;
                freq = 0.6 + math.random() * 1.2; phase = math.random() * 6.28;
            })
        end
        return layer
    end

    -- ═══════════════════════════════════════
    -- SCREEN GUI + MAIN FRAME
    -- ═══════════════════════════════════════
    local ScreenGui = make("ScreenGui", {
        Name = "OnyxGui"; ResetOnSpawn = false; ZIndexBehavior = Enum.ZIndexBehavior.Sibling; IgnoreGuiInset = true;
    }, guiParent())

    local MainFrame = make("CanvasGroup", {
        Name = "Window"; Size = UDim2.fromOffset(W, H); Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2);
        BackgroundColor3 = WHITE; BackgroundTransparency = 1; BorderSizePixel = 0; Active = true;
    }, ScreenGui)
    corner(MainFrame, RAD)

    local WinBg = make("Frame", { Name = "Bg"; Size = UDim2.fromScale(1, 1); BackgroundColor3 = WHITE; BorderSizePixel = 0 }, MainFrame)
    themedGradient(WinBg, { "winA", "winB", "winC" }, 125)

    local winStroke = stroke(MainFrame, cur.winStroke, 1.5, 0.2)
    bind(winStroke, "Color", "winStroke")

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1
    uiScale.Parent = MainFrame

    local minimized = false
    local shown, animating, animGen = true, false, 0
    local restPos = MainFrame.Position
    local introDone = false

    local function setShown(show)
        if show == shown then return end
        shown = show
        animGen += 1
        local gen = animGen
        if not animating then restPos = MainFrame.Position end
        animating = true
        local sx = minimized and 270 or W
        local sy = minimized and TOP or H
        local fromS, fromT = uiScale.Scale, MainFrame.GroupTransparency
        local toS, toT = show and 1 or 0.9, show and 0 or 1
        local dur = show and 0.28 or 0.2
        local t0 = tick()
        if show then MainFrame.Visible = true end
        task.spawn(function()
            while isCurrent() and gen == animGen do
                local a = math.clamp((tick() - t0) / dur, 0, 1)
                local e = show and (1 - (1 - a) ^ 3) or (a * a)
                local sc = fromS + (toS - fromS) * e
                uiScale.Scale = sc
                MainFrame.GroupTransparency = fromT + (toT - fromT) * e
                MainFrame.Position = UDim2.new(
                    restPos.X.Scale, restPos.X.Offset + (1 - sc) * sx / 2,
                    restPos.Y.Scale, restPos.Y.Offset + (1 - sc) * sy / 2
                )
                if a >= 1 then
                    animating = false
                    MainFrame.Position = restPos
                    if not show then MainFrame.Visible = false end
                    break
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end

    makeSky(MainFrame, SIDE, 6, W - SIDE - 6, H - 12, 26, 30)

    -- ── sidebar ────────────────────────────
    local Side = make("Frame", { Name = "Sidebar"; Size = UDim2.new(0, SIDE, 1, 0); BackgroundColor3 = WHITE; BorderSizePixel = 0 }, MainFrame)
    corner(Side, RAD)
    themedGradient(Side, { "sideA", "sideB" }, 90)
    local SideFill = make("Frame", {
        Size = UDim2.new(0, RAD, 1, 0); Position = UDim2.new(1, -RAD, 0, 0); BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, Side)
    themedGradient(SideFill, { "sideA", "sideB" }, 90)
    makeSky(Side, 6, 6, SIDE - 6, H - 12, 12, 14)

    local Logo = make("Frame", {
        Size = UDim2.fromOffset(34, 34); Position = UDim2.fromOffset(14, 14); BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, Side)
    corner(Logo, 17)
    make("TextLabel", {
        Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = cfg.Logo;
        TextColor3 = BLUE_DARK; Font = Enum.Font.GothamBlack; TextSize = 20;
    }, Logo)

    make("TextLabel", {
        Size = UDim2.fromOffset(88, 18); Position = UDim2.fromOffset(56, 14); BackgroundTransparency = 1;
        Text = cfg.Title; TextColor3 = WHITE; Font = Enum.Font.GothamBold; TextSize = 15;
        TextXAlignment = Enum.TextXAlignment.Left; TextTruncate = Enum.TextTruncate.AtEnd;
    }, Side)
    make("TextLabel", {
        Size = UDim2.fromOffset(88, 14); Position = UDim2.fromOffset(56, 31); BackgroundTransparency = 1;
        Text = cfg.Subtitle; TextColor3 = C(214, 230, 255); Font = Enum.Font.Gotham; TextSize = 10;
        TextXAlignment = Enum.TextXAlignment.Left; TextTruncate = Enum.TextTruncate.AtEnd;
    }, Side)
    make("TextLabel", {
        Size = UDim2.fromOffset(SIDE - 24, 14); Position = UDim2.fromOffset(14, 74); BackgroundTransparency = 1;
        Text = "MENU"; TextColor3 = C(200, 222, 255); Font = Enum.Font.GothamBold; TextSize = 10;
        TextXAlignment = Enum.TextXAlignment.Left;
    }, Side)

    local UserCard = make("Frame", {
        Size = UDim2.fromOffset(SIDE - 20, 76); Position = UDim2.new(0, 10, 1, -88);
        BackgroundColor3 = STS_BG; BackgroundTransparency = 0.7; BorderSizePixel = 0;
    }, Side)
    corner(UserCard, 10)
    stroke(UserCard, WHITE, 1, 0.75)
    make("TextLabel", {
        Size = UDim2.fromOffset(SIDE - 40, 16); Position = UDim2.fromOffset(10, 8); BackgroundTransparency = 1;
        Text = lp.DisplayName; TextColor3 = WHITE; Font = Enum.Font.GothamBold; TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Left; TextTruncate = Enum.TextTruncate.AtEnd;
    }, UserCard)
    local StsBar = make("Frame", {
        Size = UDim2.fromOffset(SIDE - 36, 30); Position = UDim2.fromOffset(8, 38);
        BackgroundColor3 = STS_BG; BackgroundTransparency = 0.25; BorderSizePixel = 0;
    }, UserCard)
    corner(StsBar, 8)
    local stsTxt = make("TextLabel", {
        Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = "READY"; TextColor3 = Onyx.Colors.Ok;
        Font = Enum.Font.GothamBold; TextSize = 11; TextXAlignment = Enum.TextXAlignment.Center;
    }, StsBar)

    -- The tab buttons live in their own scrolling frame that stops above the user card, so a long
    -- tab list scrolls (mouse wheel / drag) instead of sliding underneath the card.
    local NavScroll = make("ScrollingFrame", {
        Name = "Nav"; Size = UDim2.fromOffset(SIDE, H - NAV_TOP - NAV_BOTTOM); Position = UDim2.fromOffset(0, NAV_TOP);
        BackgroundTransparency = 1; BorderSizePixel = 0; ScrollBarThickness = 2;
        ScrollBarImageColor3 = WHITE; ScrollBarImageTransparency = 0.3;
        CanvasSize = UDim2.new(); ScrollingDirection = Enum.ScrollingDirection.Y;
        ElasticBehavior = Enum.ElasticBehavior.Never; ClipsDescendants = true;
    }, Side)

    -- ── top bar ────────────────────────────
    local TopBar = make("Frame", {
        Name = "TopBar"; Size = UDim2.new(1, -SIDE, 0, TOP); Position = UDim2.fromOffset(SIDE, 0);
        BackgroundTransparency = 1; BorderSizePixel = 0;
    }, MainFrame)
    local PageTitle = make("TextLabel", {
        Size = UDim2.new(1, -150, 1, 0); Position = UDim2.fromOffset(18, 0); BackgroundTransparency = 1;
        Text = ""; Font = Enum.Font.GothamBold; TextSize = 16; TextXAlignment = Enum.TextXAlignment.Left;
    }, TopBar)
    bind(PageTitle, "TextColor3", "ink")
    local TopLine = make("Frame", { Size = UDim2.new(1, -28, 0, 1); Position = UDim2.new(0, 14, 1, -1); BorderSizePixel = 0 }, TopBar)
    bind(TopLine, "BackgroundColor3", "line")

    local MinBtn = make("TextButton", {
        Size = UDim2.fromOffset(14, 14); Position = UDim2.new(1, -52, 0.5, -7);
        BackgroundColor3 = C(60, 180, 60); BorderSizePixel = 0; Text = ""; AutoButtonColor = false;
    }, TopBar)
    corner(MinBtn, 7)
    local CloseBtn = make("TextButton", {
        Size = UDim2.fromOffset(14, 14); Position = UDim2.new(1, -30, 0.5, -7);
        BackgroundColor3 = C(255, 90, 80); BorderSizePixel = 0; Text = ""; AutoButtonColor = false;
    }, TopBar)
    corner(CloseBtn, 7)

    local currentTheme = cfg.Theme
    local lastLightTheme = (cfg.Theme ~= "dark") and cfg.Theme or "winter"
    local ThemePill = make("TextButton", {
        Size = UDim2.fromOffset(72, 22); Position = UDim2.new(1, -134, 0.5, -11);
        BackgroundColor3 = WHITE; BorderSizePixel = 0; Text = ""; AutoButtonColor = false;
    }, TopBar)
    corner(ThemePill, 11)
    bind(ThemePill, "BackgroundColor3", "row")
    local pillLbl = make("TextLabel", {
        Size = UDim2.fromOffset(36, 22); Position = UDim2.fromOffset(10, 0); BackgroundTransparency = 1;
        Text = "Dark"; Font = Enum.Font.GothamBold; TextSize = 11; TextXAlignment = Enum.TextXAlignment.Left;
    }, ThemePill)
    bind(pillLbl, "TextColor3", "ink")
    local pTrack = make("Frame", {
        Size = UDim2.fromOffset(24, 14); Position = UDim2.new(1, -30, 0.5, -7); BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, ThemePill)
    corner(pTrack, 7)
    local pKnob = make("Frame", {
        Size = UDim2.fromOffset(10, 10); Position = currentTheme == "dark" and UDim2.fromOffset(12, 2) or UDim2.fromOffset(2, 2);
        BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, pTrack)
    corner(pKnob, 5)
    table.insert(refreshers, function()
        pTrack.BackgroundColor3 = (currentTheme == "dark") and cur.accent or cur.swOff
    end)

    local paintThemeChips = function() end   -- replaced once the theme picker exists
    local function setThemeByName(name)
        if not Onyx.Themes[name] then return false end
        currentTheme = name
        if name ~= "dark" then lastLightTheme = name end
        TweenService:Create(pKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = (name == "dark") and UDim2.fromOffset(12, 2) or UDim2.fromOffset(2, 2)
        }):Play()
        tweenTheme(name)
        paintThemeChips()
        return true
    end
    connect(ThemePill.MouseButton1Click, function()
        setThemeByName(currentTheme == "dark" and lastLightTheme or "dark")
    end)

    -- ── toast ──────────────────────────────
    local TOAST_HIDDEN = UDim2.new(0.5, 0, 0, -64)
    local TOAST_SHOWN  = UDim2.new(0.5, 0, 0, 18)
    local Toast = make("Frame", {
        Name = "Toast"; AnchorPoint = Vector2.new(0.5, 0); Size = UDim2.fromOffset(260, 44); Position = TOAST_HIDDEN;
        BackgroundColor3 = WHITE; BackgroundTransparency = 0.04; BorderSizePixel = 0;
    }, ScreenGui)
    corner(Toast, 12)
    themedGradient(Toast, { "cardA", "cardB" }, 90)
    local toastStroke = stroke(Toast, cur.line, 1)
    bind(toastStroke, "Color", "line")
    local toastBar = make("Frame", {
        Size = UDim2.fromOffset(4, 24); Position = UDim2.fromOffset(10, 10); BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, Toast)
    corner(toastBar, 2)
    do
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new(BLUE_DARK, CYAN)
        g.Rotation = 90
        g.Parent = toastBar
    end
    local toastTitle = make("TextLabel", {
        Size = UDim2.fromOffset(224, 16); Position = UDim2.fromOffset(24, 6); BackgroundTransparency = 1; Text = "";
        Font = Enum.Font.GothamBold; TextSize = 12; TextXAlignment = Enum.TextXAlignment.Left; TextTruncate = Enum.TextTruncate.AtEnd;
    }, Toast)
    bind(toastTitle, "TextColor3", "ink")
    local toastBody = make("TextLabel", {
        Size = UDim2.fromOffset(224, 14); Position = UDim2.fromOffset(24, 23); BackgroundTransparency = 1; Text = "";
        Font = Enum.Font.Gotham; TextSize = 11; TextXAlignment = Enum.TextXAlignment.Left; TextTruncate = Enum.TextTruncate.AtEnd;
    }, Toast)
    bind(toastBody, "TextColor3", "dim")

    local toastGen = 0
    function Window:Notify(title, body, duration)
        if not isCurrent() then return end
        toastGen += 1
        local gen = toastGen
        toastTitle.Text = tostring(title or "")
        toastBody.Text = tostring(body or "")
        TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = TOAST_SHOWN }):Play()
        task.delay(duration or 2, function()
            if gen ~= toastGen or not isCurrent() then return end
            TweenService:Create(Toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = TOAST_HIDDEN }):Play()
        end)
    end

    -- ═══════════════════════════════════════
    -- TABS, CARDS, CONTROLS
    -- ═══════════════════════════════════════
    local Tab, Card = {}, {}
    Tab.__index, Card.__index = Tab, Card

    local Pages = make("Frame", {
        Size = UDim2.new(1, -SIDE, 1, -TOP); Position = UDim2.fromOffset(SIDE, TOP);
        BackgroundTransparency = 1; BorderSizePixel = 0;
    }, MainFrame)

    local allTabs, userTabs, navTabs = {}, {}, {}
    local activeTab

    local function paintNav(animate)
        for _, t in ipairs(allTabs) do
            local on = (t == activeTab)
            local goalT = on and 0 or 1
            local goalC = on and cur.navOnTxt or WHITE
            t.Nav.BackgroundColor3 = cur.navOn
            if animate then
                TweenService:Create(t.Nav, TweenInfo.new(0.15), { BackgroundTransparency = goalT; TextColor3 = goalC }):Play()
            else
                t.Nav.BackgroundTransparency = goalT
                t.Nav.TextColor3 = goalC
            end
        end
    end
    table.insert(refreshers, function() paintNav(false) end)

    -- Scrolls the sidebar just enough that the selected tab's button is fully visible.
    local function revealNav(tab)
        local view = NavScroll.AbsoluteWindowSize.Y
        if view <= 0 then return end
        local top = tab.Nav.Position.Y.Offset
        local bottom = top + tab.Nav.Size.Y.Offset
        local y = NavScroll.CanvasPosition.Y
        if top < y then
            y = top - 2
        elseif bottom > y + view then
            y = bottom - view + 2
        end
        NavScroll.CanvasPosition = Vector2.new(0, math.max(y, 0))
    end

    local function selectTab(tab)
        activeTab = tab
        for _, t in ipairs(allTabs) do t.Page.Visible = (t == tab) end
        PageTitle.Text = tab.Name
        paintNav(true)
        revealNav(tab)
    end

    local builtinSettings, builtinCredits  -- assigned below

    local function layoutNav()
        navTabs = {}
        for _, t in ipairs(userTabs) do table.insert(navTabs, t) end
        table.insert(navTabs, builtinSettings)
        table.insert(navTabs, builtinCredits)
        for i, t in ipairs(navTabs) do
            t.Nav.Position = UDim2.fromOffset(12, 2 + (i - 1) * NAV_STEP)
        end
        NavScroll.CanvasSize = UDim2.fromOffset(0, #navTabs * NAV_STEP + 4)
    end

    local function createTab(name)
        local page = make("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; BorderSizePixel = 0; Visible = false;
            ScrollBarThickness = 3; CanvasSize = UDim2.new(); ScrollingDirection = Enum.ScrollingDirection.Y;
        }, Pages)
        bind(page, "ScrollBarImageColor3", "accent")

        local nav = make("TextButton", {
            Size = UDim2.fromOffset(SIDE - 24, 34); Position = UDim2.fromOffset(12, 2);
            BackgroundColor3 = WHITE; BackgroundTransparency = 1; BorderSizePixel = 0; Text = name; TextColor3 = WHITE;
            Font = Enum.Font.GothamBold; TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; AutoButtonColor = false;
        }, NavScroll)
        corner(nav, 10)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 14)
        pad.Parent = nav

        local tab = setmetatable({ Name = name, Page = page, Nav = nav, Cards = {} }, Tab)
        table.insert(allTabs, tab)
        connect(nav.MouseButton1Click, function() selectTab(tab) end)
        return tab
    end

    function Card:_height()
        return CARD_HEAD + self.BodyH + CARD_FOOT
    end

    function Tab:_relayout()
        local colY = { Left = PAD, Right = PAD }
        for _, c in ipairs(self.Cards) do
            if c.Column ~= "Wide" then
                local x = (c.Column == "Left") and PAD or (PAD + COL_W + COL_GAP)
                local h = c:_height()
                c.Frame.Position = UDim2.fromOffset(x, colY[c.Column])
                c.Frame.Size = UDim2.fromOffset(COL_W, h)
                c.Body.Size = UDim2.new(1, -20, 0, c.BodyH)
                colY[c.Column] += h + COL_GAP
            end
        end
        local y = math.max(colY.Left, colY.Right)
        for _, c in ipairs(self.Cards) do
            if c.Column == "Wide" then
                local h = c:_height()
                c.Frame.Position = UDim2.fromOffset(PAD, y)
                c.Frame.Size = UDim2.fromOffset(WIDE_W, h)
                c.Body.Size = UDim2.new(1, -20, 0, c.BodyH)
                y += h + COL_GAP
            end
        end
        self.Page.CanvasSize = UDim2.fromOffset(0, y + 2)
    end

    local function columnHeight(tab, col)
        local total = 0
        for _, c in ipairs(tab.Cards) do
            if c.Column == col then total += c:_height() + COL_GAP end
        end
        return total
    end

    -- AddCard({ Title, Subtitle, Column = "Left" | "Right" | "Wide" })  (Column omitted = shorter column)
    function Tab:AddCard(o)
        o = o or {}
        local col = o.Column
        if col ~= "Left" and col ~= "Right" and col ~= "Wide" then
            col = (columnHeight(self, "Left") <= columnHeight(self, "Right")) and "Left" or "Right"
        end

        local frame = make("Frame", {
            Size = UDim2.fromOffset(COL_W, 60); BackgroundColor3 = WHITE; BorderSizePixel = 0;
        }, self.Page)
        corner(frame, 12)
        bind(frame, "BackgroundTransparency", "cardT")
        themedGradient(frame, { "cardA", "cardB" }, 90)
        local st = stroke(frame, cur.line, 1)
        bind(st, "Color", "line")

        local title = make("TextLabel", {
            Size = UDim2.new(1, -24, 0, 18); Position = UDim2.fromOffset(12, 10); BackgroundTransparency = 1;
            Text = tostring(o.Title or ""); TextColor3 = WHITE; Font = Enum.Font.GothamBold; TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Left;
        }, frame)
        themedGradient(title, { "titleA", "titleB" }, 0)
        local sub = make("TextLabel", {
            Size = UDim2.new(1, -24, 0, 14); Position = UDim2.fromOffset(12, 28); BackgroundTransparency = 1;
            Text = tostring(o.Subtitle or ""); Font = Enum.Font.Gotham; TextSize = 10; TextXAlignment = Enum.TextXAlignment.Left;
            TextTruncate = Enum.TextTruncate.AtEnd;
        }, frame)
        bind(sub, "TextColor3", "dim")

        local body = make("Frame", {
            Size = UDim2.new(1, -20, 0, 0); Position = UDim2.fromOffset(10, CARD_HEAD);
            BackgroundTransparency = 1; BorderSizePixel = 0;
        }, frame)
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, ROW_GAP)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = body

        local card = setmetatable({ Tab = self, Frame = frame, Body = body, Column = col, Count = 0, BodyH = 0 }, Card)
        table.insert(self.Cards, card)
        self:_relayout()
        return card
    end

    function Card:_row(height, withBackground)
        self.Count += 1
        self.BodyH += height + ((self.Count > 1) and ROW_GAP or 0)
        local row = make("Frame", {
            Size = UDim2.new(1, 0, 0, height); BorderSizePixel = 0; LayoutOrder = self.Count;
            BackgroundTransparency = withBackground and 0 or 1;
        }, self.Body)
        if withBackground then
            corner(row, 8)
            bind(row, "BackgroundColor3", "row")
        end
        self.Tab:_relayout()
        return row
    end

    local function rowLabel(row, text, widthMinus)
        local l = make("TextLabel", {
            Size = UDim2.new(1, -widthMinus, 1, 0); Position = UDim2.fromOffset(10, 0); BackgroundTransparency = 1;
            Text = tostring(text or ""); Font = Enum.Font.GothamMedium; TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Left; TextTruncate = Enum.TextTruncate.AtEnd;
        }, row)
        bind(l, "TextColor3", "ink")
        return l
    end

    -- AddToggle({ Label, Default = false, Flag, Callback = function(value) end })  -> { Get, Set(value, silent) }
    function Card:AddToggle(o)
        o = o or {}
        local row = self:_row(30, true)
        rowLabel(row, o.Label, 60)
        local track = make("Frame", {
            Size = UDim2.fromOffset(34, 18); Position = UDim2.new(1, -44, 0.5, -9); BackgroundColor3 = WHITE; BorderSizePixel = 0;
        }, row)
        corner(track, 9)
        local knob = make("Frame", {
            Size = UDim2.fromOffset(14, 14); Position = UDim2.fromOffset(2, 2); BackgroundColor3 = WHITE; BorderSizePixel = 0;
        }, track)
        corner(knob, 7)

        local state = o.Default == true
        if o.Flag then Window.Flags[o.Flag] = state end
        local ctl = {}
        local function recolor() track.BackgroundColor3 = state and cur.accent or cur.swOff end
        local function repos(animate)
            local goal = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
            if animate then
                TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Position = goal }):Play()
            else
                knob.Position = goal
            end
        end
        recolor(); repos(false)
        table.insert(refreshers, recolor)

        function ctl:Get() return state end
        function ctl:Set(value, silent)
            value = value and true or false
            if value == state then return end
            state = value
            recolor(); repos(true)
            if o.Flag then Window.Flags[o.Flag] = state end
            if not silent then safe(o.Callback, state) end
        end

        local btn = make("TextButton", { Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = "" }, row)
        connect(btn.MouseButton1Click, function() ctl:Set(not state) end)
        return ctl
    end

    -- AddNumber({ Label, Default, Min, Max, Integer, Flag, Callback = function(value) end }) -> { Get, Set(value, silent) }
    function Card:AddNumber(o)
        o = o or {}
        local lo, hi = o.Min or -math.huge, o.Max or math.huge
        local function fix(v)
            v = math.clamp(v, lo, hi)
            if o.Integer then v = math.floor(v + 0.5) end
            return v
        end
        local value = fix(tonumber(o.Default) or (lo ~= -math.huge and lo or 0))
        if o.Flag then Window.Flags[o.Flag] = value end

        local row = self:_row(30, true)
        rowLabel(row, o.Label, 76)
        local box = make("TextBox", {
            Size = UDim2.fromOffset(60, 22); Position = UDim2.new(1, -68, 0.5, -11); BorderSizePixel = 0;
            Text = tostring(value); Font = Enum.Font.GothamBold; TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Center; ClearTextOnFocus = false;
        }, row)
        corner(box, 6)
        bind(box, "BackgroundColor3", "input")
        bind(box, "TextColor3", "inputTxt")
        local st = stroke(box, cur.line, 1)
        bind(st, "Color", "line")

        local ctl = {}
        function ctl:Get() return value end
        function ctl:Set(v, silent)
            v = tonumber(v)
            if not v or v ~= v then box.Text = tostring(value); return end
            v = fix(v)
            value = v
            box.Text = tostring(v)
            if o.Flag then Window.Flags[o.Flag] = v end
            if not silent then safe(o.Callback, v) end
        end
        connect(box.Focused, function() st.Color = BLUE end)
        connect(box.FocusLost, function()
            st.Color = cur.line
            ctl:Set(box.Text)
        end)
        return ctl
    end

    -- AddCycle({ Label, Options = { "A", "B" }, Default = index, Flag, Callback = function(option, index) end })
    --   -> { Get() -> option, index ; Set(index, silent) }. Clicking the button steps to the next option.
    function Card:AddCycle(o)
        o = o or {}
        local options = o.Options or {}
        local count = #options
        local index = math.clamp(math.floor(tonumber(o.Default) or 1), 1, math.max(count, 1))
        if o.Flag then Window.Flags[o.Flag] = options[index] end

        local row = self:_row(30, true)
        rowLabel(row, o.Label, 100)
        local btn = make("TextButton", {
            Size = UDim2.fromOffset(84, 22); Position = UDim2.new(1, -92, 0.5, -11); BorderSizePixel = 0;
            Text = tostring(options[index] or ""); Font = Enum.Font.GothamBold; TextSize = 11;
            AutoButtonColor = false; TextTruncate = Enum.TextTruncate.AtEnd;
        }, row)
        corner(btn, 6)
        bind(btn, "BackgroundColor3", "input")
        bind(btn, "TextColor3", "inputTxt")
        local st = stroke(btn, cur.line, 1)
        bind(st, "Color", "line")

        local ctl = {}
        function ctl:Get() return options[index], index end
        function ctl:Set(i, silent)
            i = tonumber(i)
            if not i or count == 0 then return end
            i = math.clamp(math.floor(i), 1, count)
            index = i
            btn.Text = tostring(options[index])
            if o.Flag then Window.Flags[o.Flag] = options[index] end
            if not silent then safe(o.Callback, options[index], index) end
        end
        connect(btn.MouseButton1Click, function()
            if count > 0 then ctl:Set(index % count + 1) end
        end)
        return ctl
    end

    -- AddColor({ Label, Default = Color3, Flag, Callback = function(color) end }) -> { Get, Set(Color3 | "RRGGBB", silent) }
    -- A swatch plus a hex box: type RRGGBB (a leading # is fine) and press Enter or click away.
    function Card:AddColor(o)
        o = o or {}
        local color = typeof(o.Default) == "Color3" and o.Default or WHITE
        if o.Flag then Window.Flags[o.Flag] = color end

        local row = self:_row(30, true)
        rowLabel(row, o.Label, 110)
        local swatch = make("Frame", {
            Size = UDim2.fromOffset(18, 18); Position = UDim2.new(1, -96, 0.5, -9);
            BackgroundColor3 = color; BorderSizePixel = 0;
        }, row)
        corner(swatch, 5)
        local swatchStroke = stroke(swatch, cur.line, 1)
        bind(swatchStroke, "Color", "line")
        local box = make("TextBox", {
            Size = UDim2.fromOffset(62, 22); Position = UDim2.new(1, -70, 0.5, -11); BorderSizePixel = 0;
            Text = toHex(color); PlaceholderText = "RRGGBB"; Font = Enum.Font.GothamBold; TextSize = 11;
            TextXAlignment = Enum.TextXAlignment.Center; ClearTextOnFocus = false;
        }, row)
        corner(box, 6)
        bind(box, "BackgroundColor3", "input")
        bind(box, "TextColor3", "inputTxt")
        local st = stroke(box, cur.line, 1)
        bind(st, "Color", "line")

        local ctl = {}
        function ctl:Get() return color end
        function ctl:Set(v, silent)
            if type(v) == "string" then v = fromHex(v) end
            if typeof(v) ~= "Color3" then
                box.Text = toHex(color) -- not a valid color: put the old one back
                return
            end
            color = v
            swatch.BackgroundColor3 = color
            box.Text = toHex(color)
            if o.Flag then Window.Flags[o.Flag] = color end
            if not silent then safe(o.Callback, color) end
        end
        connect(box.Focused, function() st.Color = BLUE end)
        connect(box.FocusLost, function()
            st.Color = cur.line
            ctl:Set(box.Text)
        end)
        return ctl
    end

    -- AddButton({ Label, Danger = false, Callback = function() end }) -> TextButton
    function Card:AddButton(o)
        o = o or {}
        local row = self:_row(30, false)
        local btn = make("TextButton", {
            Size = UDim2.fromScale(1, 1); BorderSizePixel = 0; Text = tostring(o.Label or "Button"); TextColor3 = WHITE;
            Font = Enum.Font.GothamBold; TextSize = 12; AutoButtonColor = false;
        }, row)
        corner(btn, 8)
        local function recolor() btn.BackgroundColor3 = o.Danger and C(255, 90, 80) or cur.accent end
        recolor()
        table.insert(refreshers, recolor)
        connect(btn.MouseButton1Click, function() safe(o.Callback) end)
        return btn
    end

    -- AddLabel({ Text, Height = 30 }) -> { SetText }
    function Card:AddLabel(o)
        o = o or {}
        local row = self:_row(o.Height or 30, true)
        local l = make("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0); Position = UDim2.fromOffset(10, 0); BackgroundTransparency = 1;
            Text = tostring(o.Text or ""); Font = Enum.Font.Gotham; TextSize = 11; TextWrapped = true;
            TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Center;
        }, row)
        bind(l, "TextColor3", "ink")
        local ctl = {}
        function ctl:SetText(text) l.Text = tostring(text) end
        return ctl
    end

    -- AddCustom(height, build(frame)) gives you a blank transparent row to build anything in.
    function Card:AddCustom(height, build)
        local row = self:_row(height, false)
        if build then safe(build, row) end
        return row
    end

    -- AddKeybind({ Label, Default = Enum.KeyCode, Pressed = function() end, Changed = function(keyCode) end }) -> { Get, Set(keyCode, silent) }
    local keybinds = {}
    local listeningCtl = nil
    function Card:AddKeybind(o)
        o = o or {}
        local row = self:_row(30, true)
        rowLabel(row, o.Label, 130)
        local btn = make("TextButton", {
            Size = UDim2.fromOffset(110, 22); Position = UDim2.new(1, -118, 0.5, -11); BorderSizePixel = 0; Text = "";
            Font = Enum.Font.GothamBold; TextSize = 12; AutoButtonColor = false;
        }, row)
        corner(btn, 6)
        bind(btn, "BackgroundColor3", "input")
        bind(btn, "TextColor3", "inputTxt")
        local st = stroke(btn, cur.line, 1)
        bind(st, "Color", "line")

        local key = o.Default
        local ctl = { Pressed = o.Pressed }
        function ctl:Get() return key end
        function ctl:_paint()
            local listening = (listeningCtl == ctl)
            btn.Text = listening and "Press a key..." or (key and key.Name or "None")
            st.Color = listening and BLUE or cur.line
        end
        function ctl:Set(newKey, silent)
            key = newKey
            ctl:_paint()
            if not silent then safe(o.Changed, key) end
        end
        ctl:_paint()
        table.insert(refreshers, function() ctl:_paint() end)
        table.insert(keybinds, ctl)

        connect(btn.MouseButton1Click, function()
            listeningCtl = ctl
            ctl:_paint()
        end)
        return ctl
    end

    -- ── public tab API ─────────────────────
    function Window:AddTab(name)
        local tab = createTab(tostring(name))
        table.insert(userTabs, tab)
        table.insert(Window.Tabs, tab)
        layoutNav()
        if #userTabs == 1 then selectTab(tab) else paintNav(false) end
        return tab
    end

    -- ═══════════════════════════════════════
    -- BUILT-IN PAGE: SETTINGS
    -- ═══════════════════════════════════════
    builtinSettings = createTab("Settings")
    Window.SettingsTab = builtinSettings

    local settingsCard = builtinSettings:AddCard({ Title = "Settings", Subtitle = "Hide key and session controls", Column = "Wide" })
    local hideKeyCtl = settingsCard:AddKeybind({
        Label = "Hide / Show Key", Default = cfg.ToggleKey,
        Changed = function(key) if key then cfg.ToggleKey = key end end,
    })

    local armed = false
    local unloadText = "Unload " .. cfg.Title
    local unloadBtn
    unloadBtn = settingsCard:AddButton({
        Label = unloadText, Danger = true,
        Callback = function()
            if armed then Window:Destroy(); return end
            armed = true
            unloadBtn.Text = "Click again to confirm"
            task.delay(3, function()
                if armed and isCurrent() then
                    armed = false
                    unloadBtn.Text = unloadText
                end
            end)
        end,
    })

    local themesCard = builtinSettings:AddCard({ Title = "Themes", Subtitle = "Pick a look  ·  text stays readable on every one", Column = "Wide" })
    do
        local chips = {}
        themesCard:AddCustom(52, function(holder)
            local scroll = make("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; BorderSizePixel = 0; ScrollBarThickness = 3;
                CanvasSize = UDim2.new(); AutomaticCanvasSize = Enum.AutomaticSize.X; ScrollingDirection = Enum.ScrollingDirection.X;
            }, holder)
            bind(scroll, "ScrollBarImageColor3", "accent")
            local lay = Instance.new("UIListLayout")
            lay.FillDirection = Enum.FillDirection.Horizontal
            lay.Padding = UDim.new(0, 8)
            lay.SortOrder = Enum.SortOrder.LayoutOrder
            lay.Parent = scroll

            for i, d in ipairs(Onyx.ThemeOrder) do
                local key, name = d[1], d[2]
                local th = Onyx.Themes[key]
                if th then
                    local chip = make("TextButton", {
                        Size = UDim2.fromOffset(84, 42); BackgroundTransparency = 1; Text = ""; AutoButtonColor = false; LayoutOrder = i;
                    }, scroll)
                    local prev = make("CanvasGroup", {
                        Size = UDim2.new(1, 0, 0, 28); BackgroundColor3 = WHITE; BackgroundTransparency = 1; BorderSizePixel = 0;
                    }, chip)
                    corner(prev, 8)
                    local pbg = make("Frame", { Size = UDim2.fromScale(1, 1); BackgroundColor3 = WHITE; BorderSizePixel = 0 }, prev)
                    do
                        local g = Instance.new("UIGradient")
                        g.Rotation = 125
                        g.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, th.winA); ColorSequenceKeypoint.new(0.5, th.winB); ColorSequenceKeypoint.new(1, th.winC);
                        })
                        g.Parent = pbg
                    end
                    local strip = make("Frame", { Size = UDim2.fromOffset(20, 28); BackgroundColor3 = WHITE; BorderSizePixel = 0 }, prev)
                    do
                        local g = Instance.new("UIGradient")
                        g.Rotation = 90
                        g.Color = ColorSequence.new(th.sideA, th.sideB)
                        g.Parent = strip
                    end
                    local mini = make("Frame", {
                        Size = UDim2.fromOffset(38, 14); Position = UDim2.fromOffset(26, 7); BackgroundColor3 = th.cardA; BorderSizePixel = 0;
                    }, prev)
                    corner(mini, 4)
                    local dot = make("Frame", {
                        Size = UDim2.fromOffset(10, 10); Position = UDim2.fromOffset(68, 9); BackgroundColor3 = th.accent; BorderSizePixel = 0;
                    }, prev)
                    corner(dot, 5)
                    local st = stroke(prev, cur.line, 1)
                    local lbl = make("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 12); Position = UDim2.fromOffset(0, 30); BackgroundTransparency = 1;
                        Text = name; Font = Enum.Font.GothamMedium; TextSize = 10; TextTruncate = Enum.TextTruncate.AtEnd;
                    }, chip)
                    bind(lbl, "TextColor3", "ink")
                    chips[key] = { st = st, lbl = lbl }
                    connect(chip.MouseButton1Click, function() setThemeByName(key) end)
                end
            end
        end)
        paintThemeChips = function()
            for key, c in pairs(chips) do
                local on = (key == currentTheme)
                c.st.Color = on and cur.accent or cur.line
                c.st.Thickness = on and 2 or 1
                c.lbl.Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium
            end
        end
        table.insert(refreshers, function() paintThemeChips() end)
        paintThemeChips()
    end

    -- ═══════════════════════════════════════
    -- BUILT-IN PAGE: CREDITS
    -- ═══════════════════════════════════════
    builtinCredits = createTab("Credits")
    Window.CreditsTab = builtinCredits
    do
        local credCard = make("Frame", {
            Size = UDim2.fromOffset(300, 214); Position = UDim2.fromOffset((W - SIDE) / 2 - 150, 40);
            BackgroundColor3 = WHITE; BorderSizePixel = 0;
        }, builtinCredits.Page)
        corner(credCard, 12)
        bind(credCard, "BackgroundTransparency", "cardT")
        themedGradient(credCard, { "cardA", "cardB" }, 90)
        local st = stroke(credCard, cur.line, 1)
        bind(st, "Color", "line")

        local credLogo = make("Frame", {
            Size = UDim2.fromOffset(56, 56); Position = UDim2.new(0.5, -28, 0, 22); BackgroundColor3 = WHITE; BorderSizePixel = 0;
        }, credCard)
        corner(credLogo, 28)
        do
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new(BLUE_DARK, CYAN)
            g.Rotation = 135
            g.Parent = credLogo
        end
        make("TextLabel", {
            Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = cfg.Credits.Logo; TextColor3 = WHITE;
            Font = Enum.Font.GothamBlack; TextSize = 28;
        }, credLogo)

        local t1 = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24); Position = UDim2.fromOffset(0, 86); BackgroundTransparency = 1;
            Text = cfg.Credits.Title; Font = Enum.Font.GothamBold; TextSize = 20;
        }, credCard)
        bind(t1, "TextColor3", "ink")
        local ln = make("Frame", { Size = UDim2.fromOffset(220, 1); Position = UDim2.new(0.5, -110, 0, 122); BorderSizePixel = 0 }, credCard)
        bind(ln, "BackgroundColor3", "line")
        local by = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14); Position = UDim2.fromOffset(0, 134); BackgroundTransparency = 1;
            Text = cfg.Credits.Label; Font = Enum.Font.GothamBold; TextSize = 10;
        }, credCard)
        bind(by, "TextColor3", "dim")
        local nm = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30); Position = UDim2.fromOffset(0, 150); BackgroundTransparency = 1;
            Text = cfg.Credits.Name; TextColor3 = WHITE; Font = Enum.Font.GothamBold; TextSize = 24;
        }, credCard)
        themedGradient(nm, { "titleA", "titleB" }, 0)
        local ver = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14); Position = UDim2.fromOffset(0, 186); BackgroundTransparency = 1;
            Text = cfg.Credits.Version; Font = Enum.Font.Gotham; TextSize = 11;
        }, credCard)
        bind(ver, "TextColor3", "dim")
    end

    layoutNav()
    selectTab(builtinSettings)   -- replaced by the first user tab when one is added

    -- ═══════════════════════════════════════
    -- WINDOW CONTROLS + INPUT
    -- ═══════════════════════════════════════
    connect(MinBtn.MouseButton1Click, function()
        minimized = not minimized
        ThemePill.Visible = not minimized
        local target = minimized and UDim2.fromOffset(270, TOP) or UDim2.fromOffset(W, H)
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = target }):Play()
    end)
    connect(CloseBtn.MouseButton1Click, function() Window:Destroy() end)
    makeDraggable(TopBar, MainFrame)
    makeDraggable(Side, MainFrame)

    connect(UserInputService.InputBegan, function(input)
        if not isCurrent() then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        if listeningCtl then
            local ctl = listeningCtl
            listeningCtl = nil
            if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then
                ctl:Set(input.KeyCode)
            end
            ctl:_paint()
            return
        end

        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == cfg.ToggleKey then
            if introDone then setShown(not shown) end
            return
        end
        for _, kb in ipairs(keybinds) do
            if kb.Pressed and kb:Get() == input.KeyCode then safe(kb.Pressed) end
        end
    end)

    -- sky animation: 30 updates per second, only while visible
    local clock, skyAcc, starsOn = 0, 0, true
    connect(RunService.Heartbeat, function(dt)
        if not isCurrent() or minimized or not MainFrame.Visible then return end
        skyAcc += dt
        if skyAcc < 1 / 30 then return end
        local step = math.min(skyAcc, 0.1)
        skyAcc = 0
        clock += step
        for _, f in ipairs(flakes) do
            f.y += f.vy * step
            if f.y > f.h then
                f.y = -f.size
                f.x = math.random() * f.w
            end
            f.inst.Position = UDim2.fromOffset(f.x + math.sin(clock * f.freq + f.phase) * f.amp, f.y)
        end
        local vis = cur.stars
        if vis > 0.001 then
            starsOn = true
            for _, s in ipairs(starList) do
                local tw = 0.5 + 0.5 * math.sin(clock * s.speed + s.phase)
                s.inst.BackgroundTransparency = 1 - vis * (0.25 + 0.65 * tw)
            end
        elseif starsOn then
            starsOn = false
            for _, s in ipairs(starList) do s.inst.BackgroundTransparency = 1 end
        end
    end)

    -- ═══════════════════════════════════════
    -- PUBLIC WINDOW API
    -- ═══════════════════════════════════════
    function Window:SetStatus(text, color)
        stsTxt.Text = tostring(text)
        stsTxt.TextColor3 = color or Onyx.Colors.Ok
    end
    function Window:SetTheme(name) return setThemeByName(name) end
    function Window:GetTheme() return currentTheme end
    function Window:SetToggleKey(key)
        cfg.ToggleKey = key
        hideKeyCtl:Set(key, true)
    end
    function Window:Toggle() if introDone then setShown(not shown) end end
    function Window:SelectTab(tab) if tab and tab.Page then selectTab(tab) end end
    function Window:Destroy()
        if not Window.Alive then return end
        Window.Alive = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
        pcall(function() ScreenGui:Destroy() end)
        if env.__OnyxWindows and env.__OnyxWindows[cfg.Id] == Window then env.__OnyxWindows[cfg.Id] = nil end
        safe(cfg.OnUnload)
    end

    -- ═══════════════════════════════════════
    -- OPENING SEQUENCE
    -- ═══════════════════════════════════════
    local WIN_START_SCALE, WIN_RISE, WIN_DUR = 0.84, 26, 0.75

    local function playSplash(holder)
        local vs = ScreenGui.AbsoluteSize
        if vs.X < 100 or vs.Y < 100 then
            local cam = workspace.CurrentCamera
            vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
        end
        local sw, sh = vs.X, vs.Y

        local dim = make("Frame", {
            Name = "Splash"; Size = UDim2.fromScale(1, 1); BackgroundColor3 = C(6, 10, 24);
            BackgroundTransparency = 1; BorderSizePixel = 0; ZIndex = 50;
        }, ScreenGui)
        holder.frame = dim
        TweenService:Create(dim, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.5 }):Play()

        local cx, cy = sw / 2, sh / 2
        local TW, TH = 440, 40
        local textLeft, textRight = cx - TW / 2, cx + TW / 2
        local lineY = cy + 22

        local reveal = make("Frame", {
            Position = UDim2.fromOffset(textLeft, lineY - TH - 8); Size = UDim2.fromOffset(0, TH);
            BackgroundTransparency = 1; BorderSizePixel = 0; ClipsDescendants = true; ZIndex = 52;
        }, dim)
        local label = make("TextLabel", {
            Size = UDim2.fromOffset(TW, TH); BackgroundTransparency = 1; Text = tostring(cfg.Splash);
            TextColor3 = WHITE; TextStrokeTransparency = 0.8; TextStrokeColor3 = C(120, 170, 255);
            Font = Enum.Font.GothamBold; TextSize = 32; TextXAlignment = Enum.TextXAlignment.Center; ZIndex = 52;
        }, reveal)

        local line = make("Frame", {
            Position = UDim2.fromOffset(textLeft, lineY); Size = UDim2.fromOffset(0, 2);
            BackgroundColor3 = WHITE; BorderSizePixel = 0; ZIndex = 52;
        }, dim)
        corner(line, 1)
        do
            local lg = Instance.new("UIGradient")
            lg.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1); NumberSequenceKeypoint.new(0.35, 0.4); NumberSequenceKeypoint.new(1, 0);
            })
            lg.Parent = line
        end

        local star = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5); Size = UDim2.fromOffset(40, 40); Position = UDim2.fromOffset(-100, -100);
            BackgroundTransparency = 1; ZIndex = 56;
        }, dim)
        local function starPart(w, h, rot, tr, z)
            local p = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5); Position = UDim2.fromScale(0.5, 0.5); Size = UDim2.fromOffset(w, h);
                Rotation = rot; BackgroundColor3 = WHITE; BackgroundTransparency = tr; BorderSizePixel = 0; ZIndex = z;
            }, star)
            corner(p, math.max(w, h))
            return p
        end
        starPart(40, 40, 0, 0.88, 55)
        starPart(34, 3, 0, 0, 56)
        starPart(3, 34, 0, 0, 56)
        starPart(22, 2, 45, 0.15, 56)
        starPart(22, 2, -45, 0.15, 56)
        starPart(12, 12, 0, 0, 57)

        local TRAIL, SPACING = 24, 9
        local trail = {}
        for i = 1, TRAIL do
            local k = i / TRAIL
            local sz = math.max(2, math.floor(10 * (1 - k)) + 2)
            local d = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5); Size = UDim2.fromOffset(sz, sz); Position = UDim2.fromOffset(-100, -100);
                BackgroundColor3 = WHITE; BackgroundTransparency = 0.25 + 0.75 * k; BorderSizePixel = 0; ZIndex = 54;
            }, dim)
            corner(d, sz)
            trail[i] = d
        end

        local poly = {}
        local function push(p)
            local last = poly[#poly]
            if not last or (p - last).Magnitude > 0.5 then table.insert(poly, p) end
        end
        local function bez3(a, b, c, d, n)
            for i = 0, n do
                local t, u = i / n, 1 - i / n
                push(a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t))
            end
        end

        local R0 = 0.13 * math.min(sw, sh)
        local R1 = R0 * 0.55
        local dirIn = Vector2.new(-0.7071, 0.7071)
        local Cc = Vector2.new(math.max(sw * 0.2, R0 + 24), sh * 0.68)
        local E0 = Cc + Vector2.new(-0.7071, -0.7071) * R0
        local P0 = Vector2.new(sw + 80, -80)

        bez3(P0, P0 + Vector2.new(-sw * 0.25, sh * 0.30), E0 - dirIn * (sw * 0.22), E0, 80)
        do
            local N = 120
            for i = 1, N do
                local k = i / N
                local phi = math.rad(225 - 495 * k)
                local r = R0 + (R1 - R0) * k
                push(Cc + Vector2.new(math.cos(phi), math.sin(phi)) * r)
            end
        end
        local X = poly[#poly]
        local T0 = Vector2.new(math.max(textLeft - 40, X.X + 90), lineY)
        local idxFinal = #poly
        bez3(X, X + Vector2.new(sw * 0.10, 0), T0 - Vector2.new(sw * 0.10, 0), T0, 60)
        local T1 = Vector2.new(textRight + 70, lineY)
        for i = 1, 24 do push(T0:Lerp(T1, i / 24)) end
        do
            local a, b, c = T1, T1 + Vector2.new(sw * 0.08, 0), T1 + Vector2.new(sw * 0.18, -sh * 0.24)
            for i = 1, 40 do
                local t, u = i / 40, 1 - i / 40
                push(a * (u * u) + b * (2 * u * t) + c * (t * t))
            end
        end

        local cum = { 0 }
        for i = 2, #poly do cum[i] = cum[i - 1] + (poly[i] - poly[i - 1]).Magnitude end
        local total = cum[#cum]
        local dFinal = cum[idxFinal]

        local function posAt(d)
            d = math.clamp(d, 0, total)
            local lo, hi = 1, #cum
            while lo < hi do
                local mid = math.floor((lo + hi) / 2)
                if cum[mid] < d then lo = mid + 1 else hi = mid end
            end
            if lo == 1 then return poly[1] end
            local c0, c1 = cum[lo - 1], cum[lo]
            local f = (c1 - c0 > 1e-6) and (d - c0) / (c1 - c0) or 0
            return poly[lo - 1]:Lerp(poly[lo], f)
        end

        local DUR = 2.9
        local t0 = tick()
        while isCurrent() do
            local a = math.clamp((tick() - t0) / DUR, 0, 1)
            local e = 1 - (1 - a) ^ 1.7
            local s = total * e
            local p = posAt(s)
            star.Position = UDim2.fromOffset(p.X, p.Y)
            star.Rotation = (tick() - t0) * 420
            for i = 1, TRAIL do
                local tp = posAt(math.max(0, s - i * SPACING))
                trail[i].Position = UDim2.fromOffset(tp.X, tp.Y)
            end
            if s >= dFinal then
                reveal.Size = UDim2.fromOffset(math.clamp(p.X - textLeft + 8, 0, TW), TH)
                line.Size = UDim2.fromOffset(math.clamp(p.X - textLeft + 20, 0, TW + 90), 2)
                line.Position = UDim2.fromOffset(textLeft - 20, lineY)
            end
            if a >= 1 then break end
            RunService.Heartbeat:Wait()
        end
        if not isCurrent() then return end

        reveal.Size = UDim2.fromOffset(TW, TH)
        line.Size = UDim2.fromOffset(TW + 40, 2)
        for _, d in ipairs(trail) do
            TweenService:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        end
        TweenService:Create(star, TweenInfo.new(0.25), { Size = UDim2.fromOffset(0, 0) }):Play()
        task.wait(1.0)
        if not isCurrent() then return end

        local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(label, fade, { TextTransparency = 1; TextStrokeTransparency = 1 }):Play()
        TweenService:Create(line, fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(dim, fade, { BackgroundTransparency = 1 }):Play()
        task.wait(0.5)
    end

    local function playWindowIntro()
        if not isCurrent() then return end
        local finalPos = MainFrame.Position
        restPos = finalPos
        MainFrame.Visible = true
        uiScale.Scale = WIN_START_SCALE
        MainFrame.GroupTransparency = 1
        MainFrame.Position = UDim2.new(finalPos.X.Scale, finalPos.X.Offset, finalPos.Y.Scale, finalPos.Y.Offset + WIN_RISE)

        local function slideIn(inst, dx, delay, dur)
            local goal = inst.Position
            inst.Position = UDim2.new(goal.X.Scale, goal.X.Offset + dx, goal.Y.Scale, goal.Y.Offset)
            task.delay(delay, function()
                if not isCurrent() or not inst.Parent then return end
                TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = goal }):Play()
            end)
        end

        do
            local goalSize, goalPos = Logo.Size, Logo.Position
            Logo.Size = UDim2.fromOffset(0, 0)
            Logo.Position = UDim2.fromOffset(goalPos.X.Offset + 17, goalPos.Y.Offset + 17)
            task.delay(0.22, function()
                if not isCurrent() or not Logo.Parent then return end
                TweenService:Create(Logo, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = goalSize; Position = goalPos }):Play()
            end)
        end
        for i, t in ipairs(navTabs) do
            slideIn(t.Nav, -28, 0.26 + (i - 1) * 0.07, 0.55)
        end

        local t0 = tick()
        while isCurrent() do
            local a = math.clamp((tick() - t0) / WIN_DUR, 0, 1)
            local e = easeOutQuint(a)
            local sc = WIN_START_SCALE + (1 - WIN_START_SCALE) * e
            uiScale.Scale = sc
            MainFrame.GroupTransparency = 1 - easeOutCubic(math.clamp(a * 1.6, 0, 1))
            MainFrame.Position = UDim2.new(
                finalPos.X.Scale, finalPos.X.Offset + (1 - sc) * W / 2,
                finalPos.Y.Scale, finalPos.Y.Offset + (1 - sc) * H / 2 + (1 - e) * WIN_RISE
            )
            if a >= 1 then break end
            RunService.Heartbeat:Wait()
        end
        if not isCurrent() then return end

        uiScale.Scale = 1
        MainFrame.GroupTransparency = 0
        MainFrame.Position = restPos
        animating = false
        introDone = true
        if cfg.LoadedNotice then
            task.delay(0.25, function()
                Window:Notify(cfg.Title .. " loaded", "Press " .. cfg.ToggleKey.Name .. " to hide / show")
            end)
        end
    end

    applyCur()

    if cfg.Intro then
        MainFrame.Visible = false
        MainFrame.GroupTransparency = 1
        uiScale.Scale = WIN_START_SCALE
        animating = true
        task.spawn(function()
            if cfg.Splash ~= false then
                local holder = { frame = false }
                pcall(playSplash, holder)
                if holder.frame then pcall(function() holder.frame:Destroy() end) end
            end
            if not isCurrent() then return end
            playWindowIntro()
        end)
    else
        introDone = true
    end

    return Window
end

return Onyx

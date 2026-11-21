-- code is by justH0bo and for the game myrestarunt
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local CREDIT_NAME = "JustH0bo"
local SPLASH_TEXT = "H0bo Scripts"

local CONFIG = {
    BakeryName = "justh0bo",
    Containers = { CookContainer = true, WaiterContainer = true, CustomerContainer = true },
    Multiplier = 8,
    MaxWalkSpeed = 150,
    MinMultiplier = 0.1,
    MaxMultiplier = 200,
    ScaleWalkSpeed = true,
    ScaleAnimations = true,
    Enabled = true,
    AutoSeat = false,
    SeatInterval = 0.5,
    MaxGroupsPerTick = 2,
    SkipWaiterClaimed = false,
    FailureCooldown = 5,
    MaxRememberedFailures = 200,
    PanicKey = Enum.KeyCode.V,
}

if getgenv then
    local env = getgenv()
    for _, name in ipairs({ "OnyxUnload", "WrenchBakeryStop", "WrenchSeatSpyStop", "WrenchSpyStop", "WrenchSpy2Stop" }) do
        if type(env[name]) == "function" then
            pcall(env[name])
        end
    end
end

local running = true
local stopped = false
local tracked = {}
local trackedCount = 0
local connections = {}
local gui
local seatedTotal = 0
local lastError = nil
local failedUntil = {}
local failedCount = 0

local function isCurrent() return running end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

-- ═══════════════════════════════════════
-- FEATURE LOGIC (unchanged)
-- ═══════════════════════════════════════
local function resetAnimations(humanoid)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, animationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
            animationTrack:AdjustSpeed(1)
        end
    end
end

local function restoreHumanoid(humanoid, state)
    if humanoid.Parent then
        humanoid.WalkSpeed = state.base
        resetAnimations(humanoid)
    end
    state.written = nil
end

local function trackHumanoid(humanoid)
    if tracked[humanoid] then return end
    tracked[humanoid] = { base = humanoid.WalkSpeed, written = nil }
    trackedCount += 1
end

local function attachContainer(container)
    for _, descendant in ipairs(container:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            trackHumanoid(descendant)
        end
    end
    connect(container.DescendantAdded, function(descendant)
        if descendant:IsA("Humanoid") then
            trackHumanoid(descendant)
        end
    end)
end

local function attachFloor(floor)
    for _, child in ipairs(floor:GetChildren()) do
        if CONFIG.Containers[child.Name] then
            attachContainer(child)
        end
    end
    connect(floor.ChildAdded, function(child)
        if CONFIG.Containers[child.Name] then
            attachContainer(child)
        end
    end)
end

local function attachBakeryFolder(folder)
    for _, child in ipairs(folder:GetChildren()) do
        if child.Name:match("^Floor") then
            attachFloor(child)
        end
    end
    connect(folder.ChildAdded, function(child)
        if child.Name:match("^Floor") then
            attachFloor(child)
        end
    end)
end

local things = workspace:WaitForChild("__THINGS", 10)
local bakeries = things and things:WaitForChild("BAKERIES", 10)
assert(bakeries, "Onyx: workspace.__THINGS.BAKERIES not found")

local bakeryFolder = bakeries:FindFirstChild(CONFIG.BakeryName) or bakeries:FindFirstChild(player.Name)
assert(bakeryFolder, "Onyx: bakery folder not found, check CONFIG.BakeryName")
attachBakeryFolder(bakeryFolder)

local function applyAll()
    for humanoid, state in pairs(tracked) do
        if not humanoid:IsDescendantOf(workspace) then
            tracked[humanoid] = nil
            trackedCount -= 1
        else
            if CONFIG.ScaleWalkSpeed then
                local current = humanoid.WalkSpeed
                if state.written == nil or math.abs(current - state.written) > 1e-3 then
                    state.base = current
                end
                local target = math.max(state.base, math.min(state.base * CONFIG.Multiplier, CONFIG.MaxWalkSpeed))
                state.written = target
                humanoid.WalkSpeed = target
            end
            if CONFIG.ScaleAnimations then
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    for _, animationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                        animationTrack:AdjustSpeed(CONFIG.Multiplier)
                    end
                end
            end
        end
    end
end

local function restoreAll()
    for humanoid, state in pairs(tracked) do
        restoreHumanoid(humanoid, state)
    end
end

connect(RunService.Heartbeat, function()
    if running and CONFIG.Enabled then
        applyAll()
    end
end)

local function loadBakeryModule()
    local node = ReplicatedStorage
    for _, name in ipairs({ "Framework", "Modules", "Client", "8 | Bakery" }) do
        node = node and node:FindFirstChild(name)
    end
    if not node then return nil, "module 8 | Bakery not found" end
    local ok, result = pcall(require, node)
    if not ok or type(result) ~= "table" then return nil, tostring(result) end
    return result, nil
end

local Bakery, bakeryLoadError = loadBakeryModule()
if not Bakery then
    warn("Onyx: auto seat unavailable: " .. tostring(bakeryLoadError))
end

local function getMyBakery()
    local all = Bakery and Bakery.AllBakeries
    if type(all) ~= "table" then return nil end
    for _, candidate in pairs(all) do
        if type(candidate) == "table" and candidate.owner == player then
            return candidate
        end
    end
    return nil
end

local function canSeat(entity, now)
    if type(entity) ~= "table" or type(entity.stateData) ~= "table" then return false end
    if entity.isDeleted or entity.state ~= "WaitingForSeat" or entity.stateData.busyWalking then return false end
    if CONFIG.SkipWaiterClaimed and entity.waiterIsAttendingToInQueue then return false end
    if entity.UID and (failedUntil[entity.UID] or 0) > now then return false end
    return true
end

local function seatGroup(myBakery, entity)
    entity:StopGroupEmoji()
    entity:CleanupGroupInteract()
    myBakery:SeatQueuedCustomerGroup(entity)
    myBakery:UpdateCustomerQueuePositioning()
end

local function seatWaitingGroups()
    local myBakery = getMyBakery()
    if not myBakery or not myBakery.isOpen or type(myBakery.customerQueue) ~= "table" then
        return 0
    end
    local now = os.clock()
    local seated = 0
    for _, group in ipairs(table.clone(myBakery.customerQueue)) do
        if seated >= CONFIG.MaxGroupsPerTick or not (running and CONFIG.AutoSeat) then break end
        local first = type(group) == "table" and group[1] or nil
        if canSeat(first, now) then
            local ok, err = pcall(seatGroup, myBakery, first)
            if ok then
                seated += 1
            else
                lastError = tostring(err)
                if first.UID then
                    if failedCount >= CONFIG.MaxRememberedFailures then
                        table.clear(failedUntil)
                        failedCount = 0
                    end
                    failedUntil[first.UID] = now + CONFIG.FailureCooldown
                    failedCount += 1
                end
            end
        end
    end
    return seated
end

task.spawn(function()
    while running do
        task.wait(CONFIG.SeatInterval)
        if running and CONFIG.AutoSeat and Bakery then
            local ok, result = pcall(seatWaitingGroups)
            if ok then
                seatedTotal += result
            else
                lastError = tostring(result)
            end
        end
    end
end)

local function guiParent()
    if gethui then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui then return coreGui end
    return player:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════
-- COLOURS / THEMES
-- ═══════════════════════════════════════
local WHITE     = Color3.fromRGB(255, 255, 255)
local BLUE      = Color3.fromRGB(59, 130, 246)
local BLUE_DARK = Color3.fromRGB(30,  64, 175)
local CYAN      = Color3.fromRGB(56, 189, 248)
local STS_BG    = Color3.fromRGB(10,  30,  90)

local COL_OK    = Color3.fromRGB(80,  255, 120)
local COL_BAD   = Color3.fromRGB(255,  80,  80)

local THEMES = {
    light = {
        winA = Color3.fromRGB(250, 253, 255); winB = Color3.fromRGB(196, 222, 255); winC = Color3.fromRGB(138, 182, 255);
        sideA = Color3.fromRGB(29, 78, 216);  sideB = Color3.fromRGB(96, 165, 250);
        cardA = Color3.fromRGB(255, 255, 255); cardB = Color3.fromRGB(226, 238, 255); cardT = 0.10;
        line = Color3.fromRGB(196, 216, 248); row = Color3.fromRGB(236, 243, 255);
        ink = Color3.fromRGB(15, 35, 75);     dim = Color3.fromRGB(84, 108, 150);
        swOff = Color3.fromRGB(184, 198, 222);
        input = Color3.fromRGB(255, 255, 255); inputTxt = Color3.fromRGB(30, 64, 175);
        segBg = Color3.fromRGB(212, 226, 250);
        titleA = Color3.fromRGB(30, 64, 175); titleB = Color3.fromRGB(56, 189, 248);
        navOn = Color3.fromRGB(255, 255, 255); navOnTxt = Color3.fromRGB(30, 64, 175);
        winStroke = Color3.fromRGB(255, 255, 255);
        snow = Color3.fromRGB(255, 255, 255); snowStroke = Color3.fromRGB(150, 185, 240); snowStrokeT = 0.3;
        stars = 0; accent = BLUE;
    };
    dark = {
        winA = Color3.fromRGB(30, 46, 86);    winB = Color3.fromRGB(38, 60, 108);  winC = Color3.fromRGB(48, 78, 134);
        sideA = Color3.fromRGB(22, 38, 80);   sideB = Color3.fromRGB(42, 74, 138);
        cardA = Color3.fromRGB(50, 76, 128);  cardB = Color3.fromRGB(40, 64, 110); cardT = 0.04;
        line = Color3.fromRGB(92, 126, 190);  row = Color3.fromRGB(62, 92, 150);
        ink = Color3.fromRGB(242, 247, 255);  dim = Color3.fromRGB(184, 204, 238);
        swOff = Color3.fromRGB(88, 112, 156);
        input = Color3.fromRGB(32, 52, 98);   inputTxt = Color3.fromRGB(176, 216, 255);
        segBg = Color3.fromRGB(32, 52, 98);
        titleA = Color3.fromRGB(140, 190, 255); titleB = Color3.fromRGB(140, 228, 255);
        navOn = Color3.fromRGB(64, 112, 204); navOnTxt = Color3.fromRGB(255, 255, 255);
        winStroke = Color3.fromRGB(96, 140, 214);
        snow = Color3.fromRGB(240, 246, 255); snowStroke = Color3.fromRGB(240, 246, 255); snowStrokeT = 1;
        stars = 1; accent = BLUE;
    };
    winter = {
        winA = Color3.fromRGB(246, 251, 253); winB = Color3.fromRGB(210, 232, 242); winC = Color3.fromRGB(164, 200, 222);
        sideA = Color3.fromRGB(18, 66, 98);   sideB = Color3.fromRGB(56, 128, 168);
        cardA = Color3.fromRGB(255, 255, 255); cardB = Color3.fromRGB(228, 242, 249); cardT = 0.08;
        line = Color3.fromRGB(190, 216, 230); row = Color3.fromRGB(232, 243, 249);
        ink = Color3.fromRGB(14, 40, 58);     dim = Color3.fromRGB(70, 100, 122);
        swOff = Color3.fromRGB(176, 196, 208);
        input = Color3.fromRGB(255, 255, 255); inputTxt = Color3.fromRGB(18, 66, 98);
        segBg = Color3.fromRGB(206, 226, 236);
        titleA = Color3.fromRGB(18, 86, 128); titleB = Color3.fromRGB(40, 150, 190);
        navOn = Color3.fromRGB(255, 255, 255); navOnTxt = Color3.fromRGB(18, 66, 98);
        winStroke = Color3.fromRGB(255, 255, 255);
        snow = Color3.fromRGB(255, 255, 255); snowStroke = Color3.fromRGB(140, 180, 205); snowStrokeT = 0.3;
        stars = 0; accent = Color3.fromRGB(32, 120, 168);
    };
    mono = {
        winA = Color3.fromRGB(30, 30, 32);    winB = Color3.fromRGB(42, 42, 46);   winC = Color3.fromRGB(56, 56, 60);
        sideA = Color3.fromRGB(22, 22, 24);   sideB = Color3.fromRGB(54, 54, 58);
        cardA = Color3.fromRGB(62, 62, 66);   cardB = Color3.fromRGB(48, 48, 52);  cardT = 0.04;
        line = Color3.fromRGB(104, 104, 110); row = Color3.fromRGB(76, 76, 82);
        ink = Color3.fromRGB(250, 250, 250);  dim = Color3.fromRGB(192, 192, 198);
        swOff = Color3.fromRGB(70, 70, 76);
        input = Color3.fromRGB(36, 36, 40);   inputTxt = Color3.fromRGB(240, 240, 240);
        segBg = Color3.fromRGB(36, 36, 40);
        titleA = Color3.fromRGB(255, 255, 255); titleB = Color3.fromRGB(190, 190, 196);
        navOn = Color3.fromRGB(240, 240, 244); navOnTxt = Color3.fromRGB(20, 20, 22);
        winStroke = Color3.fromRGB(140, 140, 146);
        snow = Color3.fromRGB(255, 255, 255); snowStroke = Color3.fromRGB(255, 255, 255); snowStrokeT = 1;
        stars = 1; accent = Color3.fromRGB(118, 118, 126);
    };
    autumn = {
        winA = Color3.fromRGB(255, 248, 238); winB = Color3.fromRGB(252, 224, 190); winC = Color3.fromRGB(236, 178, 122);
        sideA = Color3.fromRGB(110, 38, 16);  sideB = Color3.fromRGB(186, 84, 28);
        cardA = Color3.fromRGB(255, 252, 246); cardB = Color3.fromRGB(253, 236, 214); cardT = 0.08;
        line = Color3.fromRGB(232, 200, 164); row = Color3.fromRGB(252, 240, 224);
        ink = Color3.fromRGB(62, 28, 12);     dim = Color3.fromRGB(124, 84, 54);
        swOff = Color3.fromRGB(214, 190, 164);
        input = Color3.fromRGB(255, 255, 255); inputTxt = Color3.fromRGB(140, 56, 16);
        segBg = Color3.fromRGB(246, 222, 192);
        titleA = Color3.fromRGB(160, 58, 14); titleB = Color3.fromRGB(214, 118, 24);
        navOn = Color3.fromRGB(255, 250, 242); navOnTxt = Color3.fromRGB(120, 44, 14);
        winStroke = Color3.fromRGB(255, 236, 208);
        snow = Color3.fromRGB(232, 128, 36);  snowStroke = Color3.fromRGB(150, 64, 16); snowStrokeT = 0.55;
        stars = 0; accent = Color3.fromRGB(190, 84, 24);
    };
    sakura = {
        winA = Color3.fromRGB(255, 248, 251); winB = Color3.fromRGB(254, 226, 238); winC = Color3.fromRGB(248, 190, 214);
        sideA = Color3.fromRGB(158, 38, 92);  sideB = Color3.fromRGB(212, 82, 134);
        cardA = Color3.fromRGB(255, 255, 255); cardB = Color3.fromRGB(254, 234, 243); cardT = 0.08;
        line = Color3.fromRGB(244, 200, 220); row = Color3.fromRGB(254, 238, 246);
        ink = Color3.fromRGB(72, 20, 48);     dim = Color3.fromRGB(138, 78, 108);
        swOff = Color3.fromRGB(224, 196, 210);
        input = Color3.fromRGB(255, 255, 255); inputTxt = Color3.fromRGB(150, 34, 88);
        segBg = Color3.fromRGB(250, 216, 230);
        titleA = Color3.fromRGB(176, 36, 100); titleB = Color3.fromRGB(232, 96, 150);
        navOn = Color3.fromRGB(255, 255, 255); navOnTxt = Color3.fromRGB(150, 34, 88);
        winStroke = Color3.fromRGB(255, 255, 255);
        snow = Color3.fromRGB(255, 196, 218); snowStroke = Color3.fromRGB(226, 110, 155); snowStrokeT = 0.3;
        stars = 0; accent = Color3.fromRGB(198, 58, 118);
    };
    forest = {
        winA = Color3.fromRGB(20, 52, 42);    winB = Color3.fromRGB(28, 68, 54);   winC = Color3.fromRGB(38, 88, 68);
        sideA = Color3.fromRGB(16, 48, 38);   sideB = Color3.fromRGB(34, 110, 78);
        cardA = Color3.fromRGB(40, 92, 72);   cardB = Color3.fromRGB(30, 76, 58);  cardT = 0.04;
        line = Color3.fromRGB(70, 138, 108);  row = Color3.fromRGB(50, 108, 84);
        ink = Color3.fromRGB(236, 252, 244);  dim = Color3.fromRGB(172, 214, 194);
        swOff = Color3.fromRGB(84, 124, 106);
        input = Color3.fromRGB(24, 64, 50);   inputTxt = Color3.fromRGB(176, 246, 208);
        segBg = Color3.fromRGB(24, 64, 50);
        titleA = Color3.fromRGB(130, 236, 176); titleB = Color3.fromRGB(200, 252, 140);
        navOn = Color3.fromRGB(46, 140, 100); navOnTxt = Color3.fromRGB(255, 255, 255);
        winStroke = Color3.fromRGB(84, 160, 124);
        snow = Color3.fromRGB(210, 255, 180); snowStroke = Color3.fromRGB(210, 255, 180); snowStrokeT = 1;
        stars = 1; accent = Color3.fromRGB(46, 160, 108);
    };
}

local cur = {}
for k, v in pairs(THEMES.winter) do cur[k] = v end

-- ═══════════════════════════════════════
-- LAYOUT CONSTANTS
-- ═══════════════════════════════════════
local W      = 580
local H      = 380
local SIDE   = 150
local TOP    = 44
local RAD    = 14
local CARD_W = 195

local minimized = false
local uiToggleKey = Enum.KeyCode.RightAlt

-- ═══════════════════════════════════════
-- UI BUILDERS
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
    s.Color           = col
    s.Thickness       = th or 1
    s.Transparency    = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = inst
    return s
end

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
    g.Color    = seqOf(tokens)
    g.Parent   = inst
    table.insert(gradBindings, { g, tokens })
    return g
end

local function applyCur()
    for _, b in ipairs(bindings) do b[1][b[2]] = cur[b[3]] end
    for _, g in ipairs(gradBindings) do g[1].Color = seqOf(g[2]) end
    for _, r in ipairs(refreshers) do r() end
end

local function lerpVal(a, b, t)
    if typeof(a) == "Color3" then return a:Lerp(b, t) end
    return a + (b - a) * t
end

local themeGen = 0
local function setTheme(name)
    themeGen += 1
    local gen  = themeGen
    local from = {}
    for k, v in pairs(cur) do from[k] = v end
    local to = THEMES[name]
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
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
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

-- ── snowfall + stars ───────────────────
local flakes, starList = {}, {}

local function makeSky(parent, x, y, w, h, nSnow, nStars)
    local layer = make("Frame", {
        Name = "Sky";
        Position = UDim2.fromOffset(x, y);
        Size = UDim2.fromOffset(w, h);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
    }, parent)

    for _ = 1, nStars do
        local sz = math.random(1, 2)
        local s = make("Frame", {
            Size = UDim2.fromOffset(sz, sz);
            Position = UDim2.fromOffset(math.random() * w, math.random() * h * 0.85);
            BackgroundColor3 = WHITE;
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
        }, layer)
        corner(s, 2)
        table.insert(starList, { inst = s, phase = math.random() * 6.28, speed = 0.8 + math.random() * 1.8 })
    end

    for _ = 1, nSnow do
        local sz = math.random(2, 4)
        local f = make("Frame", {
            Size = UDim2.fromOffset(sz, sz);
            BackgroundTransparency = 0.1 + math.random() * 0.3;
            BorderSizePixel = 0;
        }, layer)
        corner(f, sz)
        bind(f, "BackgroundColor3", "snow")
        local st = stroke(f, cur.snowStroke, 1, cur.snowStrokeT)
        bind(st, "Color", "snowStroke")
        bind(st, "Transparency", "snowStrokeT")
        table.insert(flakes, {
            inst = f; size = sz; w = w; h = h;
            x = math.random() * w; y = math.random() * h;
            vy = 14 + sz * 7 + math.random() * 8;
            amp = 4 + math.random() * 10;
            freq = 0.6 + math.random() * 1.2;
            phase = math.random() * 6.28;
        })
    end
    return layer
end

-- ═══════════════════════════════════════
-- SCREEN GUI + MAIN FRAME
-- ═══════════════════════════════════════
local ScreenGui = make("ScreenGui", {
    Name = "OnyxGui";
    ResetOnSpawn = false;
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    IgnoreGuiInset = true;
}, guiParent())
gui = ScreenGui

local MainFrame = make("CanvasGroup", {
    Name = "Window";
    Size = UDim2.fromOffset(W, H);
    Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2);
    BackgroundColor3 = WHITE;
    BackgroundTransparency = 1;
    BorderSizePixel = 0;
    Active = true;
}, ScreenGui)
corner(MainFrame, RAD)

local WinBg = make("Frame", {
    Name = "Bg"; Size = UDim2.fromScale(1, 1); BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, MainFrame)
themedGradient(WinBg, { "winA", "winB", "winC" }, 125)

local winStroke = stroke(MainFrame, cur.winStroke, 1.5, 0.2)
bind(winStroke, "Color", "winStroke")

local uiScale = Instance.new("UIScale")
uiScale.Scale  = 1
uiScale.Parent = MainFrame

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

-- ═══════════════════════════════════════
-- SIDEBAR
-- ═══════════════════════════════════════
local Side = make("Frame", {
    Name = "Sidebar"; Size = UDim2.new(0, SIDE, 1, 0); BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, MainFrame)
corner(Side, RAD)
themedGradient(Side, { "sideA", "sideB" }, 90)

local SideFill = make("Frame", {
    Size = UDim2.new(0, RAD, 1, 0); Position = UDim2.new(1, -RAD, 0, 0);
    BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, Side)
themedGradient(SideFill, { "sideA", "sideB" }, 90)

makeSky(Side, 6, 6, SIDE - 6, H - 12, 12, 14)

local Logo = make("Frame", {
    Size = UDim2.fromOffset(34, 34); Position = UDim2.fromOffset(14, 14);
    BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, Side)
corner(Logo, 17)
make("TextLabel", {
    Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = "O";
    TextColor3 = BLUE_DARK; Font = Enum.Font.GothamBlack; TextSize = 20;
}, Logo)

make("TextLabel", {
    Size = UDim2.fromOffset(88, 18); Position = UDim2.fromOffset(56, 14);
    BackgroundTransparency = 1; Text = "Onyx Hub"; TextColor3 = WHITE;
    Font = Enum.Font.GothamBold; TextSize = 15; TextXAlignment = Enum.TextXAlignment.Left;
    TextTruncate = Enum.TextTruncate.AtEnd;
}, Side)
make("TextLabel", {
    Size = UDim2.fromOffset(88, 14); Position = UDim2.fromOffset(56, 31);
    BackgroundTransparency = 1; Text = "v7  ·  by JustH0bo"; TextColor3 = Color3.fromRGB(214, 230, 255);
    Font = Enum.Font.Gotham; TextSize = 10; TextXAlignment = Enum.TextXAlignment.Left;
}, Side)

make("TextLabel", {
    Size = UDim2.fromOffset(SIDE - 24, 14); Position = UDim2.fromOffset(14, 74);
    BackgroundTransparency = 1; Text = "MENU"; TextColor3 = Color3.fromRGB(200, 222, 255);
    Font = Enum.Font.GothamBold; TextSize = 10; TextXAlignment = Enum.TextXAlignment.Left;
}, Side)

local UserCard = make("Frame", {
    Size = UDim2.fromOffset(SIDE - 20, 76); Position = UDim2.new(0, 10, 1, -88);
    BackgroundColor3 = STS_BG; BackgroundTransparency = 0.7; BorderSizePixel = 0;
}, Side)
corner(UserCard, 10)
stroke(UserCard, WHITE, 1, 0.75)

make("TextLabel", {
    Size = UDim2.fromOffset(SIDE - 40, 16); Position = UDim2.fromOffset(10, 8);
    BackgroundTransparency = 1; Text = player.DisplayName; TextColor3 = WHITE;
    Font = Enum.Font.GothamBold; TextSize = 12; TextXAlignment = Enum.TextXAlignment.Left;
    TextTruncate = Enum.TextTruncate.AtEnd;
}, UserCard)

local StsBar = make("Frame", {
    Size = UDim2.fromOffset(SIDE - 36, 30); Position = UDim2.fromOffset(8, 38);
    BackgroundColor3 = STS_BG; BackgroundTransparency = 0.25; BorderSizePixel = 0;
}, UserCard)
corner(StsBar, 8)

local stsTxt = make("TextLabel", {
    Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = "RUNNING";
    TextColor3 = COL_OK; Font = Enum.Font.GothamBold; TextSize = 11;
    TextXAlignment = Enum.TextXAlignment.Center;
}, StsBar)

-- ═══════════════════════════════════════
-- TOP BAR
-- ═══════════════════════════════════════
local TopBar = make("Frame", {
    Name = "TopBar"; Size = UDim2.new(1, -SIDE, 0, TOP); Position = UDim2.fromOffset(SIDE, 0);
    BackgroundTransparency = 1; BorderSizePixel = 0;
}, MainFrame)

local PageTitle = make("TextLabel", {
    Size = UDim2.new(1, -150, 1, 0); Position = UDim2.fromOffset(18, 0);
    BackgroundTransparency = 1; Text = "Main"; Font = Enum.Font.GothamBold; TextSize = 16;
    TextXAlignment = Enum.TextXAlignment.Left;
}, TopBar)
bind(PageTitle, "TextColor3", "ink")

local TopLine = make("Frame", {
    Size = UDim2.new(1, -28, 0, 1); Position = UDim2.new(0, 14, 1, -1); BorderSizePixel = 0;
}, TopBar)
bind(TopLine, "BackgroundColor3", "line")

local MinBtn = make("TextButton", {
    Size = UDim2.fromOffset(14, 14); Position = UDim2.new(1, -52, 0.5, -7);
    BackgroundColor3 = Color3.fromRGB(60, 180, 60); BorderSizePixel = 0; Text = ""; AutoButtonColor = false;
}, TopBar)
corner(MinBtn, 7)

local CloseBtn = make("TextButton", {
    Size = UDim2.fromOffset(14, 14); Position = UDim2.new(1, -30, 0.5, -7);
    BackgroundColor3 = Color3.fromRGB(255, 90, 80); BorderSizePixel = 0; Text = ""; AutoButtonColor = false;
}, TopBar)
corner(CloseBtn, 7)

local isDark = false
local ThemeState = { last = "winter" }
local ThemePill = make("TextButton", {
    Size = UDim2.fromOffset(72, 22); Position = UDim2.new(1, -134, 0.5, -11);
    BackgroundColor3 = WHITE; BorderSizePixel = 0; Text = ""; AutoButtonColor = false;
}, TopBar)
corner(ThemePill, 11)
bind(ThemePill, "BackgroundColor3", "row")

local pillLbl = make("TextLabel", {
    Size = UDim2.fromOffset(36, 22); Position = UDim2.fromOffset(10, 0);
    BackgroundTransparency = 1; Text = "Dark"; Font = Enum.Font.GothamBold; TextSize = 11;
    TextXAlignment = Enum.TextXAlignment.Left;
}, ThemePill)
bind(pillLbl, "TextColor3", "ink")

local pTrack = make("Frame", {
    Size = UDim2.fromOffset(24, 14); Position = UDim2.new(1, -30, 0.5, -7);
    BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, ThemePill)
corner(pTrack, 7)
local pKnob = make("Frame", {
    Size = UDim2.fromOffset(10, 10); Position = UDim2.fromOffset(2, 2);
    BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, pTrack)
corner(pKnob, 5)

table.insert(refreshers, function()
    pTrack.BackgroundColor3 = isDark and cur.accent or cur.swOff
end)

connect(ThemePill.MouseButton1Click, function()
    isDark = not isDark
    TweenService:Create(pKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Position = isDark and UDim2.fromOffset(12, 2) or UDim2.fromOffset(2, 2)
    }):Play()
    setTheme(isDark and "dark" or ThemeState.last)
end)

connect(MinBtn.MouseButton1Click, function()
    minimized = not minimized
    ThemePill.Visible = not minimized
    local target = minimized and UDim2.fromOffset(270, TOP) or UDim2.fromOffset(W, H)
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = target }):Play()
end)

makeDraggable(TopBar, MainFrame)
makeDraggable(Side, MainFrame)

-- ═══════════════════════════════════════
-- PAGES (Main, Settings, Credits)
-- ═══════════════════════════════════════
local Pages = make("Frame", {
    Size = UDim2.new(1, -SIDE, 1, -TOP); Position = UDim2.fromOffset(SIDE, TOP);
    BackgroundTransparency = 1; BorderSizePixel = 0;
}, MainFrame)

local mainPage = make("Frame", {
    Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; BorderSizePixel = 0;
}, Pages)
local settingsPage = make("Frame", {
    Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; BorderSizePixel = 0; Visible = false;
}, Pages)
local credPage = make("Frame", {
    Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; BorderSizePixel = 0; Visible = false;
}, Pages)

local function cardFrame(parent, x, y, w, h)
    local card = make("Frame", {
        Size = UDim2.fromOffset(w, h); Position = UDim2.fromOffset(x, y);
        BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, parent)
    corner(card, 12)
    bind(card, "BackgroundTransparency", "cardT")
    themedGradient(card, { "cardA", "cardB" }, 90)
    local st = stroke(card, cur.line, 1)
    bind(st, "Color", "line")
    return card
end

local function makeCard(parent, x, y, w, h, title, sub)
    local card = cardFrame(parent, x, y, w, h)

    local t = make("TextLabel", {
        Size = UDim2.fromOffset(w - 24, 18); Position = UDim2.fromOffset(12, 10);
        BackgroundTransparency = 1; Text = title; TextColor3 = WHITE;
        Font = Enum.Font.GothamBold; TextSize = 14; TextXAlignment = Enum.TextXAlignment.Left;
    }, card)
    themedGradient(t, { "titleA", "titleB" }, 0)

    local s = make("TextLabel", {
        Size = UDim2.fromOffset(w - 24, 14); Position = UDim2.fromOffset(12, 28);
        BackgroundTransparency = 1; Text = sub; Font = Enum.Font.Gotham; TextSize = 10;
        TextXAlignment = Enum.TextXAlignment.Left;
    }, card)
    bind(s, "TextColor3", "dim")

    local body = make("Frame", {
        Size = UDim2.fromOffset(w - 20, h - 60); Position = UDim2.fromOffset(10, 50);
        BackgroundTransparency = 1; BorderSizePixel = 0;
    }, card)
    local lay = Instance.new("UIListLayout")
    lay.Padding   = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent    = body
    return card, body
end

local function makeRow(body, order)
    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 30); BorderSizePixel = 0; LayoutOrder = order;
    }, body)
    corner(row, 8)
    bind(row, "BackgroundColor3", "row")
    return row
end

local function makeRowLabel(row, text, widthMinus)
    local l = make("TextLabel", {
        Size = UDim2.new(1, -widthMinus, 1, 0); Position = UDim2.fromOffset(10, 0);
        BackgroundTransparency = 1; Text = text; Font = Enum.Font.GothamMedium; TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Left; TextTruncate = Enum.TextTruncate.AtEnd;
    }, row)
    bind(l, "TextColor3", "ink")
    return l
end

-- toggle row bound to a CONFIG boolean; availableFn (optional) greys it out when false
local syncers = {}
local function makeToggle(body, order, label, key, onChange, availableFn)
    local row = makeRow(body, order)
    makeRowLabel(row, label, 60)

    local track = make("Frame", {
        Size = UDim2.fromOffset(34, 18); Position = UDim2.new(1, -44, 0.5, -9);
        BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, row)
    corner(track, 9)
    local knob = make("Frame", {
        Size = UDim2.fromOffset(14, 14); Position = UDim2.fromOffset(2, 2);
        BackgroundColor3 = WHITE; BorderSizePixel = 0;
    }, track)
    corner(knob, 7)

    local function isOn()
        local available = (not availableFn) or availableFn()
        return available and CONFIG[key]
    end
    local function recolor()
        track.BackgroundColor3 = isOn() and cur.accent or cur.swOff
    end
    local function sync(animate)
        recolor()
        local goal = isOn() and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
        if animate then
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Position = goal }):Play()
        else
            knob.Position = goal
        end
    end
    sync(false)
    table.insert(refreshers, recolor)
    table.insert(syncers, sync)

    local btn = make("TextButton", {
        Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = "";
    }, row)
    connect(btn.MouseButton1Click, function()
        if availableFn and not availableFn() then return end
        CONFIG[key] = not CONFIG[key]
        if onChange then onChange(CONFIG[key]) end
        sync(true)
    end)
end

-- ═══════════════════════════════════════
-- MAIN PAGE
-- ═══════════════════════════════════════
local seatAvailable = function() return Bakery ~= nil end
local multiplierBox

local function refreshGui()
    for _, s in ipairs(syncers) do s(true) end
    if multiplierBox then multiplierBox.Text = tostring(CONFIG.Multiplier) end
end

local modCard, modBody = makeCard(mainPage, 14, 14, CARD_W, 160, "Modules", "Enable or disable features")
makeToggle(modBody, 1, "Speed", "Enabled", function(on)
    stopped = false
    if not on then restoreAll() end
end)
makeToggle(modBody, 2, "Animations", "ScaleAnimations", function(on)
    if not on then
        for humanoid in pairs(tracked) do
            resetAnimations(humanoid)
        end
    end
end)
makeToggle(modBody, 3, Bakery and "Auto Seat" or "Auto Seat (n/a)", "AutoSeat", function()
    stopped = false
    lastError = nil
end, seatAvailable)

local tuneCard, tuneBody = makeCard(mainPage, 14 + CARD_W + 12, 14, CARD_W, 160, "Tuning", "Speed and animation scale")
do
    local row = makeRow(tuneBody, 1)
    makeRowLabel(row, "Multiplier", 76)
    multiplierBox = make("TextBox", {
        Size = UDim2.fromOffset(60, 22); Position = UDim2.new(1, -68, 0.5, -11);
        BorderSizePixel = 0; Text = tostring(CONFIG.Multiplier); Font = Enum.Font.GothamBold;
        TextSize = 12; TextXAlignment = Enum.TextXAlignment.Center; ClearTextOnFocus = false;
    }, row)
    corner(multiplierBox, 6)
    bind(multiplierBox, "BackgroundColor3", "input")
    bind(multiplierBox, "TextColor3", "inputTxt")
    local st = stroke(multiplierBox, cur.line, 1)
    bind(st, "Color", "line")
    connect(multiplierBox.Focused, function() st.Color = BLUE end)
    connect(multiplierBox.FocusLost, function()
        st.Color = cur.line
        local value = tonumber(multiplierBox.Text)
        if value and value == value then
            CONFIG.Multiplier = math.clamp(value, CONFIG.MinMultiplier, CONFIG.MaxMultiplier)
        end
        refreshGui()
    end)
end

local statusCard, statusBody = makeCard(mainPage, 14, 14 + 160 + 12, CARD_W * 2 + 12, 136, "Status", "Live bakery readout")
local statusLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 44); BackgroundTransparency = 1; Text = "";
    Font = Enum.Font.GothamMedium; TextSize = 12; TextWrapped = true;
    TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Top;
    LayoutOrder = 1;
}, statusBody)
bind(statusLabel, "TextColor3", "ink")
local hintLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28); BackgroundTransparency = 1;
    Text = CONFIG.PanicKey.Name .. " = stop everything and restore NPC speed";
    Font = Enum.Font.Gotham; TextSize = 10; TextWrapped = true;
    TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Top;
    LayoutOrder = 2;
}, statusBody)
bind(hintLabel, "TextColor3", "dim")

-- ═══════════════════════════════════════
-- TOAST
-- ═══════════════════════════════════════
local TOAST_HIDDEN = UDim2.new(0.5, 0, 0, -64)
local TOAST_SHOWN  = UDim2.new(0.5, 0, 0, 18)

local Toast = make("Frame", {
    Name = "Toast"; AnchorPoint = Vector2.new(0.5, 0); Size = UDim2.fromOffset(260, 44);
    Position = TOAST_HIDDEN; BackgroundColor3 = WHITE; BackgroundTransparency = 0.04; BorderSizePixel = 0;
}, ScreenGui)
corner(Toast, 12)
themedGradient(Toast, { "cardA", "cardB" }, 90)
local toastStroke = stroke(Toast, cur.line, 1)
bind(toastStroke, "Color", "line")

local toastBar = make("Frame", {
    Size = UDim2.fromOffset(4, 24); Position = UDim2.fromOffset(10, 10);
    BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, Toast)
corner(toastBar, 2)
do
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(BLUE_DARK, CYAN)
    g.Rotation = 90
    g.Parent = toastBar
end

local toastTitle = make("TextLabel", {
    Size = UDim2.fromOffset(224, 16); Position = UDim2.fromOffset(24, 6);
    BackgroundTransparency = 1; Text = ""; Font = Enum.Font.GothamBold; TextSize = 12;
    TextXAlignment = Enum.TextXAlignment.Left;
}, Toast)
bind(toastTitle, "TextColor3", "ink")

local toastBody = make("TextLabel", {
    Size = UDim2.fromOffset(224, 14); Position = UDim2.fromOffset(24, 23);
    BackgroundTransparency = 1; Text = ""; Font = Enum.Font.Gotham; TextSize = 11;
    TextXAlignment = Enum.TextXAlignment.Left;
}, Toast)
bind(toastBody, "TextColor3", "dim")

local toastGen = 0
local function notify(title, body)
    toastGen += 1
    local gen = toastGen
    toastTitle.Text = title
    toastBody.Text  = body
    TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = TOAST_SHOWN }):Play()
    task.delay(2, function()
        if gen ~= toastGen or not isCurrent() then return end
        TweenService:Create(Toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = TOAST_HIDDEN }):Play()
    end)
end

-- ═══════════════════════════════════════
-- PANIC / UNLOAD
-- ═══════════════════════════════════════
local function panic()
    CONFIG.Enabled = false
    CONFIG.AutoSeat = false
    restoreAll()
    stopped = true
    refreshGui()
    notify("Stopped", "Speed and Auto Seat are off")
end

local function unload()
    if not running then return end
    running = false
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
    restoreAll()
    table.clear(tracked)
    trackedCount = 0
    if gui then
        gui:Destroy()
        gui = nil
    end
    if getgenv then
        getgenv().OnyxUnload = nil
    end
end

connect(CloseBtn.MouseButton1Click, unload)

-- ═══════════════════════════════════════
-- SETTINGS PAGE
-- ═══════════════════════════════════════
local SET_W = W - SIDE - 28
local SET_H = 110
local _, setBody = makeCard(settingsPage, 14, 14, SET_W, SET_H, "Settings", "Hide key and session controls")

local keyRow = makeRow(setBody, 1)
makeRowLabel(keyRow, "Hide / Show Key", 130)

local listening = false
local keyBtn = make("TextButton", {
    Size = UDim2.fromOffset(110, 22); Position = UDim2.new(1, -118, 0.5, -11);
    BorderSizePixel = 0; Text = ""; Font = Enum.Font.GothamBold; TextSize = 12; AutoButtonColor = false;
}, keyRow)
corner(keyBtn, 6)
bind(keyBtn, "BackgroundColor3", "input")
bind(keyBtn, "TextColor3", "inputTxt")
local keyStroke = stroke(keyBtn, cur.line, 1)
bind(keyStroke, "Color", "line")

local function paintKey()
    keyBtn.Text     = listening and "Press a key..." or uiToggleKey.Name
    keyStroke.Color = listening and BLUE or cur.line
end
paintKey()
table.insert(refreshers, paintKey)

connect(keyBtn.MouseButton1Click, function()
    listening = true
    paintKey()
end)

local unloadBtn = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 30); BackgroundColor3 = Color3.fromRGB(255, 90, 80);
    BorderSizePixel = 0; Text = "Unload Onyx"; TextColor3 = WHITE;
    Font = Enum.Font.GothamBold; TextSize = 12; AutoButtonColor = false; LayoutOrder = 2;
}, setBody)
corner(unloadBtn, 8)

local armed = false
connect(unloadBtn.MouseButton1Click, function()
    if armed then
        unload()
        return
    end
    armed = true
    unloadBtn.Text = "Click again to confirm"
    task.delay(3, function()
        if armed and isCurrent() then
            armed = false
            unloadBtn.Text = "Unload Onyx"
        end
    end)
end)

local keyHint = make("TextLabel", {
    Size = UDim2.fromOffset(SET_W, 14); Position = UDim2.fromOffset(14, 14 + SET_H + 6);
    BackgroundTransparency = 1; Text = "Click the key box, then press any key  ·  Esc cancels";
    Font = Enum.Font.Gotham; TextSize = 10; TextXAlignment = Enum.TextXAlignment.Left;
}, settingsPage)
bind(keyHint, "TextColor3", "dim")

-- hotkeys: key rebind capture, panic key, hide / show key
connect(UserInputService.InputBegan, function(input)
    if not isCurrent() then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if listening then
        listening = false
        if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then
            uiToggleKey = input.KeyCode
        end
        paintKey()
        return
    end

    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == CONFIG.PanicKey then
        panic()
    elseif input.KeyCode == uiToggleKey then
        if introDone then setShown(not shown) end
    end
end)

-- theme picker
do
    local T = { chips = {}; current = "winter" }
    local ORDER = {
        { "winter", "Winter" }; { "light", "Light" }; { "dark", "Dark" };
        { "mono", "Black & White" }; { "autumn", "Autumn" }; { "sakura", "Sakura" }; { "forest", "Forest" };
    }

    local _, body = makeCard(settingsPage, 14, 14 + SET_H + 6 + 22, SET_W, 114, "Themes", "Pick a look  ·  text stays readable on every one")

    local scroll = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0); BackgroundTransparency = 1; BorderSizePixel = 0;
        ScrollBarThickness = 3; CanvasSize = UDim2.new(); AutomaticCanvasSize = Enum.AutomaticSize.X;
        ScrollingDirection = Enum.ScrollingDirection.X;
    }, body)
    bind(scroll, "ScrollBarImageColor3", "accent")

    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.Padding       = UDim.new(0, 8)
    lay.SortOrder     = Enum.SortOrder.LayoutOrder
    lay.Parent        = scroll

    local function paint()
        for key, c in pairs(T.chips) do
            local on = (key == T.current)
            c.st.Color     = on and cur.accent or cur.line
            c.st.Thickness = on and 2 or 1
            c.lbl.Font     = on and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end
    end
    table.insert(refreshers, paint)

    for i, d in ipairs(ORDER) do
        local key, name = d[1], d[2]
        local th = THEMES[key]

        local chip = make("TextButton", {
            Size = UDim2.fromOffset(84, 42); BackgroundTransparency = 1; Text = "";
            AutoButtonColor = false; LayoutOrder = i;
        }, scroll)

        local prev = make("CanvasGroup", {
            Size = UDim2.new(1, 0, 0, 28); BackgroundColor3 = WHITE; BackgroundTransparency = 1; BorderSizePixel = 0;
        }, chip)
        corner(prev, 8)

        local pbg = make("Frame", {
            Size = UDim2.fromScale(1, 1); BackgroundColor3 = WHITE; BorderSizePixel = 0;
        }, prev)
        do
            local g = Instance.new("UIGradient")
            g.Rotation = 125
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, th.winA);
                ColorSequenceKeypoint.new(0.5, th.winB);
                ColorSequenceKeypoint.new(1, th.winC);
            })
            g.Parent = pbg
        end

        local strip = make("Frame", {
            Size = UDim2.fromOffset(20, 28); BackgroundColor3 = WHITE; BorderSizePixel = 0;
        }, prev)
        do
            local g = Instance.new("UIGradient")
            g.Rotation = 90
            g.Color = ColorSequence.new(th.sideA, th.sideB)
            g.Parent = strip
        end

        local mini = make("Frame", {
            Size = UDim2.fromOffset(38, 14); Position = UDim2.fromOffset(26, 7);
            BackgroundColor3 = th.cardA; BorderSizePixel = 0;
        }, prev)
        corner(mini, 4)

        local dot = make("Frame", {
            Size = UDim2.fromOffset(10, 10); Position = UDim2.fromOffset(68, 9);
            BackgroundColor3 = th.accent; BorderSizePixel = 0;
        }, prev)
        corner(dot, 5)

        local st = stroke(prev, cur.line, 1)

        local lbl = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 12); Position = UDim2.fromOffset(0, 30);
            BackgroundTransparency = 1; Text = name; Font = Enum.Font.GothamMedium; TextSize = 10;
            TextTruncate = Enum.TextTruncate.AtEnd;
        }, chip)
        bind(lbl, "TextColor3", "ink")

        T.chips[key] = { st = st; lbl = lbl }

        connect(chip.MouseButton1Click, function()
            T.current = key
            isDark    = (key == "dark")
            if key ~= "dark" then ThemeState.last = key end
            TweenService:Create(pKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Position = isDark and UDim2.fromOffset(12, 2) or UDim2.fromOffset(2, 2)
            }):Play()
            setTheme(key)
            paint()
        end)
    end

    connect(ThemePill.MouseButton1Click, function()
        task.defer(function()
            T.current = isDark and "dark" or ThemeState.last
            paint()
        end)
    end)

    paint()
end

-- ═══════════════════════════════════════
-- CREDITS PAGE
-- ═══════════════════════════════════════
local credCard = cardFrame(credPage, (W - SIDE) / 2 - 150, 40, 300, 214)

local credLogo = make("Frame", {
    Size = UDim2.fromOffset(56, 56); Position = UDim2.new(0.5, -28, 0, 22);
    BackgroundColor3 = WHITE; BorderSizePixel = 0;
}, credCard)
corner(credLogo, 28)
do
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(BLUE_DARK, CYAN)
    g.Rotation = 135
    g.Parent = credLogo
end
make("TextLabel", {
    Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1; Text = "O"; TextColor3 = WHITE;
    Font = Enum.Font.GothamBlack; TextSize = 28;
}, credLogo)

local credTitle = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24); Position = UDim2.fromOffset(0, 86); BackgroundTransparency = 1;
    Text = "Onyx Hub"; Font = Enum.Font.GothamBold; TextSize = 20;
}, credCard)
bind(credTitle, "TextColor3", "ink")

local credLine = make("Frame", {
    Size = UDim2.fromOffset(220, 1); Position = UDim2.new(0.5, -110, 0, 122); BorderSizePixel = 0;
}, credCard)
bind(credLine, "BackgroundColor3", "line")

local credBy = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14); Position = UDim2.fromOffset(0, 134); BackgroundTransparency = 1;
    Text = "CREDITS BY"; Font = Enum.Font.GothamBold; TextSize = 10;
}, credCard)
bind(credBy, "TextColor3", "dim")

local credName = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30); Position = UDim2.fromOffset(0, 150); BackgroundTransparency = 1;
    Text = CREDIT_NAME; TextColor3 = WHITE; Font = Enum.Font.GothamBold; TextSize = 24;
}, credCard)
themedGradient(credName, { "titleA", "titleB" }, 0)

local credVer = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14); Position = UDim2.fromOffset(0, 186); BackgroundTransparency = 1;
    Text = "Onyx v7"; Font = Enum.Font.Gotham; TextSize = 11;
}, credCard)
bind(credVer, "TextColor3", "dim")

-- ═══════════════════════════════════════
-- SIDEBAR NAV
-- ═══════════════════════════════════════
local pages     = { Main = mainPage; Settings = settingsPage; Credits = credPage }
local navOrder  = { "Main", "Settings", "Credits" }
local navBtns   = {}
local activeTab = "Main"

local function paintNav(animate)
    for n, b in pairs(navBtns) do
        local on    = (n == activeTab)
        local goalT = on and 0 or 1
        local goalC = on and cur.navOnTxt or WHITE
        b.BackgroundColor3 = cur.navOn
        if animate then
            TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = goalT; TextColor3 = goalC }):Play()
        else
            b.BackgroundTransparency = goalT
            b.TextColor3 = goalC
        end
    end
end

local function selectTab(name)
    activeTab = name
    for n, p in pairs(pages) do p.Visible = (n == name) end
    paintNav(true)
    PageTitle.Text = name
end

for i, name in ipairs(navOrder) do
    local b = make("TextButton", {
        Size = UDim2.fromOffset(SIDE - 24, 34); Position = UDim2.fromOffset(12, 94 + (i - 1) * 40);
        BackgroundColor3 = WHITE; BackgroundTransparency = 1; BorderSizePixel = 0;
        Text = name; TextColor3 = WHITE; Font = Enum.Font.GothamBold; TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Left; AutoButtonColor = false;
    }, Side)
    corner(b, 10)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 14)
    pad.Parent = b
    connect(b.MouseButton1Click, function() selectTab(name) end)
    navBtns[name] = b
end
table.insert(refreshers, function() paintNav(false) end)
paintNav(false)

-- ═══════════════════════════════════════
-- SKY ANIMATION (30 updates per second, only while visible)
-- ═══════════════════════════════════════
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
-- OPENING SEQUENCE (splash star + window intro)
-- ═══════════════════════════════════════
local function easeOutQuint(a) return 1 - (1 - a) ^ 5 end
local function easeOutCubic(a) return 1 - (1 - a) ^ 3 end

local WIN_START_SCALE, WIN_RISE, WIN_DUR = 0.84, 26, 0.75

MainFrame.Visible = false
MainFrame.GroupTransparency = 1
uiScale.Scale = WIN_START_SCALE
animating = true

local function playSplash(holder)
    local vs = ScreenGui.AbsoluteSize
    if vs.X < 100 or vs.Y < 100 then
        local cam = workspace.CurrentCamera
        vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
    end
    local sw, sh = vs.X, vs.Y

    local dim = make("Frame", {
        Name = "Splash"; Size = UDim2.fromScale(1, 1); BackgroundColor3 = Color3.fromRGB(6, 10, 24);
        BackgroundTransparency = 1; BorderSizePixel = 0; ZIndex = 50;
    }, ScreenGui)
    holder.frame = dim
    TweenService:Create(dim, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.5 }):Play()

    local cx, cy    = sw / 2, sh / 2
    local TW, TH    = 440, 40
    local textLeft  = cx - TW / 2
    local textRight = cx + TW / 2
    local lineY     = cy + 22

    local reveal = make("Frame", {
        Position = UDim2.fromOffset(textLeft, lineY - TH - 8); Size = UDim2.fromOffset(0, TH);
        BackgroundTransparency = 1; BorderSizePixel = 0; ClipsDescendants = true; ZIndex = 52;
    }, dim)
    local label = make("TextLabel", {
        Size = UDim2.fromOffset(TW, TH); BackgroundTransparency = 1; Text = SPLASH_TEXT;
        TextColor3 = WHITE; TextStrokeTransparency = 0.8; TextStrokeColor3 = Color3.fromRGB(120, 170, 255);
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
            NumberSequenceKeypoint.new(0, 1);
            NumberSequenceKeypoint.new(0.35, 0.4);
            NumberSequenceKeypoint.new(1, 0);
        })
        lg.Parent = line
    end

    local star = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5); Size = UDim2.fromOffset(40, 40);
        Position = UDim2.fromOffset(-100, -100); BackgroundTransparency = 1; ZIndex = 56;
    }, dim)
    local function starPart(w, h, rot, tr, z)
        local p = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5); Position = UDim2.fromScale(0.5, 0.5);
            Size = UDim2.fromOffset(w, h); Rotation = rot; BackgroundColor3 = WHITE;
            BackgroundTransparency = tr; BorderSizePixel = 0; ZIndex = z;
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
        local k  = i / TRAIL
        local sz = math.max(2, math.floor(10 * (1 - k)) + 2)
        local d = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5); Size = UDim2.fromOffset(sz, sz);
            Position = UDim2.fromOffset(-100, -100); BackgroundColor3 = WHITE;
            BackgroundTransparency = 0.25 + 0.75 * k; BorderSizePixel = 0; ZIndex = 54;
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

    local R0    = 0.13 * math.min(sw, sh)
    local R1    = R0 * 0.55
    local dirIn = Vector2.new(-0.7071, 0.7071)
    local C     = Vector2.new(math.max(sw * 0.2, R0 + 24), sh * 0.68)
    local E0    = C + Vector2.new(-0.7071, -0.7071) * R0
    local P0    = Vector2.new(sw + 80, -80)

    bez3(P0, P0 + Vector2.new(-sw * 0.25, sh * 0.30), E0 - dirIn * (sw * 0.22), E0, 80)

    do
        local N = 120
        for i = 1, N do
            local k   = i / N
            local phi = math.rad(225 - 495 * k)
            local r   = R0 + (R1 - R0) * k
            push(C + Vector2.new(math.cos(phi), math.sin(phi)) * r)
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
    local total  = cum[#cum]
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
    local t0  = tick()
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
            local w = math.clamp(p.X - textLeft + 8, 0, TW)
            reveal.Size = UDim2.fromOffset(w, TH)
            line.Size   = UDim2.fromOffset(math.clamp(p.X - textLeft + 20, 0, TW + 90), 2)
            line.Position = UDim2.fromOffset(textLeft - 20, lineY)
        end

        if a >= 1 then break end
        RunService.Heartbeat:Wait()
    end
    if not isCurrent() then return end

    reveal.Size = UDim2.fromOffset(TW, TH)
    line.Size   = UDim2.fromOffset(TW + 40, 2)
    for _, d in ipairs(trail) do
        TweenService:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
    end
    TweenService:Create(star, TweenInfo.new(0.25), { Size = UDim2.fromOffset(0, 0) }):Play()

    task.wait(1.0)
    if not isCurrent() then return end

    local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(label, fade, { TextTransparency = 1; TextStrokeTransparency = 1 }):Play()
    TweenService:Create(line,  fade, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(dim,   fade, { BackgroundTransparency = 1 }):Play()
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

    local function slideIn(inst, dx, dy, delay, dur)
        if not inst then return end
        local goal = inst.Position
        inst.Position = UDim2.new(goal.X.Scale, goal.X.Offset + dx, goal.Y.Scale, goal.Y.Offset + dy)
        task.delay(delay, function()
            if not isCurrent() or not inst.Parent then return end
            TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { Position = goal }):Play()
        end)
    end

    do
        local goalSize, goalPos = Logo.Size, Logo.Position
        Logo.Size     = UDim2.fromOffset(0, 0)
        Logo.Position = UDim2.fromOffset(goalPos.X.Offset + 17, goalPos.Y.Offset + 17)
        task.delay(0.22, function()
            if not isCurrent() or not Logo.Parent then return end
            TweenService:Create(Logo, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = goalSize; Position = goalPos }):Play()
        end)
    end

    for i, n in ipairs(navOrder) do
        slideIn(navBtns[n], -28, 0, 0.26 + (i - 1) * 0.07, 0.55)
    end

    slideIn(modCard,    0, 22, 0.34, 0.6)
    slideIn(tuneCard,   0, 22, 0.44, 0.6)
    slideIn(statusCard, 0, 22, 0.54, 0.6)

    local t0 = tick()
    while isCurrent() do
        local a  = math.clamp((tick() - t0) / WIN_DUR, 0, 1)
        local e  = easeOutQuint(a)
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
    task.delay(0.25, function()
        if isCurrent() then
            notify("Onyx v7 loaded", "Press " .. uiToggleKey.Name .. " to hide / show")
        end
    end)
end

applyCur()

task.spawn(function()
    local holder = { frame = false }
    pcall(playSplash, holder)
    if holder.frame then pcall(function() holder.frame:Destroy() end) end
    if not isCurrent() then return end
    playWindowIntro()
end)

-- status readout
task.spawn(function()
    while running and gui and gui.Parent do
        local errorText = lastError and ("\nerr: " .. lastError:sub(1, 70)) or ""
        statusLabel.Text = ("%s | %d npcs | seated %d%s"):format(
            stopped and ("STOPPED (" .. CONFIG.PanicKey.Name .. ")") or "running", trackedCount, seatedTotal, errorText)
        stsTxt.Text = stopped and "STOPPED" or "RUNNING"
        stsTxt.TextColor3 = stopped and COL_BAD or COL_OK
        task.wait(0.5)
    end
end)

if getgenv then
    getgenv().OnyxUnload = unload
end

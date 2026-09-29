-- =====================================================
--  brieli vis — Violence District Edition
--  Правый Shift — открыть/закрыть меню
-- =====================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ContextActionSvc  = game:GetService("ContextActionService")
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

if _G.brieliVisUnload then pcall(_G.brieliVisUnload) end

-- ============== СОСТОЯНИЕ ==============
local state = {
    espEnabled      = true,
    showName        = true,
    showDistance    = true,
    showHealthBar   = true,
    showKillerTag   = true,
    chams           = true,
    box2D           = false,
    skeleton        = false,
    espGenerators   = true,
    espHooks        = true,
    espPallets      = true,
    noclip          = false,
    fullbright      = false,
    noFog           = false,
    noShadows       = false,
    fovValue        = 90,
    killerAlert     = true,
    menuTheme       = "blue",
    menuKey         = Enum.KeyCode.RightShift,
    checkpointBinds = true,

    currentEffects  = {},
    effectTrail     = false,
    effectParticles = false,
    effectAura      = false,

    spinEnabled     = false,
    spinDirection   = "right",
    spinSpeed       = 40,
    spinConn        = nil,
    originalAutoRotate = true,

    autoEscape      = false,
    autoEscapeRef   = nil,
    autoEscapeConn  = nil,

    survivorColor   = Color3.fromRGB(0, 170, 255),
    killerColor     = Color3.fromRGB(255, 40, 40),
    generatorColor  = Color3.fromRGB(255, 200, 0),
    hookColor       = Color3.fromRGB(255, 0, 255),
    palletColor     = Color3.fromRGB(0, 255, 100),

    highlights      = {},
    billboards      = {},
    boxes2D         = {},
    skeletons       = {},
    connections     = {},
    renderConn      = nil,
    noclipConn      = nil,
    savedCollide    = {},
    roleCache       = {},
    checkpoint      = nil,
    checkpointMarker = nil,
    unloaded        = false,
    currentTab      = "visuals",
}

local function bind(conn)
    table.insert(state.connections, conn)
    return conn
end

-- ============== GUI ==============
local parentGui
pcall(function()
    parentGui = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not parentGui then
    parentGui = LocalPlayer:WaitForChild("PlayerGui")
end

local THEMES = {
    blue   = { name="Тёмно-синий", bg=Color3.fromRGB(18,18,24), titleBg=Color3.fromRGB(28,28,38),
        tabBg=Color3.fromRGB(35,35,48), tabAct=Color3.fromRGB(80,80,130), tabHov=Color3.fromRGB(55,55,80),
        row=Color3.fromRGB(32,32,42), rowHov=Color3.fromRGB(42,42,55), accent=Color3.fromRGB(100,140,255),
        stroke=Color3.fromRGB(70,70,100) },
    purple = { name="Тёмно-фиолетовый", bg=Color3.fromRGB(22,18,30), titleBg=Color3.fromRGB(35,28,45),
        tabBg=Color3.fromRGB(45,35,60), tabAct=Color3.fromRGB(110,80,155), tabHov=Color3.fromRGB(65,50,85),
        row=Color3.fromRGB(40,32,52), rowHov=Color3.fromRGB(52,42,68), accent=Color3.fromRGB(170,110,255),
        stroke=Color3.fromRGB(90,70,120) },
    green  = { name="Тёмно-зелёный", bg=Color3.fromRGB(18,24,20), titleBg=Color3.fromRGB(28,38,30),
        tabBg=Color3.fromRGB(35,48,40), tabAct=Color3.fromRGB(80,130,100), tabHov=Color3.fromRGB(55,78,65),
        row=Color3.fromRGB(30,42,35), rowHov=Color3.fromRGB(42,58,48), accent=Color3.fromRGB(90,210,130),
        stroke=Color3.fromRGB(70,100,85) },
    red    = { name="Тёмно-красный", bg=Color3.fromRGB(24,18,18), titleBg=Color3.fromRGB(40,25,25),
        tabBg=Color3.fromRGB(50,32,32), tabAct=Color3.fromRGB(140,65,65), tabHov=Color3.fromRGB(80,50,50),
        row=Color3.fromRGB(44,28,28), rowHov=Color3.fromRGB(60,40,40), accent=Color3.fromRGB(230,90,90),
        stroke=Color3.fromRGB(110,70,70) },
    black  = { name="Чёрный", bg=Color3.fromRGB(8,8,10), titleBg=Color3.fromRGB(18,18,20),
        tabBg=Color3.fromRGB(25,25,28), tabAct=Color3.fromRGB(70,70,80), tabHov=Color3.fromRGB(40,40,48),
        row=Color3.fromRGB(20,20,24), rowHov=Color3.fromRGB(32,32,38), accent=Color3.fromRGB(210,210,220),
        stroke=Color3.fromRGB(60,60,70) },
}

local function getTheme() return THEMES[state.menuTheme] or THEMES.blue end
local THEME = getTheme()

local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = obj
    return c
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "brieli_vis_vd"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = parentGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 500, 0, 650)
main.Position = UDim2.new(0.5, -250, 0.5, -325)
main.BackgroundColor3 = THEME.bg
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
main:SetAttribute("TR", "bg")
round(main, 12)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = THEME.stroke
mainStroke.Thickness = 1.5
mainStroke.Parent = main
mainStroke:SetAttribute("TR", "stroke")

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = THEME.titleBg
titleBar.BorderSizePixel = 0
titleBar.Parent = main
titleBar:SetAttribute("TR", "titleBg")
round(titleBar, 12)

local titleCover = Instance.new("Frame")
titleCover.Size = UDim2.new(1, 0, 0, 12)
titleCover.Position = UDim2.new(0, 0, 1, -12)
titleCover.BackgroundColor3 = THEME.titleBg
titleCover.BorderSizePixel = 0
titleCover.Parent = titleBar
titleCover:SetAttribute("TR", "titleBg")

local titleDot = Instance.new("Frame")
titleDot.Size = UDim2.new(0, 8, 0, 8)
titleDot.Position = UDim2.new(0, 14, 0.5, -4)
titleDot.BackgroundColor3 = THEME.accent
titleDot.BorderSizePixel = 0
titleDot.Parent = titleBar
titleDot:SetAttribute("TR", "accentBg")
round(titleDot, 4)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 1, 0)
titleLabel.Position = UDim2.new(0, 30, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "brieli vis  •  Violence District"
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.Parent = titleBar

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 34)
tabBar.Position = UDim2.new(0, 10, 0, 46)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -170)
content.Position = UDim2.new(0, 10, 0, 86)
content.BackgroundTransparency = 1
content.Parent = main

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, 0, 1, 0)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 4
contentScroll.ScrollBarImageColor3 = THEME.stroke
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 5)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentScroll

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingRight = UDim.new(0, 6)
contentPadding.Parent = contentScroll

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end)

local tabButtons = {}
local tabNames = {
    visuals   = "Визуальные",
    world     = "Мир",
    teleport  = "Телепорт",
    cosmetics = "Косметика",
    misc      = "Разное",
    menu      = "Меню",
}

local function switchTab(tabId)
    state.currentTab = tabId
    local th = getTheme()
    for id, btn in pairs(tabButtons) do
        local isActive = (id == tabId)
        btn.BackgroundColor3 = isActive and th.tabAct or th.tabBg
        btn.TextColor3 = isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,170)
    end
    for _, child in ipairs(contentScroll:GetChildren()) do
        if child:IsA("GuiObject") then
            child.Visible = (child:GetAttribute("Tab") == tabId)
        end
    end
end

for id, label in pairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 71, 1, 0)
    btn.BackgroundColor3 = THEME.tabBg
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(150, 150, 170)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = tabBar
    round(btn, 6)

    btn.MouseEnter:Connect(function()
        if state.currentTab ~= id then btn.BackgroundColor3 = getTheme().tabHov end
    end)
    btn.MouseLeave:Connect(function()
        if state.currentTab ~= id then btn.BackgroundColor3 = getTheme().tabBg end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(id) end)
    tabButtons[id] = btn
end

-- ============== UI ХЕЛПЕРЫ ==============
local function makeSectionLabel(text, tabId)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = getTheme().accent
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.Parent = contentScroll
    lbl:SetAttribute("Tab", tabId)
    lbl:SetAttribute("TR", "accentText")
    return lbl
end

local function makeToggle(text, defaultOn, tabId, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = getTheme().row
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Text = ""
    row.Parent = contentScroll
    row:SetAttribute("Tab", tabId)
    row:SetAttribute("TR", "row")
    round(row, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 38, 0, 20)
    track.Position = UDim2.new(1, -52, 0.5, -10)
    track.BackgroundColor3 = defaultOn and Color3.fromRGB(50, 150, 90) or Color3.fromRGB(60, 60, 75)
    track.BorderSizePixel = 0
    track.Parent = row
    round(track, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultOn and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    knob.BorderSizePixel = 0
    knob.Parent = track
    round(knob, 8)

    local st = defaultOn
    row.MouseEnter:Connect(function() row.BackgroundColor3 = getTheme().rowHov end)
    row.MouseLeave:Connect(function() row.BackgroundColor3 = getTheme().row end)
    row.MouseButton1Click:Connect(function()
        st = not st
        track.BackgroundColor3 = st and Color3.fromRGB(50, 150, 90) or Color3.fromRGB(60, 60, 75)
        if st then
            knob:TweenPosition(UDim2.new(1, -18, 0.5, -8), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        else
            knob:TweenPosition(UDim2.new(0, 2, 0.5, -8), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end
        callback(st)
    end)
    return row
end

local function makeMasterToggle(text, defaultOn, tabId, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = defaultOn and Color3.fromRGB(45, 75, 60) or getTheme().row
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Text = ""
    row.Parent = contentScroll
    row:SetAttribute("Tab", tabId)
    round(row, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = row

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 40, 1, 0)
    status.Position = UDim2.new(1, -100, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = defaultOn and "ВКЛ" or "ВЫКЛ"
    status.TextColor3 = defaultOn and Color3.fromRGB(120, 230, 160) or Color3.fromRGB(150, 150, 170)
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Font = Enum.Font.GothamBold
    status.TextSize = 12
    status.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 42, 0, 22)
    track.Position = UDim2.new(1, -54, 0.5, -11)
    track.BackgroundColor3 = defaultOn and Color3.fromRGB(50, 150, 90) or Color3.fromRGB(60, 60, 75)
    track.BorderSizePixel = 0
    track.Parent = row
    round(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = defaultOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    knob.BorderSizePixel = 0
    knob.Parent = track
    round(knob, 9)

    local st = defaultOn
    row.MouseButton1Click:Connect(function()
        st = not st
        row.BackgroundColor3 = st and Color3.fromRGB(45, 75, 60) or getTheme().row
        track.BackgroundColor3 = st and Color3.fromRGB(50, 150, 90) or Color3.fromRGB(60, 60, 75)
        status.Text = st and "ВКЛ" or "ВЫКЛ"
        status.TextColor3 = st and Color3.fromRGB(120, 230, 160) or Color3.fromRGB(150, 150, 170)
        if st then
            knob:TweenPosition(UDim2.new(1, -20, 0.5, -9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        else
            knob:TweenPosition(UDim2.new(0, 2, 0.5, -9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end
        callback(st)
    end)
    return row
end

local function makeColorButton(text, initialColor, tabId, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = getTheme().row
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = contentScroll
    btn:SetAttribute("Tab", tabId)
    btn:SetAttribute("TR", "row")
    round(btn, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = btn

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 26, 0, 26)
    swatch.Position = UDim2.new(1, -40, 0.5, -13)
    swatch.BackgroundColor3 = initialColor
    swatch.BorderSizePixel = 0
    swatch.Parent = btn
    round(swatch, 4)

    local presets = {
        Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 40, 40),
        Color3.fromRGB(255, 200, 0), Color3.fromRGB(0, 255, 100),
        Color3.fromRGB(255, 0, 255), Color3.fromRGB(255, 140, 0),
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 255),
    }
    local idx = 1
    for i, col in ipairs(presets) do
        if col == initialColor then idx = i break end
    end

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = getTheme().rowHov end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = getTheme().row end)
    btn.MouseButton1Click:Connect(function()
        idx = idx % #presets + 1
        local col = presets[idx]
        swatch.BackgroundColor3 = col
        callback(col)
    end)
    return btn
end

local function makeSlider(text, minVal, maxVal, defaultVal, tabId, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = getTheme().row
    frame.BorderSizePixel = 0
    frame.Parent = contentScroll
    frame:SetAttribute("Tab", tabId)
    frame:SetAttribute("TR", "row")
    round(frame, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -14, 0, 20)
    label.Position = UDim2.new(0, 14, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. defaultVal
    label.TextColor3 = Color3.fromRGB(230, 230, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = frame

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -28, 0, 8)
    track.Position = UDim2.new(0, 14, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    track.BorderSizePixel = 0
    track.AutoButtonColor = false
    track.Text = ""
    track.Parent = frame
    round(track, 4)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = getTheme().accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, 4)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -7, 0.5, -7)
    handle.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    handle.BorderSizePixel = 0
    handle.ZIndex = 2
    handle.Parent = track
    round(handle, 7)

    local dragging = false
    local function updateSlider(input)
        local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * relX + 0.5)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        handle.Position = UDim2.new(relX, -7, 0.5, -7)
        label.Text = text .. ": " .. val
        callback(val)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            main.Active = false
            updateSlider(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then dragging = false main.Active = true end
        end
    end)
    return frame
end

local function makeActionButton(text, tabId, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = color or getTheme().row
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(230, 230, 245)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = contentScroll
    btn:SetAttribute("Tab", tabId)
    if not color then btn:SetAttribute("TR", "row") end
    round(btn, 6)

    btn.MouseEnter:Connect(function()
        if not color then btn.BackgroundColor3 = getTheme().rowHov end
    end)
    btn.MouseLeave:Connect(function()
        if not color then btn.BackgroundColor3 = getTheme().row end
    end)
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

-- ============== РОЛИ ==============
local function getPlayerRole(player)
    if player.Team then
        local tn = player.Team.Name:lower()
        if tn:find("killer") or tn:find("murder") or tn:find("maniac") or tn:find("hunter") then
            return "killer"
        end
    end
    local ra = player:GetAttribute("Role") or player:GetAttribute("role")
    if ra then
        local r = tostring(ra):lower()
        if r:find("killer") or r:find("murder") or r:find("maniac") then return "killer" end
    end
    local char = player.Character
    if char then
        local cr = char:GetAttribute("Role") or char:GetAttribute("role")
        if cr then
            local r = tostring(cr):lower()
            if r:find("killer") or r:find("murder") or r:find("maniac") then return "killer" end
        end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("spear") or n:find("veil")
                   or n:find("weapon") or n:find("blade") then return "killer" end
            end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("spear") or n:find("veil")
                   or n:find("weapon") or n:find("blade") then return "killer" end
            end
        end
    end
    return "survivor"
end

local function getPlayerColor(player)
    if state.roleCache[player] == "killer" then return state.killerColor end
    return state.survivorColor
end

-- ============== КЛАССИФИКАЦИЯ ==============
local function classifyObject(obj)
    local name = obj.Name:lower()
    local isBox = name:find("box") or name:find("crate") or name:find("container")
        or name:find("barrel") or name:find("chest") or name:find("locker")
        or name:find("coffin") or name:find("trash")

    local attrType = obj:GetAttribute("Type") or obj:GetAttribute("type")
    if attrType then
        local t = tostring(attrType):lower()
        if t:find("generator") then return "generator" end
        if t:find("hook") then return "hook" end
        if t:find("pallet") and not isBox then return "pallet" end
        if t:find("exit") or t:find("escape") then return "gate" end
    end

    for _, tag in ipairs(CollectionService:GetTags(obj)) do
        local t = tag:lower()
        if t:find("generator") then return "generator" end
        if t:find("hook") then return "hook" end
        if t:find("pallet") and not isBox then return "pallet" end
        if t:find("exit") or t:find("escape") then return "gate" end
    end

    if name:find("generator") or name == "gen" or name:find("fuse") then return "generator" end
    if name:find("hook") then return "hook" end
    if name:find("pallet") and not isBox then return "pallet" end
    if name:find("exit") or name:find("escape") then return "gate" end

    local pp = obj:FindFirstChildOfClass("ProximityPrompt")
    if pp then
        local t = (tostring(pp.ActionText) .. " " .. tostring(pp.ObjectText)):lower()
        if t:find("generator") or t:find("repair") or t:find("fix") then return "generator" end
        if t:find("hook") or t:find("hang") or t:find("sacrifice") then return "hook" end
        if not isBox then
            if t:find("pallet") or t:find("pull down") or t:find("drop pallet")
               or t:find("throw pallet") or t:find("use pallet") then
                return "pallet"
            end
        end
        if t:find("exit") or t:find("escape") or t:find("open gate") or t:find("побег") then return "gate" end
    end
    return nil
end

local function getWorldColor(cat)
    if cat == "generator" then return state.generatorColor end
    if cat == "hook" then return state.hookColor end
    if cat == "pallet" then return state.palletColor end
    return Color3.fromRGB(255,255,255)
end

local function getWorldEnabled(cat)
    if cat == "generator" then return state.espGenerators and state.espEnabled end
    if cat == "hook" then return state.espHooks and state.espEnabled end
    if cat == "pallet" then return state.espPallets and state.espEnabled end
    return false
end

-- ============== WORLD ESP ==============
local function tryHighlightWorldObj(obj)
    if not obj or not obj.Parent then return end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    if state.highlights[obj] then return end
    local cat = classifyObject(obj)
    if not cat or cat == "gate" then return end

    local p = obj.Parent
    while p and p ~= Workspace do
        if state.highlights[p] then return end
        p = p.Parent
    end

    local hl = Instance.new("Highlight")
    hl.Name = "brieliVis_WorldESP"
    hl.Adornee = obj
    hl.FillColor = getWorldColor(cat)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = getWorldEnabled(cat)
    hl.Parent = obj
    state.highlights[obj] = hl
end

local function initialScan()
    local descendants = Workspace:GetDescendants()
    task.spawn(function()
        for i = 1, #descendants, 30 do
            if state.unloaded then return end
            for j = i, math.min(i + 29, #descendants) do
                pcall(tryHighlightWorldObj, descendants[j])
            end
            task.wait()
        end
    end)
end

local pendingQueue = {}
bind(Workspace.DescendantAdded:Connect(function(obj)
    table.insert(pendingQueue, obj)
end))

task.spawn(function()
    while not state.unloaded do
        task.wait(0.2)
        if #pendingQueue > 0 then
            local n = math.min(#pendingQueue, 25)
            for i = 1, n do
                local obj = table.remove(pendingQueue, 1)
                pcall(tryHighlightWorldObj, obj)
            end
        end
    end
end)

-- ============== PLAYER ESP ==============
local function createBillboard(character)
    if state.billboards[character] then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 180, 0, 58)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = head
    bb.Parent = head

    local nl = Instance.new("TextLabel")
    nl.Name = "NameLabel"
    nl.Size = UDim2.new(1, 0, 0, 18)
    nl.BackgroundTransparency = 1
    nl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13
    nl.TextStrokeTransparency = 0
    nl.Parent = bb

    local dl = Instance.new("TextLabel")
    dl.Name = "DistLabel"
    dl.Size = UDim2.new(1, 0, 0, 14)
    dl.Position = UDim2.new(0, 0, 0, 18)
    dl.BackgroundTransparency = 1
    dl.TextColor3 = Color3.fromRGB(200, 200, 200)
    dl.Font = Enum.Font.Gotham
    dl.TextSize = 11
    dl.TextStrokeTransparency = 0
    dl.Parent = bb

    local hBg = Instance.new("Frame")
    hBg.Name = "HealthBg"
    hBg.Size = UDim2.new(0.85, 0, 0, 5)
    hBg.Position = UDim2.new(0.075, 0, 0, 38)
    hBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hBg.BorderSizePixel = 0
    hBg.Parent = bb

    local hFill = Instance.new("Frame")
    hFill.Name = "HealthFill"
    hFill.Size = UDim2.new(1, 0, 1, 0)
    hFill.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
    hFill.BorderSizePixel = 0
    hFill.Parent = hBg

    state.billboards[character] = bb
end

local function createBox2D(character)
    if state.boxes2D[character] then return end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = screenGui
    local s = Instance.new("UIStroke")
    s.Name = "BoxStroke"
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1.5
    s.Parent = box
    state.boxes2D[character] = box
end

local function createSkeleton(character)
    if state.skeletons[character] then return end
    local skel = {}
    local bones = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    }
    for i, pair in ipairs(bones) do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Transparency = 1
        line.Visible = false
        skel[i] = {line = line, from = pair[1], to = pair[2]}
    end
    state.skeletons[character] = skel
end

-- ============== TELEPORT CORE ==============
local function teleportToCFrame(cf)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = cf
    return true
end

local function teleportToPosition(pos)
    if not pos then return false end
    return teleportToCFrame(CFrame.new(pos + Vector3.new(0, 3, 0)))
end

local function getCharacterPosition(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position
end

local function findNearestObject(predicate)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position
    local best, bestPos, bestDist = nil, nil, math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and predicate(obj) then
            local pos
            if obj:IsA("BasePart") then pos = obj.Position
            elseif obj:IsA("Model") then
                local ok, pivot = pcall(function() return obj:GetPivot().Position end)
                if ok then pos = pivot end
            end
            if pos then
                local d = (pos - myPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = obj
                    bestPos = pos
                end
            end
        end
    end
    return best, bestPos, bestDist
end

local function scoreEscapeCandidate(obj)
    local score = 0
    local name = obj.Name:lower()

    if name:find("escape") then score = score + 100 end
    if name:find("exitzone") or name:find("exitgate") or name:find("exit_gate")
       or name:find("exit_door") then score = score + 90 end
    if name:find("^exit") then score = score + 60 end
    if name:find("gate") then score = score + 40 end
    if name:find("exit") then score = score + 30 end

    local pp = obj:FindFirstChildOfClass("ProximityPrompt")
    if pp then
        local t = (tostring(pp.ActionText) .. " " .. tostring(pp.ObjectText) .. " " .. pp.Name):lower()
        if t:find("escape") or t:find("побег") then score = score + 80 end
        if t:find("exit") then score = score + 50 end
        if (t:find("open") or t:find("открыть")) and (t:find("gate") or t:find("exit")) then
            score = score + 40
        end
        if pp.HoldDuration and pp.HoldDuration >= 1.5 then score = score + 15 end
    end

    local attr = obj:GetAttribute("Type") or obj:GetAttribute("type")
    if attr then
        local a = tostring(attr):lower()
        if a:find("escape") then score = score + 100 end
        if a:find("exit") then score = score + 50 end
    end

    for _, tag in ipairs(CollectionService:GetTags(obj)) do
        local tg = tag:lower()
        if tg:find("escape") then score = score + 100 end
        if tg:find("exit") then score = score + 50 end
    end

    return score
end

local function findEscapeTrigger()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position

    local MIN_SCORE = 40
    local best, bestPos, bestScore, bestDist = nil, nil, 0, math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local s = scoreEscapeCandidate(obj)
            if s >= MIN_SCORE then
                local pos
                if obj:IsA("BasePart") then
                    pos = obj.Position
                elseif obj:IsA("Model") then
                    local ok, pivot = pcall(function() return obj:GetPivot().Position end)
                    if ok then pos = pivot end
                end

                local pp = obj:FindFirstChildOfClass("ProximityPrompt")
                if pp and pp.Parent then
                    local par = pp.Parent
                    if par:IsA("BasePart") then
                        pos = par.Position
                    elseif par:IsA("Attachment") and par.Parent then
                        pos = par.WorldPosition
                    end
                end

                if pos then
                    local d = (pos - myPos).Magnitude
                    if s > bestScore or (s == bestScore and d < bestDist) then
                        bestScore = s
                        bestDist = d
                        best = obj
                        bestPos = pos
                    end
                end
            end
        end
    end

    return best, bestPos, bestScore, bestDist
end

-- ============== CHECKPOINT ==============
local function setCheckpointMarker(pos)
    if state.checkpointMarker then
        pcall(function() state.checkpointMarker:Destroy() end)
        state.checkpointMarker = nil
    end
    local part = Instance.new("Part")
    part.Name = "brieliVis_Checkpoint"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(2, 2, 2)
    part.Position = pos
    part.Parent = Workspace

    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(0, 255, 100)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = part

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    bb.Parent = part

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "📍 ЧЕКПОИНТ"
    lbl.TextColor3 = Color3.fromRGB(120, 255, 160)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextStrokeTransparency = 0
    lbl.Parent = bb

    state.checkpointMarker = part
end

local function saveCheckpoint()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    state.checkpoint = hrp.CFrame
    setCheckpointMarker(hrp.Position)
end

local function goToCheckpoint()
    if state.checkpoint then
        teleportToCFrame(state.checkpoint)
    end
end

-- ============== АВТО-ПОБЕГ ==============
local function startAutoEscape()
    if state.autoEscapeConn then return end
    state.autoEscapeConn = RunService.Heartbeat:Connect(function()
        if state.unloaded or not state.autoEscape then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local inst, pos = findEscapeTrigger()
        if inst and pos and state.autoEscapeRef ~= inst then
            state.autoEscapeRef = inst
            teleportToPosition(pos)
        end
    end)
end

local function stopAutoEscape()
    if state.autoEscapeConn then
        state.autoEscapeConn:Disconnect()
        state.autoEscapeConn = nil
    end
end

-- ============== КОСМЕТИКА: ЭФФЕКТЫ ==============
local function clearEffects()
    for _, e in ipairs(state.currentEffects) do
        pcall(function() e:Destroy() end)
    end
    state.currentEffects = {}
    state.effectTrail = false
    state.effectParticles = false
    state.effectAura = false
end

local function applyTrailEffect()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then return end

    local att0 = Instance.new("Attachment")
    att0.Name = "brieliVis_TrailAtt0"
    att0.Position = Vector3.new(1.5, 0, 0)
    att0.Parent = head

    local att1 = Instance.new("Attachment")
    att1.Name = "brieliVis_TrailAtt1"
    att1.Position = Vector3.new(-1.5, 0, 0)
    att1.Parent = hrp

    local trail = Instance.new("Trail")
    trail.Name = "brieliVis_Trail"
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Lifetime = 0.5
    trail.MinLength = 0.1
    trail.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, state.survivorColor),
        ColorSequenceKeypoint.new(1, state.killerColor),
    }
    trail.Parent = head

    table.insert(state.currentEffects, trail)
    table.insert(state.currentEffects, att0)
    table.insert(state.currentEffects, att1)
    state.effectTrail = true
end

local function applyParticlesEffect()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "brieliVis_Particles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 25
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Speed = NumberRange.new(2, 5)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0),
    }
    emitter.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    }
    emitter.Color = ColorSequence.new(state.survivorColor)
    emitter.LightEmission = 1
    emitter.Parent = hrp

    table.insert(state.currentEffects, emitter)
    state.effectParticles = true
end

local function applyAuraEffect()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "brieliVis_AuraAtt"
    attachment.Parent = hrp

    local beam = Instance.new("Beam")
    beam.Name = "brieliVis_Aura"
    beam.Attachment0 = attachment
    beam.Attachment1 = attachment
    beam.Width0 = 3
    beam.Width1 = 0
    beam.Lifetime = 1
    beam.Segments = 10
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(state.killerColor)
    beam.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }
    beam.Parent = hrp

    table.insert(state.currentEffects, beam)
    table.insert(state.currentEffects, attachment)
    state.effectAura = true
end

-- ============== КРУТИЛКА ==============
local function startSpin()
    if state.spinConn then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    state.originalAutoRotate = hum.AutoRotate
    hum.AutoRotate = false

    state.spinConn = RunService.RenderStepped:Connect(function(dt)
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not h or not hrp then return end

        local dir = (state.spinDirection == "left") and -1 or 1
        -- state.spinSpeed = "оборотов в минуту" * 0.6, где 40 = 1 об/сек
        -- фактически: 40 = 360°/сек = 1 об/сек, поэтому умножаем на 9
        local step = math.rad(dt * state.spinSpeed * 9 * dir)
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, step, 0)
    end)
end

local function stopSpin()
    if state.spinConn then
        state.spinConn:Disconnect()
        state.spinConn = nil
    end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = state.originalAutoRotate
    end
end

-- ============== ТЕЛЕПОРТ — UI ==============
local selectedPlayer = nil
local playerListRows = {}

local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, 0, 0, 0)
playerListFrame.AutomaticSize = Enum.AutomaticSize.Y
playerListFrame.BackgroundTransparency = 1
playerListFrame.Parent = contentScroll
playerListFrame:SetAttribute("Tab", "teleport")

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 3)
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Parent = playerListFrame

local function refreshPlayerList()
    for _, row in ipairs(playerListRows) do
        pcall(function() row:Destroy() end)
    end
    playerListRows = {}
    selectedPlayer = nil

    local th = getTheme()
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        count = count + 1

        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = th.row
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = "  " .. player.Name
        row.TextColor3 = Color3.fromRGB(230, 230, 245)
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Font = Enum.Font.GothamMedium
        row.TextSize = 12
        row.Parent = playerListFrame
        row:SetAttribute("TR", "row")
        round(row, 6)

        row.MouseEnter:Connect(function()
            if selectedPlayer ~= player then row.BackgroundColor3 = getTheme().rowHov end
        end)
        row.MouseLeave:Connect(function()
            if selectedPlayer ~= player then row.BackgroundColor3 = getTheme().row end
        end)
        row.MouseButton1Click:Connect(function()
            selectedPlayer = player
            for _, r in ipairs(playerListRows) do
                if r:IsA("TextButton") then
                    r.BackgroundColor3 = getTheme().row
                    r.TextColor3 = Color3.fromRGB(230, 230, 245)
                end
            end
            row.BackgroundColor3 = getTheme().accent
            row.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        table.insert(playerListRows, row)
    end

    if count == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 26)
        empty.BackgroundTransparency = 1
        empty.Text = "  Нет других игроков"
        empty.TextColor3 = Color3.fromRGB(120, 120, 140)
        empty.TextXAlignment = Enum.TextXAlignment.Left
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.Parent = playerListFrame
        table.insert(playerListRows, empty)
    end
end

makeSectionLabel("▬ К ИГРОКАМ ▬", "teleport")

makeActionButton("🔄 Обновить список", "teleport", nil, function()
    refreshPlayerList()
end)

makeActionButton("🎯 Телепорт к выбранному", "teleport",
    Color3.fromRGB(60, 110, 170), function()
        if not selectedPlayer then return end
        local pos = getCharacterPosition(selectedPlayer)
        if pos then
            teleportToPosition(pos)
        end
    end)

makeSectionLabel("▬ ЧЕКПОИНТ ▬", "teleport")

makeToggle("Бинды F1 / F2", state.checkpointBinds, "teleport", function(on)
    state.checkpointBinds = on
end)

makeActionButton("💾 Сохранить чекпоинт  (F1)", "teleport", nil, function(btn)
    saveCheckpoint()
    btn.Text = "  ✅ Сохранено!"
    task.wait(1)
    btn.Text = "  💾 Сохранить чекпоинт  (F1)"
end)

makeActionButton("🚀 Телепорт к чекпоинту  (F2)", "teleport",
    Color3.fromRGB(60, 110, 170), function(btn)
        if state.checkpoint then
            goToCheckpoint()
            btn.Text = "  ✅ Телепортирован!"
            task.wait(1)
            btn.Text = "  🚀 Телепорт к чекпоинту  (F2)"
        else
            btn.Text = "  ⚠ Чекпоинт не задан"
            task.wait(1.5)
            btn.Text = "  🚀 Телепорт к чекпоинту  (F2)"
        end
    end)

makeActionButton("🗑 Удалить чекпоинт", "teleport",
    Color3.fromRGB(140, 55, 55), function(btn)
        state.checkpoint = nil
        if state.checkpointMarker then
            pcall(function() state.checkpointMarker:Destroy() end)
            state.checkpointMarker = nil
        end
        btn.Text = "  ✅ Удалён"
        task.wait(1)
        btn.Text = "  🗑 Удалить чекпоинт"
    end)

makeSectionLabel("▬ ОБЪЕКТЫ ▬", "teleport")

makeActionButton("⚡ Телепорт к ближайшему генератору", "teleport", nil, function(btn)
    local inst, pos, dist = findNearestObject(function(obj)
        return classifyObject(obj) == "generator"
    end)
    if pos then
        teleportToPosition(pos)
        btn.Text = string.format("  ⚡ Готово (%.0f studs)", dist)
    else
        btn.Text = "  ⚠ Генератор не найден"
    end
    task.wait(1.5)
    btn.Text = "  ⚡ Телепорт к ближайшему генератору"
end)

makeActionButton("🚪 Телепорт к выходу (триггер побега)", "teleport", nil, function(btn)
    local inst, pos, score, dist = findEscapeTrigger()
    if pos then
        teleportToPosition(pos)
        btn.Text = string.format("  🚪 Готово! «%s» (score %d, %.0f studs)",
            inst and inst.Name or "?", score, dist)
    else
        btn.Text = "  ⚠ Триггер побега не найден"
    end
    task.wait(2)
    btn.Text = "  🚪 Телепорт к выходу (триггер побега)"
end)

makeActionButton("🏃 СБЕЖАТЬ  (телепорт в триггер побега)", "teleport",
    Color3.fromRGB(60, 140, 80), function(btn)
        local inst, pos, score, dist = findEscapeTrigger()
        if pos then
            teleportToPosition(pos)
            btn.Text = string.format("  ✅ СБЕЖАЛ! «%s» (score %d)", inst and inst.Name or "?", score)
        else
            btn.Text = "  ⚠ Триггер побега не найден"
        end
        task.wait(2)
        btn.Text = "  🏃 СБЕЖАТЬ  (телепорт в триггер побега)"
    end)

makeToggle("Авто-побег при старте раунда", state.autoEscape, "teleport", function(on)
    state.autoEscape = on
    state.autoEscapeRef = nil
    if on then
        startAutoEscape()
    else
        stopAutoEscape()
    end
end)

makeActionButton("♻ Сбросить авто-побег", "teleport", nil, function(btn)
    state.autoEscapeRef = nil
    btn.Text = "  ✅ Сброшено"
    task.wait(1)
    btn.Text = "  ♻ Сбросить авто-побег"
end)

bind(Players.PlayerAdded:Connect(function() task.wait(0.3) refreshPlayerList() end))
bind(Players.PlayerRemoving:Connect(function() task.wait(0.3) refreshPlayerList() end))
bind(LocalPlayer.CharacterAdded:Connect(function()
    state.autoEscapeRef = nil
end))
refreshPlayerList()

-- ============== РЕНДЕР ==============
local renderConn = RunService.RenderStepped:Connect(function()
    if state.unloaded then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end

        local role = state.roleCache[player] or "survivor"
        local col = getPlayerColor(player)
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local espOn = state.espEnabled

        local hl = state.highlights[char]
        if hl and hl.Parent and hl.Name == "brieliVis_PlayerESP" then
            hl.FillColor = col
            hl.Enabled = espOn
            hl.FillTransparency = state.chams and 0.2 or 0.5
        end

        if espOn and head and root then
            if not state.billboards[char] then createBillboard(char) end
            local bb = state.billboards[char]
            if bb then
                bb.Enabled = true
                local nl = bb:FindFirstChild("NameLabel")
                local dl = bb:FindFirstChild("DistLabel")
                local hBg = bb:FindFirstChild("HealthBg")
                local hFill = hBg and hBg:FindFirstChild("HealthFill")

                if nl then
                    if state.showName then
                        local prefix = state.showKillerTag
                            and (role == "killer" and "[KILLER] " or "[SURV] ") or ""
                        nl.Text = prefix .. player.Name
                        nl.TextColor3 = col
                        nl.Visible = true
                    else nl.Visible = false end
                end
                if dl then
                    if state.showDistance then
                        local dist = (root.Position - cam.CFrame.Position).Magnitude
                        dl.Text = string.format("%.0f studs", dist)
                        dl.Visible = true
                    else dl.Visible = false end
                end
                if hBg and hFill and humanoid then
                    hBg.Visible = state.showHealthBar
                    if state.showHealthBar then
                        local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        hFill.Size = UDim2.new(hp, 0, 1, 0)
                        hFill.BackgroundColor3 = hp > 0.4
                            and Color3.fromRGB(0, 220, 80) or Color3.fromRGB(220, 60, 60)
                    end
                end
            end
        elseif state.billboards[char] then
            state.billboards[char].Enabled = false
        end

        if espOn and state.box2D and head and root then
            if not state.boxes2D[char] then createBox2D(char) end
            local box = state.boxes2D[char]
            if box then
                local tp, tOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                local bp, bOn = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                if tOn and bOn then
                    local h = math.abs(bp.Y - tp.Y)
                    local w = h * 0.55
                    box.Size = UDim2.new(0, w, 0, h)
                    box.Position = UDim2.new(0, tp.X - w/2, 0, tp.Y)
                    box.Visible = true
                    local s = box:FindFirstChild("BoxStroke")
                    if s then s.Color = col end
                else box.Visible = false end
            end
        elseif state.boxes2D[char] then
            state.boxes2D[char].Visible = false
        end

        if espOn and state.skeleton then
            if not state.skeletons[char] then createSkeleton(char) end
            local skel = state.skeletons[char]
            if skel then
                for _, bone in ipairs(skel) do
                    local p1 = char:FindFirstChild(bone.from)
                    local p2 = char:FindFirstChild(bone.to)
                    if p1 and p2 then
                        local s1, o1 = cam:WorldToViewportPoint(p1.Position)
                        local s2, o2 = cam:WorldToViewportPoint(p2.Position)
                        if o1 and o2 then
                            bone.line.From = Vector2.new(s1.X, s1.Y)
                            bone.line.To = Vector2.new(s2.X, s2.Y)
                            bone.line.Color = col
                            bone.line.Visible = true
                        else bone.line.Visible = false end
                    else bone.line.Visible = false end
                end
            end
        elseif state.skeletons[char] then
            for _, bone in ipairs(state.skeletons[char]) do
                bone.line.Visible = false
            end
        end
    end
end)

task.spawn(function()
    while not state.unloaded do
        for _, p in ipairs(Players:GetPlayers()) do
            state.roleCache[p] = getPlayerRole(p)
        end
        task.wait(0.5)
    end
end)

-- ============== NOCLIP ==============
local floorRayParams = RaycastParams.new()
floorRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function noclipStep()
    if state.unloaded then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            state.savedCollide[part] = true
            part.CanCollide = false
        end
    end

    floorRayParams.FilterDescendantsInstances = {char}
    local origin = hrp.Position + Vector3.new(0, 1, 0)
    local ray = Workspace:Raycast(origin, Vector3.new(0, -10, 0), floorRayParams)
    if ray then
        local floorY = ray.Position.Y + hum.HipHeight + hrp.Size.Y / 2
        if hrp.Position.Y < floorY + 0.3 and hrp.AssemblyLinearVelocity.Y < 0.1 then
            hrp.CFrame = CFrame.new(hrp.Position.X, floorY, hrp.Position.Z)
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end
end

local function enableNoclip()
    if state.noclipConn then return end
    state.savedCollide = {}
    state.noclipConn = RunService.Stepped:Connect(noclipStep)
end

local function disableNoclip()
    if state.noclipConn then
        state.noclipConn:Disconnect()
        state.noclipConn = nil
    end
    for part, _ in pairs(state.savedCollide) do
        if part and part.Parent then
            pcall(function() part.CanCollide = true end)
        end
    end
    state.savedCollide = {}
end

-- ============== LIGHTING ==============
local savedLighting = nil
local function saveLighting()
    if savedLighting then return end
    savedLighting = {
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
end
local function setFullbright(on)
    if on then
        saveLighting()
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.ExposureCompensation = 0.2
    elseif savedLighting then
        for k, v in pairs(savedLighting) do pcall(function() Lighting[k] = v end) end
    end
end
local function setNoFog(on)
    if on then
        saveLighting()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    elseif savedLighting then
        Lighting.FogEnd = savedLighting.FogEnd or 1000
        Lighting.FogStart = savedLighting.FogStart or 0
    end
end
local function setNoShadows(on)
    if on then
        saveLighting()
        Lighting.GlobalShadows = false
    elseif savedLighting then
        Lighting.GlobalShadows = savedLighting.GlobalShadows
    end
end

-- ============== ИГРОКИ ==============
local function setupPlayer(player)
    if player == LocalPlayer then return end

    local function onChar(char)
        task.wait(0.2)
        if state.unloaded then return end
        local hl = Instance.new("Highlight")
        hl.Name = "brieliVis_PlayerESP"
        hl.Adornee = char
        hl.FillColor = getPlayerColor(player)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = state.chams and 0.2 or 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = state.espEnabled
        hl.Parent = char
        state.highlights[char] = hl
    end

    if player.Character then onChar(player.Character) end
    bind(player.CharacterAdded:Connect(onChar))
    bind(player.CharacterRemoving:Connect(function(char)
        if state.highlights[char] then state.highlights[char]:Destroy() state.highlights[char] = nil end
        if state.billboards[char] then state.billboards[char]:Destroy() state.billboards[char] = nil end
        if state.boxes2D[char] then state.boxes2D[char]:Destroy() state.boxes2D[char] = nil end
        if state.skeletons[char] then
            for _, bone in ipairs(state.skeletons[char]) do bone.line:Remove() end
            state.skeletons[char] = nil
        end
    end))
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
bind(Players.PlayerAdded:Connect(setupPlayer))

-- ============== ВКЛАДКА "ВИЗУАЛЬНЫЕ" ==============
makeSectionLabel("▬ ESP ▬", "visuals")

makeMasterToggle("ESP  (мастер-переключатель)", state.espEnabled, "visuals", function(on)
    state.espEnabled = on
    for _, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_PlayerESP" then hl.Enabled = on end
        if hl.Name == "brieliVis_WorldESP" and hl.Adornee then
            local cat = classifyObject(hl.Adornee)
            if cat then hl.Enabled = on and getWorldEnabled(cat) end
        end
    end
    if not on then
        for _, bb in pairs(state.billboards) do bb.Enabled = false end
        for _, box in pairs(state.boxes2D) do box.Visible = false end
        for _, skel in pairs(state.skeletons) do
            for _, bone in ipairs(skel) do bone.line.Visible = false end
        end
    end
end)

makeSectionLabel("▬ ИГРОКИ ▬", "visuals")
makeToggle("Ник над головой", state.showName, "visuals", function(on) state.showName = on end)
makeToggle("Дистанция", state.showDistance, "visuals", function(on) state.showDistance = on end)
makeToggle("Полоса HP", state.showHealthBar, "visuals", function(on) state.showHealthBar = on end)
makeToggle("Метка роли [KILLER/SURV]", state.showKillerTag, "visuals", function(on) state.showKillerTag = on end)
makeToggle("Chams (заливка)", state.chams, "visuals", function(on)
    state.chams = on
    for _, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_PlayerESP" then
            hl.FillTransparency = on and 0.2 or 0.5
        end
    end
end)
makeToggle("2D Box", state.box2D, "visuals", function(on)
    state.box2D = on
    if not on then for _, box in pairs(state.boxes2D) do box.Visible = false end end
end)
makeToggle("Скелет", state.skeleton, "visuals", function(on)
    state.skeleton = on
    if not on then
        for _, skel in pairs(state.skeletons) do
            for _, bone in ipairs(skel) do bone.line.Visible = false end
        end
    end
end)

makeSectionLabel("▬ ОБЪЕКТЫ МИРА ▬", "visuals")
makeToggle("Генераторы", state.espGenerators, "visuals", function(on)
    state.espGenerators = on
    for inst, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_WorldESP" and classifyObject(inst) == "generator" then
            hl.Enabled = on and state.espEnabled
        end
    end
end)
makeToggle("Крюки", state.espHooks, "visuals", function(on)
    state.espHooks = on
    for inst, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_WorldESP" and classifyObject(inst) == "hook" then
            hl.Enabled = on and state.espEnabled
        end
    end
end)
makeToggle("Поддоны", state.espPallets, "visuals", function(on)
    state.espPallets = on
    for inst, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_WorldESP" and classifyObject(inst) == "pallet" then
            hl.Enabled = on and state.espEnabled
        end
    end
end)

makeSectionLabel("▬ ЦВЕТА ▬", "visuals")
makeColorButton("Цвет выживших", state.survivorColor, "visuals", function(col) state.survivorColor = col end)
makeColorButton("Цвет убийцы", state.killerColor, "visuals", function(col) state.killerColor = col end)
makeColorButton("Цвет генераторов", state.generatorColor, "visuals", function(col)
    state.generatorColor = col
    for inst, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_WorldESP" and classifyObject(inst) == "generator" then hl.FillColor = col end
    end
end)
makeColorButton("Цвет крюков", state.hookColor, "visuals", function(col)
    state.hookColor = col
    for inst, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_WorldESP" and classifyObject(inst) == "hook" then hl.FillColor = col end
    end
end)
makeColorButton("Цвет поддонов", state.palletColor, "visuals", function(col)
    state.palletColor = col
    for inst, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_WorldESP" and classifyObject(inst) == "pallet" then hl.FillColor = col end
    end
end)

-- ============== ВКЛАДКА "МИР" ==============
makeSectionLabel("▬ ОСВЕЩЕНИЕ ▬", "world")
makeToggle("Fullbright", state.fullbright, "world", function(on)
    state.fullbright = on; setFullbright(on)
end)
makeToggle("Убрать туман", state.noFog, "world", function(on)
    state.noFog = on; setNoFog(on)
end)
makeToggle("Убрать тени", state.noShadows, "world", function(on)
    state.noShadows = on; setNoShadows(on)
end)

makeSectionLabel("▬ КАМЕРА ▬", "world")
makeSlider("FOV", 60, 120, state.fovValue, "world", function(val)
    state.fovValue = val
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = val end
end)

makeSectionLabel("▬ HUD ▬", "world")
makeToggle("Оповещение об убийце", state.killerAlert, "world", function(on)
    state.killerAlert = on
    if not on then alertGui.Visible = false end
end)

-- ============== ВКЛАДКА "КОСМЕТИКА" ==============
makeSectionLabel("▬ ЭФФЕКТЫ ▬", "cosmetics")

local trailToggle = makeToggle("Трейл (шлейф)", state.effectTrail, "cosmetics", function(on)
    state.effectTrail = on
    if on then
        applyTrailEffect()
    else
        for _, e in ipairs(state.currentEffects) do
            if e.Name == "brieliVis_Trail" or e.Name:find("brieliVis_TrailAtt") then
                pcall(function() e:Destroy() end)
            end
        end
    end
end)

local particlesToggle = makeToggle("Частицы (искры)", state.effectParticles, "cosmetics", function(on)
    state.effectParticles = on
    if on then
        applyParticlesEffect()
    else
        for _, e in ipairs(state.currentEffects) do
            if e.Name == "brieliVis_Particles" then
                pcall(function() e:Destroy() end)
            end
        end
    end
end)

local auraToggle = makeToggle("Аура (луч)", state.effectAura, "cosmetics", function(on)
    state.effectAura = on
    if on then
        applyAuraEffect()
    else
        for _, e in ipairs(state.currentEffects) do
            if e.Name == "brieliVis_Aura" or e.Name == "brieliVis_AuraAtt" then
                pcall(function() e:Destroy() end)
            end
        end
    end
end)

makeActionButton("🗑 Убрать все эффекты", "cosmetics",
    Color3.fromRGB(140, 55, 55), function()
        clearEffects()
    end)

-- ============== ВКЛАДКА "РАЗНОЕ" ==============
makeSectionLabel("▬ ДВИЖЕНИЕ ▬", "misc")
makeToggle("Noclip (сквозь стены)", state.noclip, "misc", function(on)
    state.noclip = on
    if on then enableNoclip() else disableNoclip() end
end)

makeSectionLabel("▬ КРУТИЛКА ▬", "misc")

makeToggle("Включить вращение", state.spinEnabled, "misc", function(on)
    state.spinEnabled = on
    if on then startSpin() else stopSpin() end
end)

local spinDirFrame = Instance.new("Frame")
spinDirFrame.Size = UDim2.new(1, 0, 0, 50)
spinDirFrame.BackgroundColor3 = getTheme().row
spinDirFrame.BorderSizePixel = 0
spinDirFrame.Parent = contentScroll
spinDirFrame:SetAttribute("Tab", "misc")
spinDirFrame:SetAttribute("TR", "row")
round(spinDirFrame, 6)

local spinDirLabel = Instance.new("TextLabel")
spinDirLabel.Size = UDim2.new(1, -14, 0, 20)
spinDirLabel.Position = UDim2.new(0, 14, 0, 4)
spinDirLabel.BackgroundTransparency = 1
spinDirLabel.Text = "Направление"
spinDirLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
spinDirLabel.TextXAlignment = Enum.TextXAlignment.Left
spinDirLabel.Font = Enum.Font.GothamMedium
spinDirLabel.TextSize = 13
spinDirLabel.Parent = spinDirFrame

local dirRightBtn = Instance.new("TextButton")
dirRightBtn.Size = UDim2.new(0, 100, 0, 22)
dirRightBtn.Position = UDim2.new(0, 14, 0, 26)
dirRightBtn.BackgroundColor3 = getTheme().accent
dirRightBtn.BorderSizePixel = 0
dirRightBtn.Text = "➡ Вправо"
dirRightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dirRightBtn.Font = Enum.Font.GothamMedium
dirRightBtn.TextSize = 11
dirRightBtn.Parent = spinDirFrame
round(dirRightBtn, 6)

local dirLeftBtn = Instance.new("TextButton")
dirLeftBtn.Size = UDim2.new(0, 100, 0, 22)
dirLeftBtn.Position = UDim2.new(0, 120, 0, 26)
dirLeftBtn.BackgroundColor3 = getTheme().rowHov
dirLeftBtn.BorderSizePixel = 0
dirLeftBtn.Text = "⬅ Влево"
dirLeftBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
dirLeftBtn.Font = Enum.Font.GothamMedium
dirLeftBtn.TextSize = 11
dirLeftBtn.Parent = spinDirFrame
round(dirLeftBtn, 6)

dirRightBtn.MouseButton1Click:Connect(function()
    state.spinDirection = "right"
    dirRightBtn.BackgroundColor3 = getTheme().accent
    dirRightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dirLeftBtn.BackgroundColor3 = getTheme().rowHov
    dirLeftBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
end)

dirLeftBtn.MouseButton1Click:Connect(function()
    state.spinDirection = "left"
    dirLeftBtn.BackgroundColor3 = getTheme().accent
    dirLeftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dirRightBtn.BackgroundColor3 = getTheme().rowHov
    dirRightBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
end)

makeSlider("Скорость вращения", 40, 240, state.spinSpeed, "misc", function(val)
    state.spinSpeed = val
end)

-- ============== ВКЛАДКА "МЕНЮ" ==============
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 60)
infoLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
infoLabel.BorderSizePixel = 0
infoLabel.Text = "brieli vis\nViolence District Edition\n\n" ..
    "Клавиша меню: " .. state.menuKey.Name
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 13
infoLabel.Parent = contentScroll
infoLabel:SetAttribute("Tab", "menu")
round(infoLabel, 6)

makeSectionLabel("▬ ТЕМА МЕНЮ ▬", "menu")

local function makeThemeButton(text, themeKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = getTheme().row
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = contentScroll
    btn:SetAttribute("Tab", "menu")
    btn:SetAttribute("TR", "row")
    round(btn, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = btn

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 26, 0, 26)
    swatch.Position = UDim2.new(1, -40, 0.5, -13)
    swatch.BackgroundColor3 = THEMES[themeKey].accent
    swatch.BorderSizePixel = 0
    swatch.Parent = btn
    round(swatch, 4)

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = getTheme().rowHov end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = getTheme().row end)
    btn.MouseButton1Click:Connect(function()
        state.menuTheme = themeKey
        applyTheme()
    end)
end

local function applyTheme()
    local th = getTheme()
    for _, d in ipairs(screenGui:GetDescendants()) do
        local role = d:GetAttribute("TR")
        if role == "bg" then d.BackgroundColor3 = th.bg
        elseif role == "titleBg" then d.BackgroundColor3 = th.titleBg
        elseif role == "stroke" and d:IsA("UIStroke") then d.Color = th.stroke
        elseif role == "accentBg" then d.BackgroundColor3 = th.accent
        elseif role == "accentText" then d.TextColor3 = th.accent
        elseif role == "row" then d.BackgroundColor3 = th.row
        end
    end
    for id, btn in pairs(tabButtons) do
        local isActive = (id == state.currentTab)
        btn.BackgroundColor3 = isActive and th.tabAct or th.tabBg
    end
    contentScroll.ScrollBarImageColor3 = th.stroke
    for _, d in ipairs(screenGui:GetDescendants()) do
        if d.Name == "Fill" and d:IsA("Frame") then d.BackgroundColor3 = th.accent end
    end
end

makeThemeButton("Тёмно-синий", "blue")
makeThemeButton("Тёмно-фиолетовый", "purple")
makeThemeButton("Тёмно-зелёный", "green")
makeThemeButton("Тёмно-красный", "red")
makeThemeButton("Чёрный", "black")

makeSectionLabel("▬ КЛАВИША МЕНЮ ▬", "menu")

local keybindBtn = Instance.new("TextButton")
keybindBtn.Size = UDim2.new(1, 0, 0, 34)
keybindBtn.BackgroundColor3 = getTheme().row
keybindBtn.BorderSizePixel = 0
keybindBtn.AutoButtonColor = false
keybindBtn.Text = "  Изменить клавишу  (" .. state.menuKey.Name .. ")"
keybindBtn.TextColor3 = Color3.fromRGB(230, 230, 245)
keybindBtn.TextXAlignment = Enum.TextXAlignment.Left
keybindBtn.Font = Enum.Font.GothamMedium
keybindBtn.TextSize = 13
keybindBtn.Parent = contentScroll
keybindBtn:SetAttribute("Tab", "menu")
keybindBtn:SetAttribute("TR", "row")
round(keybindBtn, 6)

keybindBtn.MouseEnter:Connect(function() keybindBtn.BackgroundColor3 = getTheme().rowHov end)
keybindBtn.MouseLeave:Connect(function() keybindBtn.BackgroundColor3 = getTheme().row end)

local listeningForKey = false
keybindBtn.MouseButton1Click:Connect(function()
    if listeningForKey then return end
    listeningForKey = true
    keybindBtn.Text = "  Нажмите любую клавишу..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            state.menuKey = input.KeyCode
            keybindBtn.Text = "  Изменить клавишу  (" .. input.KeyCode.Name .. ")"
            infoLabel.Text = "brieli vis\nViolence District Edition\n\n" ..
                "Клавиша меню: " .. input.KeyCode.Name
            listeningForKey = false
            conn:Disconnect()
        end
    end)
end)

makeSectionLabel("▬ ОБСЛУЖИВАНИЕ ▬", "menu")

local rescanBtn = Instance.new("TextButton")
rescanBtn.Size = UDim2.new(1, 0, 0, 34)
rescanBtn.BackgroundColor3 = getTheme().row
rescanBtn.BorderSizePixel = 0
rescanBtn.AutoButtonColor = false
rescanBtn.Text = "  🔄 Пересканировать мир"
rescanBtn.TextColor3 = Color3.fromRGB(230, 230, 245)
rescanBtn.TextXAlignment = Enum.TextXAlignment.Left
rescanBtn.Font = Enum.Font.GothamMedium
rescanBtn.TextSize = 13
rescanBtn.Parent = contentScroll
rescanBtn:SetAttribute("Tab", "menu")
rescanBtn:SetAttribute("TR", "row")
round(rescanBtn, 6)

rescanBtn.MouseEnter:Connect(function() rescanBtn.BackgroundColor3 = getTheme().rowHov end)
rescanBtn.MouseLeave:Connect(function() rescanBtn.BackgroundColor3 = getTheme().row end)
rescanBtn.MouseButton1Click:Connect(function()
    for inst, hl in pairs(state.highlights) do
        if hl.Name == "brieliVis_WorldESP" then
            hl:Destroy(); state.highlights[inst] = nil
        end
    end
    initialScan()
    rescanBtn.Text = "  ✅ Готово!"
    task.wait(1.5)
    rescanBtn.Text = "  🔄 Пересканировать мир"
end)

local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(0, 130, 0, 28)
unloadBtn.Position = UDim2.new(1, -14, 1, -14)
unloadBtn.AnchorPoint = Vector2.new(1, 1)
unloadBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
unloadBtn.BorderSizePixel = 0
unloadBtn.AutoButtonColor = false
unloadBtn.Text = "Выгрузить"
unloadBtn.TextColor3 = Color3.fromRGB(255, 230, 230)
unloadBtn.Font = Enum.Font.GothamMedium
unloadBtn.TextSize = 13
unloadBtn.Parent = main
round(unloadBtn, 6)

unloadBtn.MouseEnter:Connect(function() unloadBtn.BackgroundColor3 = Color3.fromRGB(210, 70, 70) end)
unloadBtn.MouseLeave:Connect(function() unloadBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) end)

-- ============== ОПОВЕЩЕНИЕ ==============
local alertGui = Instance.new("TextLabel")
alertGui.Size = UDim2.new(0, 300, 0, 42)
alertGui.Position = UDim2.new(0.5, -150, 0, 70)
alertGui.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
alertGui.BackgroundTransparency = 0.1
alertGui.Text = "⚠  РЯДОМ УБИЙЦА  ⚠"
alertGui.TextColor3 = Color3.fromRGB(255, 255, 255)
alertGui.Font = Enum.Font.GothamBold
alertGui.TextSize = 18
alertGui.Visible = false
alertGui.Parent = screenGui
round(alertGui, 8)

-- ============== F1 / F2 ==============
ContextActionSvc:BindActionAtPriority("brieliVis_Checkpoint_Save",
    function(_, inputState)
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end
        if not state.checkpointBinds then
            return Enum.ContextActionResult.Pass
        end
        saveCheckpoint()
        return Enum.ContextActionResult.Sink
    end,
    false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.F1)

ContextActionSvc:BindActionAtPriority("brieliVis_Checkpoint_Go",
    function(_, inputState)
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end
        if not state.checkpointBinds then
            return Enum.ContextActionResult.Pass
        end
        goToCheckpoint()
        return Enum.ContextActionResult.Sink
    end,
    false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.F2)

-- ============== ВЫГРУЗКА ==============
local function unload()
    if state.unloaded then return end
    state.unloaded = true

    for _, c in ipairs(state.connections) do pcall(function() c:Disconnect() end) end
    state.connections = {}
    if renderConn then renderConn:Disconnect() end

    pcall(stopSpin)
    pcall(stopAutoEscape)
    pcall(disableNoclip)
    pcall(clearEffects)

    pcall(function()
        ContextActionSvc:UnbindAction("brieliVis_Checkpoint_Save")
        ContextActionSvc:UnbindAction("brieliVis_Checkpoint_Go")
    end)

    if state.checkpointMarker then pcall(function() state.checkpointMarker:Destroy() end) end

    for _, hl in pairs(state.highlights) do pcall(function() hl:Destroy() end) end
    state.highlights = {}
    for _, bb in pairs(state.billboards) do pcall(function() bb:Destroy() end) end
    state.billboards = {}
    for _, box in pairs(state.boxes2D) do pcall(function() box:Destroy() end) end
    state.boxes2D = {}
    for _, skel in pairs(state.skeletons) do
        for _, bone in ipairs(skel) do pcall(function() bone.line:Remove() end) end
    end
    state.skeletons = {}

    pcall(setFullbright, false)
    pcall(setNoFog, false)
    pcall(setNoShadows, false)

    if alertGui then pcall(function() alertGui:Destroy() end) end
    if screenGui then pcall(function() screenGui:Destroy() end) end

    _G.brieliVisUnload = nil
    print("[brieli vis] выгружен")
end

unloadBtn.MouseButton1Click:Connect(unload)
_G.brieliVisUnload = unload

-- ============== ПЕРЕКЛЮЧЕНИЕ МЕНЮ ==============
bind(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == state.menuKey then
        main.Visible = not main.Visible
    end
end))

-- ============== СТАРТ ==============
initialScan()

task.spawn(function()
    while not state.unloaded do
        task.wait(0.5)
        if not state.unloaded and state.killerAlert then
            local mc = LocalPlayer.Character
            local mr = mc and mc:FindFirstChild("HumanoidRootPart")
            if mr then
                local closest = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and state.roleCache[p] == "killer" then
                        local c = p.Character
                        local r = c and c:FindFirstChild("HumanoidRootPart")
                        if r then
                            local d = (r.Position - mr.Position).Magnitude
                            if d < closest then closest = d end
                        end
                    end
                end
                alertGui.Visible = (closest < 70)
            else
                alertGui.Visible = false
            end
        else
            alertGui.Visible = false
        end
    end
end)

switchTab("visuals")
print("[brieli vis] загружен. Правый Shift — меню.")

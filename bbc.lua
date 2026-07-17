print("[TycoonAutomator] Initializing script...")
-- ==========================================
-- EMBEDDED GUI FRAMEWORK v6.0 (Webhook Boss Analytics Patch)
-- ==========================================

if _G.AutomatorRunning ~= nil then
    _G.AutomatorRunning = false
    task.wait(1.5)
end
_G.AutomatorRunning = true

local Framework = {}
Framework.__index = Framework

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

while not Players.LocalPlayer do 
    task.wait(0.2) 
end
local LocalPlayer = Players.LocalPlayer

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local DEFAULT_THEME = {
    bg            = Color3.fromRGB(13, 13, 17),
    surface       = Color3.fromRGB(22, 22, 30),
    surfaceHover  = Color3.fromRGB(30, 30, 40),
    border        = Color3.fromRGB(42, 42, 58),
    borderActive  = Color3.fromRGB(130, 90, 255),
    textPrimary   = Color3.fromRGB(245, 245, 250),
    textSecondary = Color3.fromRGB(170, 170, 185),
    textMuted     = Color3.fromRGB(110, 110, 125),
    accent        = Color3.fromRGB(138, 98, 255),
    accentSurface = Color3.fromRGB(45, 30, 85),
    danger        = Color3.fromRGB(255, 85, 85),
    dangerDim     = Color3.fromRGB(85, 25, 25),
    warning       = Color3.fromRGB(255, 190, 60),
    warningDim     = Color3.fromRGB(85, 60, 20),
    info          = Color3.fromRGB(60, 170, 255),
    infoDim       = Color3.fromRGB(20, 55, 90),
    titleBar      = Color3.fromRGB(17, 17, 22),
    dotOff        = Color3.fromRGB(65, 65, 85),
    dotOn         = Color3.fromRGB(138, 98, 255),
}

local TWEEN_FAST   = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local delayTimer = function(t) task.wait(math.max(t or 0.1, 0.05)) end

local function tween(obj, props, info)
    pcall(function() TweenService:Create(obj, info or TWEEN_FAST, props):Play() end)
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

local function parseCashString(text)
    if not text or text == "" then return 0 end
    local clean = string.gsub(tostring(text), "[%$%,%s]", "")
    local numMatch = string.match(clean, "^%d+%.?%d*")
    local num = tonumber(numMatch) or 0
    local suffix = string.match(clean, "%a+$")
    
    if suffix then
        suffix = suffix:lower()
        if suffix == "k" then num = num * 1000
        elseif suffix == "m" then num = num * 1000000
        elseif suffix == "b" then num = num * 1000000000
        elseif suffix == "t" then num = num * 1000000000000
        end
    end
    return math.floor(num)
end

local function parseTimeBudget(text)
    if not text or text == "" then return 600 end
    local numMatch = string.match(tostring(text), "^%d+")
    local num = tonumber(numMatch) or 10
    local suffix = string.match(tostring(text), "%a+$")
    if suffix then
        suffix = suffix:lower()
        if suffix == "m" then num = num * 60
        elseif suffix == "h" then num = num * 3600
        elseif suffix == "s" then num = num * 1
        end
    end
    return num
end

local function formatNumber(value)
    local num = math.floor(tonumber(value) or 0)
    local str = tostring(math.abs(num))
    local formatted = ""
    
    while #str > 3 do
        formatted = "," .. string.sub(str, -3) .. formatted
        str = string.sub(str, 1, #str - 3)
    end
    formatted = str .. formatted
    return (num < 0 and "-" or "") .. formatted
end

-- ==========================================
-- DYNAMIC STRUCTURE REGISTER LISTS
-- ==========================================
local ALL_BUY_STRUCTURES = {
    "Corporate Campus", "Luxury Resort", "Semiconductor Plant", "Cookie Stand",
    "Shield Generator", "Behemoth Fortress", "Officer Quarters", "Fleet Command",
    "Heavy Weapons Depot", "Naval Shipyard", "ATC Tower", "Field Tent",
    "Regional Depot", "Cargo Dockyard", "Advanced Supply Depot"
}

local LEGACY_TRUE_DISMANTLE = {
    ["Cookie Stand"] = true, ["Shield Generator"] = true, ["Behemoth Fortress"] = true,
    ["Officer Quarters"] = true, ["Fleet Command"] = true, ["Heavy Weapons Depot"] = true,
    ["Naval Shipyard"] = true, ["ATC Tower"] = true, ["Field Tent"] = true,
    ["Cobra Helipad"] = true, ["Tank Warehouse"] = true
}

local ALL_DISMANTLE_STRUCTURES = {
    "Corporate Campus", "Luxury Resort", "Semiconductor Plant", "Cookie Stand",
    "Shield Generator", "Behemoth Fortress", "Officer Quarters", "Fleet Command",
    "Heavy Weapons Depot", "Naval Shipyard", "ATC Tower", "Field Tent",
    "Regional Depot", "Cargo Dockyard", "Advanced Supply Depot", "Cobra Helipad", 
    "Tank Warehouse", "Energy Node"
}

local ALL_CRATE_TYPES = {"Elite", "Titan", "Decorative", "Standard", "Golden"}

-- ==========================================
-- PERSISTENT SETTINGS CONFIG ENGINE
-- ==========================================
local ConfigFileName = "AutomatorConfig_Tycoon.json"
local SavedConfig = {
    AutoCollect = false,
    AutoBuy = false,
    AutoDismantle = false,
    AutoCrate = false,
    AutoPlaytime = false,
    AutoRebirth = false,
    AutoBuyPlots = false,
    PlotLoadInterval = 10,
    CrateInterval = 5,
    BossHopActive = false,
    BossHopTimeoutText = "10m",
    BossHopTimeoutSeconds = 600,
    WebhookURL = "https://discord.com/api/webhooks/1526157590445166643/C8p3HqSdBMMJeJiuwkyHYvbK_2azl_eVAPaIOkQln0_U2Qx9xckIPU0HGmtUu9OhYRG0",
    CrateType = "Elite",
    CrateMinCashRequirement = 5000000000,
    CrateMinCashText = "5B",
    CrateBatchSize = 10000,
    CrateBatchSizeText = "10K",
    DisconnectCount = 0,
    TotalSessionEarned = 0,
    TotalSessionTime = 0,
    BossesKilled = 0,    -- Added Persistent Tracking
    BossesSkipped = 0,   -- Added Persistent Tracking
    TotalRebirths = 0,
    SelectedBuyItems = {},
    SelectedDismantleItems = {},
    SelectedCrateTypes = {},
    CustomDismantleItems = {}
}

local function loadSettings()
    if readfile and pcall(function() return readfile(ConfigFileName) end) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do
                SavedConfig[k] = v
            end
        end
    end
    if not SavedConfig.BossesKilled then SavedConfig.BossesKilled = 0 end
    if not SavedConfig.BossesSkipped then SavedConfig.BossesSkipped = 0 end
    if not SavedConfig.TotalRebirths then SavedConfig.TotalRebirths = 0 end
    if not SavedConfig.PlotLoadInterval then SavedConfig.PlotLoadInterval = 10 end
    if not SavedConfig.CrateInterval then SavedConfig.CrateInterval = 5 end
    if not SavedConfig.CrateBatchSize then SavedConfig.CrateBatchSize = 10000 end
    if not SavedConfig.CrateBatchSizeText then SavedConfig.CrateBatchSizeText = "10K" end
    if not SavedConfig.WebhookURL then SavedConfig.WebhookURL = "https://discord.com/api/webhooks/1526157590445166643/C8p3HqSdBMMJeJiuwkyHYvbK_2azl_eVAPaIOkQln0_U2Qx9xckIPU0HGmtUu9OhYRG0" end
    if not SavedConfig.SelectedBuyItems or next(SavedConfig.SelectedBuyItems) == nil then
        SavedConfig.SelectedBuyItems = {}
        for _, name in ipairs(ALL_BUY_STRUCTURES) do SavedConfig.SelectedBuyItems[name] = true end
    end
    if not SavedConfig.SelectedDismantleItems or next(SavedConfig.SelectedDismantleItems) == nil then
        SavedConfig.SelectedDismantleItems = {}
        for _, name in ipairs(ALL_DISMANTLE_STRUCTURES) do 
            if LEGACY_TRUE_DISMANTLE[name] then
                SavedConfig.SelectedDismantleItems[name] = true 
            else
                SavedConfig.SelectedDismantleItems[name] = false
            end
        end
    end
    if not SavedConfig.CustomDismantleItems then
        SavedConfig.CustomDismantleItems = {}
    end

    if not SavedConfig.SelectedCrateTypes or type(SavedConfig.SelectedCrateTypes) ~= "table" then
        SavedConfig.SelectedCrateTypes = {}
    end

    local hasSelected = false
    for _, name in ipairs(ALL_CRATE_TYPES) do
        if SavedConfig.SelectedCrateTypes[name] == nil then
            SavedConfig.SelectedCrateTypes[name] = false
        end
        if SavedConfig.SelectedCrateTypes[name] then
            hasSelected = true
        end
    end
    if not hasSelected then
        SavedConfig.SelectedCrateTypes["Elite"] = true
    end
end

local function saveSettings()
    if writefile then
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(SavedConfig))
        end)
    end
end

loadSettings()
print("[TycoonAutomator] Settings loaded!")

local function syncTenCrateState()
    local LootCrateRemotes = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Resources")
        and ReplicatedStorage.Shared.Resources:FindFirstChild("LootCrateResources")
        and ReplicatedStorage.Shared.Resources.LootCrateResources:FindFirstChild("Remotes")
        
    local ToggleTenEvent = LootCrateRemotes and LootCrateRemotes:FindFirstChild("ToggleTenOpen")
    if ToggleTenEvent then
        pcall(function() ToggleTenEvent:FireServer() end)
    end
end

function Framework:CreateWindow(config)
    config = config or {}
    local theme = DEFAULT_THEME
    local title    = config.Title or "WINDOW"
    local width    = (config.Size and config.Size[1]) or 280
    local height   = (config.Size and config.Size[2]) or 450
    local posX     = (config.Position and config.Position[1]) or 0.1
    local posY     = (config.Position and config.Position[2]) or 0.2

    local targetParent = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    local guiName = title:gsub("%s+", "") .. "_GUI"
    local old = targetParent:FindFirstChild(guiName)
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = guiName
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = targetParent

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Parent = screenGui
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(posX, -8, posY, -8)
    shadow.Size = UDim2.new(0, width + 16, 0, height + 16)
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = theme.bg
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(posX, 0, posY, 0)
    mainFrame.Size = UDim2.new(0, width, 0, height)
    mainFrame.Active = true
    mainFrame.Draggable = true

    corner(mainFrame, 10)
    stroke(mainFrame, theme.border, 1)

    mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        shadow.Position = mainFrame.Position + UDim2.new(0, -8, 0, -8)
    end)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.BackgroundColor3 = theme.titleBar
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 38)

    local accentLine = Instance.new("Frame")
    accentLine.Parent = titleBar
    accentLine.BackgroundColor3 = theme.accent
    accentLine.BorderSizePixel = 0
    accentLine.Size = UDim2.new(1, 0, 0, 2)

    local titleDot = Instance.new("Frame")
    titleDot.Parent = titleBar
    titleDot.BackgroundColor3 = theme.accent
    titleDot.BorderSizePixel = 0
    titleDot.Position = UDim2.new(0, 14, 0.5, -4)
    titleDot.Size = UDim2.new(0, 8, 0, 8)
    corner(titleDot, 4)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = titleBar
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 28, 0, 2)
    titleLabel.Size = UDim2.new(1, -80, 1, -2)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = string.upper(title)
    titleLabel.TextColor3 = theme.textPrimary
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Parent = mainFrame
    tabBar.BackgroundColor3 = theme.bg
    tabBar.BorderSizePixel = 0
    tabBar.Position = UDim2.new(0, 0, 0, 38)
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = tabBar
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    padding(tabBar, 2, 2, 10, 10)

    local viewContainer = Instance.new("Frame")
    viewContainer.Name = "ViewContainer"
    viewContainer.Parent = mainFrame
    viewContainer.BackgroundTransparency = 1
    viewContainer.Position = UDim2.new(0, 0, 0, 72)
    viewContainer.Size = UDim2.new(1, 0, 1, -76)

    local Window = {}
    Window.__index = Window
    Window._screenGui = screenGui
    Window._mainFrame = mainFrame
    Window._viewContainer = viewContainer
    Window._tabBar = tabBar
    Window._theme = theme
    Window._tabs = {}
    Window._activeTab = nil

    local visibleState = true
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.N then
            visibleState = not visibleState
            mainFrame.Visible = visibleState
            shadow.Visible = visibleState
        end
    end)

    function Window:CreateTab(tabName)
        local tabOrder = #self._tabs + 1
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Parent = self._tabBar
        tabBtn.BackgroundColor3 = theme.surface
        tabBtn.BorderSizePixel = 0
        tabBtn.Size = UDim2.new(0, 84, 1, 0)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Text = tabName
        tabBtn.TextSize = 10
        tabBtn.TextColor3 = theme.textSecondary
        tabBtn.LayoutOrder = tabOrder
        corner(tabBtn, 4)
        
        local scroller = Instance.new("ScrollingFrame")
        scroller.Name = tabName .. "_Container"
        scroller.Parent = self._viewContainer
        scroller.BackgroundTransparency = 1
        scroller.Size = UDim2.new(1, 0, 1, 0)
        scroller.ScrollBarThickness = 4
        scroller.ScrollBarImageColor3 = theme.border
        scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroller.Visible = false
        scroller.ClipsDescendants = true
        padding(scroller, 0, 12, 14, 14)

        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = scroller
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 6)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 25)
        end)

        local Tab = {}
        Tab._container = scroller
        Tab._order = 0
        Tab._theme = theme

        local function selectTab()
            if Window._activeTab then
                Window._activeTab._container.Visible = false
                Window._activeTab._btn.BackgroundColor3 = theme.surface
                Window._activeTab._btn.TextColor3 = theme.textSecondary
            end
            Window._activeTab = Tab
            scroller.Visible = true
            tabBtn.BackgroundColor3 = theme.accentSurface
            tabBtn.TextColor3 = theme.accent
        end

        tabBtn.MouseButton1Click:Connect(selectTab)
        Tab._btn = tabBtn
        
        if tabOrder == 1 then selectTab() end

        function Tab:AddToggle(cfg)
            cfg = cfg or {}
            self._order = self._order + 1
            local state = cfg.Default or false
            local offText = cfg.OffText or cfg.Text or "Toggle: OFF"
            local onText  = cfg.OnText or cfg.Text or "Toggle: ON"

            local btn = Instance.new("TextButton")
            btn.Parent = self._container
            btn.BackgroundColor3 = theme.surface
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(1, 0, 0, 36)
            btn.Text = ""
            btn.LayoutOrder = self._order
            corner(btn, 6)
            local btnStroke = stroke(btn, theme.border, 1)

            local dot = Instance.new("Frame")
            dot.Parent = btn
            dot.BackgroundColor3 = theme.dotOff
            dot.Position = UDim2.new(0, 12, 0.5, -4)
            dot.Size = UDim2.new(0, 8, 0, 8)
            corner(dot, 4)

            local label = Instance.new("TextLabel")
            label.Parent = btn
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 28, 0, 0)
            label.Size = UDim2.new(1, -40, 1, 0)
            label.Font = Enum.Font.GothamMedium
            label.Text = state and onText or offText
            label.TextColor3 = state and theme.textPrimary or theme.textSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left

            local function updateVisual()
                if state then
                    label.Text = onText
                    tween(label, {TextColor3 = theme.textPrimary})
                    tween(btn, {BackgroundColor3 = theme.accentSurface})
                    tween(btnStroke, {Color = theme.borderActive})
                    tween(dot, {BackgroundColor3 = theme.dotOn})
                else
                    label.Text = offText
                    tween(label, {TextColor3 = theme.textSecondary})
                    tween(btn, {BackgroundColor3 = theme.surface})
                    tween(btnStroke, {Color = theme.border})
                    tween(dot, {BackgroundColor3 = theme.dotOff})
                end
            end

            if state then updateVisual() end

            btn.MouseButton1Click:Connect(function()
                state = not state
                updateVisual()
                if cfg.Callback then cfg.Callback(state) end
            end)

            return {SetState = function(_, ns) state = ns; updateVisual() end}
        end

        function Tab:AddDropdown(titleText, itemsList, savedTargetTable, updateCallback)
            self._order = self._order + 1
            local baseZIndex = 100 - self._order
            
            local dropContainer = Instance.new("Frame")
            dropContainer.Parent = self._container
            dropContainer.BackgroundColor3 = theme.surface
            dropContainer.Size = UDim2.new(1, 0, 0, 36)
            dropContainer.LayoutOrder = self._order
            dropContainer.ZIndex = baseZIndex
            dropContainer.ClipsDescendants = false
            corner(dropContainer, 6)
            local dropStroke = stroke(dropContainer, theme.border, 1)
            
            local label = Instance.new("TextLabel")
            label.Parent = dropContainer
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(0.6, -12, 1, 0)
            label.Font = Enum.Font.GothamMedium
            label.Text = titleText
            label.TextColor3 = theme.textSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = baseZIndex + 1
            
            local arrow = Instance.new("TextLabel")
            arrow.Parent = dropContainer
            arrow.BackgroundTransparency = 1
            arrow.Position = UDim2.new(1, -24, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.Font = Enum.Font.GothamBold
            arrow.Text = "▼"
            arrow.TextColor3 = theme.textMuted
            arrow.TextSize = 10
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = baseZIndex + 1

            local triggerBtn = Instance.new("TextButton")
            triggerBtn.Parent = dropContainer
            triggerBtn.BackgroundTransparency = 1
            triggerBtn.Size = UDim2.new(1, 0, 1, 0)
            triggerBtn.Text = ""
            triggerBtn.ZIndex = baseZIndex + 2
            
            local scrollList = Instance.new("ScrollingFrame")
            scrollList.Parent = screenGui
            scrollList.BackgroundColor3 = theme.surface
            scrollList.BorderColor3 = theme.border
            scrollList.Position = UDim2.new(0, 0, 0, 0)
            local listHeight = math.min(26 * #itemsList + 24, 180)
            scrollList.Size = UDim2.new(0, 0, 0, listHeight)
            scrollList.Visible = false
            scrollList.ZIndex = 300
            scrollList.ScrollBarThickness = 7
            scrollList.ScrollBarImageColor3 = theme.accent
            scrollList.Active = true
            scrollList.ScrollingEnabled = true
            scrollList.VerticalScrollBarInset = Enum.ScrollBarInset.Always
            scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
            scrollList.ClipsDescendants = true
            corner(scrollList, 6)
            stroke(scrollList, theme.border, 1)
            
            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = scrollList
            listLayout.SortOrder = Enum.SortOrder.Name
            listLayout.Padding = UDim.new(0, 2)
            padding(scrollList, 4, 4, 6, 6)
            scrollList.ScrollingEnabled = true

            local function refreshCount()
                local count = 0
                for _, active in pairs(savedTargetTable) do if active then count = count + 1 end end
                arrow.Text = isOpen and "▲" or "▼"
                label.Text = titleText .. " (" .. tostring(count) .. " Active)"
            end

            local function spawnRow(itemName)
                if savedTargetTable[itemName] == nil then 
                    if LEGACY_TRUE_DISMANTLE[itemName] then
                        savedTargetTable[itemName] = true 
                    else
                        savedTargetTable[itemName] = false
                    end
                end
                
                local row = Instance.new("TextButton")
                row.Name = itemName
                row.Parent = scrollList
                row.BackgroundColor3 = savedTargetTable[itemName] and theme.accentSurface or theme.bg
                row.Size = UDim2.new(1, 0, 0, 26)
                row.Text = ""
                row.ZIndex = 305
                corner(row, 4)
                
                local checkDot = Instance.new("Frame")
                checkDot.Parent = row
                checkDot.BackgroundColor3 = savedTargetTable[itemName] and theme.accent or theme.dotOff
                checkDot.Position = UDim2.new(0, 8, 0.5, -3)
                checkDot.Size = UDim2.new(0, 6, 0, 6)
                corner(checkDot, 3)
                checkDot.ZIndex = 306
                
                local txt = Instance.new("TextLabel")
                txt.Parent = row
                txt.BackgroundTransparency = 1
                txt.Position = UDim2.new(0, 22, 0, 0)
                txt.Size = UDim2.new(1, -26, 1, 0)
                txt.Font = Enum.Font.GothamMedium
                txt.Text = itemName
                txt.TextColor3 = savedTargetTable[itemName] and theme.textPrimary or theme.textSecondary
                txt.TextSize = 10
                txt.TextXAlignment = Enum.TextXAlignment.Left
                txt.ZIndex = 306
                
                row.MouseButton1Click:Connect(function()
                    savedTargetTable[itemName] = not savedTargetTable[itemName]
                    saveSettings()
                    row.BackgroundColor3 = savedTargetTable[itemName] and theme.accentSurface or theme.bg
                    checkDot.BackgroundColor3 = savedTargetTable[itemName] and theme.accent or theme.dotOff
                    txt.TextColor3 = savedTargetTable[itemName] and theme.textPrimary or theme.textSecondary
                    refreshCount()
                    if updateCallback then updateCallback() end
                end)
            end

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
            end)
            
            local isOpen = false
            
            for _, itemName in ipairs(itemsList) do
                spawnRow(itemName)
            end

            triggerBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local cam = workspace.CurrentCamera
                    local screenHeight = (cam and cam.ViewportSize.Y) or 1080
                    local dropPos = dropContainer.AbsolutePosition
                    local dropSize = dropContainer.AbsoluteSize
                    scrollList.Size = UDim2.new(0, dropSize.X, 0, listHeight)
                    if dropPos.Y + dropSize.Y + listHeight + 4 > screenHeight then
                        scrollList.Position = UDim2.new(0, dropPos.X, 0, dropPos.Y - listHeight - 2)
                    else
                        scrollList.Position = UDim2.new(0, dropPos.X, 0, dropPos.Y + dropSize.Y + 2)
                    end
                end
                scrollList.Visible = isOpen
                
                dropContainer.ZIndex = isOpen and 250 or baseZIndex
                label.ZIndex = isOpen and 251 or baseZIndex + 1
                arrow.ZIndex = isOpen and 251 or baseZIndex + 1
                triggerBtn.ZIndex = isOpen and 252 or baseZIndex + 2
                
                tween(dropStroke, {Color = isOpen and theme.borderActive or theme.border})
                refreshCount()
            end)
            
            refreshCount()
            return {
                Frame = dropContainer,
                InjectItem = function(_, newName)
                    spawnRow(newName)
                    refreshCount()
                end
            }
        end

        function Tab:AddSelectionDropdown(titleText, itemsList, selectedValue, updateCallback)
            self._order = self._order + 1
            local baseZIndex = 100 - self._order
            local dropContainer = Instance.new("Frame")
            dropContainer.Parent = self._container
            dropContainer.BackgroundColor3 = theme.surface
            dropContainer.Size = UDim2.new(1, 0, 0, 36)
            dropContainer.LayoutOrder = self._order
            dropContainer.ZIndex = baseZIndex
            dropContainer.ClipsDescendants = false
            corner(dropContainer, 6)
            local dropStroke = stroke(dropContainer, theme.border, 1)

            local label = Instance.new("TextLabel")
            label.Parent = dropContainer
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -40, 1, 0)
            label.Font = Enum.Font.GothamMedium
            label.Text = titleText .. ": " .. tostring(selectedValue or "")
            label.TextColor3 = theme.textSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = baseZIndex + 1

            local arrow = Instance.new("TextLabel")
            arrow.Parent = dropContainer
            arrow.BackgroundTransparency = 1
            arrow.Position = UDim2.new(1, -24, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.Font = Enum.Font.GothamBold
            arrow.Text = "▼"
            arrow.TextColor3 = theme.textMuted
            arrow.TextSize = 10
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = baseZIndex + 1

            local triggerBtn = Instance.new("TextButton")
            triggerBtn.Parent = dropContainer
            triggerBtn.BackgroundTransparency = 1
            triggerBtn.Size = UDim2.new(1, 0, 1, 0)
            triggerBtn.Text = ""
            triggerBtn.ZIndex = baseZIndex + 2

            local scrollList = Instance.new("ScrollingFrame")
            scrollList.Parent = screenGui
            scrollList.BackgroundColor3 = theme.surface
            scrollList.BorderColor3 = theme.border
            scrollList.Position = UDim2.new(0, 0, 0, 0)
            local listHeight = math.min(26 * #itemsList + 12, 170)
            scrollList.Size = UDim2.new(0, 0, 0, listHeight)
            scrollList.Visible = false
            scrollList.ZIndex = 300
            scrollList.ScrollBarThickness = 7
            scrollList.ScrollBarImageColor3 = theme.accent
            scrollList.Active = true
            scrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scrollList.ClipsDescendants = true
            corner(scrollList, 6)
            stroke(scrollList, theme.border, 1)

            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = scrollList
            listLayout.SortOrder = Enum.SortOrder.Name
            listLayout.Padding = UDim.new(0, 2)
            padding(scrollList, 4, 4, 6, 6)

            local function refreshDisplay()
                label.Text = titleText .. ": " .. tostring(selectedValue or "")
                arrow.Text = isOpen and "▲" or "▼"
            end

            local function updateRows()
                for _, child in ipairs(scrollList:GetChildren()) do
                    if child:IsA("TextButton") then
                        local dot = child:FindFirstChild("CheckDot")
                        local textLabel = child:FindFirstChild("ItemText")
                        local isSelected = child.Name == selectedValue
                        child.BackgroundColor3 = isSelected and theme.accentSurface or theme.bg
                        if dot then dot.BackgroundColor3 = isSelected and theme.accent or theme.dotOff end
                        if textLabel then textLabel.TextColor3 = isSelected and theme.textPrimary or theme.textSecondary end
                    end
                end
            end

            local function spawnRow(itemName)
                local row = Instance.new("TextButton")
                row.Name = itemName
                row.Parent = scrollList
                row.BackgroundColor3 = itemName == selectedValue and theme.accentSurface or theme.bg
                row.Size = UDim2.new(1, 0, 0, 26)
                row.Text = ""
                row.ZIndex = 305
                corner(row, 4)

                local checkDot = Instance.new("Frame")
                checkDot.Name = "CheckDot"
                checkDot.Parent = row
                checkDot.BackgroundColor3 = itemName == selectedValue and theme.accent or theme.dotOff
                checkDot.Position = UDim2.new(0, 8, 0.5, -3)
                checkDot.Size = UDim2.new(0, 6, 0, 6)
                corner(checkDot, 3)
                checkDot.ZIndex = 306

                local txt = Instance.new("TextLabel")
                txt.Name = "ItemText"
                txt.Parent = row
                txt.BackgroundTransparency = 1
                txt.Position = UDim2.new(0, 22, 0, 0)
                txt.Size = UDim2.new(1, -26, 1, 0)
                txt.Font = Enum.Font.GothamMedium
                txt.Text = itemName
                txt.TextColor3 = itemName == selectedValue and theme.textPrimary or theme.textSecondary
                txt.TextSize = 10
                txt.TextXAlignment = Enum.TextXAlignment.Left
                txt.ZIndex = 306

                row.MouseButton1Click:Connect(function()
                    selectedValue = itemName
                    if updateCallback then updateCallback(selectedValue) end
                    refreshDisplay()
                    updateRows()
                    isOpen = false
                    scrollList.Visible = false
                    dropContainer.ZIndex = baseZIndex
                    label.ZIndex = baseZIndex + 1
                    arrow.ZIndex = baseZIndex + 1
                    triggerBtn.ZIndex = baseZIndex + 2
                    tween(dropStroke, {Color = theme.border})
                end)
            end

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
            end)

            local isOpen = false
            for _, itemName in ipairs(itemsList) do
                spawnRow(itemName)
            end

            triggerBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local cam = workspace.CurrentCamera
                    local screenHeight = (cam and cam.ViewportSize.Y) or 1080
                    local dropPos = dropContainer.AbsolutePosition
                    local dropSize = dropContainer.AbsoluteSize
                    local listHeight = math.min(26 * #itemsList + 12, 170)
                    scrollList.Size = UDim2.new(0, dropSize.X, 0, listHeight)
                    if dropPos.Y + dropSize.Y + listHeight + 4 > screenHeight then
                        scrollList.Position = UDim2.new(0, dropPos.X, 0, dropPos.Y - listHeight - 2)
                    else
                        scrollList.Position = UDim2.new(0, dropPos.X, 0, dropPos.Y + dropSize.Y + 2)
                    end
                end
                scrollList.Visible = isOpen

                dropContainer.ZIndex = isOpen and 250 or baseZIndex
                label.ZIndex = isOpen and 251 or baseZIndex + 1
                arrow.ZIndex = isOpen and 251 or baseZIndex + 1
                triggerBtn.ZIndex = isOpen and 252 or baseZIndex + 2

                tween(dropStroke, {Color = isOpen and theme.borderActive or theme.border})
                refreshDisplay()
            end)

            refreshDisplay()
            return {
                SetValue = function(_, newValue)
                    selectedValue = newValue
                    updateRows()
                    refreshDisplay()
                end
            }
        end

        function Tab:AddButton(cfg)
            cfg = cfg or {}
            self._order = self._order + 1

            local btn = Instance.new("TextButton")
            btn.Parent = self._container
            btn.BackgroundColor3 = theme.surface
            btn.Size = UDim2.new(1, 0, 0, 36)
            btn.Text = ""
            btn.LayoutOrder = self._order
            corner(btn, 6)
            local btnStroke = stroke(btn, theme.border, 1)

            local dot = Instance.new("Frame")
            dot.Parent = btn
            dot.BackgroundColor3 = cfg.DotColor or theme.info
            dot.Position = UDim2.new(0, 12, 0.5, -4)
            dot.Size = UDim2.new(0, 8, 0, 8)
            corner(dot, 4)

            local label = Instance.new("TextLabel")
            label.Parent = btn
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 28, 0, 0)
            label.Size = UDim2.new(1, -40, 1, 0)
            label.Font = Enum.Font.GothamMedium
            label.Text = cfg.Text or "Button"
            label.TextColor3 = theme.textSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left

            local handle = {}
            function handle:SetState(stateType, text)
                if text then label.Text = text end
                if stateType == "loading" then
                    tween(btn, {BackgroundColor3 = theme.warningDim})
                    tween(btnStroke, {Color = theme.warning})
                elseif stateType == "success" then
                    tween(btn, {BackgroundColor3 = theme.accentSurface})
                    tween(btnStroke, {Color = theme.borderActive})
                elseif stateType == "reset" then
                    tween(btn, {BackgroundColor3 = theme.surface})
                    tween(btnStroke, {Color = theme.border})
                end
            end

            btn.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback(handle) end end)
            return handle
        end

        function Tab:AddInputField(titleText, defaultText, callback)
            self._order = self._order + 1

            local container = Instance.new("Frame")
            container.Parent = self._container
            container.BackgroundColor3 = theme.surface
            container.Size = UDim2.new(1, 0, 0, 36)
            container.LayoutOrder = self._order
            corner(container, 6)
            local containerStroke = stroke(container, theme.border, 1)

            local label = Instance.new("TextLabel")
            label.Parent = container
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(0.5, -12, 1, 0)
            label.Font = Enum.Font.GothamMedium
            label.Text = titleText
            label.TextColor3 = theme.textSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left

            local box = Instance.new("TextBox")
            box.Parent = container
            box.BackgroundTransparency = 1
            box.Position = UDim2.new(0.5, 0, 0, 0)
            box.Size = UDim2.new(0.5, -12, 1, 0)
            box.Font = Enum.Font.GothamBold
            box.Text = defaultText or ""
            box.TextColor3 = theme.accent
            box.TextSize = 11
            box.TextXAlignment = Enum.TextXAlignment.Right
            box.ClearTextOnFocus = false

            box.Focused:Connect(function() tween(containerStroke, {Color = theme.borderActive}) end)
            box.FocusLost:Connect(function() tween(containerStroke, {Color = theme.border}); if callback then callback(box.Text) end end)

            return {}
        end

        function Tab:AddLabel(text, cfg)
            cfg = cfg or {}
            self._order = self._order + 1

            local label = Instance.new("TextLabel")
            label.Parent = self._container
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 0, cfg.Height or 20)
            label.Font = cfg.Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
            label.Text = text or ""
            label.TextColor3 = cfg.Color or theme.textMuted
            label.TextSize = cfg.TextSize or 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.LayoutOrder = self._order

            return {SetText = function(_, t) label.Text = t end}
        end

        function Tab:AddDisplayCard(titleText, defaultVal, dotColor)
            self._order = self._order + 1
            
            local card = Instance.new("Frame")
            card.Parent = self._container
            card.BackgroundColor3 = theme.surface
            card.Size = UDim2.new(1, 0, 0, 42)
            card.LayoutOrder = self._order
            corner(card, 6)
            stroke(card, theme.border, 1)
            padding(card, 0, 0, 12, 12)
            
            local dot = Instance.new("Frame")
            dot.Parent = card
            dot.BackgroundColor3 = dotColor or theme.textMuted
            dot.Position = UDim2.new(0, 0, 0.5, -4)
            dot.Size = UDim2.new(0, 8, 0, 8)
            corner(dot, 4)
            
            local titleLbl = Instance.new("TextLabel")
            titleLbl.Parent = card
            titleLbl.BackgroundTransparency = 1
            titleLbl.Position = UDim2.new(0, 16, 0.15, 0)
            titleLbl.Size = UDim2.new(1, -20, 0, 14)
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.Text = string.upper(titleText)
            titleLbl.TextColor3 = theme.textMuted
            titleLbl.TextSize = 9
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local valLbl = Instance.new("TextLabel")
            valLbl.Parent = card
            valLbl.BackgroundTransparency = 1
            valLbl.Position = UDim2.new(0, 16, 0.48, 0)
            valLbl.Size = UDim2.new(1, -20, 0, 18)
            valLbl.Font = Enum.Font.GothamMedium
            valLbl.Text = defaultVal or "---"
            valLbl.TextColor3 = theme.textPrimary
            valLbl.TextSize = 12
            valLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            return {Update = function(_, newVal) valLbl.Text = tostring(newVal) end}
        end

        function Tab:AddSlider(titleText, cfg)
            cfg = cfg or {}
            self._order = self._order + 1
            
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local val = cfg.Default or min
            
            local container = Instance.new("Frame")
            container.Parent = self._container
            container.BackgroundColor3 = theme.surface
            container.Size = UDim2.new(1, 0, 0, 48)
            container.LayoutOrder = self._order
            corner(container, 6)
            stroke(container, theme.border, 1)
            
            local label = Instance.new("TextLabel")
            label.Parent = container
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 4)
            label.Size = UDim2.new(1, -24, 0, 14)
            label.Font = Enum.Font.GothamMedium
            label.Text = titleText .. " : " .. tostring(val)
            label.TextColor3 = theme.textSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            
            local sliderBg = Instance.new("Frame")
            sliderBg.Parent = container
            sliderBg.BackgroundColor3 = theme.bg
            sliderBg.Position = UDim2.new(0, 12, 0, 26)
            sliderBg.Size = UDim2.new(1, -24, 0, 8)
            corner(sliderBg, 4)
            stroke(sliderBg, theme.border, 1)
            
            local fill = Instance.new("Frame")
            fill.Parent = sliderBg
            fill.BackgroundColor3 = theme.accent
            fill.Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0)
            corner(fill, 4)
            
            local dragger = Instance.new("TextButton")
            dragger.Parent = sliderBg
            dragger.BackgroundColor3 = theme.textPrimary
            dragger.Position = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), -6, 0.5, -6)
            dragger.Size = UDim2.new(0, 12, 0, 12)
            dragger.Text = ""
            corner(dragger, 6)
            
            local dragging = false
            
            local function updateSlider(input, triggerCallback)
                local percent = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                val = math.floor(min + (max - min) * percent)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                dragger.Position = UDim2.new(percent, -6, 0.5, -6)
                label.Text = titleText .. " : " .. tostring(val)
                if triggerCallback and cfg.Callback then cfg.Callback(val) end
            end
            
            dragger.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        dragging = false
                        if cfg.Callback then cfg.Callback(val) end
                    end
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input, false)
                end
            end)
            
            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    updateSlider(input, false)
                    dragging = true
                end
            end)
            
            return {}
        end

        function Tab:AddDivider()
            self._order = self._order + 1
            local div = Instance.new("Frame")
            div.Parent = self._container
            div.BackgroundColor3 = theme.border
            div.BorderSizePixel = 0
            div.Size = UDim2.new(1, 0, 0, 1)
            div.LayoutOrder = self._order
        end

        table.insert(Window._tabs, Tab)
        return Tab
    end

    return Window
end

-- ==========================================
-- SAFE DIRECT SHARD EXTRACTION ENGINE
-- ==========================================
local initialCashValue = nil
local lastObservedCash = 0
local absoluteLastKnownShards = 0

local function getShardCount()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local shardValue = leaderstats:FindFirstChild("Shards") or leaderstats:FindFirstChild("Mythic Shards") or leaderstats:FindFirstChild("Mythic")
        if shardValue and shardValue:IsA("ValueBase") then
            absoluteLastKnownShards = tonumber(shardValue.Value) or absoluteLastKnownShards
            return absoluteLastKnownShards
        end
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local hud = playerGui:FindFirstChild("hud") or playerGui:FindFirstChild("HUD")
        if hud then
            local shardsFrame = hud:FindFirstChild("shardsFrame") or hud:FindFirstChild("ShardsFrame") or hud:FindFirstChild("mythicFrame")
            local amountLabel = shardsFrame and (shardsFrame:FindFirstChild("amount") or shardsFrame:FindFirstChild("Amount") or shardsFrame:FindFirstChild("TextLabel"))
            if amountLabel and amountLabel:IsA("TextLabel") then
                local txt = amountLabel.Text ~= "" and amountLabel.Text or amountLabel.ContentText
                local cleanText = string.gsub(txt, "[%,%s]", "")
                local parsed = tonumber(cleanText)
                if parsed then
                    absoluteLastKnownShards = parsed
                    return parsed
                end
            end
        end
    end

    return absoluteLastKnownShards
end

local function triggerServerHop()
    _G.AutomatorRunning = false 
    saveSettings()
    task.wait(1.0) 

    local Http = game:GetService("HttpService")
    local Teleport = game:GetService("TeleportService")
    
    local success, err = pcall(function()
        local rawData = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local serverList = Http:JSONDecode(rawData)
        
        if serverList and serverList.data then
            table.sort(serverList.data, function(a, b)
                return (a.playing or 0) > (b.playing or 0)
            end)

            for _, server in ipairs(serverList.data) do
                if server.playing and server.playing < server.maxPlayers and server.playing > 1 and server.id ~= game.JobId then
                    Teleport:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
        Teleport:Teleport(game.PlaceId, LocalPlayer)
    end)
    
    if not success then
        pcall(function() Teleport:Teleport(game.PlaceId, LocalPlayer) end)
    end
end

-- ==========================================
-- INITIALIZE AUTOMATION SYSTEM GUI
-- ==========================================
local DiscordWebhookURL = SavedConfig.WebhookURL or "https://discord.com/api/webhooks/1526157590445166643/C8p3HqSdBMMJeJiuwkyHYvbK_2azl_eVAPaIOkQln0_U2Qx9xckIPU0HGmtUu9OhYRG0"

local collectingActive = SavedConfig.AutoCollect
local buyActive         = SavedConfig.AutoBuy
local dismantleActive   = SavedConfig.AutoDismantle
local crateActive      = SavedConfig.AutoCrate
local rewardActive     = SavedConfig.AutoPlaytime
local rebirthActive    = SavedConfig.AutoRebirth
local buyPlotsActive   = SavedConfig.AutoBuyPlots

print("[TycoonAutomator] Creating GUI window...")
local Window = Framework:CreateWindow({
    Title = "Automator Controller",
    Size = {315, 570},
    Position = {0.05, 0.25}
})

task.spawn(function()
    delayTimer(1.5)
    if _G.AutomatorRunning then syncTenCrateState() end
end)

task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if _G.AutomatorRunning then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.5)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
end)

local function postWebhookUpdate(customMessage)
    local currentWebhook = SavedConfig.WebhookURL or DiscordWebhookURL
    if not currentWebhook or currentWebhook == "" then return end
    local totalSecs = SavedConfig.TotalSessionTime or 0
    local cashPerHour = totalSecs > 0 and math.floor(((SavedConfig.TotalSessionEarned or 0) / totalSecs) * 3600) or 0
    local formattedTimeStr = string.format("%dh %dm", math.floor(totalSecs / 3600), math.floor((totalSecs % 3600) / 60))

    -- PATCH: Wired persistent combat stats fields directly into embed structure arrays
    local fields = {
        {["name"] = "Mythic Shards", ["value"] = "```" .. formatNumber(absoluteLastKnownShards) .. "```", ["inline"] = true},
        {["name"] = "Actual Disconnects", ["value"] = "```" .. tostring(SavedConfig.DisconnectCount or 0) .. "```", ["inline"] = true},
        {["name"] = "Bosses Destroyed", ["value"] = "```" .. tostring(SavedConfig.BossesKilled or 0) .. "```", ["inline"] = true},
        {["name"] = "Bosses Skipped", ["value"] = "```" .. tostring(SavedConfig.BossesSkipped or 0) .. "```", ["inline"] = true},
        {["name"] = "Total Rebirths", ["value"] = "```" .. tostring(SavedConfig.TotalRebirths or 0) .. "```", ["inline"] = true},
        {["name"] = "Total Money Earned", ["value"] = "```$" .. formatNumber(SavedConfig.TotalSessionEarned or 0) .. "```", ["inline"] = false},
        {["name"] = "Money Per Hour", ["value"] = "```$" .. formatNumber(cashPerHour) .. "/hr```", ["inline"] = true},
        {["name"] = "Playtime", ["value"] = "```" .. formattedTimeStr .. "```", ["inline"] = true}
    }

    if customMessage then
        table.insert(fields, 1, {["name"] = "System Notice Alert", ["value"] = "**" .. customMessage .. "**", ["inline"] = false})
    end

    local data = {
        ["embeds"] = {{
            ["title"] = "Automator Statistics Report",
            ["color"] = customMessage and 16731136 or 527196,
            ["fields"] = fields,
            ["footer"] = {["text"] = "Automator Engine Live Log Update"},
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }
    pcall(function()
        local payload = HttpService:JSONEncode(data)
        local httpFunc = request or http_request or (syn and syn.request)
        if httpFunc then
            httpFunc({
                Url = currentWebhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = payload
            })
        elseif HttpService.HttpEnabled then
            HttpService:PostAsync(currentWebhook, payload, Enum.HttpContentType.ApplicationJson)
        end
    end)
end

-- ==========================================
-- TAB 1: DASHBOARD TRACKERS
-- ==========================================
local DashboardTab = Window:CreateTab("Dashboard")
DashboardTab:AddLabel("LIVE STATISTICS", {Bold = true, Color = DEFAULT_THEME.accent})
DashboardTab:AddDivider()

local cashCard = DashboardTab:AddDisplayCard("Total Money Earned (Saved)", "$0", DEFAULT_THEME.accent)
local incomeCard = DashboardTab:AddDisplayCard("Money Per Hour", "$0 / hr", DEFAULT_THEME.accent)
local shardCard = DashboardTab:AddDisplayCard("Mythic Shards", "0", DEFAULT_THEME.info)
local sessionCard = DashboardTab:AddDisplayCard("Total Playtime (Saved)", "00h 00m 00s", DEFAULT_THEME.warning)
local disconnectCard = DashboardTab:AddDisplayCard("Actual Disconnects (Saved)", tostring(SavedConfig.DisconnectCount), DEFAULT_THEME.danger)

task.spawn(function()
    task.wait(6.0) 
    
    while _G.AutomatorRunning do
        local success, err = pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local hud = playerGui and (playerGui:FindFirstChild("hud") or playerGui:FindFirstChild("HUD"))
            local currentLiveCash = 0

            if hud then
                local cashFrame = hud:FindFirstChild("cashFrame") or hud:FindFirstChild("CashFrame")
                local cashAmount = cashFrame and (cashFrame:FindFirstChild("cashAmount") or cashFrame:FindFirstChild("Amount"))
                if cashAmount and cashAmount:IsA("TextLabel") then
                    local txt = cashAmount.Text ~= "" and cashAmount.Text or cashAmount.ContentText
                    currentLiveCash = parseCashString(txt)
                end
            end

            if currentLiveCash > 0 then
                if not initialCashValue then 
                    initialCashValue = currentLiveCash
                    lastObservedCash = currentLiveCash 
                end
                if currentLiveCash > lastObservedCash then 
                    SavedConfig.TotalSessionEarned = (SavedConfig.TotalSessionEarned or 0) + (currentLiveCash - lastObservedCash) 
                end
                lastObservedCash = currentLiveCash
            end
            
            cashCard:Update("$" .. formatNumber(SavedConfig.TotalSessionEarned or 0))
            
            local totalSecs = SavedConfig.TotalSessionTime or 0
            local hourlyRate = totalSecs > 0 and math.floor(((SavedConfig.TotalSessionEarned or 0) / totalSecs) * 3600) or 0
            incomeCard:Update("$" .. formatNumber(hourlyRate) .. " / hr")

            absoluteLastKnownShards = getShardCount()
            shardCard:Update(formatNumber(absoluteLastKnownShards))

            SavedConfig.TotalSessionTime = (SavedConfig.TotalSessionTime or 0) + 1
            sessionCard:Update(string.format("%02dh %02dm %02ds", math.floor(totalSecs/3600), math.floor((totalSecs%3600)/60), totalSecs%60))
            
            if totalSecs % 5 == 0 then saveSettings() end
        end)
        
        delayTimer(1.0)
    end
end)

task.spawn(function()
    game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg, code)
        if code and tonumber(code) >= 200 then
            SavedConfig.DisconnectCount = (SavedConfig.DisconnectCount or 0) + 1
            saveSettings()
            delayTimer(4)
            triggerServerHop()
        end
    end)
end)

-- ==========================================
-- TAB 2: AUTOMATOR CONTROLS
-- ==========================================
local AutomatorTab = Window:CreateTab("Automator")
AutomatorTab:AddLabel("PLOT SYSTEM LOOPS", {Bold = true, Color = DEFAULT_THEME.accent})
AutomatorTab:AddDivider()

AutomatorTab:AddToggle({
    Text = "Auto Boss/Awakened Everhop",
    Default = SavedConfig.BossHopActive,
    Callback = function(state) SavedConfig.BossHopActive = state; saveSettings() end
})

AutomatorTab:AddInputField("Boss Timeout Fallback", SavedConfig.BossHopTimeoutText or "10m", function(text)
    local secs = parseTimeBudget(text)
    if secs > 0 then
        SavedConfig.BossHopTimeoutSeconds = secs
        SavedConfig.BossHopTimeoutText = text
        saveSettings()
    end
end)

AutomatorTab:AddToggle({
    Text = "Auto Collect Loop",
    Default = SavedConfig.AutoCollect,
    Callback = function(state) collectingActive = state; SavedConfig.AutoCollect = state; saveSettings() end
})

AutomatorTab:AddToggle({
    Text = "Auto Rebirth",
    Default = SavedConfig.AutoRebirth,
    Callback = function(state) rebirthActive = state; SavedConfig.AutoRebirth = state; saveSettings() end
})

AutomatorTab:AddSlider("Plot Load Frequency (s)", {
    Min = 1, Max = 600,
    Default = SavedConfig.PlotLoadInterval,
    Callback = function(val)
        SavedConfig.PlotLoadInterval = val
        saveSettings()
    end
})

AutomatorTab:AddToggle({
    Text = "Auto Buy Plots",
    Default = SavedConfig.AutoBuyPlots,
    Callback = function(state) buyPlotsActive = state; SavedConfig.AutoBuyPlots = state; saveSettings() end
})

AutomatorTab:AddToggle({
    Text = "Auto Buy Active",
    Default = SavedConfig.AutoBuy,
    Callback = function(state) buyActive = state; SavedConfig.AutoBuy = state; saveSettings() end
})

AutomatorTab:AddDropdown("Choose Items To Buy", ALL_BUY_STRUCTURES, SavedConfig.SelectedBuyItems)

AutomatorTab:AddToggle({
    Text = "Auto Dismantle Active",
    Default = SavedConfig.AutoDismantle,
    Callback = function(state) dismantleActive = state; SavedConfig.AutoDismantle = state; saveSettings() end
})

local dismantleDropdown = AutomatorTab:AddDropdown("Choose Items To Dismantle", ALL_DISMANTLE_STRUCTURES, SavedConfig.SelectedDismantleItems)

if SavedConfig.CustomDismantleItems then
    for name, _ in pairs(SavedConfig.CustomDismantleItems) do
        dismantleDropdown:InjectItem(name)
    end
end

AutomatorTab:AddInputField("Register Missing Mythic", "Type name here...", function(inputText)
    if inputText and string.gsub(inputText, "%s+", "") ~= "" and inputText ~= "Type name here..." then
        if SavedConfig.SelectedDismantleItems[inputText] == nil then
            SavedConfig.SelectedDismantleItems[inputText] = false
            SavedConfig.CustomDismantleItems[inputText] = true
            saveSettings()
            dismantleDropdown:InjectItem(inputText)
        end
    end
end)

AutomatorTab:AddToggle({
    Text = "Auto Crate Loop",
    Default = SavedConfig.AutoCrate,
    Callback = function(state) crateActive = state; SavedConfig.AutoCrate = state; saveSettings() if state then syncTenCrateState() end end
})

AutomatorTab:AddSlider("Crate Buy Interval (s)", {
    Min = 1, Max = 600,
    Default = SavedConfig.CrateInterval,
    Callback = function(val)
        SavedConfig.CrateInterval = val
        saveSettings()
    end
})

AutomatorTab:AddDropdown("Choose Crates To Buy", ALL_CRATE_TYPES, SavedConfig.SelectedCrateTypes)

AutomatorTab:AddInputField("Min Cash To Buy", SavedConfig.CrateMinCashText or "5B", function(text)
    local p = parseCashString(text)
    if p >= 0 then SavedConfig.CrateMinCashRequirement = p; SavedConfig.CrateMinCashText = text; saveSettings() end
end)

AutomatorTab:AddInputField("Crates Per Purchase", SavedConfig.CrateBatchSizeText or "10K", function(text)
    local p = parseCashString(text)
    if p > 0 then SavedConfig.CrateBatchSize = p; SavedConfig.CrateBatchSizeText = text; saveSettings() end
end)

AutomatorTab:AddToggle({
    Text = "Auto Playtime Rewards",
    Default = SavedConfig.AutoPlaytime,
    Callback = function(state) rewardActive = state; SavedConfig.AutoPlaytime = state; saveSettings() end
})

-- ==========================================
-- TAB 3: UTILITIES
-- ==========================================
local UtilitiesTab = Window:CreateTab("Utilities")
UtilitiesTab:AddLabel("UNRELATED SYSTEM TOOLS", {Bold = true, Color = DEFAULT_THEME.accent})
UtilitiesTab:AddDivider()

UtilitiesTab:AddButton({
    Text = "Reset All Saved Trackers to 0",
    Callback = function()
        SavedConfig.DisconnectCount = 0; SavedConfig.TotalSessionEarned = 0; SavedConfig.TotalSessionTime = 0
        SavedConfig.BossesKilled = 0; SavedConfig.BossesSkipped = 0; SavedConfig.TotalRebirths = 0
        saveSettings()
    end
})

UtilitiesTab:AddInputField("Webhook URL", SavedConfig.WebhookURL or "", function(text)
    SavedConfig.WebhookURL = text
    saveSettings()
end)

UtilitiesTab:AddButton({
    Text = "Force Update Discord Webhook",
    Callback = function() postWebhookUpdate() end
})

UtilitiesTab:AddButton({
    Text = "Launch Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'), true))()
    end
})

print("[TycoonAutomator] GUI built successfully! Starting background loops...")

UtilitiesTab:AddButton({
    Text = "Unload UI Script",
    Callback = function()
        _G.AutomatorRunning = false; collectingActive = false; buyActive = false; dismantleActive = false; crateActive = false; rewardActive = false; rebirthActive = false; buyPlotsActive = false
        delayTimer(0.2)
        Window._screenGui:Destroy()
    end
})

-- ==========================================
-- HARDENED BACKGROUND LOOP EXECUTIONS
-- ==========================================

task.spawn(function()
    task.wait(8.0) 
    
    while true do
        if not _G.AutomatorRunning then break end
        if SavedConfig.BossHopActive then
            local activeUnits = workspace:FindFirstChild("ActiveUnits")
            local foundBoss = nil
            
            if activeUnits then
                for _, obj in ipairs(activeUnits:GetChildren()) do
                    local upperName = string.upper(obj.Name)
                    if string.find(upperName, "BOSS:") or string.find(upperName, "AWAKENED:") then
                        foundBoss = obj
                        break
                    end
                end
            end
            
            if foundBoss then
                local bossLabelName = foundBoss.Name
                local startTime = os.time()
                local timeoutLimit = SavedConfig.BossHopTimeoutSeconds or 600
                local timedOut = false
                
                while _G.AutomatorRunning and SavedConfig.BossHopActive and foundBoss and foundBoss:IsDescendantOf(workspace) do
                    if (os.time() - startTime) >= timeoutLimit then
                        timedOut = true
                        break
                    end
                    task.wait(1.0)
                end
                
                if _G.AutomatorRunning and SavedConfig.BossHopActive then
                    if timedOut then
                        -- PATCH: Target timed out/ran away, count it as a skip
                        SavedConfig.BossesSkipped = (SavedConfig.BossesSkipped or 0) + 1
                        saveSettings()
                        postWebhookUpdate("Target execution took too long! Forcing fallback serverhop...")
                    else
                        -- PATCH: Target was deleted successfully by team, count it as a kill
                        SavedConfig.BossesKilled = (SavedConfig.BossesKilled or 0) + 1
                        saveSettings()
                        postWebhookUpdate("Target Destroyed: " .. bossLabelName .. "! Serverhopping now...")
                    end
                    task.spawn(triggerServerHop)
                    break 
                end
            else
                postWebhookUpdate("No Boss found. Hopping to find another...")
                task.spawn(triggerServerHop)
                break 
            end
        end
        task.wait(3.0)
    end
end)

task.spawn(function()
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Event = Shared:WaitForChild("Resources"):WaitForChild("PlotResources"):WaitForChild("Remotes"):WaitForChild("Collect")
    local plotName = LocalPlayer.Name .. "'s plot"
    
    while true do
        if not _G.AutomatorRunning then break end
        local folder = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName) and workspace.Plots[plotName]:FindFirstChild("baseplate") and workspace.Plots[plotName].baseplate:FindFirstChild("Structures")
        if collectingActive and Event and folder then
            for _, tower in pairs(folder:GetChildren()) do 
                if not _G.AutomatorRunning or not collectingActive then break end 
                pcall(function() Event:FireServer(tower) end)
                task.wait(0.02) 
            end
            delayTimer(1.0)
        else
            delayTimer(1.0)
        end
    end
end)

task.spawn(function()
    local PurchaseEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("VendorResources"):WaitForChild("Remotes"):WaitForChild("PurchaseStructure")
    while true do
        if not _G.AutomatorRunning then break end
        if buyActive and PurchaseEvent then
            for name, isSelected in pairs(SavedConfig.SelectedBuyItems) do 
                if not _G.AutomatorRunning or not buyActive then break end 
                if isSelected then
                    pcall(function() PurchaseEvent:FireServer(name) end)
                    task.wait(0.05)
                end
            end
            delayTimer(0.5)
        else
            delayTimer(1.0)
        end
    end
end)

task.spawn(function()
    local DismantleEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("VendorResources"):WaitForChild("Remotes"):WaitForChild("DismantleMythicStructure")
    while true do
        if not _G.AutomatorRunning then break end
        if dismantleActive and DismantleEvent then
            for name, isSelected in pairs(SavedConfig.SelectedDismantleItems) do 
                if not _G.AutomatorRunning or not dismantleActive then break end 
                if isSelected then
                    pcall(function() DismantleEvent:FireServer(name, 1) end) 
                    task.wait(0.05)
                end
            end
            delayTimer(0.5)
        else
            delayTimer(1.0)
        end
    end
end)

task.spawn(function()
    local CrateEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("LootCrateResources"):WaitForChild("Remotes"):WaitForChild("OpenLootCrate")
    while true do
        if not _G.AutomatorRunning then break end
        if crateActive and CrateEvent then
            local currentLiveCash = 0
            
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local hud = playerGui and (playerGui:FindFirstChild("hud") or playerGui:FindFirstChild("HUD"))
                if hud then
                    local cashFrame = hud:FindFirstChild("cashFrame") or hud:FindFirstChild("CashFrame")
                    local cashAmount = cashFrame and (cashFrame:FindFirstChild("cashAmount") or cashFrame:FindFirstChild("Amount"))
                    if cashAmount and cashAmount:IsA("TextLabel") then
                        currentLiveCash = parseCashString(cashAmount.Text ~= "" and cashAmount.Text or cashAmount.ContentText)
                    end
                end
            end)

                    if currentLiveCash >= (SavedConfig.CrateMinCashRequirement or 5000000000) then
                local crateBatchSize = tonumber(SavedConfig.CrateBatchSize) or 10000
                if crateBatchSize <= 0 then crateBatchSize = 10000 end
                local crateTypes = {}
                for crateType, enabled in pairs(SavedConfig.SelectedCrateTypes) do
                    if enabled then
                        table.insert(crateTypes, crateType)
                    end
                end
                for _, crateType in ipairs(crateTypes) do
                    pcall(function() CrateEvent:FireServer(crateType, crateBatchSize) end)
                    task.wait(0.2)
                end
                delayTimer(SavedConfig.CrateInterval or 5.0)
            else
                delayTimer(1.5)
            end
        else
            delayTimer(1.0)
        end
    end
end)

task.spawn(function()
    local RewardEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("RewardResources"):WaitForChild("Remotes"):WaitForChild("ClaimPlaytimeReward")
    while true do
        if not _G.AutomatorRunning then break end
        if rewardActive and RewardEvent then
            for i = 1, 6 do 
                if not _G.AutomatorRunning or not rewardActive then break end 
                pcall(function() RewardEvent:FireServer(i) end) 
                delayTimer(0.5) 
            end
            delayTimer(30.0)
        else
            delayTimer(1.0)
        end
    end
end)

task.spawn(function()
    local LoadPlotEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("PlotResources"):WaitForChild("Remotes"):WaitForChild("LoadPlot")
    local RebirthEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("RebirthResources"):WaitForChild("Remotes"):WaitForChild("Rebirth")
    
    local lastLoadPlot = os.time()
    
    while true do
        if not _G.AutomatorRunning then break end
        if rebirthActive then
            if os.time() - lastLoadPlot >= (SavedConfig.PlotLoadInterval or 10) then
                pcall(function() LoadPlotEvent:FireServer("2") end)
                lastLoadPlot = os.time()
            end
            
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local hud = playerGui and (playerGui:FindFirstChild("hud") or playerGui:FindFirstChild("HUD"))
                if hud then
                    local rebirthFrame = hud:FindFirstChild("rebirthFrame")
                    local main = rebirthFrame and rebirthFrame:FindFirstChild("main")
                    local rebirthProgress = main and main:FindFirstChild("rebirthProgress")
                    local amountFrame = rebirthProgress and rebirthProgress:FindFirstChild("amountFrame")
                    local amountLabel = amountFrame and amountFrame:FindFirstChild("amount")
                    
                    if amountLabel and amountLabel:IsA("TextLabel") then
                        local txt = amountLabel.Text ~= "" and amountLabel.Text or amountLabel.ContentText
                        local parts = string.split(txt, "/")
                        if #parts == 2 then
                            local currentStr = string.gsub(parts[1], "[%D]", "")
                            local maxStr = string.gsub(parts[2], "[%D]", "")
                            local currentNum = tonumber(currentStr)
                            local maxNum = tonumber(maxStr)
                            
                            if currentNum and maxNum and currentNum >= maxNum and maxNum > 0 then
                                RebirthEvent:FireServer()
                                SavedConfig.TotalRebirths = (SavedConfig.TotalRebirths or 0) + 1
                                saveSettings()
                                postWebhookUpdate("Successfully Rebirthed!")
                                delayTimer(5.0) 
                            end
                        end
                    end
                end
            end)
            delayTimer(1.0)
        else
            delayTimer(1.0)
        end
    end
end)

task.spawn(function()
    local PurchasePlotEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("PlotResources"):WaitForChild("Remotes"):WaitForChild("PurchasePlot")
    
    while true do
        if not _G.AutomatorRunning then break end
        if buyPlotsActive and PurchasePlotEvent then
            for i = 1, 12 do
                if not _G.AutomatorRunning or not buyPlotsActive then break end
                pcall(function() PurchasePlotEvent:FireServer("buildArea" .. tostring(i)) end)
                task.wait(0.05)
            end
            delayTimer(0.1) 
        else
            delayTimer(1.0)
        end
    end
end)

print("[TycoonAutomator] Script fully executed and running!")

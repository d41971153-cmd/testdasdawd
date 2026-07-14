-- ==========================================
-- EMBEDDED GUI FRAMEWORK v2.9 (Network Hook & Data Sync)
-- ==========================================
local Framework = {}
Framework.__index = Framework

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local DEFAULT_THEME = {
    bg            = Color3.fromRGB(12, 12, 14),
    surface       = Color3.fromRGB(22, 22, 26),
    surfaceHover  = Color3.fromRGB(30, 30, 36),
    border        = Color3.fromRGB(38, 38, 44),
    borderActive  = Color3.fromRGB(80, 200, 140),
    textPrimary   = Color3.fromRGB(230, 232, 236),
    textSecondary = Color3.fromRGB(140, 142, 148),
    textMuted     = Color3.fromRGB(90, 92, 98),
    accent        = Color3.fromRGB(80, 200, 140),
    accentSurface = Color3.fromRGB(22, 50, 38),
    danger        = Color3.fromRGB(200, 70, 70),
    dangerDim     = Color3.fromRGB(60, 20, 20),
    warning       = Color3.fromRGB(200, 170, 60),
    warningDim     = Color3.fromRGB(50, 45, 20),
    info          = Color3.fromRGB(70, 140, 210),
    infoDim       = Color3.fromRGB(20, 40, 65),
    titleBar = Color3.fromRGB(16, 16, 19),
    dotOff        = Color3.fromRGB(55, 55, 62),
    dotOn         = Color3.fromRGB(80, 200, 140),
}

local TWEEN_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local delayTimer = task and task.wait or wait

local function tween(obj, props, info)
    TweenService:Create(obj, info or TWEEN_FAST, props):Play()
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
    local raw = string.gsub(tostring(text), "[%$%,%s]", "")
    local num = tonumber(string.match(raw, "^%d+%.?%d*")) or 0
    local suffix = string.match(raw, "%a+$")
    
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
    local num = tonumber(string.match(text, "^%d+")) or 10
    local suffix = string.match(text, "%a+$")
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
    local num = tonumber(value) or 0
    local formatted = tostring(num)
    while true do  
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

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
    BossHopActive = false,
    BossHopTimeoutText = "10m",
    BossHopTimeoutSeconds = 600,
    CrateType = "Elite",
    CrateMinCashRequirement = 5000000000,
    CrateMinCashText = "5B",
    ReconnectCount = 0,
    TotalSessionEarned = 0,
    TotalSessionTime = 0
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
end

local function saveSettings()
    if writefile then
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(SavedConfig))
        end)
    end
end

loadSettings()

local function syncTenCrateState()
    local LootCrateRemotes = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Resources")
        and ReplicatedStorage.Shared.Resources:FindFirstChild("LootCrateResources")
        and ReplicatedStorage.Shared.Resources.LootCrateResources:FindFirstChild("Remotes")
        
    local ToggleTenEvent = LootCrateRemotes and LootCrateRemotes:FindFirstChild("ToggleTenOpen")
    if ToggleTenEvent then
        ToggleTenEvent:FireServer()
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
    tabLayout.Padding = UDim.new(0, 2)
    padding(tabBar, 2, 2, 14, 14)

    local viewContainer = Instance.new("Frame")
    viewContainer.Name = "ViewContainer"
    viewContainer.Parent = mainFrame
    viewContainer.BackgroundTransparency = 1
    viewContainer.Position = UDim2.new(0, 0, 0, 72)
    viewContainer.Size = UDim2.new(1, 0, 1, -94)

    local footer = Instance.new("TextLabel")
    footer.Name = "Footer"
    footer.Parent = mainFrame
    footer.BackgroundTransparency = 1
    footer.Position = UDim2.new(0, 14, 1, -22)
    footer.Size = UDim2.new(1, -28, 0, 16)
    footer.Font = Enum.Font.Gotham
    footer.Text = config.Footer or ""
    footer.TextColor3 = theme.textMuted
    footer.TextSize = 10
    footer.TextXAlignment = Enum.TextXAlignment.Left

    local Window = {}
    Window.__index = Window
    Window._screenGui = screenGui
    Window._mainFrame = mainFrame
    Window._viewContainer = viewContainer
    Window._tabBar = tabBar
    Window._footer = footer
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
        tabBtn.Size = UDim2.new(0, 80, 1, 0)
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
        padding(scroller, 0, 6, 14, 14)

        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = scroller
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 6)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
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
        
        if tabOrder == 1 then
            selectTab()
        end

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
            btn.AutoButtonColor = false
            corner(btn, 6)
            local btnStroke = stroke(btn, theme.border, 1)

            local dot = Instance.new("Frame")
            dot.Parent = btn
            dot.BackgroundColor3 = theme.dotOff
            dot.BorderSizePixel = 0
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

            local handle = {}
            function handle:SetState(newState) state = newState; updateVisual() end
            return handle
        end

        function Tab:AddButton(cfg)
            cfg = cfg or {}
            self._order = self._order + 1

            local btn = Instance.new("TextButton")
            btn.Parent = self._container
            btn.BackgroundColor3 = theme.surface
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(1, 0, 0, 36)
            btn.Text = ""
            btn.LayoutOrder = self._order
            btn.AutoButtonColor = false
            corner(btn, 6)
            local btnStroke = stroke(btn, theme.border, 1)

            local dot = Instance.new("Frame")
            dot.Parent = btn
            dot.BackgroundColor3 = cfg.DotColor or theme.info
            dot.BorderSizePixel = 0
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
            container.BorderSizePixel = 0
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

            local handle = {}
            function handle:SetText(t) label.Text = t end
            return handle
        end

        function Tab:AddDisplayCard(titleText, defaultVal, dotColor)
            self._order = self._order + 1
            
            local card = Instance.new("Frame")
            card.Parent = self._container
            card.BackgroundColor3 = theme.surface
            card.Size = UDim2.new(1, 0, 0, 42)
            card.BorderSizePixel = 0
            card.LayoutOrder = self._order
            corner(card, 6)
            stroke(card, theme.border, 1)
            padding(card, 0, 0, 12, 12)
            
            local dot = Instance.new("Frame")
            dot.Parent = card
            dot.BackgroundColor3 = dotColor or theme.textMuted
            dot.BorderSizePixel = 0
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
            
            local handle = {}
            function handle:Update(newVal) valLbl.Text = tostring(newVal) end
            return handle
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
-- REAL-TIME NETWORK & DATA ISOLATION ENGINE (v2.9)
-- ==========================================
local cachedShardObj = nil
local forcedUIRefreshNeeded = true

local function getShardCount()
    -- 1. Scan ProfileData & leaderstats Values (Instantly changes upon dismantle server execution)
    if cachedShardObj and cachedShardObj:Parent() then
        return tonumber(cachedShardObj.Value) or 0
    end
    
    local searchTrees = { LocalPlayer:FindFirstChild("ProfileData"), LocalPlayer:FindFirstChild("leaderstats"), LocalPlayer }
    for _, source in ipairs(searchTrees) do
        if source then
            local exact = source:FindFirstChild("MythicShards") or source:FindFirstChild("Shards") or source:FindFirstChild("MythicShard")
            if exact and exact:IsA("ValueBase") then
                cachedShardObj = exact
                return tonumber(exact.Value) or 0
            end
            for _, child in ipairs(source:GetDescendants()) do
                if child:IsA("ValueBase") and (string.find(child.Name, "Shard") or string.find(child.Name, "Mythic")) then
                    cachedShardObj = child
                    return tonumber(child.Value) or 0
                end
            end
        end
    end
    
    -- 2. UI Fallback (Scans layout structures cleanly)
    local hud = LocalPlayer.PlayerGui:FindFirstChild("hud")
    if hud then
        for _, object in ipairs(hud:GetDescendants()) do
            if object:IsA("TextLabel") and object.Visible and string.match(object.Text, "^%d+$") then
                local p = object.Parent
                if p and (p:IsA("Frame") or p:IsA("GuiObject")) then
                    local hasPlusButton = false
                    local hasShardKeywords = false
                    
                    for _, sibling in ipairs(p:GetChildren()) do
                        if (sibling:IsA("TextButton") or sibling:IsA("ImageButton")) and (sibling.Text == "+" or string.find(string.lower(sibling.Name), "plus") or string.find(string.lower(sibling.Name), "add")) then
                            hasPlusButton = true
                        end
                        if string.find(string.lower(sibling.Name), "shard") or string.find(string.lower(sibling.Name), "mythic") then
                            hasShardKeywords = true
                        end
                    end
                    
                    if string.find(string.lower(p.Name), "shard") or string.find(string.lower(p.Name), "mythic") then
                        hasShardKeywords = true
                    end
                    
                    if hasPlusButton or hasShardKeywords then
                        return tonumber(object.Text) or 0
                    end
                end
            end
        end
    end
    return 0
end

local function triggerServerHop()
    local Http = game:GetService("HttpService")
    local Teleport = game:GetService("TeleportService")
    pcall(function()
        local rawData = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local serverList = Http:JSONDecode(rawData)
        if serverList and serverList.data then
            for _, server in ipairs(serverList.data) do
                if server.playing and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    Teleport:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
        Teleport:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- ==========================================
-- INITIALIZE AUTOMATION SYSTEM GUI
-- ==========================================
local running = true
local DiscordWebhookURL = "https://discord.com/api/webhooks/1526157590445166643/C8p3HqSdBMMJeJiuwkyHYvbK_2azl_eVAPaIOkQln0_U2Qx9xckIPU0HGmtUu9OhYRG0"

local initialCashValue = nil
local lastObservedCash = 0
local absoluteLastKnownShards = 0

local collectingActive = SavedConfig.AutoCollect
local buyActive         = SavedConfig.AutoBuy
local dismantleActive   = SavedConfig.AutoDismantle
local crateActive      = SavedConfig.AutoCrate
local rewardActive     = SavedConfig.AutoPlaytime

local Window = Framework:CreateWindow({
    Title = "Automator Controller",
    Size = {295, 610},
    Position = {0.05, 0.25},
    Footer = "PRESS [N] TO TOGGLE INTERFACE"
})

-- Network Intercept Hooks to Force Metric Refreshes On Action Execution
local DismantleEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("VendorResources"):WaitForChild("Remotes"):WaitForChild("DismantleMythicStructure")
if DismantleEvent and DismantleEvent:IsA("RemoteEvent") then
    DismantleEvent.OnClientEvent:Connect(function()
        forcedUIRefreshNeeded = true
    end)
end

task.spawn(function()
    delayTimer(1)
    syncTenCrateState()
end)

task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if running then
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

local function postWebhookUpdate(customMessage)
    if not DiscordWebhookURL or DiscordWebhookURL == "" then return end
    local totalSecs = SavedConfig.TotalSessionTime or 0
    local cashPerHour = totalSecs > 0 and math.floor(((SavedConfig.TotalSessionEarned or 0) / totalSecs) * 3600) or 0
    local formattedTimeStr = string.format("%dh %dm", math.floor(totalSecs / 3600), math.floor((totalSecs % 3600) / 60))

    local fields = {
        {["name"] = "Mythic Shards", ["value"] = "```" .. formatNumber(absoluteLastKnownShards) .. "```", ["inline"] = true},
        {["name"] = "Server Reconnects", ["value"] = "```" .. tostring(SavedConfig.ReconnectCount or 0) .. "```", ["inline"] = true},
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
        local httpFunc = request or http_request or (syn and syn.request)
        if httpFunc then httpFunc({Url = DiscordWebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end
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
local reconnectCard = DashboardTab:AddDisplayCard("Total Reconnects (Saved)", tostring(SavedConfig.ReconnectCount), DEFAULT_THEME.danger)

task.spawn(function()
    while running do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("hud")
            local cashAmount = hud and hud:FindFirstChild("cashFrame") and hud.cashFrame:FindFirstChild("cashAmount")
            local currentLiveCash = cashAmount and parseCashString(cashAmount.ContentText ~= "" and cashAmount.ContentText or cashAmount.Text) or 0

            if currentLiveCash > 0 then
                if not initialCashValue then initialCashValue = currentLiveCash; lastObservedCash = currentLiveCash end
                if currentLiveCash > lastObservedCash then SavedConfig.TotalSessionEarned = (SavedConfig.TotalSessionEarned or 0) + (currentLiveCash - lastObservedCash) end
                lastObservedCash = currentLiveCash
            end
            
            cashCard:Update("$" .. formatNumber(SavedConfig.TotalSessionEarned))
            local totalSecs = SavedConfig.TotalSessionTime or 0
            incomeCard:Update("$" .. formatNumber(totalSecs > 0 and math.floor((SavedConfig.TotalSessionEarned / totalSecs) * 3600) or 0) .. " / hr")

            -- Perform core value evaluation
            local newShards = getShardCount()
            if newShards ~= absoluteLastKnownShards or forcedUIRefreshNeeded then
                absoluteLastKnownShards = newShards
                shardCard:Update(formatNumber(absoluteLastKnownShards))
                forcedUIRefreshNeeded = false
            end
        end)

        SavedConfig.TotalSessionTime = (SavedConfig.TotalSessionTime or 0) + 1
        local totalSecs = SavedConfig.TotalSessionTime
        sessionCard:Update(string.format("%02dh %02dm %02ds", math.floor(totalSecs/3600), math.floor((totalSecs%3600)/60), totalSecs%60))
        if totalSecs % 5 == 0 then saveSettings() end
        delayTimer(1)
    end
end)

task.spawn(function()
    GuiService.ErrorMessageChanged:Connect(function()
        SavedConfig.ReconnectCount = (SavedConfig.ReconnectCount or 0) + 1
        saveSettings()
        delayTimer(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end)

-- ==========================================
-- TAB 2: AUTOMATOR CONTROLS
-- ==========================================
local AutomatorTab = Window:CreateTab("Automator")
AutomatorTab:AddLabel("PLOT SYSTEM LOOPS", {Bold = true, Color = DEFAULT_THEME.accent})
AutomatorTab:AddDivider()

AutomatorTab:AddToggle({
    Text = "Auto Boss Everhop Hunt",
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
    Text = "Auto Buy Active",
    Default = SavedConfig.AutoBuy,
    Callback = function(state) buyActive = state; SavedConfig.AutoBuy = state; saveSettings() end
})

AutomatorTab:AddToggle({
    Text = "Auto Dismantle Active",
    Default = SavedConfig.AutoDismantle,
    Callback = function(state) dismantleActive = state; SavedConfig.AutoDismantle = state; saveSettings() end
})

AutomatorTab:AddToggle({
    Text = "Auto Crate Loop",
    Default = SavedConfig.AutoCrate,
    Callback = function(state) crateActive = state; SavedConfig.AutoCrate = state; saveSettings() if state then syncTenCrateState() end end
})

local crateTypes = {"Elite", "Titan", "Decorative", "Standard", "Golden"}
AutomatorTab:AddButton({
    Text = "Crate Selected: " .. (SavedConfig.CrateType or "Elite"),
    Callback = function(btn)
        local curr = SavedConfig.CrateType or "Elite"
        for i, v in ipairs(crateTypes) do if v == curr then SavedConfig.CrateType = crateTypes[i % #crateTypes + 1] break end end
        saveSettings()
        btn:SetState("reset", "Crate Selected: " .. SavedConfig.CrateType)
    end
})

AutomatorTab:AddInputField("Min Cash To Buy", SavedConfig.CrateMinCashText or "5B", function(text)
    local p = parseCashString(text)
    if p >= 0 then SavedConfig.CrateMinCashRequirement = p; SavedConfig.CrateMinCashText = text; saveSettings() end
end)

AutomatorTab:AddToggle({
    Text = "Auto Playtime Rewards",
    Default = SavedConfig.AutoPlaytime,
    Callback = function(state) rewardActive = state; SavedConfig.AutoPlaytime = state; saveSettings() end
})

AutomatorTab:AddDivider()
AutomatorTab:AddLabel("UTILITY HOOKS")

AutomatorTab:AddButton({
    Text = "Reset All Saved Trackers to 0",
    Callback = function()
        SavedConfig.ReconnectCount = 0; SavedConfig.TotalSessionEarned = 0; SavedConfig.TotalSessionTime = 0
        saveSettings()
    end
})

AutomatorTab:AddButton({
    Text = "Force Update Discord Webhook",
    Callback = function() postWebhookUpdate() end
})

AutomatorTab:AddButton({
    Text = "Launch Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'), true))()
    end
})

AutomatorTab:AddButton({
    Text = "Unload UI Script",
    Callback = function()
        running = false; collectingActive = false; buyActive = false; dismantleActive = false; crateActive = false; rewardActive = false
        task.wait(0.2)
        Window._screenGui:Destroy()
    end
})

-- ==========================================
-- BACKGROUND AUTOMATION EXECUTION THREADS
-- ==========================================

task.spawn(function()
    task.wait(4)
    while true do
        if not running then break end
        if SavedConfig.BossHopActive then
            local activeUnits = workspace:FindFirstChild("ActiveUnits")
            local foundBoss = nil
            
            if activeUnits then
                for _, obj in ipairs(activeUnits:GetChildren()) do
                    if string.find(string.upper(obj.Name), "BOSS:") then
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
                
                while SavedConfig.BossHopActive and foundBoss and foundBoss:IsDescendantOf(workspace) do
                    if (os.time() - startTime) >= timeoutLimit then
                        timedOut = true
                        break
                    end
                    task.wait(1)
                end
                
                if SavedConfig.BossHopActive then
                    if timedOut then
                        postWebhookUpdate("Boss target execution took too long (Exceeded " .. (SavedConfig.BossHopTimeoutText or "10m") .. ")! Forcing fallback serverhop...")
                    else
                        postWebhookUpdate("Boss Defeated: " .. bossLabelName .. "! Serverhopping now...")
                    end
                    task.wait(1)
                    triggerServerHop()
                    task.wait(10)
                end
            else
                postWebhookUpdate("No boss found in server. Hopping to find another...")
                task.wait(1)
                triggerServerHop()
                task.wait(10)
            end
        end
        task.wait(2)
    end
end)

task.spawn(function()
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Event = Shared:WaitForChild("Resources"):WaitForChild("PlotResources"):WaitForChild("Remotes"):WaitForChild("Collect")
    local plotName = LocalPlayer.Name .. "'s plot"
    
    while true do
        if not running then break end
        local folder = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName) and workspace.Plots[plotName]:FindFirstChild("baseplate") and workspace.Plots[plotName].baseplate:FindFirstChild("Structures")
        if collectingActive and Event and folder then
            for _, tower in pairs(folder:GetChildren()) do if not collectingActive then break end Event:FireServer(tower) task.wait(0.01) end
            delayTimer(1)
        else
            delayTimer(0.5)
        end
    end
end)

task.spawn(function()
    local PurchaseEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("VendorResources"):WaitForChild("Remotes"):WaitForChild("PurchaseStructure")
    local structuresToBuy = {
        "Corporate Campus", "Luxury Resort", "Semiconductor Plant", "Cookie Stand",
        "Shield Generator", "Behemoth Fortress", "Officer Quarters", "Fleet Command",
        "Heavy Weapons Depot", "Naval Shipyard", "ATC Tower", "Field Tent",
        "Regional Depot", "Cargo Dockyard", "Advanced Supply Depot",
    }
    while true do
        if not running then break end
        if buyActive and PurchaseEvent then
            for _, name in ipairs(structuresToBuy) do if not buyActive then break end task.spawn(function() PurchaseEvent:FireServer(name) end) end
            delayTimer(0.1)
        else
            delayTimer(0.5)
        end
    end
end)

task.spawn(function()
    local structuresToDismantle = {
        "Cookie Stand", "Shield Generator", "Behemoth Fortress", "Officer Quarters",
        "Fleet Command", "Heavy Weapons Depot", "Naval Shipyard", "ATC Tower", "Field Tent",
        "Cobra Helipad", "Tank Warehouse"
    }
    while true do
        if not running then break end
        if dismantleActive and DismantleEvent then
            for _, name in ipairs(structuresToDismantle) do 
                if not dismantleActive then break end 
                task.spawn(function() 
                    DismantleEvent:FireServer(name, 1) 
                end) 
            end
            forcedUIRefreshNeeded = true
            delayTimer(0.1)
        else
            delayTimer(0.5)
        end
    end
end)

task.spawn(function()
    local CrateEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("LootCrateResources"):WaitForChild("Remotes"):WaitForChild("OpenLootCrate")
    while true do
        if not running then break end
        if crateActive and CrateEvent then
            local hud = LocalPlayer.PlayerGui:FindFirstChild("hud")
            local cashAmount = hud and hud:WaitForChild("cashFrame"):WaitForChild("cashAmount")
            local currentLiveCash = cashAmount and parseCashString(cashAmount.ContentText ~= "" and cashAmount.ContentText or cashAmount.Text) or 0

            if currentLiveCash >= (SavedConfig.CrateMinCashRequirement or 5000000000) then
                CrateEvent:FireServer(SavedConfig.CrateType or "Elite", 10000)
                forcedUIRefreshNeeded = true
                delayTimer(5)
            else
                delayTimer(1)
            end
        else
            delayTimer(0.5)
        end
    end
end)

task.spawn(function()
    local RewardEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("RewardResources"):WaitForChild("Remotes"):WaitForChild("ClaimPlaytimeReward")
    while true do
        if not running then break end
        if rewardActive and RewardEvent then
            for i = 1, 6 do if not rewardActive then break end RewardEvent:FireServer(i) delayTimer(0.5) end
            delayTimer(30)
        else
            delayTimer(0.5)
        end
    end
end)

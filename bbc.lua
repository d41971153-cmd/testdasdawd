-- ==========================================
-- EMBEDDED GUI FRAMEWORK v1.4 (Ultimate Premium Edition)
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
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local DEFAULT_THEME = {
    bg            = Color3.fromRGB(15, 17, 22),
    surface       = Color3.fromRGB(23, 26, 33),
    surfaceHover  = Color3.fromRGB(31, 35, 45),
    border        = Color3.fromRGB(42, 47, 59),
    borderActive  = Color3.fromRGB(75, 215, 145),
    textPrimary   = Color3.fromRGB(245, 247, 250),
    textSecondary = Color3.fromRGB(160, 168, 185),
    textMuted     = Color3.fromRGB(105, 115, 135),
    accent        = Color3.fromRGB(75, 215, 145),
    accentSurface = Color3.fromRGB(22, 50, 40),
    danger        = Color3.fromRGB(230, 80, 80),
    dangerDim     = Color3.fromRGB(60, 25, 25),
    warning       = Color3.fromRGB(235, 175, 65),
    warningDim    = Color3.fromRGB(55, 45, 20),
    info          = Color3.fromRGB(80, 160, 240),
    infoDim       = Color3.fromRGB(25, 45, 70),
    titleBar      = Color3.fromRGB(20, 23, 30),
    dotOff        = Color3.fromRGB(65, 72, 88),
    dotOn         = Color3.fromRGB(75, 215, 145),
}

local TWEEN_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local delayTimer = task.wait

local function tween(obj, props, info)
    local t = TweenService:Create(obj, info or TWEEN_FAST, props)
    t:Play()
    return t
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

-- ==========================================
-- GLOBAL NOTIFICATION SYSTEM (TOAST ENGINE)
-- ==========================================
local ToastContainer = nil
local function createToast(text, typeOfToast)
    local targetParent = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    
    if not ToastContainer then
        ToastContainer = Instance.new("ScreenGui")
        ToastContainer.Name = "NotificationEngine_System"
        ToastContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ToastContainer.Parent = targetParent
        
        local layoutFrame = Instance.new("Frame")
        layoutFrame.Name = "LayoutFrame"
        layoutFrame.BackgroundTransparency = 1
        layoutFrame.Position = UDim2.new(1, -290, 1, -25)
        layoutFrame.Size = UDim2.new(0, 270, 0, 500)
        layoutFrame.Parent = ToastContainer
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = layoutFrame
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        listLayout.Padding = UDim.new(0, 8)
    end
    
    local theme = DEFAULT_THEME
    local accentColor = theme.info
    if typeOfToast == "success" then accentColor = theme.accent
    elseif typeOfToast == "warning" then accentColor = theme.warning
    elseif typeOfToast == "danger" then accentColor = theme.danger end
    
    local item = Instance.new("Frame")
    item.BackgroundColor3 = theme.surface
    item.Size = UDim2.new(1, 0, 0, 0)
    item.BorderSizePixel = 0
    item.ClipsDescendants = true
    item.Parent = ToastContainer.LayoutFrame
    
    corner(item, 6)
    local itemStroke = stroke(item, theme.border, 1)
    
    local leftPill = Instance.new("Frame")
    leftPill.BackgroundColor3 = accentColor
    leftPill.BorderSizePixel = 0
    leftPill.Size = UDim2.new(0, 4, 1, 0)
    leftPill.Parent = item
    
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = theme.textPrimary
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = item
    
    tween(item, {Size = UDim2.new(1, 0, 0, 38)}, TWEEN_FAST)
    
    task.delay(3.5, function()
        local t = tween(item, {Size = UDim2.new(1, 0, 0, 0)}, TWEEN_FAST)
        t.Completed:Connect(function()
            item:Destroy()
        end)
    end)
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
    mainFrame.ClipsDescendants = true

    corner(mainFrame, 10)
    local mainStroke = stroke(mainFrame, theme.border, 1)

    mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        shadow.Position = mainFrame.Position + UDim2.new(0, -8, 0, -8)
    end)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.BackgroundColor3 = theme.titleBar
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 40)

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

    -- Clean minimizing system implementation
    local isMinimised = false
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Parent = titleBar
    minBtn.BackgroundTransparency = 1
    minBtn.Position = UDim2.new(1, -34, 0, 0)
    minBtn.Size = UDim2.new(0, 34, 1, 0)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Text = "_"
    minBtn.TextSize = 14
    minBtn.TextColor3 = theme.textSecondary
    
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Parent = mainFrame
    tabBar.BackgroundColor3 = theme.bg
    tabBar.BorderSizePixel = 0
    tabBar.Position = UDim2.new(0, 0, 0, 40)
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = tabBar
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    padding(tabBar, 4, 4, 14, 14)

    local viewContainer = Instance.new("Frame")
    viewContainer.Name = "ViewContainer"
    viewContainer.Parent = mainFrame
    viewContainer.BackgroundTransparency = 1
    viewContainer.Position = UDim2.new(0, 0, 0, 76)
    viewContainer.Size = UDim2.new(1, 0, 1, -98)

    local footer = Instance.new("TextLabel")
    footer.Name = "Footer"
    footer.Parent = mainFrame
    footer.BackgroundTransparency = 1
    footer.Position = UDim2.new(0, 14, 1, -22)
    footer.Size = UDim2.new(1, -28, 0, 16)
    footer.Font = Enum.Font.GothamMedium
    footer.Text = config.Footer or ""
    footer.TextColor3 = theme.textMuted
    footer.TextSize = 10
    footer.TextXAlignment = Enum.TextXAlignment.Left

    minBtn.MouseButton1Click:Connect(function()
        isMinimised = not isMinimised
        if isMinimised then
            minBtn.Text = "+"
            tween(mainFrame, {Size = UDim2.new(0, width, 0, 40)}, TWEEN_SMOOTH)
            tween(shadow, {Size = UDim2.new(0, width + 16, 0, 56)}, TWEEN_SMOOTH)
            viewContainer.Visible = false
            tabBar.Visible = false
            footer.Visible = false
        else
            minBtn.Text = "_"
            viewContainer.Visible = true
            tabBar.Visible = true
            footer.Visible = true
            tween(mainFrame, {Size = UDim2.new(0, width, 0, height)}, TWEEN_SMOOTH)
            tween(shadow, {Size = UDim2.new(0, width + 16, 0, height + 16)}, TWEEN_SMOOTH)
        end
    end)

    mainFrame.Size = UDim2.new(0, width, 0, height)
    mainFrame.BackgroundTransparency = 1
    shadow.ImageTransparency = 1

    task.delay(0.05, function()
        tween(mainFrame, {Size = UDim2.new(0, width, 0, height), BackgroundTransparency = 0}, TWEEN_SMOOTH)
        tween(shadow, {ImageTransparency = 0.5}, TWEEN_SMOOTH)
    end)

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

    function Window:CreateTab(tabName, hasSearch)
        local tabOrder = #self._tabs + 1
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Parent = self._tabBar
        tabBtn.BackgroundColor3 = theme.surface
        tabBtn.BorderSizePixel = 0
        tabBtn.Size = UDim2.new(0, 85, 1, 0)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Text = tabName
        tabBtn.TextSize = 10
        tabBtn.TextColor3 = theme.textSecondary
        tabBtn.LayoutOrder = tabOrder
        corner(tabBtn, 5)
        
        local tabStroke = stroke(tabBtn, theme.border, 1)

        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= Tab then
                tween(tabBtn, {BackgroundColor3 = theme.surfaceHover, TextColor3 = theme.textPrimary})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= Tab then
                tween(tabBtn, {BackgroundColor3 = theme.surface, TextColor3 = theme.textSecondary})
            end
        end)

        local canvasGroup = Instance.new("CanvasGroup")
        canvasGroup.Name = tabName .. "_Canvas"
        canvasGroup.Parent = self._viewContainer
        canvasGroup.BackgroundTransparency = 1
        canvasGroup.Size = UDim2.new(1, 0, 1, 0)
        canvasGroup.GroupTransparency = 1
        canvasGroup.Visible = false

        -- Integrated filter mechanism header area
        local searchOffset = 0
        local searchBox = nil
        if hasSearch then
            searchOffset = 42
            local searchContainer = Instance.new("Frame")
            searchContainer.BackgroundColor3 = theme.surface
            searchContainer.Size = UDim2.new(1, -28, 0, 34)
            searchContainer.Position = UDim2.new(0, 14, 0, 4)
            searchContainer.Parent = canvasGroup
            corner(searchContainer, 6)
            local searchStroke = stroke(searchContainer, theme.border, 1)
            
            searchBox = Instance.new("TextBox")
            searchBox.BackgroundTransparency = 1
            searchBox.Size = UDim2.new(1, -20, 1, 0)
            searchBox.Position = UDim2.new(0, 10, 0, 0)
            searchBox.Font = Enum.Font.GothamMedium
            searchBox.PlaceholderText = "Search configuration settings..."
            searchBox.PlaceholderColor3 = theme.textMuted
            searchBox.Text = ""
            searchBox.TextColor3 = theme.textPrimary
            searchBox.TextSize = 11
            searchBox.TextXAlignment = Enum.TextXAlignment.Left
            searchBox.ClearTextOnFocus = false
            searchBox.Parent = searchContainer
            
            searchBox.Focused:Connect(function() tween(searchStroke, {Color = theme.borderActive}) end)
            searchBox.FocusLost:Connect(function() tween(searchStroke, {Color = theme.border}) end)
        end

        local scroller = Instance.new("ScrollingFrame")
        scroller.Name = "Scroller"
        scroller.Parent = canvasGroup
        scroller.BackgroundTransparency = 1
        scroller.Position = UDim2.new(0, 0, 0, searchOffset)
        scroller.Size = UDim2.new(1, 0, 1, -searchOffset)
        scroller.ScrollBarThickness = 3
        scroller.ScrollBarImageColor3 = theme.border
        scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
        padding(scroller, 4, 8, 14, 14)

        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = scroller
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 6)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 15)
        end)

        local Tab = {}
        Tab._canvas = canvasGroup
        Tab._container = scroller
        Tab._order = 0
        Tab._theme = theme
        Tab._elements = {}

        -- Live search matching processor
        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local query = searchBox.Text:lower()
                for _, entry in pairs(Tab._elements) do
                    if query == "" or string.find(entry.name:lower(), query) then
                        entry.instance.Visible = true
                    else
                        entry.instance.Visible = false
                    end
                end
            end)
        end

        local function selectTab()
            if Window._activeTab == Tab then return end
            if Window._activeTab then
                local oldTab = Window._activeTab
                oldTab._btn.BackgroundColor3 = theme.surface
                oldTab._btn.TextColor3 = theme.textSecondary
                oldTab._stroke.Color = theme.border
                task.spawn(function()
                    tween(oldTab._canvas, {GroupTransparency = 1}, TWEEN_FAST)
                    task.wait(0.15)
                    oldTab._canvas.Visible = false
                end)
            end
            Window._activeTab = Tab
            canvasGroup.Visible = true
            tween(canvasGroup, {GroupTransparency = 0}, TWEEN_FAST)
            tabBtn.BackgroundColor3 = theme.accentSurface
            tabBtn.TextColor3 = theme.accent
            tabStroke.Color = theme.borderActive
        end

        tabBtn.MouseButton1Click:Connect(selectTab)
        Tab._btn = tabBtn
        Tab._stroke = tabStroke
        
        if tabOrder == 1 then
            canvasGroup.Visible = true
            canvasGroup.GroupTransparency = 0
            Window._activeTab = Tab
            tabBtn.BackgroundColor3 = theme.accentSurface
            tabBtn.TextColor3 = theme.accent
            tabStroke.Color = theme.borderActive
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
            btn.Size = UDim2.new(1, 0, 0, 38)
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
            label.Size = UDim2.new(1, -75, 1, 0)
            label.Font = Enum.Font.GothamMedium
            label.Text = state and onText or offText
            label.TextColor3 = state and theme.textPrimary or theme.textSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left

            local statusIndicator = Instance.new("TextLabel")
            statusIndicator.Parent = btn
            statusIndicator.BackgroundTransparency = 1
            statusIndicator.Position = UDim2.new(1, -55, 0, 0)
            statusIndicator.Size = UDim2.new(0, 45, 1, 0)
            statusIndicator.Font = Enum.Font.GothamBold
            statusIndicator.Text = state and "ACTIVE" or "IDLE"
            statusIndicator.TextColor3 = state and theme.accent or theme.textMuted
            statusIndicator.TextSize = 9
            statusIndicator.TextXAlignment = Enum.TextXAlignment.Right

            local function updateVisual()
                if state then
                    label.Text = onText
                    statusIndicator.Text = "ACTIVE"
                    tween(statusIndicator, {TextColor3 = theme.accent})
                    tween(label, {TextColor3 = theme.textPrimary})
                    tween(btn, {BackgroundColor3 = theme.accentSurface})
                    tween(btnStroke, {Color = theme.borderActive})
                    tween(dot, {BackgroundColor3 = theme.dotOn})
                else
                    label.Text = offText
                    statusIndicator.Text = "IDLE"
                    tween(statusIndicator, {TextColor3 = theme.textMuted})
                    tween(label, {TextColor3 = theme.textSecondary})
                    tween(btn, {BackgroundColor3 = theme.surface})
                    tween(btnStroke, {Color = theme.border})
                    tween(dot, {BackgroundColor3 = theme.dotOff})
                end
            end

            if state then updateVisual() end

            -- Interactivity glow implementation
            btn.MouseEnter:Connect(function()
                tween(btnStroke, {Color = theme.borderActive})
                if not state then tween(btn, {BackgroundColor3 = theme.surfaceHover}) end
            end)
            btn.MouseLeave:Connect(function()
                tween(btnStroke, {Color = state and theme.borderActive or theme.border})
                if not state then tween(btn, {BackgroundColor3 = theme.surface}) end
            end)

            btn.MouseButton1Click:Connect(function()
                state = not state
                updateVisual()
                createToast((state and "Activated " or "Deactivated ") .. (cfg.Text or "Module"), "info")
                if cfg.Callback then cfg.Callback(state) end
            end)

            table.insert(self._elements, {name = cfg.Text or offText, instance = btn})
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
            btn.Size = UDim2.new(1, 0, 0, 38)
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

            btn.MouseEnter:Connect(function() 
                tween(btnStroke, {Color = theme.borderActive})
                tween(btn, {BackgroundColor3 = theme.surfaceHover, TextColor3 = theme.textPrimary}) 
            end)
            btn.MouseLeave:Connect(function() 
                tween(btnStroke, {Color = theme.border})
                tween(btn, {BackgroundColor3 = theme.surface, TextColor3 = theme.textSecondary}) 
            end)

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
            
            function handle:GetButton() return btn end

            btn.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback(handle) end end)
            table.insert(self._elements, {name = cfg.Text or "Button", instance = btn})
            return handle
        end

        function Tab:AddInputField(titleText, defaultText, callback)
            self._order = self._order + 1

            local container = Instance.new("Frame")
            container.Parent = self._container
            container.BackgroundColor3 = theme.surface
            container.BorderSizePixel = 0
            container.Size = UDim2.new(1, 0, 0, 38)
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

            box.Focused:Connect(function()
                tween(containerStroke, {Color = theme.borderActive})
            end)

            box.FocusLost:Connect(function(enterPressed)
                tween(containerStroke, {Color = theme.border})
                createToast("Updated setting: " .. titleText .. " -> " .. box.Text, "success")
                if callback then callback(box.Text) end
            end)

            table.insert(self._elements, {name = titleText, instance = container})
            local handle = {}
            function handle:SetText(t) box.Text = t end
            return handle
        end

        function Tab:AddSectionHeader(text)
            self._order = self._order + 1
            
            local headerFrame = Instance.new("Frame")
            headerFrame.Parent = self._container
            headerFrame.BackgroundTransparency = 1
            headerFrame.Size = UDim2.new(1, 0, 0, 24)
            headerFrame.LayoutOrder = self._order
            padding(headerFrame, 6, 0, 2, 0)
            
            local lbl = Instance.new("TextLabel")
            lbl.Parent = headerFrame
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.Text = string.upper(text)
            lbl.TextColor3 = theme.accent
            lbl.TextSize = 10
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            table.insert(self._elements, {name = text, instance = headerFrame})
        end

        function Tab:AddDisplayCard(titleText, defaultVal, dotColor)
            self._order = self._order + 1
            
            local card = Instance.new("Frame")
            card.Parent = self._container
            card.BackgroundColor3 = theme.surface
            card.Size = UDim2.new(1, 0, 0, 44)
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
-- SYSTEM CONFIGURATION
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
    Size = {295, 680},
    Position = {0.05, 0.25},
    Footer = "PRESS [N] TO TOGGLE INTERFACE"
})

task.spawn(function()
    delayTimer(1)
    syncTenCrateState()
end)

-- ==========================================
-- ANTI-AFK IMMUNITY HOOK
-- ==========================================
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if running then
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

local function postWebhookUpdate(isTestMsg)
    if not DiscordWebhookURL or DiscordWebhookURL == "" or DiscordWebhookURL == "YOUR_WEBHOOK_URL_HERE" then 
        return false, "No URL Configured" 
    end

    local totalSecs = SavedConfig.TotalSessionTime or 0
    local hours = math.floor(totalSecs / 3600)
    local mins = math.floor((totalSecs % 3600) / 60)
    local formattedTimeStr = string.format("%dh %dm", hours, mins)

    local cashPerHour = 0
    if totalSecs > 0 then
        cashPerHour = math.floor(((SavedConfig.TotalSessionEarned or 0) / totalSecs) * 3600)
    end

    local data = {
        ["embeds"] = {{
            ["title"] = isTestMsg and "Test" or "report blud",
            ["color"] = isTestMsg and 15844367 or 527196,
            ["fields"] = {
                {["name"] = "Mythic Shards", ["value"] = "```" .. formatNumber(absoluteLastKnownShards) .. "```", ["inline"] = true},
                {["name"] = "Total Server Reconnects", ["value"] = "```" .. tostring(SavedConfig.ReconnectCount or 0) .. "```", ["inline"] = true},
                {["name"] = "Total Money Earned", ["value"] = "```$" .. formatNumber(SavedConfig.TotalSessionEarned or 0) .. "```", ["inline"] = false},
                {["name"] = "Money Per Hour", ["value"] = "```$" .. formatNumber(cashPerHour) .. "/hr```", ["inline"] = true},
                {["name"] = "Playtime", ["value"] = "```" .. formattedTimeStr .. "```", ["inline"] = true}
            },
            ["footer"] = {["text"] = isTestMsg and "Webhook Connection verified successfully." or "Automator Engine Live Log Update"},
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    local jsonPayload = HttpService:JSONEncode(data)
    local success, err = pcall(function()
        local httpFunc = request or http_request or (syn and syn.request)
        if httpFunc then
            httpFunc({Url = DiscordWebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonPayload})
        else
            error("Executor missing generic HTTP Pipeline support.")
        end
    end)
    return success, err
end

-- ==========================================
-- TAB 1: DASHBOARD TRACKERS
-- ==========================================
local DashboardTab = Window:CreateTab("Dashboard", false)
DashboardTab:AddSectionHeader("Live Statistics")
DashboardTab:AddDivider()

local cashCard = DashboardTab:AddDisplayCard("Total Money Earned (Saved)", "$0", DEFAULT_THEME.accent)
local incomeCard = DashboardTab:AddDisplayCard("Money Per Hour", "$0 / hr", DEFAULT_THEME.accent)
local shardCard = DashboardTab:AddDisplayCard("Mythic Shards", "0", DEFAULT_THEME.info)
local sessionCard = DashboardTab:AddDisplayCard("Total Playtime (Saved)", "00h 00m 00s", DEFAULT_THEME.warning)
local reconnectCard = DashboardTab:AddDisplayCard("Total Reconnects (Saved)", tostring(SavedConfig.ReconnectCount), DEFAULT_THEME.danger)

-- ==========================================
-- AUTO RECONNECT BACKGROUND HANDLER
-- ==========================================
task.spawn(function()
    GuiService.ErrorMessageChanged:Connect(function()
        Window._footer.Text = "Disconnected! Tracking reconnect..."
        Window._footer.TextColor3 = DEFAULT_THEME.danger
        
        SavedConfig.ReconnectCount = (SavedConfig.ReconnectCount or 0) + 1
        saveSettings()
        reconnectCard:Update(tostring(SavedConfig.ReconnectCount))
        
        delayTimer(5)
        
        local success, err = pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
        
        if not success then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end)

task.spawn(function()
    while running do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("hud")
            local cashFrame = hud and hud:FindFirstChild("cashFrame")
            local cashAmount = cashFrame and cashFrame:FindFirstChild("cashAmount")
            
            local currentLiveCash = 0
            if cashAmount then
                local textSrc = cashAmount.ContentText ~= "" and cashAmount.ContentText or cashAmount.Text
                currentLiveCash = parseCashString(textSrc)
            else
                local stats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("ProfileData")
                local cashObj = stats and (stats:FindFirstChild("Cash") or stats:FindFirstChild("Money") or stats:FindFirstChild("Coins"))
                if cashObj then currentLiveCash = cashObj.Value end
            end

            if currentLiveCash > 0 then
                if not initialCashValue then
                    initialCashValue = currentLiveCash
                    lastObservedCash = currentLiveCash
                end

                if currentLiveCash > lastObservedCash then
                    local difference = currentLiveCash - lastObservedCash
                    SavedConfig.TotalSessionEarned = (SavedConfig.TotalSessionEarned or 0) + difference
                end
                lastObservedCash = currentLiveCash
            end
            
            cashCard:Update("$" .. formatNumber(SavedConfig.TotalSessionEarned))

            local totalSecs = SavedConfig.TotalSessionTime or 0
            local cashPerHour = 0
            if totalSecs > 0 then
                cashPerHour = math.floor(((SavedConfig.TotalSessionEarned or 0) / totalSecs) * 3600)
            end
            incomeCard:Update("$" .. formatNumber(cashPerHour) .. " / hr")

            local parsedShardsValue = nil
            local stats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("ProfileData") or LocalPlayer:FindFirstChild("skyblock")
            if stats then
                local foundObj = stats:FindFirstChild("Shards") or stats:FindFirstChild("MythicShards") or stats:FindFirstChild("MythicShard")
                if foundObj and foundObj:IsA("ValueBase") then
                    parsedShardsValue = tonumber(foundObj.Value)
                end
            end
            
            if not parsedShardsValue then
                local mythicFrame = hud and hud:FindFirstChild("mythicShardFrame")
                local title = mythicFrame and mythicFrame:FindFirstChild("title")
                local shardFrame = title and title:FindFirstChild("shardFrame")
                local amountLabel = shardFrame and shardFrame:FindFirstChild("amount")

                if amountLabel and amountLabel.Text ~= "" then
                    local shardSrc = amountLabel.ContentText ~= "" and amountLabel.ContentText or amountLabel.Text
                    local uiCheckValue = parseCashString(shardSrc)
                    if uiCheckValue ~= 999999 and uiCheckValue > 0 then
                        parsedShardsValue = uiCheckValue
                    end
                end
            end
            
            if parsedShardsValue and parsedShardsValue ~= 999999 then
                absoluteLastKnownShards = parsedShardsValue
            end
            
            shardCard:Update(formatNumber(absoluteLastKnownShards))
        end)

        SavedConfig.TotalSessionTime = (SavedConfig.TotalSessionTime or 0) + 1
        
        local totalSecs = SavedConfig.TotalSessionTime
        local hours = math.floor(totalSecs / 3600)
        local mins = math.floor((totalSecs % 3600) / 60)
        local secs = totalSecs % 60
        sessionCard:Update(string.format("%02dh %02dm %02ds", hours, mins, secs))

        if totalSecs % 5 == 0 then
            saveSettings()
        end

        delayTimer(1)
    end
end)

-- ==========================================
-- AUTOMATIC DISCORD WEBHOOK CRON THREAD
-- ==========================================
task.spawn(function()
    task.wait(10)
    while running do
        postWebhookUpdate(false)
        task.wait(3600)
    end
end)

-- ==========================================
-- TAB 2: AUTOMATOR CONTROLS (WITH SEARCH MECHANIC)
-- ==========================================
local AutomatorTab = Window:CreateTab("Automator", true)

AutomatorTab:AddSectionHeader("Plot System Loops")
AutomatorTab:AddDivider()

AutomatorTab:AddToggle({
    Text = "Auto Collect Buildings",
    Default = SavedConfig.AutoCollect,
    OnText = "Auto Collect: ON",
    OffText = "Auto Collect: OFF",
    Callback = function(state)
        collectingActive = state
        SavedConfig.AutoCollect = state
        saveSettings()
    end
})

AutomatorTab:AddToggle({
    Text = "Auto Buy Vendor Shop",
    Default = SavedConfig.AutoBuy,
    OnText = "Auto Buy Shop: ON",
    OffText = "Auto Buy Shop: OFF",
    Callback = function(state)
        buyActive = state
        SavedConfig.AutoBuy = state
        saveSettings()
    end
})

AutomatorTab:AddToggle({
    Text = "Auto Dismantle Mythics",
    Default = SavedConfig.AutoDismantle,
    OnText = "Auto Dismantle: ON",
    OffText = "Auto Dismantle: OFF",
    Callback = function(state)
        dismantleActive = state
        SavedConfig.AutoDismantle = state
        saveSettings()
    end
})

AutomatorTab:AddToggle({
    Text = "Auto Crate Open Loop",
    Default = SavedConfig.AutoCrate,
    OnText = "Auto Crate Loop: ON",
    OffText = "Auto Crate Loop: OFF",
    Callback = function(state)
        crateActive = state
        SavedConfig.AutoCrate = state
        saveSettings()
        if state then syncTenCrateState() end
    end
})

local crateTypes = {"Elite", "Titan", "Decorative", "Standard", "Golden"}
local function getNextCrateType(current)
    for i, v in ipairs(crateTypes) do
        if v == current then
            return crateTypes[i % #crateTypes + 1]
        end
    end
    return "Elite"
end

local crateTypeBtn
crateTypeBtn = AutomatorTab:AddButton({
    Text = "Crate Selected: " .. (SavedConfig.CrateType or "Elite"),
    DotColor = DEFAULT_THEME.info,
    Callback = function(btn)
        local nextType = getNextCrateType(SavedConfig.CrateType or "Elite")
        SavedConfig.CrateType = nextType
        saveSettings()
        btn:SetState("reset", "Crate Selected: " .. nextType)
        createToast("Crate rotation set to: " .. nextType, "info")
    end
})

AutomatorTab:AddInputField("Min Cash To Buy", SavedConfig.CrateMinCashText or "5B", function(text)
    if text and text ~= "" then
        local parsedVal = parseCashString(text)
        if parsedVal >= 0 then
            SavedConfig.CrateMinCashRequirement = parsedVal
            SavedConfig.CrateMinCashText = text
            saveSettings()
        end
    end
end)

AutomatorTab:AddToggle({
    Text = "Auto Playtime Rewards",
    Default = SavedConfig.AutoPlaytime,
    OnText = "Auto Playtime: ON",
    OffText = "Auto Playtime: OFF",
    Callback = function(state)
        rewardActive = state
        SavedConfig.AutoPlaytime = state
        saveSettings()
    end
})

-- ==========================================
-- UTILITY HOOKS
-- ==========================================
AutomatorTab:AddDivider()
AutomatorTab:AddSectionHeader("Utility Handlers")

AutomatorTab:AddButton({
    Text = "Reset Cached Counters to 0",
    DotColor = DEFAULT_THEME.warning,
    Callback = function(btn)
        SavedConfig.ReconnectCount = 0
        SavedConfig.TotalSessionEarned = 0
        SavedConfig.TotalSessionTime = 0
        saveSettings()
        
        reconnectCard:Update("0")
        cashCard:Update("$0")
        incomeCard:Update("$0 / hr")
        sessionCard:Update("00h 00m 00s")
        
        createToast("Session database cache cleared successfully", "success")
    end
})

AutomatorTab:AddButton({
    Text = "Force Test Discord Webhook",
    DotColor = DEFAULT_THEME.accent,
    Callback = function(btn)
        btn:SetState("loading", "Sending Post...")
        local ok, err = postWebhookUpdate(true)
        if ok then
            btn:SetState("reset")
            createToast("Discord payload synchronized successfully!", "success")
        else
            btn:SetState("reset")
            createToast("Failed: Webhook delivery failure.", "danger")
            warn("Webhook execution error details: ", tostring(err))
        end
    end
})

AutomatorTab:AddButton({
    Text = "Launch Infinite Yield",
    DotColor = DEFAULT_THEME.info,
    Callback = function(btn)
        btn:SetState("loading", "Executing...")
        local success, err = pcall(function()
            local content = game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source', true)
            loadstring(content)()
        end)
        if success then
            btn:SetState("reset")
            createToast("Infinite Yield injected into environment.", "success")
        else
            btn:SetState("reset")
            createToast("Execution failure on payload hook.", "danger")
            warn("Failed to load Infinite Yield: " .. tostring(err))
        end
    end
})

AutomatorTab:AddButton({
    Text = "Unload UI Interface Script",
    DotColor = DEFAULT_THEME.danger,
    Callback = function(btn)
        createToast("Deconstructing operational pipelines...", "warning")
        running = false
        collectingActive = false
        buyActive = false
        dismantleActive = false
        crateActive = false
        rewardActive = false
        task.wait(0.4)
        Window._screenGui:Destroy()
    end
})

-- ==========================================
-- BACKGROUND AUTOMATION ENGINE THREADS
-- ==========================================

-- REALLY FAST PACED COLLECTOR (NON-INSTANT)
task.spawn(function()
    local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
    local Resources = Shared and Shared:WaitForChild("Resources", 5)
    local PlotResources = Resources and Resources:WaitForChild("PlotResources", 5)
    local Remotes = PlotResources and PlotResources:WaitForChild("Remotes", 5)
    local Event = Remotes and Remotes:WaitForChild("Collect", 5)

    local plotName = LocalPlayer.Name .. "'s plot"
    local structuresFolder = workspace:WaitForChild("Plots", 5)
        and workspace.Plots:WaitForChild(plotName, 5)
        and workspace.Plots[plotName]:WaitForChild("baseplate", 5)
        and workspace.Plots[plotName].baseplate:WaitForChild("Structures", 5)

    while true do
        if not running then break end
        if collectingActive and Event and structuresFolder then
            for _, tower in pairs(structuresFolder:GetChildren()) do
                if not collectingActive then break end
                if tower:IsA("Instance") then
                    Event:FireServer(tower)
                    task.wait(0.01)
                end
            end
            delayTimer(0.2)
        else
            delayTimer(0.5)
        end
    end
end)

task.spawn(function()
    local PurchaseEvent = ReplicatedStorage:WaitForChild("Shared")
        :WaitForChild("Resources"):WaitForChild("VendorResources")
        :WaitForChild("Remotes"):WaitForChild("PurchaseStructure")

    local structuresToBuy = {
        "Corporate Campus", "Luxury Resort", "Semiconductor Plant", "Cookie Stand",
        "Shield Generator", "Behemoth Fortress", "Officer Quarters", "Fleet Command",
        "Heavy Weapons Depot", "Naval Shipyard", "ATC Tower", "Field Tent",
        "Regional Depot", "Cargo Dockyard", "Advanced Supply Depot",
    }

    while true do
        if not running then break end
        if buyActive and PurchaseEvent then
            for _, name in ipairs(structuresToBuy) do
                if not buyActive then break end
                task.spawn(function()
                    PurchaseEvent:FireServer(name)
                end)
            end
            delayTimer(0.1)
        else
            delayTimer(0.5)
        end
    end
end)

task.spawn(function()
    local DismantleEvent = ReplicatedStorage:WaitForChild("Shared")
        :WaitForChild("Resources"):WaitForChild("VendorResources")
        :WaitForChild("Remotes"):WaitForChild("DismantleMythicStructure")

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
            delayTimer(0.1)
        else
            delayTimer(0.5)
        end
    end
end)

task.spawn(function()
    local LootCrateRemotes = ReplicatedStorage:WaitForChild("Shared")
        :WaitForChild("Resources"):WaitForChild("LootCrateResources")
        :WaitForChild("Remotes")

    local CrateEvent = LootCrateRemotes:WaitForChild("OpenLootCrate")

    while true do
        if not running then break end
        if crateActive and CrateEvent then
            local currentLiveCash = 0
            local hud = LocalPlayer.PlayerGui:FindFirstChild("hud")
            local cashAmount = hud and hud:WaitForChild("cashFrame"):WaitForChild("cashAmount")
            if cashAmount then
                local rawText = cashAmount.ContentText ~= "" and cashAmount.ContentText or cashAmount.Text
                currentLiveCash = parseCashString(rawText)
            end

            local targetMin = SavedConfig.CrateMinCashRequirement or 5000000000
            if currentLiveCash >= targetMin then
                CrateEvent:FireServer(SavedConfig.CrateType or "Elite", 10000)
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
    local RewardEvent = ReplicatedStorage:WaitForChild("Shared")
        :WaitForChild("Resources"):WaitForChild("RewardResources")
        :WaitForChild("Remotes"):WaitForChild("ClaimPlaytimeReward")

    while true do
        if not running then break end
        if rewardActive and RewardEvent then
            for i = 1, 6 do
                if not rewardActive then break end
                RewardEvent:FireServer(i)
                delayTimer(0.5)
            end
            delayTimer(30)
        else
            delayTimer(0.5)
        end
    end
end)

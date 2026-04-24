-- Blox Fruits Auto Farm Script
-- Creado a medida según tus especificaciones

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- Funciones de guardado de configuración
local configName = "BloxFruitsConfig_Slayer.json"
local cfg = {
    distanceValue = 5,
    posName = "Arriba",
    selectedWeapon = "Auto"
}

local function saveSettings()
    if writefile then
        pcall(function()
            writefile(configName, HttpService:JSONEncode(cfg))
        end)
    end
end

local function loadSettings()
    if isfile and isfile(configName) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(configName))
            if decoded.distanceValue then cfg.distanceValue = decoded.distanceValue end
            if decoded.posName then cfg.posName = decoded.posName end
            if decoded.selectedWeapon then cfg.selectedWeapon = decoded.selectedWeapon end
        end)
    end
end
loadSettings()

-- Limpiar interfaz anterior si existe
local existing = CoreGui:FindFirstChild("AutoFarmMenuUI") or player:WaitForChild("PlayerGui"):FindFirstChild("AutoFarmMenuUI")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmMenuUI"
ScreenGui.ResetOnSpawn = false
-- Intentar ponerlo en CoreGui (común en exploits) o en PlayerGui
local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

-- Variables de Estado
local isMenuOpen = true
local autoFarmEnabled = false
local autoClickEnabled = false

-- Marco Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 310) -- Más grande para que quepan las nuevas opciones
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = isMenuOpen
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Menú Auto Farm"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local function createButton(text, yPos, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.9, 0, 0, 35)
    Btn.Position = UDim2.new(0.05, 0, 0, yPos)
    Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14
    Btn.Parent = MainFrame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    Btn.MouseButton1Click:Connect(function()
        callback(Btn)
    end)
    return Btn
end

local function createSlider(text, yPos, min, max, default)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.9, 0, 0, 45)
    Frame.Position = UDim2.new(0.05, 0, 0, yPos)
    Frame.BackgroundTransparency = 1
    Frame.Parent = MainFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0.5, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local SliderBG = Instance.new("TextButton")
    SliderBG.Size = UDim2.new(1, 0, 0.3, 0)
    SliderBG.Position = UDim2.new(0, 0, 0.7, 0)
    SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    SliderBG.Text = ""
    SliderBG.Parent = Frame
    Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1, 0)
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    SliderFill.Parent = SliderBG
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
    
    local isDragging = false
    SliderBG.MouseButton1Down:Connect(function() isDragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if isDragging then
            local mousePos = UserInputService:GetMouseLocation().X
            local relX = math.clamp((mousePos - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
            SliderFill.Size = UDim2.new(relX, 0, 1, 0)
            local val = math.floor(min + (max - min) * relX)
            cfg.distanceValue = val
            Label.Text = text .. ": " .. val
            saveSettings()
        end
    end)
end

local function createDropdown(text, yPos, getOptionsFunc, defaultOption, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.9, 0, 0, 35)
    Frame.Position = UDim2.new(0.05, 0, 0, yPos)
    Frame.BackgroundTransparency = 1
    Frame.Parent = MainFrame
    
    local MainBtn = Instance.new("TextButton")
    MainBtn.Size = UDim2.new(1, 0, 1, 0)
    MainBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    MainBtn.Text = text .. ": " .. defaultOption
    MainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MainBtn.Font = Enum.Font.Gotham
    MainBtn.TextSize = 14
    MainBtn.ZIndex = 2
    MainBtn.Parent = Frame
    Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 6)
    
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 0, 100)
    Scroll.Position = UDim2.new(0, 0, 1, 2)
    Scroll.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Scroll.BorderSizePixel = 0
    Scroll.Visible = false
    Scroll.ZIndex = 5
    Scroll.ScrollBarThickness = 4
    Scroll.Parent = Frame
    Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 6)
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = Scroll
    
    MainBtn.MouseButton1Click:Connect(function()
        Scroll.Visible = not Scroll.Visible
        if Scroll.Visible then
            for _, child in ipairs(Scroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            local opts = getOptionsFunc()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, #opts * 30)
            for _, opt in ipairs(opts) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 30)
                OptBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                OptBtn.Text = opt
                OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.TextSize = 14
                OptBtn.ZIndex = 6
                OptBtn.Parent = Scroll
                OptBtn.MouseButton1Click:Connect(function()
                    MainBtn.Text = text .. ": " .. opt
                    Scroll.Visible = false
                    callback(opt)
                end)
            end
        end
    end)
    
    return MainBtn
end

-- Creación de Componentes de la Interfaz
local AutoFarmBtn = createButton("Auto Farm Money: OFF", 50, function(btn)
    autoFarmEnabled = not autoFarmEnabled
    btn.Text = "Auto Farm Money: " .. (autoFarmEnabled and "ON" or "OFF")
    btn.BackgroundColor3 = autoFarmEnabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(50, 50, 55)
end)

local posOptionsList = {"Arriba", "Lado", "Abajo"}
createDropdown("Posición", 95, function() return posOptionsList end, cfg.posName, function(selected)
    cfg.posName = selected
    saveSettings()
end)

createSlider("Distancia al NPC (M)", 140, 0, 30, cfg.distanceValue)

-- Función que recolecta todas tus armas del inventario
local function getWeaponOptions()
    local opts = {"Auto"}
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and not table.find(opts, tool.Name) then table.insert(opts, tool.Name) end
    end
    if player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") and not table.find(opts, tool.Name) then table.insert(opts, tool.Name) end
        end
    end
    return opts
end

createDropdown("Arma", 195, getWeaponOptions, cfg.selectedWeapon, function(selected)
    cfg.selectedWeapon = selected
    saveSettings()
end)

local AutoClickBtn = createButton("Auto Click Remotes: OFF", 250, function(btn)
    autoClickEnabled = not autoClickEnabled
    btn.Text = "Auto Click Remotes: " .. (autoClickEnabled and "ON" or "OFF")
    btn.BackgroundColor3 = autoClickEnabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(50, 50, 55)
end)

-- Lógica para abrir/cerrar menú
local function toggleMenu()
    isMenuOpen = not isMenuOpen
    MainFrame.Visible = isMenuOpen
end

-- Toggle con Insert (PC)
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Insert then
        toggleMenu()
    end
end)

-- Botón para Móviles
if UserInputService.TouchEnabled then
    local MobileToggle = Instance.new("TextButton")
    MobileToggle.Size = UDim2.new(0, 50, 0, 50)
    MobileToggle.Position = UDim2.new(0, 10, 0.5, 0)
    MobileToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MobileToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileToggle.Text = "Menú"
    MobileToggle.Font = Enum.Font.GothamBold
    MobileToggle.Parent = ScreenGui
    Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(0, 8)
    MobileToggle.MouseButton1Click:Connect(toggleMenu)
end

-- Lógica Interna del Script

-- Verifica si ya tienes una misión activa leyendo la interfaz de Blox Fruits
local function hasActiveQuest()
    local mainUI = player:WaitForChild("PlayerGui"):FindFirstChild("Main")
    if mainUI and mainUI:FindFirstChild("Quest") then
        return mainUI.Quest.Visible
    end
    return false
end

local lastQuestTime = 0
local function checkAndStartQuest()
    -- Solo pide la misión si NO tienes una misión activa
    if not hasActiveQuest() and tick() - lastQuestTime > 5 then
        lastQuestTime = tick()
        task.spawn(function()
            local args = {
                "StartQuest",
                "TikiQuest3",
                2
            }
            pcall(function()
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
            end)
        end)
    end
end

-- Equipa el arma seleccionada en el Dropdown
local function equipSelectedTool()
    local char = player.Character
    if not char then return end
    
    local targetToolName = cfg.selectedWeapon
    
    if targetToolName == "Auto" then
        if char:FindFirstChildOfClass("Tool") then return end
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = char
                break
            end
        end
    else
        -- Equipa un arma específica
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and currentTool.Name == targetToolName then
            return -- Ya la tiene en la mano
        end
        
        -- Si tiene otra cosa equipada, la devuelve a la mochila
        if currentTool then
            currentTool.Parent = player.Backpack
        end
        
        -- Saca el arma elegida de la mochila y la pone en el personaje
        local toolInBackpack = player.Backpack:FindFirstChild(targetToolName)
        if toolInBackpack and toolInBackpack:IsA("Tool") then
            toolInBackpack.Parent = char
        end
    end
end

local function getEnemy()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    
    local bestEnemy = nil
    local shortestDist = math.huge
    
    if workspace:FindFirstChild("Enemies") then
        for _, obj in ipairs(workspace.Enemies:GetChildren()) do
            if string.find(string.lower(obj.Name), "skull slayer") and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj:FindFirstChild("HumanoidRootPart") then
                local dist = (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    bestEnemy = obj
                end
            end
        end
    end
    return bestEnemy
end

local function getPositionOffset(eHrp)
    local targetPos = eHrp.Position
    local posName = cfg.posName
    local distanceValue = cfg.distanceValue
    
    if posName == "Arriba" then
        return CFrame.new(targetPos + Vector3.new(0, distanceValue, 0), targetPos)
    elseif posName == "Abajo" then
        return CFrame.new(targetPos + Vector3.new(0, -distanceValue, 0), targetPos)
    else -- Lado
        return CFrame.new(targetPos + Vector3.new(distanceValue, 0, 0), targetPos)
    end
end

-- Bucle Principal del Auto Farm
task.spawn(function()
    while task.wait() do
        if autoFarmEnabled then
            checkAndStartQuest()
            local targetEnemy = getEnemy()
            
            if targetEnemy then
                local eHrp = targetEnemy:FindFirstChild("HumanoidRootPart")
                local eHum = targetEnemy:FindFirstChild("Humanoid")
                
                while autoFarmEnabled and targetEnemy.Parent and eHum and eHum.Health > 0 do
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        -- Teletransportar y mirar al NPC
                        char.HumanoidRootPart.CFrame = getPositionOffset(eHrp)
                        
                        -- Anti-Fling: Previene salir volando al matar al NPC
                        char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                        char.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
                        
                        equipSelectedTool()
                    end
                    task.wait()
                end
            else
                task.wait(1)
            end
        end
    end
end)

local lastAttackTick = 0

-- Bucle del Auto Click (Remotes)
RunService.RenderStepped:Connect(function()
    if autoClickEnabled and not isMenuOpen then
        -- Disparar los Remotes de ataque rápido sin click físico
        if tick() - lastAttackTick >= 0.1 then
            lastAttackTick = tick()
            local targetEnemy = getEnemy()
            if targetEnemy then
                local hitPart = targetEnemy:FindFirstChild("LowerTorso") or targetEnemy:FindFirstChild("HumanoidRootPart")
                if hitPart then
                    task.spawn(function()
                        pcall(function()
                            local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                            Net:WaitForChild("RE/RegisterAttack"):FireServer(0.4000000059604645)
                            
                            local hitArgs = {
                                hitPart,
                                {},
                                [4] = "991f3c02"
                            }
                            Net:WaitForChild("RE/RegisterHit"):FireServer(unpack(hitArgs))
                        end)
                    end)
                end
            end
        end
    end
end)

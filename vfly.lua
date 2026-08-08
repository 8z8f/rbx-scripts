local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer

local CONFIG = {
    Speed = 600,
    ToggleKey = 80,
    DefaultEnabled = false,
    UIKey = 221
}

local enabled = CONFIG.DefaultEnabled
local keyDebounce = false
local seatPart = nil
local heartbeatConnection = nil
local uiVisible = true

local ui = {}
local UI_X = 20
local UI_Y = 20
local UI_W = 260
local UI_H = 160
local UI_TITLE_H = 32
local SLIDER_X = 30
local SLIDER_Y = 75
local SLIDER_W = 200
local SLIDER_H = 10

local isDraggingSlider = false
local isDraggingUI = false
local dragStartPos = nil
local dragStartUI = nil
local arrowCooldown = 0
local ARROW_COOLDOWN = 0.12

local function getPlayerCar()
    local playerName = LocalPlayer.Name
    local carName = playerName .. "sCar"
    return Workspace:FindFirstChild(carName)
end

local function getMousePos()
    local mouse = LocalPlayer:GetMouse()
    if mouse then
        return Vector2.new(mouse.X, mouse.Y)
    end
    return nil
end

local function createUI()
    local win = Drawing.new("Square")
    win.Filled = true
    win.Color = Color3.fromRGB(25, 25, 35)
    win.Position = Vector2.new(UI_X, UI_Y)
    win.Size = Vector2.new(UI_W, UI_H)
    win.Transparency = 0.9
    win.ZIndex = 10
    win.Visible = true
    ui.window = win

    local borderColor = Color3.fromRGB(60, 120, 200)
    local borderThick = 2
    local bPos = win.Position
    local bSize = win.Size
    local lines = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = borderThick
        line.Color = borderColor
        line.Transparency = 0.4
        line.ZIndex = 9
        line.Visible = true
        lines[i] = line
    end
    lines[1].From = bPos
    lines[1].To = Vector2.new(bPos.X + bSize.X, bPos.Y)
    lines[2].From = Vector2.new(bPos.X, bPos.Y + bSize.Y)
    lines[2].To = Vector2.new(bPos.X + bSize.X, bPos.Y + bSize.Y)
    lines[3].From = bPos
    lines[3].To = Vector2.new(bPos.X, bPos.Y + bSize.Y)
    lines[4].From = Vector2.new(bPos.X + bSize.X, bPos.Y)
    lines[4].To = Vector2.new(bPos.X + bSize.X, bPos.Y + bSize.Y)
    ui.border = lines

    local titleBg = Drawing.new("Square")
    titleBg.Filled = true
    titleBg.Color = Color3.fromRGB(45, 45, 60)
    titleBg.Position = Vector2.new(UI_X, UI_Y)
    titleBg.Size = Vector2.new(UI_W, UI_TITLE_H)
    titleBg.Transparency = 0.3
    titleBg.ZIndex = 10
    titleBg.Visible = true
    ui.titleBg = titleBg

    local title = Drawing.new("Text")
    title.Text = "Vehicle Fly"
    title.Color = Color3.fromRGB(230, 230, 255)
    title.Position = Vector2.new(UI_X + 12, UI_Y + 6)
    title.Size = 20
    title.Font = Drawing.Fonts.UI
    title.Center = false
    title.Outline = true
    title.ZIndex = 11
    title.Visible = true
    ui.title = title

    local speedVal = Drawing.new("Text")
    speedVal.Text = tostring(CONFIG.Speed)
    speedVal.Color = Color3.fromRGB(100, 200, 255)
    speedVal.Position = Vector2.new(UI_X + UI_W - 60, UI_Y + 40)
    speedVal.Size = 28
    speedVal.Font = Drawing.Fonts.UI
    speedVal.Center = false
    speedVal.Outline = true
    speedVal.ZIndex = 12
    speedVal.Visible = true
    ui.speedVal = speedVal

    local spdLabel = Drawing.new("Text")
    spdLabel.Text = "Speed"
    spdLabel.Color = Color3.fromRGB(200, 200, 200)
    spdLabel.Position = Vector2.new(UI_X + 12, UI_Y + 42)
    spdLabel.Size = 14
    spdLabel.Font = Drawing.Fonts.UI
    spdLabel.Center = false
    spdLabel.ZIndex = 11
    spdLabel.Visible = true
    ui.speedLabel = spdLabel

    local track = Drawing.new("Square")
    track.Filled = true
    track.Color = Color3.fromRGB(60, 60, 80)
    track.Position = Vector2.new(UI_X + SLIDER_X, UI_Y + SLIDER_Y)
    track.Size = Vector2.new(SLIDER_W, SLIDER_H)
    track.Transparency = 0.3
    track.ZIndex = 10
    track.Visible = true
    ui.sliderTrack = track

    local fill = Drawing.new("Square")
    fill.Filled = true
    fill.Color = Color3.fromRGB(100, 180, 255)
    fill.Position = track.Position
    fill.Size = Vector2.new(0, SLIDER_H)
    fill.Transparency = 0.5
    fill.ZIndex = 11
    fill.Visible = true
    ui.sliderFill = fill

    local handle = Drawing.new("Circle")
    handle.Filled = true
    handle.Color = Color3.fromRGB(255, 255, 255)
    handle.Radius = 10
    handle.Thickness = 2
    handle.NumSides = 32
    handle.Transparency = 0
    handle.ZIndex = 12
    handle.Visible = true
    ui.sliderHandle = handle

    local toggleLabel = Drawing.new("Text")
    toggleLabel.Text = "Toggle: P   UI: ]"
    toggleLabel.Color = Color3.fromRGB(180, 180, 190)
    toggleLabel.Position = Vector2.new(UI_X + 12, UI_Y + 105)
    toggleLabel.Size = 13
    toggleLabel.Font = Drawing.Fonts.UI
    toggleLabel.Center = false
    toggleLabel.ZIndex = 11
    toggleLabel.Visible = true
    ui.toggleLabel = toggleLabel

    local arrowHint = Drawing.new("Text")
    arrowHint.Text = "Arrows: +/- 50   WASD Z X"
    arrowHint.Color = Color3.fromRGB(140, 140, 160)
    arrowHint.Position = Vector2.new(UI_X + 12, UI_Y + 128)
    arrowHint.Size = 12
    arrowHint.Font = Drawing.Fonts.UI
    arrowHint.Center = false
    arrowHint.ZIndex = 11
    arrowHint.Visible = true
    ui.arrowHint = arrowHint

    updateSliderVisuals()
end

local function updateSliderVisuals()
    if not ui.sliderHandle or not ui.sliderTrack then return end
    local minSpeed = 0
    local maxSpeed = 2000
    local ratio = (CONFIG.Speed - minSpeed) / (maxSpeed - minSpeed)
    ratio = math.max(0, math.min(1, ratio))

    local trackPos = ui.sliderTrack.Position
    local trackSize = ui.sliderTrack.Size

    if ui.sliderFill then
        ui.sliderFill.Size = Vector2.new(trackSize.X * ratio, trackSize.Y)
    end

    local handleX = trackPos.X + trackSize.X * ratio
    local handleY = trackPos.Y + trackSize.Y / 2
    ui.sliderHandle.Position = Vector2.new(handleX, handleY)

    if ui.speedVal then
        ui.speedVal.Text = tostring(CONFIG.Speed)
    end
end

local function updateUI()
    updateSliderVisuals()
end

local function toggleUI()
    uiVisible = not uiVisible
    for _, obj in pairs(ui) do
        if type(obj) == "table" then
            for _, sub in ipairs(obj) do
                if sub and sub.Visible ~= nil then
                    sub.Visible = uiVisible
                end
            end
        elseif obj and obj.Visible ~= nil then
            obj.Visible = uiVisible
        end
    end
end

local function isMouseOverCircle(mousePos, center, radius)
    if not mousePos then return false end
    local dx = mousePos.X - center.X
    local dy = mousePos.Y - center.Y
    return (dx*dx + dy*dy) <= (radius * radius)
end

local function isMouseOverRect(mousePos, pos, size)
    if not mousePos then return false end
    return mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and
           mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y
end

local function handleSliderInput()
    if not ui.sliderHandle or not ui.sliderTrack then return end
    local mousePos = getMousePos()
    if not mousePos then return end

    local handlePos = ui.sliderHandle.Position
    local handleRadius = ui.sliderHandle.Radius
    local trackPos = ui.sliderTrack.Position
    local trackSize = ui.sliderTrack.Size

    local overHandle = isMouseOverCircle(mousePos, handlePos, handleRadius + 4)
    local overTrack = isMouseOverRect(mousePos, trackPos, trackSize)

    if ismouse1pressed() then
        if overHandle or (overTrack and not isDraggingSlider) then
            isDraggingSlider = true
        end
    else
        isDraggingSlider = false
    end

    if isDraggingSlider then
        local trackLeft = trackPos.X
        local trackRight = trackPos.X + trackSize.X
        local clampedX = math.max(trackLeft, math.min(trackRight, mousePos.X))
        local ratio = (clampedX - trackLeft) / (trackSize.X)
        local minSpeed = 0
        local maxSpeed = 2000
        local newSpeed = minSpeed + (maxSpeed - minSpeed) * ratio
        newSpeed = math.floor(newSpeed / 10) * 10
        CONFIG.Speed = math.max(0, newSpeed)
        updateUI()
    end
end

local function handleUIDrag()
    if not ui.window or not ui.window.Visible then return end
    if not ui.border or #ui.border < 4 then return end
    local mousePos = getMousePos()
    if not mousePos then return end

    local winPos = ui.window.Position
    local winSize = ui.window.Size
    local titleBar = {
        Position = winPos,
        Size = Vector2.new(winSize.X, UI_TITLE_H)
    }

    local overTitle = isMouseOverRect(mousePos, titleBar.Position, titleBar.Size)

    if ismouse1pressed() then
        if overTitle and not isDraggingUI and not isDraggingSlider then
            isDraggingUI = true
            dragStartPos = mousePos
            dragStartUI = winPos
        end
    else
        isDraggingUI = false
    end

    if isDraggingUI and dragStartPos and dragStartUI then
        local delta = mousePos - dragStartPos
        local newPos = dragStartUI + delta
        local viewport = Camera.ViewportSize
        newPos = Vector2.new(
            math.max(0, math.min(viewport.X - winSize.X, newPos.X)),
            math.max(0, math.min(viewport.Y - winSize.Y, newPos.Y))
        )
        local offset = newPos - dragStartUI
        UI_X = UI_X + offset.X
        UI_Y = UI_Y + offset.Y
        dragStartUI = newPos
        dragStartPos = mousePos

        ui.window.Position = newPos
        local bPos = newPos
        local bSize = winSize
        ui.border[1].From = bPos
        ui.border[1].To = Vector2.new(bPos.X + bSize.X, bPos.Y)
        ui.border[2].From = Vector2.new(bPos.X, bPos.Y + bSize.Y)
        ui.border[2].To = Vector2.new(bPos.X + bSize.X, bPos.Y + bSize.Y)
        ui.border[3].From = bPos
        ui.border[3].To = Vector2.new(bPos.X, bPos.Y + bSize.Y)
        ui.border[4].From = Vector2.new(bPos.X + bSize.X, bPos.Y)
        ui.border[4].To = Vector2.new(bPos.X + bSize.X, bPos.Y + bSize.Y)

        if ui.titleBg then ui.titleBg.Position = newPos end
        if ui.title then ui.title.Position = Vector2.new(newPos.X + 12, newPos.Y + 6) end
        if ui.speedLabel then ui.speedLabel.Position = Vector2.new(newPos.X + 12, newPos.Y + 42) end
        if ui.speedVal then ui.speedVal.Position = Vector2.new(newPos.X + UI_W - 60, newPos.Y + 40) end
        if ui.sliderTrack then ui.sliderTrack.Position = Vector2.new(newPos.X + SLIDER_X, newPos.Y + SLIDER_Y) end
        if ui.sliderFill then ui.sliderFill.Position = ui.sliderTrack.Position end
        if ui.toggleLabel then ui.toggleLabel.Position = Vector2.new(newPos.X + 12, newPos.Y + 105) end
        if ui.arrowHint then ui.arrowHint.Position = Vector2.new(newPos.X + 12, newPos.Y + 128) end
        updateSliderVisuals()
    end
end

local function handleArrowKeys()
    local now = tick()
    if now < arrowCooldown then return end

    local up = iskeypressed(0x26)
    local down = iskeypressed(0x28)

    if up or down then
        arrowCooldown = now + ARROW_COOLDOWN
        if up then
            CONFIG.Speed = CONFIG.Speed + 50
        elseif down then
            CONFIG.Speed = CONFIG.Speed - 50
        end
        CONFIG.Speed = math.max(0, CONFIG.Speed)
        updateUI()
    end
end

local function toggle()
    enabled = not enabled
    if enabled then
        local car = getPlayerCar()
        if not car then
            notify("Vehicle Fly", "Car not found! (" .. LocalPlayer.Name .. "sCar)", 2)
            enabled = false
            return
        end
        seatPart = car:FindFirstChild("VehicleSeat")
        if not seatPart then
            notify("Vehicle Fly", "VehicleSeat not found!", 2)
            enabled = false
            return
        end
        notify("Vehicle Fly", "ON - " .. car.Name, 2)
    else
        if seatPart then
            pcall(function()
                seatPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
                seatPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end)
        end
        notify("Vehicle Fly", "OFF", 2)
    end
end

local function onHeartbeat()
    if not enabled or not seatPart or not seatPart.Parent then
        return
    end

    local speed = CONFIG.Speed
    local dir = Vector3.new(0, 0, 0)

    if Camera then
        local forward = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector
        if iskeypressed(87) then dir = dir + forward * speed end
        if iskeypressed(83) then dir = dir - forward * speed end
        if iskeypressed(65) then dir = dir - right * speed end
        if iskeypressed(68) then dir = dir + right * speed end
    else
        if iskeypressed(87) then dir = dir + Vector3.new(0, 0, -speed) end
        if iskeypressed(83) then dir = dir + Vector3.new(0, 0, speed) end
        if iskeypressed(65) then dir = dir + Vector3.new(-speed, 0, 0) end
        if iskeypressed(68) then dir = dir + Vector3.new(speed, 0, 0) end
    end

    if iskeypressed(90) then dir = dir + Vector3.new(0, speed, 0) end
    if iskeypressed(88) then dir = dir + Vector3.new(0, -speed, 0) end

    pcall(function()
        seatPart.AssemblyLinearVelocity = dir
        seatPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
    end)
end

local function onRenderStepped()
    if uiVisible and not ui.window then
        createUI()
        updateUI()
    end

    if uiVisible then
        handleUIDrag()
        handleSliderInput()
        handleArrowKeys()
    end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        local pressed = iskeypressed(CONFIG.ToggleKey)
        if pressed and not keyDebounce then
            keyDebounce = true
            toggle()
        elseif not pressed then
            keyDebounce = false
        end
    end
end)

task.spawn(function()
    local uiKeyDebounce = false
    while true do
        task.wait(0.05)
        local pressed = iskeypressed(CONFIG.UIKey)
        if pressed and not uiKeyDebounce then
            uiKeyDebounce = true
            toggleUI()
        elseif not pressed then
            uiKeyDebounce = false
        end
    end
end)

heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
RunService.RenderStepped:Connect(onRenderStepped)

createUI()
updateUI()

if CONFIG.DefaultEnabled then
    toggle()
else
    notify("Vehicle Fly", "Loaded - P toggle, ] UI, WASD Z X", 3)
end

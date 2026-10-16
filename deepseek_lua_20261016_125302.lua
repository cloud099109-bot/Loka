--[[
  ollie_hub_v3.lua — DeltaX / Delta Mobile
  Thêm tab "khai thác" — chủ đích chọc vào:
    - AdminAbuse.Remotes.AdminAbuseRequest / Sync / BossFx / BossSync
    - AdminActionEvent, AdminCodeEvent, AdminFeedback, ClearAdminReplies
    - ccPanel.getAccess / giveAll / giveOne / setWins / setLevel /
      setMultiplier / setKeyEffect / resetData / spawnKey / startEvent
    - Packages.remo.container.BuyWins / BuyRobux / BuyAura / BuyTrail
    - year20xx.spawn / collect / despawn (event coin farming)
    - playtimeRewards.claim, eventQuests.claimQuest, codeRedemption.claimCode

  Cách chạy:
    1. Load script như bình thường.
    2. Vào tab "khai thác".
    3. Bấm "Quét & tự thử".
    4. Xem log — cái nào trả về data / không lỗi là có cửa.
--]]

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- gắn GUI an toàn
local function layChaGui()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if syn and syn.protect_gui then
        local ok, g = pcall(function() return Instance.new("ScreenGui") end)
        if ok and g then syn.protect_gui(g) return g end
    end
    return CoreGui
end

local State = {
    -- các toggle cơ bản giữ nguyên
    ESP = false, Aimbot = false, Fly = false, Speed = false,
    HighJump = false, InfiniteJump = false,
    SpeedValue = 32, JumpValue = 120, FlySpeed = 60,
    AimbotFOV = 150, AimbotPart = "Head",
    ESPColor = Color3.fromRGB(255, 60, 60), SavedTP = nil,
}

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ollie_hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = layChaGui()

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 420)
Main.Position = UDim2.new(0.5, -150, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = Main
local ms = Instance.new("UIStroke"); ms.Color = Color3.fromRGB(255, 70, 120)
ms.Thickness = 1.5; ms.Transparency = 0.2; ms.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 14); tbc.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ollie hub v3  •  khai thác"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold; Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -34, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 120)
MinimizeBtn.Text = "–"; MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.TextSize = 18
MinimizeBtn.BorderSizePixel = 0; MinimizeBtn.Parent = TitleBar
local mbc = Instance.new("UICorner"); mbc.CornerRadius = UDim.new(0, 8); mbc.Parent = MinimizeBtn

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 30)
TabBar.Position = UDim2.new(0, 8, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TabBar.BorderSizePixel = 0; TabBar.Parent = Main
local tbc2 = Instance.new("UICorner"); tbc2.CornerRadius = UDim.new(0, 8); tbc2.Parent = TabBar
local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabBar

local Body = Instance.new("ScrollingFrame")
Body.Size = UDim2.new(1, -16, 1, -90)
Body.Position = UDim2.new(0, 8, 0, 76)
Body.BackgroundTransparency = 1; Body.BorderSizePixel = 0
Body.ScrollBarThickness = 4
Body.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 120)
Body.CanvasSize = UDim2.new(0, 0, 0, 0)
Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
Body.Parent = Main
local BodyLayout = Instance.new("UIListLayout")
BodyLayout.Padding = UDim.new(0, 8)
BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
BodyLayout.Parent = Body

local function clearBody()
    for _, ch in ipairs(Body:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
    end
end

local function makeToggle(ten, key, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -4, 0, 34)
    Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    Btn.Text = ""; Btn.BorderSizePixel = 0; Btn.AutoButtonColor = false
    Btn.Parent = Body
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = Btn
    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, 10, 0.5, -7)
    Dot.BackgroundColor3 = State[key] and Color3.fromRGB(255, 70, 120) or Color3.fromRGB(70, 70, 80)
    Dot.BorderSizePixel = 0; Dot.Parent = Btn
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = Dot
    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -40, 1, 0); Lbl.Position = UDim2.new(0, 34, 0, 0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = ten
    Lbl.TextColor3 = State[key] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(230, 230, 235)
    Lbl.Font = Enum.Font.GothamMedium; Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Btn
    Btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        local v = State[key]
        Dot.BackgroundColor3 = v and Color3.fromRGB(255, 70, 120) or Color3.fromRGB(70, 70, 80)
        Lbl.TextColor3 = v and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 190)
        if callback then callback(v) end
    end)
end

local function makeSlider(ten, min, max, init, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -4, 0, 52)
    Holder.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    Holder.BorderSizePixel = 0; Holder.Parent = Body
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 8); hc.Parent = Holder
    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -16, 0, 20); Lbl.Position = UDim2.new(0, 10, 0, 4)
    Lbl.BackgroundTransparency = 1; Lbl.Text = ten .. ": " .. init
    Lbl.TextColor3 = Color3.fromRGB(230, 230, 235)
    Lbl.Font = Enum.Font.GothamMedium; Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Holder
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -20, 0, 6); Track.Position = UDim2.new(0, 10, 1, -18)
    Track.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Track.BorderSizePixel = 0; Track.Parent = Holder
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = Track
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((init - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 70, 120)
    Fill.BorderSizePixel = 0; Fill.Parent = Track
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = Fill
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Lbl.Text = ten .. ": " .. val
        callback(val)
    end
    Track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function makeButton(ten, callback, mau)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -4, 0, 34)
    Btn.BackgroundColor3 = mau or Color3.fromRGB(255, 70, 120)
    Btn.Text = ten; Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13
    Btn.BorderSizePixel = 0; Btn.Parent = Body
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = Btn
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

local function makeTextBox(chieuCao, placeholder)
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1, -4, 0, chieuCao)
    Box.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    Box.BorderSizePixel = 0; Box.Text = placeholder or ""
    Box.TextColor3 = Color3.fromRGB(200, 220, 200)
    Box.Font = Enum.Font.Code; Box.TextSize = 11
    Box.TextXAlignment = Enum.TextXAlignment.Left
    Box.TextYAlignment = Enum.TextYAlignment.Top
    Box.TextWrapped = true; Box.MultiLine = true
    Box.ClearTextOnFocus = false; Box.Parent = Body
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = Box
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = Box
    return Box
end

local tabs = {}
local function makeTab(ten, id, buildFn)
    tabs[id] = buildFn
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 82, 0, 24)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    Btn.Text = ten; Btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12
    Btn.BorderSizePixel = 0; Btn.Parent = TabBar
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = Btn
    Btn.MouseButton1Click:Connect(function()
        for _, b in ipairs(TabBar:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = (b == Btn) and Color3.fromRGB(255, 70, 120)
                    or Color3.fromRGB(40, 40, 48)
            end
        end
        clearBody()
        buildFn()
    end)
end

local FAB = Instance.new("TextButton")
FAB.Size = UDim2.new(0, 56, 0, 56)
FAB.Position = UDim2.new(0, 20, 0.4, 0)
FAB.BackgroundColor3 = Color3.fromRGB(255, 70, 120)
FAB.Text = "ollie"; FAB.TextColor3 = Color3.fromRGB(255, 255, 255)
FAB.Font = Enum.Font.GothamBold; FAB.TextSize = 12
FAB.BorderSizePixel = 0; FAB.Active = true; FAB.Draggable = true
FAB.Visible = false; FAB.Parent = ScreenGui
local fbc = Instance.new("UICorner"); fbc.CornerRadius = UDim.new(1, 0); fbc.Parent = FAB
local fbs = Instance.new("UIStroke"); fbs.Color = Color3.fromRGB(255, 255, 255)
fbs.Thickness = 1.5; fbs.Transparency = 0.4; fbs.Parent = FAB
MinimizeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false; FAB.Visible = true
end)
FAB.MouseButton1Click:Connect(function()
    Main.Visible = true; FAB.Visible = false
end)

-- ============ TIỆN ÍCH REMOTE ============
-- Lấy remote theo đường dẫn, an toàn
local function layRemote(duongDan)
    local cur = game
    for _, phan in ipairs(string.split(duongDan, ".")) do
        if cur == nil then return nil end
        local ok, next_ = pcall(function() return cur[phan] end)
        if not ok or next_ == nil then return nil end
        cur = next_
    end
    return cur
end

-- Dò kiểu dữ liệu để bọc arg an toàn
local function kieuDuLieu(v)
    local t = typeof(v)
    if t == "string" then return "string"
    elseif t == "number" then return "number"
    elseif t == "boolean" then return "boolean"
    elseif t == "Instance" then return "Instance"
    elseif t == "Vector3" then return "Vector3"
    elseif t == "CFrame" then return "CFrame"
    elseif t == "table" then return "table"
    else return t end
end

-- Log có ghi rõ kiểu dữ liệu
local ProbeLog = {}
local probeBox, exploitBox

local function ghiProbe(line)
    table.insert(ProbeLog, 1, line)
    if #ProbeLog > 400 then table.remove(ProbeLog) end
    if probeBox then probeBox.Text = table.concat(ProbeLog, "\n") end
    if exploitBox then exploitBox.Text = table.concat(ProbeLog, "\n") end
end

-- Gọi thử remote an toàn, trả về (ok, kết quả)
local function thuGoi(remote, args)
    if not remote then return false, "nil remote" end
    local ok, res = pcall(function(...)
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        elseif remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
            remote:FireServer(...)
            return "<fired>"
        end
    end, table.unpack(args))
    return ok, res
end

-- Ghi kết quả gọn
local function moTaKetQua(ok, res)
    if not ok then
        return "✗ " .. tostring(res):sub(1, 120)
    end
    local t = typeof(res)
    if t == "table" then
        local dem = 0
        local phan = {}
        for k, v in pairs(res) do
            dem += 1
            if dem > 6 then break end
            table.insert(phan, tostring(k) .. "=" .. tostring(v):sub(1, 40))
        end
        return "✓ {" .. table.concat(phan, ", ") .. "}"
    elseif t == "Instance" then
        return "✓ " .. res:GetFullName()
    else
        return "✓ " .. tostring(res):sub(1, 140)
    end
end

-- ============ CÁC BỘ ARG ỨNG VIÊN ============
-- Thử nhiều dạng arg cho một remote, dừng khi có kết quả không lỗi
local function thuNhieuDang(remote, tenHienThi)
    if not remote then
        ghiProbe("• " .. tenHienThi .. " → KHÔNG TÌM THẤY")
        return
    end
    ghiProbe("• " .. tenHienThi .. " (" .. remote.ClassName .. ")")

    local lp = LocalPlayer
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    -- Bộ arg phổ biến, xếp theo mức tăng dần
    local cacBo = {
        {},                                          -- không arg
        {lp},                                        -- chỉ player
        {lp.Name},
        {"1", 1, true},
        {1, 1, 1},
        {999999999, 999999999},
        {hrp and hrp.Position or Vector3.zero},      -- vị trí
        {"Admin", "admin", "true"},                  -- thử quyền
        {"giveAll", 999999999, "all"},
        {"setWins", 999999999},
        {"setLevel", 999},
        {"setMultiplier", 9999},
    }

    for i, bo in ipairs(cacBo) do
        local ok, res = thuGoi(remote, bo)
        local mo = moTaKetQua(ok, res)
        ghiProbe(string.format("   arg#%d [%d phần tử] → %s", i, #bo, mo))
        -- nếu RemoteFunction trả về data thật thì dừng, có cửa
        if ok and remote:IsA("RemoteFunction") and typeof(res) ~= "nil" then
            -- thử luôn arg khác để so sánh
        end
        task.wait(0.15)  -- chống ratelimit
    end
    ghiProbe("")
end

-- ============ DANH SÁCH MỤC TIÊU ============
local dsMucTieuAdmin = {
    "ReplicatedStorage.AdminAbuse.Remotes.AdminAbuseBossFx",
    "ReplicatedStorage.AdminAbuse.Remotes.AdminAbuseBossSync",
    "ReplicatedStorage.AdminAbuse.Remotes.AdminAbuseRequest",
    "ReplicatedStorage.AdminAbuse.Remotes.AdminAbuseSync",
    "ReplicatedStorage.AdminActionEvent",
    "ReplicatedStorage.AdminCmd_PartyMode",
    "ReplicatedStorage.AdminCodeEvent",
    "ReplicatedStorage.AdminFeedback",
    "ReplicatedStorage.AdminMessageToAll",
    "ReplicatedStorage.ClearAdminReplies",
    "ReplicatedStorage.GetAdminReplies",
    "ReplicatedStorage.CmdrClient.CmdrEvent",
    "ReplicatedStorage.CmdrClient.CmdrFunction",
    "ReplicatedStorage.CreatorTag.Toggle",
    "ReplicatedStorage.CreatorTag.ToggleDev",
    "ReplicatedStorage.CreatorTag.ToggleHelper",
    "ReplicatedStorage.CreatorTag.ToggleMod",
    "ReplicatedStorage.DataViewerAction",
    "ReplicatedStorage.Packages.remo.container.RaceSetEnabled",
    "ReplicatedStorage.Packages.remo.container.SetStudioPermissions",
    "ReplicatedStorage.Packages.remo.container.SettingsAction",
    "ReplicatedStorage.Packages.remo.container.Reset",
}

local dsMucTieuCcPanel = {
    "ReplicatedStorage.Packages.remo.container.ccPanel.getAccess",
    "ReplicatedStorage.Packages.remo.container.ccPanel.getCatalog",
    "ReplicatedStorage.Packages.remo.container.ccPanel.getContentState",
    "ReplicatedStorage.Packages.remo.container.ccPanel.getEventState",
    "ReplicatedStorage.Packages.remo.container.ccPanel.getGiftState",
    "ReplicatedStorage.Packages.remo.container.ccPanel.getTrollActions",
    "ReplicatedStorage.Packages.remo.container.ccPanel.getWorldState",
    "ReplicatedStorage.Packages.remo.container.ccPanel.giveAll",
    "ReplicatedStorage.Packages.remo.container.ccPanel.giveOne",
    "ReplicatedStorage.Packages.remo.container.ccPanel.giftTreadmill",
    "ReplicatedStorage.Packages.remo.container.ccPanel.selfGiftCandy",
    "ReplicatedStorage.Packages.remo.container.ccPanel.setLevel",
    "ReplicatedStorage.Packages.remo.container.ccPanel.setWins",
    "ReplicatedStorage.Packages.remo.container.ccPanel.setMultiplier",
    "ReplicatedStorage.Packages.remo.container.ccPanel.setKeyEffect",
    "ReplicatedStorage.Packages.remo.container.ccPanel.spawnKey",
    "ReplicatedStorage.Packages.remo.container.ccPanel.startEvent",
    "ReplicatedStorage.Packages.remo.container.ccPanel.stopEvent",
    "ReplicatedStorage.Packages.remo.container.ccPanel.resetData",
    "ReplicatedStorage.Packages.remo.container.ccPanel.teleportToWorld",
    "ReplicatedStorage.Packages.remo.container.ccPanel.morph",
    "ReplicatedStorage.Packages.remo.container.ccPanel.unmorph",
    "ReplicatedStorage.Packages.remo.container.ccPanel.trollAction",
}

local dsMucTieuTien = {
    "ReplicatedStorage.ItemsShopPanelAction",
    "ReplicatedStorage.Packages.remo.container.BuyRobux",
    "ReplicatedStorage.Packages.remo.container.BuyWins",
    "ReplicatedStorage.Packages.remo.container.BuyAura",
    "ReplicatedStorage.Packages.remo.container.BuyTrail",
    "ReplicatedStorage.Packages.remo.container.eventShops.buyWithCurrency",
    "ReplicatedStorage.Packages.remo.container.eventShops.buyWithRobux",
    "ReplicatedStorage.Packages.remo.container.eventShops.requestState",
    "ReplicatedStorage.Packages.remo.container.playtimeRewards.claim",
    "ReplicatedStorage.Packages.remo.container.eventQuests.claimQuest",
    "ReplicatedStorage.Packages.remo.container.codeRedemption.claimCode",
    "ReplicatedStorage.Packages.remo.container.itemSignatures.signItem",
}

local dsMucTieuEvent = {}
for _, nam in ipairs({"2015","2016","2017","2018","2019","2020","2021","2022"}) do
    table.insert(dsMucTieuEvent, "ReplicatedStorage.Packages.remo.container.year" .. nam .. ".collect")
end
-- year 2018 Orbs, 2020 Orbs
table.insert(dsMucTieuEvent, "ReplicatedStorage.Packages.remo.container.year2018Orbs.collect")
table.insert(dsMucTieuEvent, "ReplicatedStorage.Packages.remo.container.year2020Orbs.collect")

-- ============ QUÉT TỔNG HỢP ============
local function quetTatCa()
    ghiProbe("═══ BẮT ĐẦU QUÉT " .. os.date("%H:%M:%S") .. " ═══")
    for _, dd in ipairs(dsMucTieuAdmin) do
        thuNhieuDang(layRemote(dd), dd)
    end
    for _, dd in ipairs(dsMucTieuCcPanel) do
        thuNhieuDang(layRemote(dd), dd)
    end
    for _, dd in ipairs(dsMucTieuTien) do
        thuNhieuDang(layRemote(dd), dd)
    end
    for _, dd in ipairs(dsMucTieuEvent) do
        -- event coin: chỉ cần gọi collect 1 lần vì spam dễ bị kick
        local r = layRemote(dd)
        if r then
            local ok, res = thuGoi(r, {})
            ghiProbe("• " .. dd .. " → " .. moTaKetQua(ok, res))
        end
        task.wait(0.05)
    end
    ghiProbe("═══ XONG ═══")
end

-- ============ KHAI THÁC CỤ THỂ ============
-- giveAll: thử tặng hết cho mình
local function khaiThacGiveAll()
    local r = layRemote("ReplicatedStorage.Packages.remo.container.ccPanel.giveAll")
    if not r then ghiProbe("giveAll: không tìm thấy") return end
    ghiProbe("── giveAll ──")
    local lp = LocalPlayer
    for _, bo in ipairs({
        {lp},
        {lp, "all"},
        {"all", lp},
        {lp.UserId},
        {"*"},
    }) do
        local ok, res = thuGoi(r, bo)
        ghiProbe("  " .. moTaKetQua(ok, res))
        task.wait(0.2)
    end
end

-- setWins: đặt số win
local function khaiThacSetWins()
    local r = layRemote("ReplicatedStorage.Packages.remo.container.ccPanel.setWins")
    if not r then ghiProbe("setWins: không tìm thấy") return end
    ghiProbe("── setWins ──")
    local lp = LocalPlayer
    for _, bo in ipairs({
        {999999999},
        {lp, 999999999},
        {999999999, lp},
        {"wins", 999999999},
    }) do
        local ok, res = thuGoi(r, bo)
        ghiProbe("  " .. moTaKetQua(ok, res))
        task.wait(0.2)
    end
end

-- setLevel
local function khaiThacSetLevel()
    local r = layRemote("ReplicatedStorage.Packages.remo.container.ccPanel.setLevel")
    if not r then return end
    ghiProbe("── setLevel ──")
    for _, bo in ipairs({{999}, {999, LocalPlayer}, {999, "level"}}) do
        local ok, res = thuGoi(r, bo)
        ghiProbe("  " .. moTaKetQua(ok, res))
        task.wait(0.2)
    end
end

-- BuyWins: mua win không tốn tiền?
local function khaiThacBuyWins()
    local r = layRemote("ReplicatedStorage.Packages.remo.container.BuyWins")
    if not r then return end
    ghiProbe("── BuyWins ──")
    for _, bo in ipairs({{1}, {100}, {999999999}, {-1}, {0}}) do
        local ok, res = thuGoi(r, bo)
        ghiProbe("  " .. moTaKetQua(ok, res))
        task.wait(0.3)
    end
end

-- buyWithCurrency: âm để được hoàn tiền
local function khaiThacBuyAm()
    local r = layRemote("ReplicatedStorage.Packages.remo.container.eventShops.buyWithCurrency")
    if not r then return end
    ghiProbe("── buyWithCurrency (thử arg âm) ──")
    for _, bo in ipairs({{-999999}, {-1}, {1, -999999}, {-999999, 1}}) do
        local ok, res = thuGoi(r, bo)
        ghiProbe("  " .. moTaKetQua(ok, res))
        task.wait(0.3)
    end
end

-- getAccess: kiểm tra xem có quyền admin không (thường trả về bool/level)
local function kiemTraQuyen()
    local r = layRemote("ReplicatedStorage.Packages.remo.container.ccPanel.getAccess")
    if not r then ghiProbe("getAccess: không tìm thấy") return end
    ghiProbe("── getAccess (quyền hiện tại) ──")
    for _, bo in ipairs({{}, {LocalPlayer}}) do
        local ok, res = thuGoi(r, bo)
        ghiProbe("  " .. moTaKetQua(ok, res))
    end
end

-- getCatalog, getTrollActions: rò rỉ data
local function layCatalog()
    for _, dd in ipairs({
        "ReplicatedStorage.Packages.remo.container.ccPanel.getCatalog",
        "ReplicatedStorage.Packages.remo.container.ccPanel.getTrollActions",
        "ReplicatedStorage.Packages.remo.container.ccPanel.getGiftState",
    }) do
        local r = layRemote(dd)
        if r then
            local ok, res = thuGoi(r, {})
            ghiProbe("── " .. dd:match("[^.]+$") .. " ──")
            ghiProbe("  " .. moTaKetQua(ok, res))
        end
    end
end

-- ============ DỰNG TAB ============
makeTab("cơ bản", "chinh", function()
    makeToggle("ESP", "ESP", function(v)
        if not v and type(xoaESP) == "function" then return end
    end)
    makeToggle("Aimbot", "Aimbot")
    makeSlider("Bán kính Aimbot", 50, 600, 150, function(v) State.AimbotFOV = v end)
    makeToggle("Bay", "Fly")
    makeSlider("Tốc độ bay", 10, 300, 60, function(v) State.FlySpeed = v end)
    makeToggle("Tăng tốc", "Speed")
    makeSlider("Tốc độ chạy", 16, 300, 32, function(v) State.SpeedValue = v end)
    makeToggle("Nhảy cao", "HighJump")
    makeSlider("Lực nhảy", 50, 500, 120, function(v) State.JumpValue = v end)
    makeToggle("Nhảy vô tận", "InfiniteJump")
end)

makeTab("khai thác", "khai", function()
    makeButton("① Kiểm tra quyền (getAccess)", kiemTraQuyen,
        Color3.fromRGB(80, 80, 200))
    makeButton("② Lấy catalog (getCatalog/troll/gift)", layCatalog,
        Color3.fromRGB(80, 80, 200))
    makeButton("③ giveAll — tặng hết cho mình", khaiThacGiveAll,
        Color3.fromRGB(200, 60, 60))
    makeButton("④ setWins 999,999,999", khaiThacSetWins,
        Color3.fromRGB(200, 60, 60))
    makeButton("⑤ setLevel 999", khaiThacSetLevel,
        Color3.fromRGB(200, 60, 60))
    makeButton("⑥ BuyWins (thử không tốn tiền)", khaiThacBuyWins,
        Color3.fromRGB(200, 120, 60))
    makeButton("⑦ buyWithCurrency arg âm", khaiThacBuyAm,
        Color3.fromRGB(200, 120, 60))
    makeButton("⑧ QUÉT TỔNG HỢP (mất ~2 phút)", quetTatCa,
        Color3.fromRGB(160, 40, 160))
    makeButton("Xoá log", function()
        ProbeLog = {}
        if probeBox then probeBox.Text = "" end
        if exploitBox then exploitBox.Text = "" end
    end, Color3.fromRGB(80, 80, 120))

    exploitBox = makeTextBox(340,
        "Bấm ① → xem quyền. Nếu trả về false/nil thì bạn KHÔNG có quyền admin.\n" ..
        "Bấm ② → xem catalog, đôi khi lộ ra tên item/troll để gọi.\n" ..
        "Bấm ③-⑦ → thử khai thác, xem log kết quả từng bộ arg.\n" ..
        "Bấm ⑧ → quét toàn bộ danh sách (chậm, chống bị kick).\n\n" ..
        "Chú ý:\n" ..
        "  ✓ = server trả về data hoặc chấp nhận lệnh\n" ..
        "  ✗ = lỗi / bị từ chối (khả năng cao không có quyền)\n" ..
        "  <fired> = RemoteEvent, server không trả lời — không biết được.\n")
end)

tabs["chinh"]()
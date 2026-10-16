--[[
  vuln_recon_v3.lua — sửa 8 lỗi của v2
   FIX-1  SpyLog khai báo TRƯỚC ghiSpy (Lua local scope)
   FIX-2  goiCoKiemSoat trả về (not laLoi) — không báo true khi pcall fail
   FIX-3  Đổi nhãn: "server trả data" ≠ "lỗ hổng". Không overclaim.
   FIX-4  snapshot() rộng: attributes, leaderstats, backpack, folders data,
          humanoid, character children, custom "Data"/"Stats"/"Inventory"
   FIX-5  Mọi task.spawn con đều register vào Run.threads
   FIX-6  Từ chối chỉ khi: pcall error có keyword, hoặc string return có keyword.
          nil/false trên RemoteFunction = "?", không tính là từ chối.
   FIX-7  Chờ remote: chờ đến khi >80% danh sách quan trọng xuất hiện (hoặc timeout)
   FIX-8  Lock toàn cục Run.dangQuet — không cho 2 lượt quét chồng nhau
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

local function layChaGui()
    if gethui then
        local ok, hui = pcall(gethui); if ok and hui then return hui end
    end
    if syn and syn.protect_gui then
        local g = Instance.new("ScreenGui"); syn.protect_gui(g); return g
    end
    return CoreGui
end

-- ============================================================
-- TRẠNG THÁI TOÀN CỤC
-- ============================================================
local Run = {
    dangChay   = true,
    dangQuet   = false,       -- FIX-8: lock
    generation = 0,
    threads    = {},          -- FIX-5: mọi task (kể cả child)
    daKhoa     = {},
    demLoi     = {},
    maxLoi     = 2,
    cooldown   = {},
    spyDaBat   = false,
    oldNamecall= nil,
    mt         = nil,
}

-- FIX-1: khai báo spy state TRƯỚC mọi hàm dùng
local SpyLog = {}
local spyBox = nil
local LogBox = nil
local Log    = {}

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "vuln_recon_v3"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = layChaGui()

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 340, 0, 520)
Main.Position = UDim2.new(0.5, -170, 0.5, -260)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
Main.BorderSizePixel = 0; Main.Active = true; Main.Draggable = true
Main.Parent = ScreenGui
local mc = Instance.new("UICorner", Main); mc.CornerRadius = UDim.new(0, 14)
local ms = Instance.new("UIStroke", Main)
ms.Color = Color3.fromRGB(200, 40, 60); ms.Thickness = 1.5; ms.Transparency = 0.15

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
TitleBar.BorderSizePixel = 0; TitleBar.Parent = Main
local tbc = Instance.new("UICorner", TitleBar); tbc.CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "vuln recon v3  •  có lock + verify"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold; Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -34, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 60)
MinimizeBtn.Text = "–"; MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.TextSize = 18
MinimizeBtn.BorderSizePixel = 0; MinimizeBtn.Parent = TitleBar
local mbc = Instance.new("UICorner", MinimizeBtn); mbc.CornerRadius = UDim.new(0, 8)

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(1, -16, 0, 40)
StopBtn.Position = UDim2.new(0, 8, 0, 42)
StopBtn.BackgroundColor3 = Color3.fromRGB(160, 20, 30)
StopBtn.Text = "■ DỪNG KHẨN (cancel ALL threads + gỡ hook)"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.Font = Enum.Font.GothamBold; StopBtn.TextSize = 11
StopBtn.BorderSizePixel = 0; StopBtn.Parent = Main
local sbc = Instance.new("UICorner", StopBtn); sbc.CornerRadius = UDim.new(0, 8)

local Body = Instance.new("ScrollingFrame")
Body.Size = UDim2.new(1, -16, 1, -92)
Body.Position = UDim2.new(0, 8, 0, 88)
Body.BackgroundTransparency = 1; Body.BorderSizePixel = 0
Body.ScrollBarThickness = 4
Body.ScrollBarImageColor3 = Color3.fromRGB(200, 40, 60)
Body.CanvasSize = UDim2.new(0, 0, 0, 0)
Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
Body.Parent = Main
local Lay = Instance.new("UIListLayout", Body)
Lay.Padding = UDim.new(0, 6); Lay.SortOrder = Enum.SortOrder.LayoutOrder

local FAB = Instance.new("TextButton")
FAB.Size = UDim2.new(0, 56, 0, 56)
FAB.Position = UDim2.new(0, 20, 0.4, 0)
FAB.BackgroundColor3 = Color3.fromRGB(200, 40, 60)
FAB.Text = "recon"; FAB.TextColor3 = Color3.fromRGB(255, 255, 255)
FAB.Font = Enum.Font.GothamBold; FAB.TextSize = 11
FAB.BorderSizePixel = 0; FAB.Active = true; FAB.Draggable = true
FAB.Visible = false; FAB.Parent = ScreenGui
local fbc = Instance.new("UICorner", FAB); fbc.CornerRadius = UDim.new(1, 0)

MinimizeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false; FAB.Visible = true
end)
FAB.MouseButton1Click:Connect(function()
    Main.Visible = true; FAB.Visible = false
end)

-- ============================================================
-- HELPERS UI
-- ============================================================
local function nut(ten, fn, mau)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 32)
    b.BackgroundColor3 = mau or Color3.fromRGB(60, 60, 90)
    b.Text = ten; b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12
    b.BorderSizePixel = 0; b.Parent = Body
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(fn)
    return b
end

local function oLog(chieuCao, placeholder, mauChu)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1, -4, 0, chieuCao)
    t.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    t.Text = placeholder or ""; t.TextColor3 = mauChu or Color3.fromRGB(180, 240, 180)
    t.Font = Enum.Font.Code; t.TextSize = 11
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Top
    t.TextWrapped = true; t.MultiLine = true
    t.ClearTextOnFocus = false; t.Parent = Body
    local c = Instance.new("UICorner", t); c.CornerRadius = UDim.new(0, 8)
    local p = Instance.new("UIPadding", t)
    p.PaddingTop = UDim.new(0, 6); p.PaddingBottom = UDim.new(0, 6)
    p.PaddingLeft = UDim.new(0, 8); p.PaddingRight = UDim.new(0, 8)
    return t
end

local function ghi(line)
    table.insert(Log, 1, line)
    if #Log > 600 then table.remove(Log) end
    if LogBox then LogBox.Text = table.concat(Log, "\n") end
end

-- ============================================================
-- FIX-5: task registration
-- ============================================================
local function themThread(t)
    table.insert(Run.threads, t)
end

-- wrapper đăng ký task con
local function spawnCon(fn)
    local t
    t = task.spawn(function(...)
        local ok, err = pcall(fn, ...)
        -- dọn chính nó khỏi pool khi xong
        for i, th in ipairs(Run.threads) do
            if th == t then table.remove(Run.threads, i); break end
        end
        if not ok then ghi("⚠ task con lỗi: " .. tostring(err):sub(1, 100)) end
    end)
    themThread(t)
    return t
end

-- ============================================================
-- SNAPSHOT RỘNG — FIX-4
-- ============================================================
local function themAttrVao(s, inst, prefix)
    if inst and inst.GetAttributes then
        local ok, attrs = pcall(function() return inst:GetAttributes() end)
        if ok and attrs then
            for k, v in pairs(attrs) do
                s[prefix .. k] = tostring(v)
            end
        end
    end
end

local function themConValueVao(s, parent, prefix, doSau)
    if not parent then return end
    local dem = 0
    for _, v in ipairs(parent:GetChildren()) do
        dem = dem + 1
        if doSau and dem > doSau then break end
        if v:IsA("ValueBase") then
            s[prefix .. v.Name] = tostring(v.Value)
        end
    end
end

local function snapshot()
    local s = {}
    local lp = LocalPlayer

    -- player attributes
    themAttrVao(s, lp, "attr:player:")

    -- leaderstats
    local ls = lp:FindFirstChild("leaderstats")
    themConValueVao(s, ls, "ls:")

    -- các folder dữ liệu thường gặp
    for _, ten in ipairs({
        "Data", "Stats", "Inventory", "InventoryData",
        "Currencies", "Wallet", "GameData", "PlayerData",
        "Upgrades", "Items", "Pets", "Rebirths",
    }) do
        local f = lp:FindFirstChild(ten)
        if f then
            themConValueVao(s, f, ten .. ":")
            themAttrVao(s, f, "attr:" .. ten .. ":")
        end
    end

    -- Backpack & Character
    local bp = lp:FindFirstChildOfClass("Backpack")
    if bp then s["_backpack_count"] = tostring(#bp:GetChildren()) end

    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if pg then s["_playergui_count"] = tostring(#pg:GetChildren()) end

    local char = lp.Character
    if char then
        s["_char_children"] = tostring(#char:GetChildren())
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            s["hum:WalkSpeed"] = tostring(hum.WalkSpeed)
            s["hum:JumpPower"] = tostring(hum.JumpPower)
            s["hum:Health"]    = tostring(math.floor(hum.Health))
            s["hum:MaxHealth"] = tostring(math.floor(hum.MaxHealth))
        end
    end

    return s
end

local function diff(a, b)
    local ds = {}
    for k, v in pairs(b) do
        if a[k] ~= v then
            table.insert(ds, string.format("%s: %s→%s",
                k, tostring(a[k] or "∅"), v))
        end
    end
    for k in pairs(a) do
        if b[k] == nil then table.insert(ds, k .. ": mất") end
    end
    return ds
end

-- ============================================================
-- ĐẾM BẢNG
-- ============================================================
local function demBang(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- ============================================================
-- LẤY REMOTE
-- ============================================================
local function layRemote(dd)
    local cur = game
    for _, phan in ipairs(string.split(dd, ".")) do
        if cur == nil then return nil end
        local ok, nxt = pcall(function() return cur[phan] end)
        if not ok or nxt == nil then return nil end
        cur = nxt
    end
    return cur
end

-- ============================================================
-- COOLDOWN
-- ============================================================
local function quaCooldown(duongDan, giay)
    local now = os.clock()
    local lanTruoc = Run.cooldown[duongDan] or 0
    if now - lanTruoc < giay then
        return false, giay - (now - lanTruoc)
    end
    Run.cooldown[duongDan] = now
    return true, 0
end

-- ============================================================
-- PHÂN TÍCH KẾT QUẢ — FIX-6
--   laLoi:    pcall thất bại
--   laTuChoi: server từ chối RÕ RÀNG (keyword match)
--   moHo:     nil/false/không rõ — KHÔNG tính là từ chối
-- ============================================================
local TU_KHOA_TU_CHOI = {
    "denied", "refused", "refus", "not allowed", "forbidden",
    "unauthor", "no access", "permission", "accès refusé",
    "admin only", "requires admin", "insufficient",
}
local function chuoiLaTuChoi(s)
    if type(s) ~= "string" then return false end
    local lower = s:lower()
    for _, kw in ipairs(TU_KHOA_TU_CHOI) do
        if lower:find(kw, 1, true) then return true end
    end
    return false
end

local function phanTichKetQua(ok, res)
    if not ok then
        local err = tostring(res)
        -- FIX-6: chỉ tính là từ chối khi keyword có thật
        local tuChoi = chuoiLaTuChoi(err)
        return true, tuChoi, "✗ pcall fail: " .. err:sub(1, 100)
    end

    -- FIX-6: string match keyword → từ chối chắc
    if type(res) == "string" and chuoiLaTuChoi(res) then
        return false, true, "• từ chối: " .. res:sub(1, 100)
    end

    -- FIX-6: nil/false chỉ là MƠ HỒ, không tính từ chối
    if res == nil then
        return false, false, "? nil (không có data / remote không trả)"
    end
    if res == false then
        return false, false, "? false (có thể là kết quả hợp lệ)"
    end

    local t = typeof(res)
    if t == "table" then
        local n = demBang(res)
        local ds = {}
        local dem = 0
        for k, v in pairs(res) do
            dem = dem + 1
            if dem > 6 then break end
            table.insert(ds, tostring(k) .. "=" .. tostring(v):sub(1, 22))
        end
        return false, false,
            "◇ data table (" .. n .. "): {" .. table.concat(ds, ", ") .. "}"
    elseif t == "Instance" then
        return false, false, "◇ Instance: " .. res:GetFullName()
    else
        return false, false, "◇ " .. tostring(res):sub(1, 120)
    end
end

-- ============================================================
-- GỌI REMOTE — FIX-2 (trả về đúng), FIX-3 (nhãn rõ)
-- ============================================================
local function goiCoKiemSoat(duongDan, args, laGhi, doVerify)
    if not Run.dangChay then return false, "đã dừng", nil end
    if Run.daKhoa[duongDan] then return false, "module khóa", nil end

    local remote = layRemote(duongDan)
    if not remote then return false, "không tìm thấy remote", nil end

    if laGhi then
        local ok, cho = quaCooldown(duongDan, 3)
        if not ok then
            return false, string.format("cooldown %.1fs", cho), nil
        end
    end

    local snapTruoc
    if doVerify then snapTruoc = snapshot() end

    local pcallOk, res = pcall(function(...)
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        elseif remote:IsA("RemoteEvent")
            or remote:IsA("UnreliableRemoteEvent") then
            remote:FireServer(...)
            return "__fired__"
        end
    end, table.unpack(args))

    local laLoi, laTuChoi, moTa = phanTichKetQua(pcallOk, res)

    if laTuChoi then
        Run.demLoi[duongDan] = (Run.demLoi[duongDan] or 0) + 1
        local dem = Run.demLoi[duongDan]
        ghi(string.format("  ⚠ %s bị từ chối (%d/%d)",
            duongDan:match("[^.]+$"), dem, Run.maxLoi))
        if dem >= Run.maxLoi then
            Run.daKhoa[duongDan] = true
            ghi("  🔒 KHÓA " .. duongDan:match("[^.]+$"))
        end
    end

    local thayDoi = nil
    if doVerify and snapTruoc then
        task.wait(0.4)
        thayDoi = diff(snapTruoc, snapshot())
        if #thayDoi > 0 then
            moTa = moTa .. "  ★STATE: " .. table.concat(thayDoi, " | ")
        end
    end

    -- FIX-2: trả về false nếu pcall fail hoặc bị từ chối
    local thanhCong = (not laLoi) and (not laTuChoi)
    return thanhCong, moTa, thayDoi
end

-- ============================================================
-- THỬ NHIỀU BỘ ARG
-- ============================================================
local function thuNhieuDang(duongDan, danhSachArg, laGhi)
    local tenNgan = duongDan:match("[^.]+$") or duongDan
    if Run.daKhoa[duongDan] then
        ghi("-- " .. tenNgan .. " — đã khóa")
        return
    end
    if not layRemote(duongDan) then
        ghi("-- " .. tenNgan .. " — KHÔNG TÌM THẤY")
        return
    end
    ghi("-- " .. tenNgan .. " --")
    for i, bo in ipairs(danhSachArg) do
        if not Run.dangChay then return end
        local ok, moTa = goiCoKiemSoat(duongDan, bo, laGhi, true)
        local nhan = ok and "OK " or "SKIP"
        ghi(string.format("  [%s] arg#%d (%d) → %s",
            nhan, i, #bo, moTa or "?"))
        task.wait(laGhi and 3 or 0.4)
    end
end

-- ============================================================
-- MODULE A–F
-- ============================================================
local function doA_Quyen()
    if not Run.dangChay then return end
    ghi("═══ A. QUYỀN ADMIN ═══")
    thuNhieuDang(
        "ReplicatedStorage.Packages.remo.container.ccPanel.getAccess",
        {{}, {LocalPlayer}}, false)
    thuNhieuDang("ReplicatedStorage.CmdrClient.CmdrFunction", {{}}, false)
    thuNhieuDang("ReplicatedStorage.GetAdminReplies", {{}}, false)
    for _, tag in ipairs({"Toggle","ToggleDev","ToggleHelper","ToggleMod"}) do
        if not Run.dangChay then return end
        thuNhieuDang("ReplicatedStorage.CreatorTag." .. tag, {{true}}, true)
    end
end

local function doB_InfoLeak()
    if not Run.dangChay then return end
    ghi("═══ B. INFO LEAK ═══")
    local ds = {
        "ReplicatedStorage.Packages.remo.container.ccPanel.getCatalog",
        "ReplicatedStorage.Packages.remo.container.ccPanel.getContentState",
        "ReplicatedStorage.Packages.remo.container.ccPanel.getEventState",
        "ReplicatedStorage.Packages.remo.container.ccPanel.getGiftState",
        "ReplicatedStorage.Packages.remo.container.ccPanel.getTrollActions",
        "ReplicatedStorage.Packages.remo.container.ccPanel.getWorldState",
        "ReplicatedStorage.Packages.remo.container.GetConfig",
        "ReplicatedStorage.Packages.remo.container.RequestInfo",
        "ReplicatedStorage.Packages.remo.container.RequestState",
        "ReplicatedStorage.Packages.remo.container.trading.queryTarget",
    }
    for _, dd in ipairs(ds) do
        if not Run.dangChay then return end
        thuNhieuDang(dd, {{}}, false)
    end
end

local function doC_TienTe()
    if not Run.dangChay then return end
    ghi("═══ C. TIỀN TỆ (verify state) ═══")
    thuNhieuDang("ReplicatedStorage.Packages.remo.container.BuyWins",
        {{1},{-1},{0},{999999999}}, true)
    thuNhieuDang("ReplicatedStorage.Packages.remo.container.BuyRobux",
        {{1},{-1},{999999999}}, true)
    thuNhieuDang("ReplicatedStorage.Packages.remo.container.eventShops.buyWithCurrency",
        {{-999999},{-1},{1,-999999}}, true)
    thuNhieuDang("ReplicatedStorage.ItemsShopPanelAction",
        {{-999999},{999999999}}, true)
end

local function doD_SuKien()
    if not Run.dangChay then return end
    ghi("═══ D. SỰ KIỆN ═══")
    for _, nam in ipairs({"2015","2016","2017","2018","2019","2020","2021","2022"}) do
        if not Run.dangChay then return end
        thuNhieuDang(
            "ReplicatedStorage.Packages.remo.container.year" .. nam .. ".collect",
            {{}}, false)
    end
end

local function doE_LeoQuyen()
    if not Run.dangChay then return end
    ghi("═══ E. LEO QUYỀN ═══")
    local getAccess = "ReplicatedStorage.Packages.remo.container.ccPanel.getAccess"
    for _, q in ipairs({"admin","owner","mod","helper","dev","creator"}) do
        if not Run.dangChay then return end
        thuNhieuDang(getAccess, {{q}}, false)
    end
    thuNhieuDang(
        "ReplicatedStorage.Packages.remo.container.SetStudioPermissions",
        {{true},{LocalPlayer,true},{"admin"}}, true)
end

local function doF_Race()
    if not Run.dangChay then return end
    ghi("═══ F. RACE CONDITION ═══")
    local gA = "ReplicatedStorage.Packages.remo.container.ccPanel.getAccess"
    local gB = "ReplicatedStorage.Packages.remo.container.BuyWins"
    if not layRemote(gA) or not layRemote(gB) then
        ghi("Thiếu remote — bỏ qua"); return
    end
    for i = 1, 3 do
        if not Run.dangChay then return end
        ghi("-- lượt " .. i .. " --")
        -- FIX-5: đăng ký task con
        spawnCon(function()
            local ok, moTa = goiCoKiemSoat(gA, {}, false, false)
            ghi("  [A] " .. (moTa or "?"))
        end)
        spawnCon(function()
            local ok, moTa = goiCoKiemSoat(gB, {1}, true, true)
            ghi("  [B] " .. (moTa or "?"))
        end)
        task.wait(3)
    end
end

-- ============================================================
-- SPY — FIX-1, FIX-3
-- ============================================================
-- FIX-1: spyBox đã khai báo ở đầu file, SpyLog đã khai báo ở đầu file.
local function ghiSpy(line)
    table.insert(SpyLog, 1, line)
    if #SpyLog > 300 then table.remove(SpyLog) end
    if spyBox then spyBox.Text = table.concat(SpyLog, "\n") end
end

local function coTheSpy()
    if not getrawmetatable   then return false, "thiếu getrawmetatable" end
    if not setreadonly       then return false, "thiếu setreadonly" end
    if not newcclosure       then return false, "thiếu newcclosure" end
    if not getnamecallmethod then return false, "thiếu getnamecallmethod" end
    local mt = getrawmetatable(game)
    if not mt or not mt.__namecall then return false, "không có __namecall" end
    return true, mt
end

local function dinhDang(a)
    local t = typeof(a)
    if t == "Instance" then return a:GetFullName() end
    if t == "string" then
        if #a > 50 then return '"' .. a:sub(1,50) .. '…"' end
        return '"' .. a .. '"'
    end
    if t == "number" or t == "boolean" then return tostring(a) end
    if t == "Vector3" then
        return string.format("V3(%.0f,%.0f,%.0f)", a.X, a.Y, a.Z)
    end
    if t == "table" then return "{t:" .. demBang(a) .. "}" end
    return tostring(t)
end

local function batSpy()
    if Run.spyDaBat then
        ghi("Spy đã bật rồi")
        return
    end
    local ok, mt = coTheSpy()
    if not ok then
        ghi("Không bật được spy: " .. tostring(mt))
        return
    end
    local old = mt.__namecall
    Run.mt = mt
    Run.oldNamecall = old
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if method == "FireServer" or method == "InvokeServer" then
            local args = {...}
            local argStr = {}
            for i = 1, math.min(#args, 4) do
                argStr[i] = dinhDang(args[i])
            end
            local ten = typeof(self) == "Instance"
                and self:GetFullName() or tostring(self)
            -- FIX-1: SpyLog đã tồn tại, ghiSpy chạy an toàn
            ghiSpy(string.format("[%s] %s(%s)",
                method, ten, table.concat(argStr, ", ")))
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
    Run.spyDaBat = true
    ghi("✓ Spy đã bật")
end

local function goSpy()
    if not Run.spyDaBat or not Run.mt or not Run.oldNamecall then return end
    setreadonly(Run.mt, false)
    Run.mt.__namecall = Run.oldNamecall
    setreadonly(Run.mt, true)
    Run.spyDaBat = false
    Run.oldNamecall = nil
    ghi("✓ Đã gỡ hook spy")
end

-- ============================================================
-- CHẠY TASK CÓ GENERATION + LOCK — FIX-8
-- ============================================================
local function chayTask(fn)
    -- FIX-8: chặn chồng lượt quét
    if Run.dangQuet then
        ghi("⏸ Đang có lượt quét chạy — chờ xong hoặc DỪNG KHẨN")
        return nil
    end
    Run.dangQuet = true
    local gen = Run.generation

    local t
    t = task.spawn(function()
        local ok, err = pcall(fn, function()
            return Run.generation ~= gen
        end)
        Run.dangQuet = false
        for i, th in ipairs(Run.threads) do
            if th == t then table.remove(Run.threads, i); break end
        end
        if not ok then
            ghi("⚠ task lỗi: " .. tostring(err):sub(1, 100))
        end
    end)
    themThread(t)
    return t
end

-- ============================================================
-- QUÉT TỔNG
-- ============================================================
local function quetTong()
    chayTask(function(daDung)
        ghi("╔══════════════════════════════╗")
        ghi("║  BẮT ĐẦU QUÉT " .. os.date("%H:%M:%S") .. "  ║")
        ghi("╚══════════════════════════════╝")
        doA_Quyen();    if daDung() then return end
        doB_InfoLeak(); if daDung() then return end
        doE_LeoQuyen(); if daDung() then return end
        doF_Race();     if daDung() then return end
        doC_TienTe();   if daDung() then return end
        doD_SuKien()
        ghi("╔══════════════════════════════╗")
        ghi("║  XONG — xem log              ║")
        ghi("╚══════════════════════════════╝")
    end)
end

-- ============================================================
-- DỪNG KHẨN — FIX-5 hoàn chỉnh
-- ============================================================
local function dungKhan()
    Run.dangChay = false
    Run.dangQuet = false
    Run.generation = Run.generation + 1
    -- hủy TẤT CẢ thread đã đăng ký (bao gồm task con từ spawnCon)
    local dem = 0
    for _, t in ipairs(Run.threads) do
        local ok = pcall(task.cancel, t)
        if ok then dem = dem + 1 end
    end
    Run.threads = {}
    goSpy()
    ghi(string.format("🛑 DỪNG KHẨN — đã cancel %d thread, gỡ hook", dem))
    ghi("   Remote đã gửi trước đó KHÔNG thể thu hồi.")
end

local function tiepTuc()
    Run.dangChay = true
    Run.generation = Run.generation + 1
    ghi("▶ Đã bật lại")
end

StopBtn.MouseButton1Click:Connect(function()
    if Run.dangChay then
        dungKhan()
        StopBtn.Text = "▶ TIẾP TỤC"
        StopBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
    else
        tiepTuc()
        StopBtn.Text = "■ DỪNG KHẨN (cancel ALL threads + gỡ hook)"
        StopBtn.BackgroundColor3 = Color3.fromRGB(160, 20, 30)
    end
end)

-- ============================================================
-- UI
-- ============================================================
nut("① Dò quyền admin (A)", function()
    chayTask(function(d) doA_Quyen() end)
end, Color3.fromRGB(80, 80, 200))

nut("② Info leak (B)", function()
    chayTask(function(d) doB_InfoLeak() end)
end, Color3.fromRGB(80, 80, 200))

nut("③ Thử leo quyền (E)", function()
    chayTask(function(d) doE_LeoQuyen() end)
end, Color3.fromRGB(180, 60, 180))

nut("④ Race condition (F)", function()
    chayTask(function(d) doF_Race() end)
end, Color3.fromRGB(180, 60, 180))

nut("⑤ Lỗi tiền tệ (C) — verify", function()
    chayTask(function(d) doC_TienTe() end)
end, Color3.fromRGB(200, 120, 60))

nut("⑥ Lỗi sự kiện (D)", function()
    chayTask(function(d) doD_SuKien() end)
end, Color3.fromRGB(200, 120, 60))

nut("⑦ QUÉT TỔNG (A→B→E→F→C→D)", quetTong,
    Color3.fromRGB(200, 40, 60))

nut("Bật SPY (nền)", batSpy, Color3.fromRGB(60, 140, 60))
nut("Tắt SPY (gỡ hook)", goSpy, Color3.fromRGB(140, 60, 60))
nut("Xoá log chính", function()
    Log = {}; if LogBox then LogBox.Text = "" end
end, Color3.fromRGB(80, 80, 100))

LogBox = oLog(240,
    "HƯỚNG DẪN v3:\n" ..
    "1. ① → hỏi server quyền hiện tại.\n" ..
    "2. ② → moi data server.\n" ..
    "3. ③ → thử leo quyền.\n" ..
    "4. ④ → race, gọi song song.\n" ..
    "5. ⑤⑥ → tiền tệ / sự kiện.\n" ..
    "6. ⑦ → chạy hết tự động.\n\n" ..
    "ĐỌC KẾT QUẢ (đã sửa nhãn):\n" ..
    "  [OK]   ◇ data    → server trả data (KHÔNG hẳn là lỗi)\n" ..
    "  [OK]   ◇ data ★STATE: x→y → state client đổi (mạnh hơn)\n" ..
    "  [OK]   ? nil/false → không rõ, không tính từ chối\n" ..
    "  [SKIP] • từ chối  → server nói denied/refused rõ ràng\n" ..
    "  [SKIP] ✗ pcall fail → gọi lỗi (arg sai kiểu, remote đổi)\n" ..
    "  [SKIP] cooldown / khóa → không thử\n\n" ..
    "⚠ 'OK' CHỈ nghĩa là pcall không lỗi và server không nói từ chối.\n" ..
    "  Muốn kết luận lỗ hổng: phải thấy ★STATE hoặc tự kiểm tra UI game.\n" ..
    "  ★STATE có thể do lag/game tự đổi — verify bằng mắt.")

spyBox = oLog(160,
    "Spy log xuất hiện ở đây khi bật SPY.\n" ..
    "Mọi FireServer/InvokeServer sẽ bị bắt.")

-- ============================================================
-- KHỞI ĐỘNG — FIX-7: chờ nhiều remote hơn
-- ============================================================
spawnCon(function()
    local quanTrong = {
        "ReplicatedStorage.Packages.remo.container.ccPanel.getAccess",
        "ReplicatedStorage.Packages.remo.container.BuyWins",
        "ReplicatedStorage.Packages.remo.container.BuyRobux",
        "ReplicatedStorage.Packages.remo.container.RequestState",
        "ReplicatedStorage.Packages.remo.container.RequestInfo",
        "ReplicatedStorage.CmdrClient.CmdrFunction",
        "ReplicatedStorage.AdminActionEvent",
        "ReplicatedStorage.Packages.remo.container.eventShops.requestState",
    }
    for i = 1, 30 do
        if Run.generation ~= 0 then return end
        local co = 0
        for _, dd in ipairs(quanTrong) do
            if layRemote(dd) then co = co + 1 end
        end
        local pct = math.floor(co / #quanTrong * 100)
        if pct >= 80 then
            ghi(string.format("✓ Remote sẵn sàng: %d/%d (%d%%)",
                co, #quanTrong, pct))
            return
        end
        task.wait(0.5)
    end
    ghi("⚠ Hết thời gian chờ — một số remote có thể chưa load")
end)

ghi("vuln recon v3 sẵn sàng. Bấm ① để bắt đầu.")
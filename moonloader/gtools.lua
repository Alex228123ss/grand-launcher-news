script_name("GTools")
script_author("Катана_Версетти")
script_version("1.2.0")

local ACTIVATION_KEY = "GTOOLS-PREMIUM-2026"

local imgui = require 'mimgui'
local encoding = require 'encoding'
local ffi = require 'ffi'
local vk = require 'vkeys'
local inicfg = require 'inicfg'
local mem = require 'memory'
local sampev = require 'lib.samp.events'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local UPDATE_JSON_URL = "https://raw.githubusercontent.com/Alex228123ss/grand-launcher-news/refs/heads/main/moonloader/update.json"
local UPDATE_LUA_URL = "https://raw.githubusercontent.com/Alex228123ss/grand-launcher-news/refs/heads/main/moonloader/gtools.luac"
local update_status = 0

local cfg_path = "GTools.ini"
local default_cfg = {
    main = { admin_pass = "", server_pass = "", hotkey1 = vk.VK_MENU, hotkey2 = vk.VK_G, target_mode = 1 }
}
local cfg = inicfg.load(default_cfg, cfg_path)
if not cfg then inicfg.save(default_cfg, cfg_path); cfg = default_cfg end

-- ================= ГЛОБАЛЬНЫЕ ТАБЛИЦЫ =================
local UI = {
    win_state = imgui.new.bool(false),
    win_alpha = 0.0,
    win_y_offset = 200.0,
    is_authenticated = false,
    is_booting = false,
    boot_start_time = 0,
    show_notif = false,
    notif_alpha = 0.0,
    notif_start_time = 0,
    current_tab = 1,
    tab_names = {u8"Админ ПО", u8"Управление сервером", u8"Настройки", u8"О GTools", u8"Правила сервера"},
    wait_hotkey1 = false, wait_hotkey2 = false,
    popup_target = "",
    list_mode = ""
}

local Buf = {
    admin_pass = imgui.new.char[256](cfg.main.admin_pass),
    skin_pid = imgui.new.char[256](), skin_id = imgui.new.char[256](), skin_mode = imgui.new.int(1),
    gun_pid = imgui.new.char[256](), gun_id = imgui.new.char[256](), gun_ammo = imgui.new.char[256](),
    veh_mode = imgui.new.int(1), veh_pid = imgui.new.char[256](), veh_id = imgui.new.char[256](), veh_col1 = imgui.new.char[256](), veh_col2 = imgui.new.char[256](),
    hp_pid = imgui.new.char[256](), hp_val = imgui.new.char[256](),
    arm_pid = imgui.new.char[256](), arm_val = imgui.new.char[256](),
    server_pass_input = imgui.new.char[256](cfg.main.server_pass),
    weath_val = imgui.new.char[256](), time_val = imgui.new.char[256](),
    mon_pid = imgui.new.char[256](), mon_val = imgui.new.char[256](),
    don_pid = imgui.new.char[256](), don_val = imgui.new.char[256]()
}

local Cheat = {
    flycar = imgui.new.bool(false), nitro = imgui.new.bool(false), fly_cars = 0.0, ppc = {},
    airbrake = imgui.new.bool(false), ab_speed = imgui.new.float(0.5),
    ab_x = 0.0, ab_y = 0.0, ab_z = 0.0
}

local Tex = {}
local SERVER_SECRET = "iw819!_92;828hdk+$628!3_($*20&" 

-- ================= БАЗА ДАННЫХ ID =================
local lists = {
    weapons = {
        {0, u8"Кулак"}, {1, u8"Кастет"}, {2, u8"Клюшка для гольфа"}, {3, u8"Полицейская дубинка"},
        {4, u8"Нож"}, {5, u8"Бейсбольная бита"}, {6, u8"Лопата"}, {7, u8"Кий"}, {8, u8"Катана"},
        {9, u8"Бензопила"}, {10, u8"Двухсторонний дилдо"}, {11, u8"Дилдо"}, {12, u8"Вибратор"},
        {13, u8"Серебряный вибратор"}, {14, u8"Букет цветов"}, {15, u8"Трость"}, {16, u8"Граната"},
        {17, u8"Слезоточивый газ"}, {18, u8"Коктейль Молотова"}, {22, u8"Пистолет 9мм"},
        {23, u8"Пистолет с глушителем"}, {24, u8"Пистолет Дигл"}, {25, u8"Обычный дробовик"},
        {26, u8"Обрез"}, {27, u8"Скорострельный дробовик"}, {28, u8"УЗИ"}, {29, u8"MP5"},
        {30, u8"Автомат Калашникова"}, {31, u8"Автомат M4"}, {32, u8"Тес-9"}, {33, u8"Охотничье ружье"},
        {34, u8"Снайперская винтовка"}, {35, u8"РПГ"}, {36, u8"Ракетная установка"},
        {37, u8"Огнемет"}, {38, u8"Пулемёт"}, {39, u8"Сумка с тротилом"}, {40, u8"Детонатор к сумке"},
        {41, u8"Баллончик с краской"}, {42, u8"Огнетушитель"}, {43, u8"Фотоаппарат"},
        {44, u8"Прибор ночного видения"}, {45, u8"Тепловизор"}, {46, u8"Парашют"}
    },
    cars = {
        {400, u8"Mercedes G63 AMG RN [Автомобиль] (Админ транспорт)"},
        {401, u8"Mercedes G63 AMG [Автомобиль] (Донат транспорт набора Физрук)"},
        {402, u8"Lada Vesta Cross [Автомобиль] (Игровой транспорт)"},
        {403, u8"Scania G 4x6 [Фура для прицепа] (Гос транспорт)"},
        {404, u8"Mercedes-Benz E200 [Автомобиль] (Донат транспорт набора MORGENSHTERN)"},
        {405, u8"??? [Автомобиль] (Игровой транспорт)"},
        {406, u8"dumper - [Белаз] (Гос транспорт) | GTA SA"},
        {407, u8"Камаз 6520 [Автомобиль] (Гос транспорт / Пожарный департамент)"},
        {408, u8"Камаз 53215 [Автомобиль] (Гос транспорт / Мусоровоз)"},
        {409, u8"Rolls-Royce Phantom [Автомобиль] (Админ транспорт)"},
        {410, u8"Audi A4 [Автомобиль] (Игровой транспорт)"},
        {411, u8"Mercedes CLS 63 AMG [Автомобиль] (Игровой транспорт)"},
        {412, u8"??? [Автомобиль] (Игровой транспорт)"},
        {413, u8"Tesla CyberTruck 6x6 RGB [Автомобиль] (Донат транспорт)"},
        {414, u8"mule [Автомобиль] (Гос транспорт) | GTA SA"},
        {415, u8"Mercedes CLS 63 AMG RGB [Автомобиль] (Донат транспорт)"},
        {416, u8"Mercedes-Benz Sprinter [Автомобиль] (Гос транспорт / Медицинский департамент)"},
        {417, u8"??? [Вертолёт] (Донат транспорт)"},
        {418, u8"moonbeam [Автомобиль] (Игровой транспорт) | GTA SA"},
        {419, u8"Cadillac Escalade [Автомобиль] (Игровой транспорт)"},
        {420, u8"Lada Vesta Cross [Автомобиль] (Гос транспорт / Такси)"},
        {421, u8"Tayota Land Cruiser 200 [Автомобиль] (Игровой транспорт)"},
        {422, u8"Range Rover Sport SVR [Автомобиль] (Игровой транспорт)"},
        {423, u8"mrwhoop [Автомобиль] (Гос транспорт) | GTA SA"},
        {424, u8"Багги [Автомобиль] (МП Транспорт)"},
        {425, u8"Ми-24 [Вертолёт] (Гос транспорт / Военный департамент)"},
        {426, u8"Ваз 2107 [Автомобиль] (Игровой транспорт)"},
        {427, u8"Камаз 43118 [Автомобиль] (Гос транспорт / Полицейский департамент)"},
        {428, u8"Mercedes-Benz Sprinter [Автомобиль] (Гос транспорт / GRAND BANK)"},
        {429, u8"Ваз 2114 [Автомобиль] (Игровой транспорт)"},
        {430, u8"predator [Лодка] (Полицейский департамент) | GTA SA"},
        {431, u8"Электробус [Автобус] (Гос транспорт)"},
        {432, u8"rhino [Танк] (Гос транспорт / Военный департамент) | GTA SA"},
        {433, u8"barracks [Автомобиль] (Гос транспорт / Военный департамент) | GTA SA"},
        {434, u8"hotknife [Автомобиль] (Игровой транспорт) | GTA SA"},
        {435, u8"artict1 [Прицеп для фуры 1] (Гос транспорт) | GTA SA"},
        {436, u8"Tesla Model S [Автомобиль] (Игровой транспорт)"},
        {437, u8"coach (автобус 2) [Автобус] (Гос транспорт) | GTA SA"},
        {438, u8"Lamborghini Urus [Автомобиль] (Игровой транспорт)"},
        {439, u8"stallion [Автомобль] (Игровой транспорт) | GTA SA"},
        {440, u8"rumpo [Автомобиль] (Игровой транспорт) | GTA SA"},
        {441, u8"rcbandit [Игрушка] (Неизвестно) | GTA SA"},
        {442, u8"romero [Автомобиль] (Игровой транспорт) | GTA SA"},
        {443, u8"packer [Неизвестно] (Неизвестно) | GTA SA"},
        {444, u8"monster [Автомобиль] (Донат транспорт) | GTA SA"},
        {445, u8"Mercedes GT 63 AMG [Автомобиль] (Игровой транспорт)"},
        {446, u8"squalo [Лодка] (Донат транспорт) | GTA SA"},
        {448, u8"Honda Dio [Мотоцикл] (Гос транспорт)"},
        {449, u8"71-931 Витязь [Трамвай] (Гос транспорт)"},
        {450, u8"artict2 [Прицеп для фуры 2] (Гос транспорт) | GTA SA"}
    },
    skins = {{1, u8"Кетрин Глитч (Скин основателя)"}, {74, u8"CJ"}},
    weather = {{1, u8"Обычная (1-7)"}, {8, u8"Сильная гроза"}, {11, u8"Жара"}, {19, u8"Песчаная буря"}},
    time = {}
}
for i = 0, 23 do table.insert(lists.time, {i, string.format("%02d:00", i)}) end

-- ================= ТЕМА ОФОРМЛЕНИЯ ПЛАНШЕТА =================
local function ApplyTheme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    style.WindowRounding = 12.0
    style.ChildRounding = 8.0
    style.FrameRounding = 6.0
    style.FrameBorderSize = 1.0 
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)

    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.05, 0.05, 0.08, 0.98)
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.08, 0.08, 0.12, 0.95)
    colors[imgui.Col.Text] = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
    colors[imgui.Col.Border] = imgui.ImVec4(1.0, 0.647, 0.0, 0.8)
    colors[imgui.Col.Separator] = imgui.ImVec4(0.3, 0.3, 0.3, 1.0)
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.0, 0.0, 0.0, 1.0)
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.15, 0.15, 0.15, 1.0)
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.25, 0.25, 0.25, 1.0)
    colors[imgui.Col.Button] = imgui.ImVec4(0.1, 0.1, 0.1, 1.0)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.2, 0.2, 0.2, 1.0)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(1.0, 0.647, 0.0, 0.4)
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.02, 0.02, 0.02, 1.0)
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.05, 0.05, 0.05, 1.0)
end

imgui.OnInitialize(function()
    ApplyTheme()
    imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 16.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    local rp = getWorkingDirectory() .. '\\resource\\GTools\\'
    if doesFileExist(rp .. 'admin.png') then Tex.admin = imgui.CreateTextureFromFile(rp .. 'admin.png') end
    if doesFileExist(rp .. 'settings.png') then Tex.settings = imgui.CreateTextureFromFile(rp .. 'settings.png') end
    if doesFileExist(rp .. 'info.png') then Tex.info = imgui.CreateTextureFromFile(rp .. 'info.png') end
    if doesFileExist(rp .. 'skin.png') then Tex.skin = imgui.CreateTextureFromFile(rp .. 'skin.png') end
    if doesFileExist(rp .. 'gun.png') then Tex.gun = imgui.CreateTextureFromFile(rp .. 'gun.png') end
    if doesFileExist(rp .. 'car.png') then Tex.car = imgui.CreateTextureFromFile(rp .. 'car.png') end
    if doesFileExist(rp .. 'hp.png') then Tex.hp = imgui.CreateTextureFromFile(rp .. 'hp.png') end
    if doesFileExist(rp .. 'armor.png') then Tex.armor = imgui.CreateTextureFromFile(rp .. 'armor.png') end
    if doesFileExist(rp .. 'server.png') then Tex.server = imgui.CreateTextureFromFile(rp .. 'server.png') end
    if doesFileExist(rp .. 'telegram.png') then Tex.telegram = imgui.CreateTextureFromFile(rp .. 'telegram.png') end
    if doesFileExist(rp .. 'nitro.png') then Tex.nitro = imgui.CreateTextureFromFile(rp .. 'nitro.png') end
    if doesFileExist(rp .. 'fly.png') then Tex.fly = imgui.CreateTextureFromFile(rp .. 'fly.png') end
    if doesFileExist(rp .. 'god.png') then Tex.god = imgui.CreateTextureFromFile(rp .. 'god.png') end
end)

local function GetKeyName(id)
    for k, v in pairs(vk) do if v == id then return k:gsub("VK_", "") end end return "NONE"
end
local function trim(s) return s:match("^%s*(.-)%s*$") or "" end

function CheckForUpdate()
    local temp_json = os.getenv("TEMP") .. "\\gtools_update.json"
    downloadUrlToFile(UPDATE_JSON_URL, temp_json, function(id, status)
        if status == 58 then
            local file = io.open(temp_json, "r")
            if file then
                local content = file:read("*a")
                file:close()
                os.remove(temp_json)
                local remote_version = content:match('"version"%s*:%s*"(.-)"')
                if remote_version and remote_version ~= thisScript().version then
                    update_status = 1
                    sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Найдено обновление: v" .. remote_version, -1)
                end
            end
        end
    end)
end

function PerformUpdate()
    local script_path = thisScript().path
    downloadUrlToFile(UPDATE_LUA_URL, script_path, function(id, status)
        if status == 58 then
            sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] {008000}Успешно обновлено! Перезагрузка...", -1)
            lua_thread.create(function() wait(1500) thisScript():reload() end)
        end
    end)
end

-- ================= ПЕРЕХВАТ СООБЩЕНИЙ ЧАТА ДЛЯ АВТОРИЗАЦИИ =================
function sampev.onServerMessage(color, text)
    if UI.win_state[0] and not UI.is_authenticated then
        if text:find("авторизовался") or text:find("уже авторизованы") or text:find("успешно вошли") then
            UI.is_booting = true
            UI.boot_start_time = os.clock()
            UI.is_authenticated = true
        end
    end
end

function onWindowMessage(msg, wparam, lparam)
    if msg == 0x020A then 
        local delta = bit.rshift(wparam, 16)
        if delta > 32767 then delta = delta - 65536 end
        if Cheat.airbrake[0] and not UI.win_state[0] then
            Cheat.ab_speed[0] = math.max(0.1, math.min(5.0, Cheat.ab_speed[0] + (delta > 0 and 0.1 or -0.1)))
        end
    end
end

function sampev.onSendPassengerSync(data) if Cheat.flycar[0] then Cheat.ppc = {data.vehicleId, data.seatId} end end
function sampev.onSendUnoccupiedSync(data)
    if Cheat.flycar[0] then 
        local res, veh = sampGetCarHandleBySampVehicleId(data.vehicleId)
        if res then data.moveSpeed = {x = math.sin(-math.rad(getCarHeading(veh))) * 0.2, y = math.cos(-math.rad(getCarHeading(veh))) * 0.2, z = 0.25} return data end
    end
end
function sampev.onSendVehicleSync(data)
    if Cheat.flycar[0] then 
        Cheat.ppc = {data.vehicleId}
        local res, veh = sampGetCarHandleBySampVehicleId(data.vehicleId)
        if res then data.moveSpeed = {x = math.sin(-math.rad(getCarHeading(veh))) * 1.25, y = math.cos(-math.rad(getCarHeading(veh))) * 1.25, z = 0.25} return data end
    end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    if ACTIVATION_KEY ~= "GTOOLS-PREMIUM-2026" then
        sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Статус: {FF0000}Ошибка активации!{FFFFFF}.", -1)
        thisScript():unload() return
    end

    sampRegisterChatCommand("gtools", function() UI.win_state[0] = not UI.win_state[0] end)
    sampRegisterChatCommand("gp", function() UI.win_state[0] = not UI.win_state[0] end)
    
    sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Статус: {008000}Успешно{FFFFFF}.", -1)
    sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Для открытия панели используйте команду /gtools или /gp", -1)
    
    UI.notif_start_time = os.clock()
    UI.show_notif = true
    CheckForUpdate()

    while true do
        wait(0)
        
        if UI.win_state[0] then 
            UI.win_alpha = math.min(UI.win_alpha + 0.06, 1.0)
            UI.win_y_offset = math.max(UI.win_y_offset - 15.0, 0.0)
        else 
            UI.win_alpha = math.max(UI.win_alpha - 0.06, 0.0) 
            UI.win_y_offset = math.min(UI.win_y_offset + 15.0, 200.0)
        end

        if isKeyDown(cfg.main.hotkey1) and wasKeyPressed(cfg.main.hotkey2) and not sampIsChatInputActive() and not sampIsDialogActive() then
            UI.win_state[0] = not UI.win_state[0]
        end

        if UI.win_state[0] and wasKeyPressed(vk.VK_ESCAPE) and not UI.wait_hotkey1 and not UI.wait_hotkey2 then
            UI.win_state[0] = false
        end

        if UI.wait_hotkey1 or UI.wait_hotkey2 then
            for k, v in pairs(vk) do
                if wasKeyPressed(v) then
                    if UI.wait_hotkey1 then cfg.main.hotkey1 = v; UI.wait_hotkey1 = false
                    elseif UI.wait_hotkey2 then cfg.main.hotkey2 = v; UI.wait_hotkey2 = false end
                    inicfg.save(cfg, cfg_path)
                end
            end
        end

        -- ================= ИСПРАВЛЕННЫЙ AIRBRAKE =================
        if wasKeyPressed(vk.VK_RSHIFT) and not sampIsChatInputActive() and not sampIsDialogActive() then
            Cheat.airbrake[0] = not Cheat.airbrake[0]
            if Cheat.airbrake[0] then 
                Cheat.ab_x, Cheat.ab_y, Cheat.ab_z = getCharCoordinates(PLAYER_PED)
                sampAddChatMessage('[{FFA500}G{FFFFFF}Tools] AirBrake - {00DD00}Вкл', -1)
            else 
                sampAddChatMessage('[{FFA500}G{FFFFFF}Tools] AirBrake - {FF0000}Выкл', -1) 
                freezeCharPosition(PLAYER_PED, false) 
            end
        end

        if Cheat.airbrake[0] and not isCharInAnyCar(PLAYER_PED) then
            freezeCharPosition(PLAYER_PED, true)
            local speed = Cheat.ab_speed[0]
            local rx, ry, rz = getActiveCameraCoordinates()
            local tx, ty, tz = getActiveCameraPointAt()
            local vecX, vecY = tx - rx, ty - ry
            local norm = math.sqrt(vecX^2 + vecY^2)
            if norm > 0 then vecX, vecY = (vecX / norm) * speed, (vecY / norm) * speed else vecX, vecY = 0, 0 end

            if isKeyDown(vk.VK_W) then Cheat.ab_x = Cheat.ab_x + vecX; Cheat.ab_y = Cheat.ab_y + vecY end
            if isKeyDown(vk.VK_S) then Cheat.ab_x = Cheat.ab_x - vecX; Cheat.ab_y = Cheat.ab_y - vecY end
            if isKeyDown(vk.VK_A) then Cheat.ab_x = Cheat.ab_x - vecY; Cheat.ab_y = Cheat.ab_y + vecX end
            if isKeyDown(vk.VK_D) then Cheat.ab_x = Cheat.ab_x + vecY; Cheat.ab_y = Cheat.ab_y - vecX end
            if isKeyDown(vk.VK_SPACE) then Cheat.ab_z = Cheat.ab_z + speed end      
            if isKeyDown(vk.VK_LSHIFT) then Cheat.ab_z = Cheat.ab_z - speed end    

            setCharCoordinates(PLAYER_PED, Cheat.ab_x, Cheat.ab_y, Cheat.ab_z)
            printStringNow('~Y~AirBrake Speed: ~W~' .. string.format("%.1f", speed), 100)
        end
        
        -- FlyCar
        if Cheat.flycar[0] and isCharInAnyCar(PLAYER_PED) then
            local veh = getCarCharIsUsing(PLAYER_PED)
            if getDriverOfCar(veh) == -1 then pcall(sampForcePassengerSyncSeatId, Cheat.ppc[1], Cheat.ppc[2]) pcall(sampForceUnoccupiedSyncSeatId, Cheat.ppc[1], Cheat.ppc[2]) 
            else pcall(sampForceVehicleSync, Cheat.ppc[1]) end
            local speed = getCarSpeed(veh)
            setCarHeavy(veh, false)
            setCarProofs(veh, true, true, true, true, true)
            local var_1, var_2 = getPositionOfAnalogueSticks(0)
            setCarRotationVelocity(veh, var_2 / 64.0, 0.0, var_1 / -64.0)
            if isKeyDown(vk.VK_W) then if speed <= 200.0 then Cheat.fly_cars = Cheat.fly_cars + 0.4 end
            elseif isKeyDown(vk.VK_S) then if Cheat.fly_cars >= 0.0 then Cheat.fly_cars = Cheat.fly_cars - 0.3 else Cheat.fly_cars = 0.0 end end
            if isKeyDown(vk.VK_S) and isKeyDown(vk.VK_SPACE) then Cheat.fly_cars = 0 setCarRotationVelocity(veh, 0.0, 0.0, 0.0) setCarRoll(veh, 0.0) end
            setCarForwardSpeed(veh, Cheat.fly_cars)
        end

        -- Nitro
        if Cheat.nitro[0] and isCharInAnyCar(PLAYER_PED) then
            local myCar = storeCarCharIsInNoSave(PLAYER_PED)
            if getDriverOfCar(myCar) == PLAYER_PED and isKeyDown(vk.VK_MENU) then
                giveNonPlayerCarNitro(myCar)
                local cs = getCarSpeed(myCar)
                if cs < 1.8 then setCarForwardSpeed(myCar, cs + 0.03) end
                mem.setfloat(getCarPointer(myCar) + 0x08A4, -0.5)
                removeVehicleMod(myCar, 1008) removeVehicleMod(myCar, 1009) removeVehicleMod(myCar, 1010)
            end
        end
    end
end

-- ================= УМНЫЕ КНОПКИ =================
local function ActionBtn(label, size, icon_left)
    local pos = imgui.GetCursorScreenPos()
    local clicked = imgui.Button("##btn"..label, size)
    local t_size = imgui.CalcTextSize(label)
    local i_size = icon_left and 18 or 0
    local total_w = t_size.x + i_size + (icon_left and 5 or 0)
    local start_x = pos.x + (size.x - total_w) / 2
    local mid_y = pos.y + size.y / 2

    if icon_left then
        imgui.GetWindowDrawList():AddImage(icon_left, imgui.ImVec2(start_x, mid_y - 9), imgui.ImVec2(start_x + 18, mid_y + 9))
        start_x = start_x + 23
    end
    imgui.GetWindowDrawList():AddText(imgui.ImVec2(start_x, mid_y - t_size.y/2), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Text]), label)
    return clicked
end

local function CustomToggleBtn(label, is_active, width)
    local col_btn = is_active and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.GetStyle().Colors[imgui.Col.Button]
    imgui.PushStyleColor(imgui.Col.Button, col_btn)
    local clicked = imgui.Button(label, imgui.ImVec2(width or 140, 25))
    imgui.PopStyleColor()
    return clicked
end

local function RenderInputWithHint(id_str, hint, buffer, width)
    imgui.PushItemWidth(width)
    imgui.InputTextWithHint("##" .. id_str, hint, buffer, 256)
    imgui.PopItemWidth()
end

local function IDListButton(mode_name)
    if imgui.Button(u8"ID Лист##btn_" .. mode_name, imgui.ImVec2(70, 24)) then
        UI.list_mode = mode_name
        imgui.OpenPopup("ID_List_Popup")
    end
end

-- ================= ФРЕЙМ УВЕДОМЛЕНИЯ =================
local notif_frame = imgui.OnFrame(
    function() return UI.show_notif end,
    function(player)
        player.HideCursor = true
        local resX, resY = getScreenResolution()
        
        local time_passed = os.clock() - UI.notif_start_time
        if time_passed < 0.8 then UI.notif_alpha = time_passed / 0.8
        elseif time_passed > 3.2 and time_passed <= 4.0 then UI.notif_alpha = (4.0 - time_passed) / 0.8
        elseif time_passed > 4.0 then UI.show_notif = false; UI.notif_alpha = 0.0 end

        if UI.notif_alpha > 0 then
            imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY - 120), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(400, 100), imgui.Cond.Always)
            
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, UI.notif_alpha)
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.0, 0.0, 0.0, 0.90))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1.0, 0.647, 0.0, UI.notif_alpha))
            
            if imgui.Begin("##StartupNotif", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
                imgui.Dummy(imgui.ImVec2(0, 10))
                local text1 = u8"[ GTools v" .. thisScript().version .. u8" ]"
                local text2 = u8"Скрипт успешно загружен и готов к работе!"
                local text3 = u8"Открыть меню: /gtools или /gp"
                
                imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(text1).x) / 2)
                imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), text1)
                
                imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(text2).x) / 2)
                imgui.Text(text2)
                
                imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(text3).x) / 2)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), text3)
            end
            imgui.End()
            
            imgui.PopStyleColor(2)
            imgui.PopStyleVar()
        end
    end
)

-- ================= ГЛАВНОЕ ОКНО ПЛАНШЕТА =================
local main_frame = imgui.OnFrame(
    function() return UI.win_alpha > 0.0 end,
    function(player)
        player.HideCursor = not UI.win_state[0]
        local resX, resY = getScreenResolution()
        
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, UI.win_alpha)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 15.0)
        
        local target_y = (resY / 2) + UI.win_y_offset
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, target_y), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(820, 580), imgui.Cond.Always)
        
        if imgui.Begin("##Tablet", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
            
            -- Статус-бар планшета
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"G-OS 1.1.0")
            imgui.SameLine(imgui.GetWindowWidth() - 70)
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), os.date("%H:%M"))
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 5))

            if not UI.is_authenticated then
                -- ЭКРАН АВТОРИЗАЦИИ
                imgui.SetCursorPosY(imgui.GetWindowHeight() / 2 - 60)
                imgui.SetCursorPosX((imgui.GetWindowWidth() - 300) / 2)
                if imgui.BeginChild("AuthScreen", imgui.ImVec2(300, 150), true) then
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    local t1 = u8"Авторизация в панели"
                    imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(t1).x) / 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), t1)
                    
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(20)
                    RenderInputWithHint("auth_pass_tab", u8"Пароль...", Buf.admin_pass, 260)
                    
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(70)
                    if ActionBtn(u8"Войти (/alogin)", imgui.ImVec2(160, 30)) then
                        local p = trim(ffi.string(Buf.admin_pass))
                        if p ~= "" then
                            cfg.main.admin_pass = p
                            inicfg.save(cfg, cfg_path)
                            lua_thread.create(function()
                                sampSendChat("/alogin") wait(300)
                                if sampIsDialogActive() then 
                                    sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, p) 
                                    sampCloseCurrentDialogWithButton(1) 
                                end
                            end)
                        end
                    end
                    imgui.EndChild()
                end

            elseif UI.is_booting then
                -- АНИМАЦИЯ ЗАГРУЗКИ G-OS
                local time_passed = os.clock() - UI.boot_start_time
                if time_passed > 2.0 then UI.is_booting = false end
                
                imgui.SetCursorPosY(imgui.GetWindowHeight() / 2 - 30)
                local boot_text = u8"Загрузка системы G-OS..."
                imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(boot_text).x) / 2)
                imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), boot_text)
                
                imgui.Dummy(imgui.ImVec2(0, 10))
                imgui.SetCursorPosX((imgui.GetWindowWidth() - 300) / 2)
                imgui.ProgressBar(time_passed / 2.0, imgui.ImVec2(300, 4))

            else
                -- РАБОЧИЙ СТОЛ ПЛАНШЕТА
                imgui.BeginChild("LeftMenu", imgui.ImVec2(210, 0), true)
                local btn_h = 35
                local function DrawMenuBtn(id, label, tex, is_red)
                    local pos = imgui.GetCursorScreenPos()
                    local is_active = (UI.current_tab == id)
                    if is_active then imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonActive]) end
                    if is_red then imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 0.3, 0.3, 1.0)) end
                    if imgui.Button(label, imgui.ImVec2(-1, btn_h)) then UI.current_tab = id end
                    if is_red then imgui.PopStyleColor() end
                    if is_active then imgui.PopStyleColor() end
                    if tex then imgui.GetWindowDrawList():AddImage(tex, imgui.ImVec2(pos.x + 12, pos.y + 5), imgui.ImVec2(pos.x + 37, pos.y + 30)) end
                    imgui.Dummy(imgui.ImVec2(0, 3))
                end

                DrawMenuBtn(1, u8"          Админ ПО", Tex.admin)
                DrawMenuBtn(2, u8"          Управление сервером", Tex.server, true)
                DrawMenuBtn(3, u8"          Настройки", Tex.settings)
                DrawMenuBtn(4, u8"          О GTools", Tex.info)
                DrawMenuBtn(5, u8"          Правила сервера", Tex.info)
                imgui.EndChild()
                imgui.SameLine()

                imgui.BeginChild("RightContent", imgui.ImVec2(0, 0), true)

                if UI.current_tab == 1 then
                    -- === АДМИН ПО ===
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Авторизация")
                    RenderInputWithHint("auth_pass", u8"Ваш пароль...", Buf.admin_pass, 180)
                    if string.len(ffi.string(Buf.admin_pass)) > 0 then cfg.main.admin_pass = ffi.string(Buf.admin_pass); inicfg.save(cfg, cfg_path) end
                    imgui.SameLine()
                    if ActionBtn(u8"Войти (/alogin)", imgui.ImVec2(160, 24), Tex.okay) then
                        local p = trim(ffi.string(Buf.admin_pass))
                        if p ~= "" then
                            lua_thread.create(function()
                                sampSendChat("/alogin") wait(300)
                                if sampIsDialogActive() then sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, p) sampCloseCurrentDialogWithButton(1) end
                            end)
                        end
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))

                    local function RenderSelector(id_str, buffer, p_id)
                        if cfg.main.target_mode == 1 then RenderInputWithHint(id_str, u8"ID Игрока", buffer, 90)
                        else
                            if imgui.Button(trim(ffi.string(buffer)) == "" and u8"Выбрать ID" or (u8"ID: " .. trim(ffi.string(buffer))), imgui.ImVec2(90, 24)) then
                                UI.popup_target = p_id imgui.OpenPopup("PlayerListPopup")
                            end
                        end
                    end

                    -- СКИН
                    if Tex.skin then imgui.Image(Tex.skin, imgui.ImVec2(24, 24)) imgui.SameLine() end
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Выдача скина")
                    
                    if CustomToggleBtn(u8"Постоянный", Buf.skin_mode[0] == 1, 100) then Buf.skin_mode[0] = 1 end
                    imgui.SameLine()
                    if CustomToggleBtn(u8"Временный", Buf.skin_mode[0] == 2, 100) then Buf.skin_mode[0] = 2 end
                    
                    imgui.Dummy(imgui.ImVec2(0, 2))
                    RenderSelector("skin_pid_input", Buf.skin_pid, "skin") imgui.SameLine() RenderInputWithHint("skin_id_input", u8"ID Скина", Buf.skin_id, 70) imgui.SameLine() IDListButton("skins") imgui.SameLine()
                    if ActionBtn(u8"Выдать скин", imgui.ImVec2(120, 24), Tex.okay) then
                        local pid, sid = trim(ffi.string(Buf.skin_pid)), trim(ffi.string(Buf.skin_id))
                        if pid ~= "" and sid ~= "" then 
                            if Buf.skin_mode[0] == 1 then sampSendChat("/setskin " .. pid .. " " .. sid) else sampSendChat("/tskin " .. pid .. " " .. sid) end 
                        end
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))

                    -- ОРУЖИЕ
                    if Tex.gun then imgui.Image(Tex.gun, imgui.ImVec2(24, 24)) imgui.SameLine() end
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Выдача оружия")
                    RenderSelector("gun_pid_input", Buf.gun_pid, "gun") imgui.SameLine() RenderInputWithHint("gun_id_input", u8"ID Оружия", Buf.gun_id, 70) imgui.SameLine() IDListButton("weapons") imgui.SameLine() RenderInputWithHint("gun_ammo_input", u8"Патроны", Buf.gun_ammo, 80) imgui.SameLine()
                    if ActionBtn(u8"Выдать оружие", imgui.ImVec2(140, 24), Tex.okay) then
                        local pid, wid, ammo = trim(ffi.string(Buf.gun_pid)), trim(ffi.string(Buf.gun_id)), trim(ffi.string(Buf.gun_ammo))
                        if pid ~= "" and wid ~= "" and ammo ~= "" then sampSendChat(string.format("/givegun %s %s %s", pid, wid, ammo)) end
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))

                    -- АВТО
                    if Tex.car then imgui.Image(Tex.car, imgui.ImVec2(24, 24)) imgui.SameLine() end
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Создание авто")
                    
                    if CustomToggleBtn(u8"Себе", Buf.veh_mode[0] == 1, 80) then Buf.veh_mode[0] = 1 end
                    imgui.SameLine()
                    if CustomToggleBtn(u8"Игроку", Buf.veh_mode[0] == 2, 80) then Buf.veh_mode[0] = 2 end

                    imgui.Dummy(imgui.ImVec2(0, 2))
                    if Buf.veh_mode[0] == 2 then RenderSelector("veh_pid_input", Buf.veh_pid, "veh") imgui.SameLine() end
                    RenderInputWithHint("veh_id_input", u8"ID Авто", Buf.veh_id, 70) imgui.SameLine() IDListButton("cars") imgui.SameLine() RenderInputWithHint("veh_c1_input", u8"Цвет 1", Buf.veh_col1, 50) imgui.SameLine() RenderInputWithHint("veh_c2_input", u8"Цвет 2", Buf.veh_col2, 50) imgui.SameLine()
                    if ActionBtn(u8"Создать авто", imgui.ImVec2(140, 24), Tex.okay) then
                        local vpid, vid, c1, c2 = trim(ffi.string(Buf.veh_pid)), trim(ffi.string(Buf.veh_id)), trim(ffi.string(Buf.veh_col1)), trim(ffi.string(Buf.veh_col2))
                        if c2 == "" then c2 = c1 end 
                        if vid ~= "" and c1 ~= "" then
                            if Buf.veh_mode[0] == 1 then sampSendChat(string.format("/veh %s %s %s", vid, c1, c2)) else sampSendChat(string.format("/plveh %s %s %s %s", vpid, vid, c1, c2)) end
                        end
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))

                    -- ХП И БРОНЯ
                    if Tex.hp then imgui.Image(Tex.hp, imgui.ImVec2(24, 24)) imgui.SameLine() end
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Выдача здоровья")
                    RenderSelector("hp_pid_input", Buf.hp_pid, "hp") imgui.SameLine() RenderInputWithHint("hp_val_input", u8"Кол-во ХП", Buf.hp_val, 80) imgui.SameLine()
                    if ActionBtn(u8"Выдать ХП", imgui.ImVec2(130, 24), Tex.okay) then
                        local pid, val = trim(ffi.string(Buf.hp_pid)), trim(ffi.string(Buf.hp_val))
                        if pid ~= "" and val ~= "" then sampSendChat(string.format("/sethp %s %s", pid, val)) end
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    
                    if Tex.armor then imgui.Image(Tex.armor, imgui.ImVec2(24, 24)) imgui.SameLine() end
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Выдача брони")
                    RenderSelector("arm_pid_input", Buf.arm_pid, "arm") imgui.SameLine() RenderInputWithHint("arm_val_input", u8"Кол-во Брони", Buf.arm_val, 80) imgui.SameLine()
                    if ActionBtn(u8"Выдать Броню", imgui.ImVec2(140, 24), Tex.okay) then
                        local pid, val = trim(ffi.string(Buf.arm_pid)), trim(ffi.string(Buf.arm_val))
                        if pid ~= "" and val ~= "" then sampSendChat(string.format("/setarmor %s %s", pid, val)) end
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    
                    -- ЧИТЫ
                    if Tex.cheat then imgui.Image(Tex.cheat, imgui.ImVec2(24, 24)) imgui.SameLine() end
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Управление транспортом и читы")
                    
                    if ActionBtn(u8"Починить (/flip)", imgui.ImVec2(160, 25), Tex.okay) then sampSendChat("/flip") end imgui.SameLine()
                    if ActionBtn(u8"Заправить (/setfuel)", imgui.ImVec2(180, 25), Tex.okay) then sampSendChat("/setfuel 80") end imgui.SameLine()
                    if ActionBtn(u8"Удалить (/spcar)", imgui.ImVec2(160, 25), Tex.okay) then sampSendChat("/spcar") end 
                    
                    imgui.Dummy(imgui.ImVec2(0, 3))
                    
                    if ActionBtn(u8"Активировать бессмертие", imgui.ImVec2(240, 25), Tex.god) then sampSendChat("/gm") sampAddChatMessage("[{FFA500}G{FFFFFF}Tools] Команда /gm отправлена.", -1) end imgui.SameLine()
                    if ActionBtn(Cheat.flycar[0] and u8"Выкл FlyCar" or u8"Вкл FlyCar", imgui.ImVec2(140, 25), Tex.fly) then Cheat.flycar[0] = not Cheat.flycar[0] end imgui.SameLine()
                    if ActionBtn(Cheat.nitro[0] and u8"Выкл Nitro" or u8"Вкл Nitro", imgui.ImVec2(140, 25), Tex.nitro) then Cheat.nitro[0] = not Cheat.nitro[0] end

                elseif UI.current_tab == 2 then
                    -- === УПРАВЛЕНИЕ СЕРВЕРОМ ===
                    if trim(ffi.string(Buf.server_pass_input)) ~= SERVER_SECRET and cfg.main.server_pass ~= SERVER_SECRET then
                        if Tex.auth then imgui.Image(Tex.auth, imgui.ImVec2(32, 32)) imgui.SameLine() end
                        imgui.SetCursorPosY(imgui.GetCursorPosY() + 6)
                        imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), u8"Доступ закрыт!")
                        imgui.Text(u8"Введите 30-значный уникальный пароль.")
                        RenderInputWithHint("serv_pass_inp", u8"Пароль...", Buf.server_pass_input, 300) imgui.SameLine()
                        if ActionBtn(u8"Подтвердить", imgui.ImVec2(140, 24), Tex.okay) then
                            if trim(ffi.string(Buf.server_pass_input)) == SERVER_SECRET then 
                                cfg.main.server_pass = trim(ffi.string(Buf.server_pass_input)) 
                                inicfg.save(cfg, cfg_path) 
                            end
                        end
                    else
                        imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Погодные условия и время суток")
                        RenderInputWithHint("weath_inp", u8"ID Погоды", Buf.weath_val, 100) imgui.SameLine() IDListButton("weather") imgui.SameLine()
                        if ActionBtn(u8"Установить погоду", imgui.ImVec2(180, 24), Tex.okay) then 
                            local val = trim(ffi.string(Buf.weath_val))
                            if val ~= "" then sampSendChat("/weather " .. val) end 
                        end
                        
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        RenderInputWithHint("time_inp", u8"Часы (0-23)", Buf.time_val, 100) imgui.SameLine() IDListButton("time") imgui.SameLine()
                        if ActionBtn(u8"Установить время", imgui.ImVec2(180, 24), Tex.okay) then 
                            local val = trim(ffi.string(Buf.time_val))
                            if val ~= "" then sampSendChat("/settime " .. val) end 
                        end
                        
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        
                        imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Экономика")
                        local function RenderServerSelector(id_str, buffer, p_id)
                            if cfg.main.target_mode == 1 then RenderInputWithHint(id_str, u8"ID Игрока", buffer, 90)
                            else if imgui.Button(trim(ffi.string(buffer)) == "" and u8"Выбрать ID" or (u8"ID: " .. trim(ffi.string(buffer))), imgui.ImVec2(90, 24)) then UI.popup_target = p_id imgui.OpenPopup("PlayerListPopup") end end
                        end

                        RenderServerSelector("mon_pid_inp", Buf.mon_pid, "mon") imgui.SameLine() RenderInputWithHint("mon_val_inp", u8"Сумма ?", Buf.mon_val, 120) imgui.SameLine()
                        if ActionBtn(u8"Выдать рубли", imgui.ImVec2(150, 24), Tex.okay) then 
                            local pid, val = trim(ffi.string(Buf.mon_pid)), trim(ffi.string(Buf.mon_val))
                            if pid ~= "" and val ~= "" then sampSendChat(string.format("/givemoney %s %s", pid, val)) end 
                        end
                        
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        RenderServerSelector("don_pid_inp", Buf.don_pid, "don") imgui.SameLine() RenderInputWithHint("don_val_inp", u8"Сумма Доната", Buf.don_val, 120) imgui.SameLine()
                        if ActionBtn(u8"Выдать донат", imgui.ImVec2(150, 24), Tex.okay) then 
                            local pid, val = trim(ffi.string(Buf.don_pid)), trim(ffi.string(Buf.don_val))
                            if pid ~= "" and val ~= "" then sampSendChat(string.format("/givedonate %s %s", pid, val)) end 
                        end
                    end

                elseif UI.current_tab == 3 then
                    -- === НАСТРОЙКИ ===
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Система выдачи и Ввода")
                    if CustomToggleBtn(u8"Ввод ID и чисел вручную", cfg.main.target_mode == 1, 240) then cfg.main.target_mode = 1; inicfg.save(cfg, cfg_path) end
                    imgui.SameLine()
                    if CustomToggleBtn(u8"Выбор из списка игроков", cfg.main.target_mode == 2, 240) then cfg.main.target_mode = 2; inicfg.save(cfg, cfg_path) end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Управление клавишами")
                    if imgui.Button(UI.wait_hotkey1 and u8"Клавиша 1..." or u8"Кнопка: " .. GetKeyName(cfg.main.hotkey1), imgui.ImVec2(160, 25)) then UI.wait_hotkey1 = true end
                    imgui.SameLine()
                    if imgui.Button(UI.wait_hotkey2 and u8"Клавиша 2..." or u8"Кнопка: " .. GetKeyName(cfg.main.hotkey2), imgui.ImVec2(160, 25)) then UI.wait_hotkey2 = true end
                    
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Настройка AirBrake (Скорость полёта)")
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"Вы можете крутить колесико мыши во время полета для изменения скорости.")
                    imgui.PushItemWidth(300)
                    imgui.SliderFloat("##abspeed", Cheat.ab_speed, 0.1, 5.0, "%.1f")
                    imgui.PopItemWidth()

                    imgui.Dummy(imgui.ImVec2(0, 5))
                    imgui.Separator()
                    imgui.Dummy(imgui.ImVec2(0, 5))
                    
                    imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), u8"Опасная зона")
                    if imgui.Button(u8"Сбросить настройки", imgui.ImVec2(328, 30)) then inicfg.save(default_cfg, cfg_path); thisScript():reload() end

                elseif UI.current_tab == 4 then
                    -- === О GTOOLS ===
                    imgui.Dummy(imgui.ImVec2(0, 20))
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Информация о скрипте:")
                    imgui.Text(u8"Разработчик: Савелий / Катана_Версетти")
                    imgui.Text(u8"Версия: " .. thisScript().version)
                    
                    imgui.Dummy(imgui.ImVec2(0, 15))
                    imgui.SetCursorPosX((imgui.GetWindowWidth() - 320) / 2)
                    if ActionBtn(u8"Telegram чат поддержки (скоро)", imgui.ImVec2(320, 35), Tex.telegram) then os.execute('explorer "https://t.me/shedexx1"') end

                elseif UI.current_tab == 5 then
                    -- === ПРАВИЛА ===
                    imgui.TextColored(imgui.ImVec4(1.0, 0.647, 0.0, 1.0), u8"Основные правила сервера:")
                    imgui.TextWrapped(u8"Здесь будет текст правил. Этот раздел находится в разработке и будет заполнен в следующих обновлениях.")
                end

                -- ПОПАП ВЫБОРА ИГРОКА
                if imgui.BeginPopupModal("PlayerListPopup", nil, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings) then
                    imgui.Text(u8"Выберите игрока из списка:")
                    if imgui.BeginChild("##PlayerListChild", imgui.ImVec2(300, 200), true) then
                        for i = 0, 1000 do
                            if sampIsPlayerConnected(i) then
                                if imgui.Selectable(string.format("[%d] %s", i, sampGetPlayerNickname(i))) then
                                    if UI.popup_target == "skin" then ffi.copy(Buf.skin_pid, tostring(i))
                                    elseif UI.popup_target == "gun" then ffi.copy(Buf.gun_pid, tostring(i))
                                    elseif UI.popup_target == "veh" then ffi.copy(Buf.veh_pid, tostring(i))
                                    elseif UI.popup_target == "hp" then ffi.copy(Buf.hp_pid, tostring(i))
                                    elseif UI.popup_target == "arm" then ffi.copy(Buf.arm_pid, tostring(i))
                                    elseif UI.popup_target == "mon" then ffi.copy(Buf.mon_pid, tostring(i))
                                    elseif UI.popup_target == "don" then ffi.copy(Buf.don_pid, tostring(i)) end
                                    imgui.CloseCurrentPopup()
                                end
                            end
                        end
                    end
                    imgui.EndChild()
                    if imgui.Button(u8"Закрыть", imgui.ImVec2(300, 25)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end

                -- ПОПАП ID ЛИСТА
                if imgui.BeginPopupModal("ID_List_Popup", nil, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings) then
                    imgui.Text(u8"Доступные ID:")
                    if imgui.BeginChild("##IDDataChild", imgui.ImVec2(340, 300), true) then
                        local data = lists[UI.list_mode] or {}
                        for _, v in ipairs(data) do
                            if imgui.Selectable(string.format("[%s] %s", tostring(v[1]), v[2])) then
                                if UI.list_mode == "skins" then ffi.copy(Buf.skin_id, tostring(v[1]))
                                elseif UI.list_mode == "weapons" then ffi.copy(Buf.gun_id, tostring(v[1]))
                                elseif UI.list_mode == "cars" then ffi.copy(Buf.veh_id, tostring(v[1]))
                                elseif UI.list_mode == "weather" then ffi.copy(Buf.weath_val, tostring(v[1]))
                                elseif UI.list_mode == "time" then ffi.copy(Buf.time_val, tostring(v[1])) end
                                imgui.CloseCurrentPopup()
                            end
                        end
                    end
                    imgui.EndChild()
                    if imgui.Button(u8"Закрыть", imgui.ImVec2(340, 25)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end

                imgui.EndChild()
            end
        end
        imgui.End()
        imgui.PopStyleVar(2)
    end
)
script_name("GTools")
script_author("Савелий / Катана_Версетти")
script_version("1.1.0") -- ТЕКУЩАЯ ВЕРСИЯ (Меняй тут при обновлениях)

local imgui = require 'mimgui'
local encoding = require 'encoding'
local ffi = require 'ffi'
local vk = require 'vkeys'
local inicfg = require 'inicfg'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ================= ССЫЛКИ ДЛЯ АВТООБНОВЛЕНИЯ =================
-- Замени эти ссылки на свои RAW-ссылки с GitHub, когда зальешь туда файлы!
local UPDATE_JSON_URL = "https://raw.githubusercontent.com/Alex228123ss/grand-launcher-news/blob/main/moonloader/update.json"
local UPDATE_LUA_URL = "https://raw.githubusercontent.com/Alex228123ss/grand-launcher-news/blob/main/moonloader/gtools.lua"
local update_status = 0 -- 0 - ожидание, 1 - есть обнова, 2 - обновлено

-- ================= НАСТРОЙКИ (INICFG) =================
local cfg_path = "GTools.ini"
local default_cfg = {
    main = {
        admin_pass = "",
        theme = 1,          
        hotkey1 = vk.VK_MENU,
        hotkey2 = vk.VK_G,
        target_mode = 1 -- 1 = Ручной ввод, 2 = Выбор из списка
    }
}

local cfg = inicfg.load(default_cfg, cfg_path)
if not cfg then
    inicfg.save(default_cfg, cfg_path)
    cfg = default_cfg
end

-- Переменные состояний
local win_state = imgui.new.bool(false)
local show_notif = false
local notif_start_time = 0

-- Буферы
local admin_pass = imgui.new.char[256](cfg.main.admin_pass)

local skin_pid  = imgui.new.char[256]()
local skin_id   = imgui.new.char[256]()

local gun_pid   = imgui.new.char[256]()
local gun_id    = imgui.new.char[256]()
local gun_ammo  = imgui.new.char[256]()

local veh_id    = imgui.new.char[256]()
local veh_col1  = imgui.new.char[256]()
local veh_col2  = imgui.new.char[256]()

local wait_hotkey1 = false
local wait_hotkey2 = false

-- Вспомогательная функция для всплывающего списка игроков
local popup_target = "" -- Чтобы понимать, для какого поля открыли список

-- ================= ТЕМЫ ОФОРМЛЕНИЯ =================
local function ApplyTheme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    
    style.WindowRounding = 8.0
    style.FrameRounding = 6.0
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    if cfg.main.theme == 1 then
        colors[imgui.Col.WindowBg] = imgui.ImVec4(0.12, 0.12, 0.14, 0.98)
        colors[imgui.Col.Text] = imgui.ImVec4(0.95, 0.96, 0.98, 1.00)
        colors[imgui.Col.Button] = imgui.ImVec4(0.28, 0.40, 0.65, 1.00)
        colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.38, 0.50, 0.75, 1.00)
        colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.22, 0.35, 0.55, 1.00)
    elseif cfg.main.theme == 2 then
        colors[imgui.Col.WindowBg] = imgui.ImVec4(0.95, 0.95, 0.95, 0.98)
        colors[imgui.Col.Text] = imgui.ImVec4(0.1, 0.1, 0.1, 1.00)
        colors[imgui.Col.Button] = imgui.ImVec4(0.7, 0.7, 0.7, 1.00)
        colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.6, 0.6, 0.6, 1.00)
        colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.5, 0.5, 0.5, 1.00)
    elseif cfg.main.theme == 3 then
        colors[imgui.Col.WindowBg] = imgui.ImVec4(0.05, 0.10, 0.20, 0.98)
        colors[imgui.Col.Text] = imgui.ImVec4(0.90, 0.95, 1.00, 1.00)
        colors[imgui.Col.Button] = imgui.ImVec4(0.10, 0.40, 0.80, 1.00)
        colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.15, 0.50, 0.90, 1.00)
        colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.05, 0.30, 0.70, 1.00)
    end
end

imgui.OnInitialize(function()
    ApplyTheme()
    imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 16.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
end)

local function GetKeyName(id)
    for k, v in pairs(vk) do
        if v == id then return k:gsub("VK_", "") end
    end
    return "NONE"
end

-- ================= ФУНКЦИЯ АВТООБНОВЛЕНИЯ =================
function CheckForUpdate()
    local temp_json = os.getenv("TEMP") .. "\\gtools_update.json"
    downloadUrlToFile(UPDATE_JSON_URL, temp_json, function(id, status)
        if status == 58 then -- Успешно скачано
            local file = io.open(temp_json, "r")
            if file then
                local content = file:read("*a")
                file:close()
                os.remove(temp_json)
                -- Парсим JSON вручную (простая регулярка)
                local remote_version = content:match('"version"%s*:%s*"(.-)"')
                if remote_version and remote_version ~= thisScript().version then
                    update_status = 1 -- Доступно обновление!
                    sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Найдено обновление: v" .. remote_version .. ". Откройте меню для скачивания.", -1)
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
            thisScript():reload()
        end
    end)
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    local init_success = true 
    sampRegisterChatCommand("gtools", function() win_state[0] = not win_state[0] end)

    if init_success then
        sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Статус: {008000}Успешно{FFFFFF}.", -1)
        sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Для открытия панели {FFA500}G{FFFFFF}Tools используйте команду /gtools", -1)
        notif_start_time = os.clock()
        show_notif = true
        
        -- Запускаем проверку обновлений
        CheckForUpdate()
    else
        sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Статус: {FF0000}Ошибка{FFFFFF}.", -1)
        sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Код ошибки: {FF0000}77", -1)
        sampAddChatMessage("{FFFFFF}[{FFA500}G{FFFFFF}Tools] Сообщите {FF0000}код ошибки {0088CC}Telegram чат '{FFA500}G{FFFFFF}Tools{FFFFFF}'.", -1)
    end

    while true do
        wait(0)
        if isKeyDown(cfg.main.hotkey1) and wasKeyPressed(cfg.main.hotkey2) and not sampIsChatInputActive() and not sampIsDialogActive() then
            win_state[0] = not win_state[0]
        end

        if wait_hotkey1 or wait_hotkey2 then
            for k, v in pairs(vk) do
                if wasKeyPressed(v) then
                    if wait_hotkey1 then cfg.main.hotkey1 = v; wait_hotkey1 = false
                    elseif wait_hotkey2 then cfg.main.hotkey2 = v; wait_hotkey2 = false end
                    inicfg.save(cfg, cfg_path)
                end
            end
        end
    end
end

-- Вспомогательная функция для создания красивого блока ввода с выравниванием
local function RenderInputRow(label, buffer, width)
    imgui.Text(label)
    imgui.SameLine(90) -- Фиксированный отступ для ровности
    imgui.PushItemWidth(width)
    imgui.InputText("##" .. label, buffer, 256)
    imgui.PopItemWidth()
end

local frame = imgui.OnFrame(
    function() return win_state[0] or show_notif or update_status == 1 end,
    function(player)
        local resX, resY = getScreenResolution()
        
        -- ================= АНИМИРОВАННОЕ RGB УВЕДОМЛЕНИЕ =================
        if show_notif then
            local time_passed = os.clock() - notif_start_time
            local alpha = 1.0
            local y_offset = 0

            if time_passed < 0.5 then alpha = time_passed / 0.5; y_offset = 30 * (1.0 - alpha)
            elseif time_passed > 3.5 and time_passed <= 4.0 then alpha = (4.0 - time_passed) / 0.5; y_offset = 30 * (1.0 - alpha)
            elseif time_passed > 4.0 then show_notif = false; alpha = 0.0 end

            if alpha > 0 then
                imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY - 120 + y_offset), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
                imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
                imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.1, 0.1, 0.1, 0.90))
                
                local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings
                
                if imgui.Begin("##StartupNotif", nil, flags) then
                    -- Генерация RGB цвета по времени (переливание)
                    local time_now = os.clock() * 2.0
                    local r = math.sin(time_now) * 0.5 + 0.5
                    local g = math.sin(time_now + 2.094) * 0.5 + 0.5
                    local b = math.sin(time_now + 4.188) * 0.5 + 0.5
                    local rgb_color = imgui.GetColorU32Vec4(imgui.ImVec4(r, g, b, alpha))

                    -- Рисуем обводку окна
                    local p_min = imgui.GetWindowPos()
                    local p_max = imgui.ImVec2(p_min.x + imgui.GetWindowWidth(), p_min.y + imgui.GetWindowHeight())
                    imgui.GetWindowDrawList():AddRect(p_min, p_max, rgb_color, 8.0, 15, 2.0)

                    imgui.TextColored(imgui.ImVec4(1.0, 0.65, 0.0, 1.0), "G")
                    imgui.SameLine(0, 0)
                    imgui.TextColored(imgui.ImVec4(1.0, 1.0, 1.0, 1.0), "Tools")
                    imgui.SameLine()
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8" | v" .. thisScript().version .. " | ")
                    imgui.SameLine()
                    imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.3, 1.0), u8"Успешно загружен")
                end
                imgui.End()
                
                imgui.PopStyleVar()
                imgui.PopStyleColor()
            end
        end

        -- ================= ГЛАВНОЕ МЕНЮ =================
        if win_state[0] then
            imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(560, 520), imgui.Cond.FirstUseEver)

            if imgui.Begin(u8"GTools | Панель управления", win_state, imgui.WindowFlags.NoCollapse) then
                
                -- Плашка обновления
                if update_status == 1 then
                    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.2, 0.6, 0.2, 0.3))
                    if imgui.BeginChild("UpdateBox", imgui.ImVec2(0, 40), true) then
                        imgui.TextColored(imgui.ImVec4(0.5, 1.0, 0.5, 1.0), u8"Доступно новое обновление GTools!")
                        imgui.SameLine(imgui.GetWindowWidth() - 150)
                        if imgui.Button(u8"Обновить сейчас", imgui.ImVec2(140, 25)) then
                            PerformUpdate()
                        end
                    end
                    imgui.EndChild()
                    imgui.PopStyleColor()
                end

                if imgui.BeginTabBar("Tabs") then
                    
                    -- === АДМИН ПО ===
                    if imgui.BeginTabItem(u8"Админ ПО") then
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1.0), u8"? Авторизация в админ-панель")
                        RenderInputRow(u8"Пароль:", admin_pass, 180)
                        if string.len(ffi.string(admin_pass)) > 0 then
                            cfg.main.admin_pass = ffi.string(admin_pass)
                            inicfg.save(cfg, cfg_path)
                        end
                        imgui.SameLine(280)
                        if imgui.Button(u8"Войти (/alogin)", imgui.ImVec2(140, 24)) then
                            local pass = ffi.string(admin_pass)
                            if pass ~= "" then
                                lua_thread.create(function()
                                    sampSendChat("/alogin")
                                    wait(300)
                                    if sampIsDialogActive() then
                                        sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, pass)
                                        sampCloseCurrentDialogWithButton(1)
                                        sampAddChatMessage("[GTools] {00FF00}Авто-вход выполнен!", -1)
                                    end
                                end)
                            else
                                sampAddChatMessage("[GTools] {FFFFFF}Ошибка: Введите пароль!", 0xFF5555)
                            end
                        end
                        
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        
                        -- Функция рендера выбора игрока (Ручной ввод или Кнопка списка)
                        local function RenderPlayerSelector(label_prefix, buffer, popup_id)
                            imgui.Text(label_prefix)
                            imgui.SameLine(90)
                            
                            if cfg.main.target_mode == 1 then
                                -- Ручной ввод
                                imgui.PushItemWidth(80)
                                imgui.InputText("##" .. label_prefix, buffer, 256)
                                imgui.PopItemWidth()
                            else
                                -- Выбор из списка
                                local btn_text = ffi.string(buffer) == "" and u8"Выбрать игрока" or (u8"Игрок ID: " .. ffi.string(buffer))
                                if imgui.Button(btn_text, imgui.ImVec2(140, 24)) then
                                    popup_target = popup_id
                                    imgui.OpenPopup("PlayerListPopup")
                                end
                            end
                        end

                        -- СКИН
                        imgui.TextColored(imgui.ImVec4(0.5, 0.8, 1.0, 1.0), u8"? Выдача скина")
                        RenderPlayerSelector(u8"Игрок:", skin_pid, "skin")
                        
                        imgui.Text(u8"Скин:")
                        imgui.SameLine(90)
                        imgui.PushItemWidth(80)
                        imgui.InputText("##skindata", skin_id, 256)
                        imgui.PopItemWidth()
                        
                        imgui.SameLine(280)
                        if imgui.Button(u8"Выдать скин", imgui.ImVec2(140, 24)) then
                            if ffi.string(skin_pid) ~= "" and ffi.string(skin_id) ~= "" then
                                sampSendChat(string.format("/setskin %s %s", ffi.string(skin_pid), ffi.string(skin_id)))
                            end
                        end
                        
                        imgui.Dummy(imgui.ImVec2(0, 5))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 5))

                        -- ОРУЖИЕ
                        imgui.TextColored(imgui.ImVec4(0.5, 0.8, 1.0, 1.0), u8"? Выдача оружия")
                        RenderPlayerSelector(u8"Игрок: ", gun_pid, "gun")
                        
                        imgui.Text(u8"Оружие:") imgui.SameLine(90) imgui.PushItemWidth(80) imgui.InputText("##gun_id", gun_id, 256) imgui.PopItemWidth()
                        imgui.SameLine(180)
                        imgui.Text(u8"Пат:") imgui.SameLine(220) imgui.PushItemWidth(50) imgui.InputText("##gun_ammo", gun_ammo, 256) imgui.PopItemWidth()
                        
                        imgui.SameLine(280)
                        if imgui.Button(u8"Выдать оружие", imgui.ImVec2(140, 24)) then
                            if ffi.string(gun_pid) ~= "" and ffi.string(gun_id) ~= "" and ffi.string(gun_ammo) ~= "" then
                                sampSendChat(string.format("/givegun %s %s %s", ffi.string(gun_pid), ffi.string(gun_id), ffi.string(gun_ammo)))
                            end
                        end

                        imgui.Dummy(imgui.ImVec2(0, 5))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 5))

                        -- АВТО
                        imgui.TextColored(imgui.ImVec4(0.5, 0.8, 1.0, 1.0), u8"? Создание автомобиля")
                        imgui.Text(u8"ID авто:") imgui.SameLine(90) imgui.PushItemWidth(80) imgui.InputText("##vehid", veh_id, 256) imgui.PopItemWidth()
                        
                        imgui.Text(u8"Цвета:") imgui.SameLine(90) imgui.PushItemWidth(35) imgui.InputText("##vehc1", veh_col1, 256) imgui.PopItemWidth()
                        imgui.SameLine(130) imgui.PushItemWidth(35) imgui.InputText("##vehc2", veh_col2, 256) imgui.PopItemWidth()
                        
                        imgui.SameLine(280)
                        if imgui.Button(u8"Создать авто", imgui.ImVec2(140, 24)) then
                            local c2 = ffi.string(veh_col2)
                            if c2 == "" then c2 = ffi.string(veh_col1) end 
                            if ffi.string(veh_id) ~= "" and ffi.string(veh_col1) ~= "" then
                                sampSendChat(string.format("/veh %s %s %s", ffi.string(veh_id), ffi.string(veh_col1), c2))
                            end
                        end

                        imgui.Dummy(imgui.ImVec2(0, 5))
                        
                        -- БЫСТРЫЕ ДЕЙСТВИЯ С АВТО
                        imgui.TextColored(imgui.ImVec4(0.8, 1.0, 0.5, 1.0), u8"? Быстрые действия со своим авто")
                        if imgui.Button(u8"Починить (/flip)", imgui.ImVec2(140, 25)) then sampSendChat("/flip") end
                        imgui.SameLine()
                        if imgui.Button(u8"Заправить (/setfuel)", imgui.ImVec2(160, 25)) then sampSendChat("/setfuel 80") end
                        imgui.SameLine()
                        if imgui.Button(u8"Удалить (/spcar)", imgui.ImVec2(140, 25)) then sampSendChat("/spcar") end

                        -- === ВСПЛЫВАЮЩЕЕ ОКНО СПИСКА ИГРОКОВ ===
                        if imgui.BeginPopupModal("PlayerListPopup", nil, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings) then
                            imgui.Text(u8"Выберите игрока из списка:")
                            imgui.Separator()
                            
                            if imgui.BeginChild("##PlayerListChild", imgui.ImVec2(300, 200), true) then
                                for i = 0, 1000 do
                                    if sampIsPlayerConnected(i) then
                                        local name = sampGetPlayerNickname(i)
                                        if imgui.Selectable(string.format("[%d] %s", i, name)) then
                                            if popup_target == "skin" then ffi.copy(skin_pid, tostring(i))
                                            elseif popup_target == "gun" then ffi.copy(gun_pid, tostring(i)) end
                                            imgui.CloseCurrentPopup()
                                        end
                                    end
                                end
                            end
                            imgui.EndChild()
                            
                            if imgui.Button(u8"Закрыть", imgui.ImVec2(300, 25)) then imgui.CloseCurrentPopup() end
                            imgui.EndPopup()
                        end

                        imgui.EndTabItem()
                    end

                    -- === НАСТРОЙКИ ===
                    if imgui.BeginTabItem(u8"Настройки") then
                        imgui.Dummy(imgui.ImVec2(0, 10))
                        
                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1.0), u8"Дизайн и оформление")
                        if imgui.Button(u8"Темная тема", imgui.ImVec2(150, 25)) then cfg.main.theme = 1; inicfg.save(cfg, cfg_path); ApplyTheme() end
                        imgui.SameLine()
                        if imgui.Button(u8"Светлая тема", imgui.ImVec2(150, 25)) then cfg.main.theme = 2; inicfg.save(cfg, cfg_path); ApplyTheme() end
                        imgui.SameLine()
                        if imgui.Button(u8"Синяя тема", imgui.ImVec2(150, 25)) then cfg.main.theme = 3; inicfg.save(cfg, cfg_path); ApplyTheme() end

                        imgui.Dummy(imgui.ImVec2(0, 10))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 10))

                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1.0), u8"Система выдачи (Выбор цели)")
                        if imgui.RadioButton(u8"Ввод ID вручную", cfg.main.target_mode == 1) then cfg.main.target_mode = 1; inicfg.save(cfg, cfg_path) end
                        imgui.SameLine(180)
                        if imgui.RadioButton(u8"Выбор игрока из списка", cfg.main.target_mode == 2) then cfg.main.target_mode = 2; inicfg.save(cfg, cfg_path) end

                        imgui.Dummy(imgui.ImVec2(0, 10))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 10))

                        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1.0), u8"Кнопки открытия меню: " .. GetKeyName(cfg.main.hotkey1) .. " + " .. GetKeyName(cfg.main.hotkey2))
                        if imgui.Button(wait_hotkey1 and u8"Нажмите клавишу 1..." or u8"Изменить клавишу 1", imgui.ImVec2(180, 25)) then wait_hotkey1 = true end
                        imgui.SameLine()
                        if imgui.Button(wait_hotkey2 and u8"Нажмите клавишу 2..." or u8"Изменить клавишу 2", imgui.ImVec2(180, 25)) then wait_hotkey2 = true end

                        imgui.Dummy(imgui.ImVec2(0, 10))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 10))

                        imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), u8"Опасная зона")
                        if imgui.Button(u8"Сбросить настройки", imgui.ImVec2(280, 30)) then
                            inicfg.save(default_cfg, cfg_path)
                            thisScript():reload()
                        end

                        imgui.EndTabItem()
                    end

                    -- === О GTOOLS ===
                    if imgui.BeginTabItem(u8"О GTools") then
                        imgui.Dummy(imgui.ImVec2(0, 10))
                        
                        imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), u8"Информация о скрипте:")
                        imgui.Text(u8"Разработчик: ") imgui.SameLine() imgui.TextColored(imgui.ImVec4(0.5, 0.8, 1.0, 1.0), u8"Катана_Версетти")
                        imgui.Text(u8"Версия: ") imgui.SameLine() imgui.TextColored(imgui.ImVec4(1.0, 1.0, 0.5, 1.0), u8(thisScript().version))
                        imgui.Text(u8"Дата обновления: ") imgui.SameLine() imgui.TextColored(imgui.ImVec4(0.5, 1.0, 0.5, 1.0), u8"21.02.2026")
                        
                        imgui.Dummy(imgui.ImVec2(0, 15))
                        imgui.Separator()
                        imgui.Dummy(imgui.ImVec2(0, 15))
                        
                        if imgui.Button(u8"Telegram разработчика", imgui.ImVec2(250, 35)) then
                            os.execute('explorer "https://t.me/shedexx1"')
                        end

                        imgui.EndTabItem()
                    end

                    imgui.EndTabBar()
                end
            end
            imgui.End()
        end
    end
)
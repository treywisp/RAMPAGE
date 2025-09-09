--[[

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>

]]

script_name("RAMPAGE")
script_author("treywisp, благодарность chapo за mimgui сниппеты")

local sampev = require("samp.events")
local imgui = require("mimgui")

local rampage_text = {
    "1 YEbaH XyEB", "2 cblHa wJllOxu", "3 WaJlaBbl", "4 nugopaca", "5 XYECOCOB", "6 Ye6uW gETgOMA",
    "7 CblHoBeu WJllOX", "Wicked Sick", "Godlike", "Hitman", "GODNESS KILL", "Most Respected",
    "Unreal Shit", "Bruh Moment", "You madz?", "Stop Please", "Are you God?",
    "Extreme Kill", "wJllOxa c AuMoM Tbl"
}

local func_vars = {
    screen_width = getScreenResolution(),
    frame_path = getWorkingDirectory() .. "\\RAMPAGE\\img",
    sound = getWorkingDirectory().."\\RAMPAGE\\sounds\\sound.mp3",

    gif = nil,
    font = nil,

    first_start = false,
    current_kills = 0,
}

local fade = {
    start_timer = 0,
    alpha = 1.0,
}

local imgui_states = {
    window_state = imgui.new.bool(),
    frame_time = imgui.new.int(50),
}

local killed_players = {}
local recent_textdraws = {}

local function updateFade()
    local current_time = os.clock()
    local time_since_event = current_time - fade.start_timer

    if time_since_event < 1.5 then
        return

    elseif time_since_event < 2.0 then
        fade.alpha = 1.0 - (time_since_event - 1.5) / 0.5

    else
        imgui_states.window_state[0] = false
    end
end

local function notify(text)
    sampAddChatMessage("[RAMPAGE] {FFFFFF}"..text, 0xFF0000)
end

local function playSound()
    local audio = loadAudioStream(func_vars.sound)
    setAudioStreamState(audio, 1)
    setAudioStreamVolume(audio, math.floor(4))
end

local function rampage()
    func_vars.current_kills = math.min(func_vars.current_kills + 1, #rampage_text)
    fade.start_timer = os.clock()
    fade.alpha = 1

    imgui_states.window_state[0] = true
    playSound()
end

function imgui.LoadFrames(path)
    local function getFilesInPath(path, file_type)
        local files, search_handle, file = {}, findFirstFile(path.."\\"..file_type)
        table.insert(files, file)
        while file do file = findNextFile(search_handle) table.insert(files, file) end
        return files
    end
    local files = getFilesInPath(path, '*.png')
    local t = { current = 1, max = #files, last_frame_time = os.clock() }
    table.sort(files, function(a, b)
        local a_num, b_num = tonumber(a:match('(%d+)%.png')), tonumber(b:match('(%d+)%.png'))
        return a_num < b_num
    end)
    for index, file in ipairs(files) do
        t[index] = imgui.CreateTextureFromFile(path..'\\'..file)
    end
    return t
end

function imgui.DrawFrames(images_table, size, frame_time)
    if images_table then
        imgui.Image(images_table[images_table.current], size, nil, nil, imgui.ImVec4(1, 1, 1, fade.alpha))
        if images_table.last_frame_time + ((frame_time or 50)/1000) - os.clock() <= 0 then
            images_table.last_frame_time = os.clock()
            if images_table.current ~= nil then
                images_table.current = images_table[images_table.current + 1] == nil and 1 or images_table.current + 1
            else
                images_table.current = 1
            end
        end
    end
end

function imgui.TextWithShadow(text)
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0, 0, 0, fade.alpha))
    local s_shadowSize = {v = 3}
    local pos = imgui.GetCursorPos()
    imgui.SetCursorPos(imgui.ImVec2(pos.x - s_shadowSize.v, pos.y)) imgui.Text(text)
    imgui.SetCursorPos(imgui.ImVec2(pos.x + s_shadowSize.v, pos.y)) imgui.Text(text)
    imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y + s_shadowSize.v)) imgui.Text(text)
    imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y - s_shadowSize.v)) imgui.Text(text)
    imgui.PopStyleColor()
    imgui.SetCursorPos(pos)
    imgui.TextColored(imgui.ImVec4(1, 1, 1, fade.alpha), text)
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(width / 2 - calc.x / 2)
    imgui.TextWithShadow(text)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    func_vars.gif = imgui.LoadFrames(func_vars.frame_path)
    imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14.0, nil, glyph_ranges)
    func_vars.font = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 34.0, _, glyph_ranges)
end)

imgui.OnFrame(function() return imgui_states.window_state[0] end, function(player)
    player.HideCursor = true
    -- cursor fix
    if not func_vars.first_start then
        imgui_states.window_state[0] = false
        func_vars.first_start = true
        return
    end

    imgui.SetNextWindowSize(imgui.ImVec2(600, 150), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowPos(imgui.ImVec2(func_vars.screen_width / 2, 300), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.Begin("RAMPAGE", imgui_states.window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar +
                                                      imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoFocusOnAppearing +
                                                      imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoBackground)
    
    updateFade()

    imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 2 - imgui.GetStyle().WindowPadding.x);
    imgui.DrawFrames(func_vars.gif, imgui.ImVec2(100, 75), imgui_states.frame_time[0])

    imgui.PushFont(func_vars.font)
    imgui.CenterText(rampage_text[func_vars.current_kills])

    imgui.End()
end)

function main()
    if not isSampAvailable or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait (100) end

    imgui_states.window_state[0] = true -- cursor fix

    notify("Скрипт успешно загружен. Все инструкции на \"github.com/treywisp\"")

    while true do wait(0)

    end
end

function sampev.onSendSpawn()
    func_vars.current_kills = 0
end

-- srp damage informer
function sampev.onShowTextDraw(id, data)
    if id == 2050 and data.text:find(".- %- .- %- KILL") then
        local current_time = os.clock()
        recent_textdraws[data.text] = current_time

        lua_thread.create(function() wait(100)
            if recent_textdraws[data.text] ~= current_time then
                return
            end

            local current_text = sampTextdrawGetString(2050)
            if current_text and current_text:match(".- %- .- %- KILL") then
                local nick = current_text:match("([^%s]-) %-")
                if nick and not killed_players[nick] then
                    killed_players[nick] = true
                    rampage()
                    wait(1500)
                    recent_textdraws[data.text] = nil
                    killed_players[nick] = nil
                end
            end
        end)
    end
end

-- kill list
function sampev.onPlayerDeathNotification(killer_id, victim_id)
    if sampIsPlayerConnected(victim_id) then
        local nick = sampGetPlayerNickname(victim_id)
        if killer_id == select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) and not killed_players[nick] then
            lua_thread.create(function()
                killed_players[nick] = true
                rampage() wait(1500)
                killed_players[nick] = nil
            end)
        end
    end
end

-- standart check
function sampev.onSendGiveDamage(id, damage)
    if sampIsPlayerConnected(id) then
        local nick = sampGetPlayerNickname(id)
        if id == 65535 or killed_players[nick] then return end
        if sampGetPlayerHealth(id) - damage <= 0 then
            lua_thread.create(function()
                wait(350)
                local _, char = sampGetCharHandleBySampPlayerId(id)
                if sampGetPlayerHealth(id) <= 0 and isCharDead(char) and not killed_players[nick] then
                    killed_players[nick] = true
                    rampage() wait(1500)
                    killed_players[nick] = nil
                end
            end)
        end
    end
end
script_name('Craft Helper')
script_author('instrinna')
script_properties("work-in-pause")

local ev = require 'lib.samp.events'
local vkeys = require 'vkeys'
local imgui = require 'mimgui'
local ffi = require 'ffi'
local faicons = require('fAwesome6')
local dlstatus = require('moonloader').download_status
local rkeys = require 'rkeys'
local MoonMonet = require 'MoonMonet'
local gen_colors = MoonMonet.buildColors(0xff50009c, 2.0, true);
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local thisScript = script.this
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
sw, sh 	= getScreenResolution()

-- COLORS
function explode_U32(u32)
  local a = bit.band(bit.rshift(u32, 24), 0xFF)
  local r = bit.band(bit.rshift(u32, 16), 0xFF)
  local g = bit.band(bit.rshift(u32, 8), 0xFF)
  local b = bit.band(u32, 0xFF)
  return a, r, g, b
end
function join_argb(a, r, g, b)
  local argb = b
  argb = bit.bor(argb, bit.lshift(g, 8))
  argb = bit.bor(argb, bit.lshift(r, 16))
  argb = bit.bor(argb, bit.lshift(a, 24))
  return argb
end
function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end
function argb_to_rgba(argb)
  local a, r, g, b = explode_argb(argb)
  return join_argb(r, g, b, a)
end
function vec4ToFloat4(vec4, type)
  type = type or 1
  if type == 1 then
    return new.float[4](vec4.x, vec4.y, vec4.z, vec4.w)
  else
    return new.float[4](vec4.z, vec4.y, vec4.x, vec4.w)
  end
end
function ARGBtoRGB(color)
  return bit.band(color, 0xFFFFFF)
end
function ColorAccentsAdapter(color)
  local a, r, g, b = explode_argb(color)
  local ret = {a = a, r = r, g = g, b = b}
  function ret:apply_alpha(alpha)
    self.a = alpha
    return self
  end
  function ret:as_u32()
    return join_argb(self.a, self.b, self.g, self.r)
  end
  function ret:as_vec4()
    return imgui.ImVec4(self.r / 255, self.g / 255, self.b / 255, self.a / 255)
  end
  function ret:as_argb()
    return join_argb(self.a, self.r, self.g, self.b)
  end
  function ret:as_rgba()
    return join_argb(self.r, self.g, self.b, self.a)
  end
  function ret:as_chat()
    return string.format("%06X", ARGBtoRGB(join_argb(self.a, self.r, self.g, self.b)))
  end
  return ret
end
--<<
-- JSON
function json(filePath)
  local filePath = getWorkingDirectory()..'\\Craft Helper\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
  local class = {}
    if not doesDirectoryExist(getWorkingDirectory()..'\\Craft Helper') then
      createDirectory(getWorkingDirectory()..'\\Craft Helper')
    end
  function class:Save(tbl)
    if tbl then
      local F, err = io.open(filePath, 'w')
      if not F then return false, 'Не удалось открыть файл для записи: ' .. (err or '') end
      local jsonData = encodeJson(tbl)
      if jsonData then
      F:write(jsonData)
      else
      return false, 'Ошибка при кодировании в JSON'
      end
      F:close()
      return true, 'ok'
    end
    return false, 'таблица = nil'
  end
  function class:Load(defaultTable)
      local F
      if not doesFileExist(filePath) then
          class:Save(defaultTable or {})
      end
      F, err = io.open(filePath, 'r')
      if not F then return {}, 'Не удалось открыть файл для чтения: ' .. (err or '') end
      local content = F:read('*a')
      F:close()
      local TABLE = decodeJson(content)
      if TABLE == nil then
        TABLE = {}
      end
      if defaultTable then
        for def_k, def_v in pairs(defaultTable) do
          if TABLE[def_k] == nil then
              TABLE[def_k] = def_v
          end
        end
      end
      return TABLE
  end
  return class
end
--<<
-- Variables
  -- Trash
    otype = "All"
    currentObj = nil
    initialized = false
    CH_DIRECTORY_OBJECTS = "moonloader\\Craft Helper\\objects\\"
    local lu_rus, ul_rus = {}, {}
    local g = {}
    g.curScrollGor = 0
    for i = 192, 223 do
      local A, a = string.char(i), string.char(i + 32)
      ul_rus[A] = a
      lu_rus[a] = A
    end
    local E, e = string.char(168), string.char(184)
    ul_rus[E] = e
    lu_rus[e] = E
  -- JSON
    settingsJs = json('settings.json'):Load({
      ['activeCraft'] = {},
      ['updateInv'] = 30,
      ['showStats'] = true
    })
  -- Imgui windows
    local craft_menu = new.bool(false)
    local active_craft = new.bool(true)
  -- Arrays
    inputs = {
      ['search'] = new.char[256](),
      ['update_inv'] = new.int(30)
    }
    nav = {
      {name = (faicons("GLOBE")..u8" Все предметы"), type = "All"},
      {name = (faicons("HAT_WITCH")..u8" Аксессуары"), type = "Аксессуар"},
      {name = (faicons("SHIRT")..u8" Скины"), type = "Скин"},
      {name = (faicons("CAR")..u8" Транспорт"), type = "Транспорт"},
      {name = (faicons("LOVESEAT")..u8" Объекты"), type = "Объект"},
      {name = (faicons("FLASK")..u8" Эликсиры"), type = "Эликсир"},
      {name = (faicons("ELLIPSIS")..u8" Прочее"), type = "Прочее"},
    }
    toggles = {
      ['showStats'] = new.bool(settingsJs['showStats'])
    }
    object_icons = {}
    await = {}
  --<<
--<<
-- Tags
  function tagerr(arg)
    sampAddChatMessage(("{BE2D2D}[Craft Helper | Ошибка]: {FFFFFF}%s"):format(arg), 0xFFBE2D2D)
  end
  function tagq(arg)
    sampAddChatMessage(("{b09e00}[Craft Helper | Информация]: {FFFFFF}%s"):format(arg), 0xFFb09e00)
  end
  function tag(arg)
    sampAddChatMessage(("{9370DB}[Craft Helper]: {FFFFFF}%s"):format(arg), 0xFF9370DB)
  end
--<<
-- Main
function main()
  if not isSampLoaded() then return end
  while not isSampAvailable() do wait(100) end
  if not sampIsLocalPlayerSpawned() then 
    tagq("Для загрузки скрипта необходимо заспавниться")
    repeat wait(0) until sampIsLocalPlayerSpawned()
  end
  checkFiles()
  registerCommands()
  lua_thread.create(checkInv)
  tag("Все готово к работе!")
  while true do
    wait(0)
    selfid = select(2, sampGetPlayerIdByCharHandle(playerPed))
    self = {
      nick = sampGetPlayerNickname(selfid),
      score = sampGetPlayerScore(selfid),
      color = sampGetPlayerColor(selfid),
      ping = sampGetPlayerPing(selfid),
      gameState = sampGetGamestate()
      }
  end
end
--<<
-- Functions
function registerCommands()
  sampRegisterChatCommand("craft", function()
    craft_menu[0] = not craft_menu[0]
  end)
end
function checkInv()
  lua_thread.create(function()
    await['check_inv'] = true
    if not sampIsDialogActive() then
      sampSendChat("/stats")
      sampSendDialogResponse(235, 1, -1, nil)
    else
      tagerr("Неудалось проверить инвентарь. Причина: Активное диалоговое окно")
    end
  end)
end
function checkFiles()
  local directories = {
      "moonloader\\Craft Helper",
      "moonloader\\Craft Helper\\objects",
      "moonloader\\Craft Helper\\fonts"
  }
  for _, dir in ipairs(directories) do
    if not doesDirectoryExist(dir) then
      tagerr("Не хватает библиотек для работы скрипта. Отсутствует директория: \'' .. dir .. '\'")
      return
    end
  end
  local filePath = getWorkingDirectory() .. "\\Craft Helper\\items.json"
  local f = io.open(filePath, "r")
  if f then
    local s = f:read("*a")
      f:close()
      items = decodeJson(s)
      itemsLoaded = true
  else
    tagerr("Файл \'items.json\' не найден в директории.")
  end
end
function theme()
  imgui.SwitchContext()
  local style = imgui.GetStyle()
  local colors = style.Colors
  local clr = imgui.Col
  local ImVec4 = imgui.ImVec4
  local ImVec2 = imgui.ImVec2
  style.WindowPadding         = imgui.ImVec2(8, 8)
  style.WindowRounding        = 5
  style.ChildRounding   	  	= 5
  style.FramePadding          = imgui.ImVec2(5, 3)
  style.FrameRounding         = 5
  style.ItemSpacing           = imgui.ImVec2(5, 4)
  style.ItemInnerSpacing      = imgui.ImVec2(4, 4)
  style.IndentSpacing         = 21
  style.ScrollbarSize         = 10.0
  style.ScrollbarRounding     = 13
  style.GrabMinSize           = 8
  style.GrabRounding          = 1
  style.WindowTitleAlign      = imgui.ImVec2(0.5, 0.5)
  style.ButtonTextAlign       = imgui.ImVec2(0.5, 0.5)
  disabledButton                      = ColorAccentsAdapter(gen_colors.accent1.color_900):apply_alpha(0xcc):as_vec4()
  disabledButtonActive                = ColorAccentsAdapter(gen_colors.accent1.color_900):apply_alpha(0xb3):as_vec4()
  disabledButtonHovered               = ColorAccentsAdapter(gen_colors.accent1.color_900):as_vec4()
  colors[clr.Text]					          = ColorAccentsAdapter(gen_colors.accent2.color_50):as_vec4()
  colors[clr.TextDisabled]			      = ColorAccentsAdapter(gen_colors.neutral1.color_600):as_vec4()
  colors[clr.WindowBg]				        = ColorAccentsAdapter(gen_colors.accent2.color_900):as_vec4()
  colors[clr.ChildBg]					        = ColorAccentsAdapter(gen_colors.accent2.color_900):as_vec4()
  colors[clr.PopupBg]					        = ColorAccentsAdapter(gen_colors.accent2.color_900):as_vec4()
  colors[clr.Border]					        = ColorAccentsAdapter(gen_colors.accent2.color_300):as_vec4()
  colors[clr.Separator]					      = ColorAccentsAdapter(gen_colors.accent2.color_300):as_vec4()
  colors[clr.BorderShadow]			      = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
  colors[clr.FrameBg]					        = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0x60):as_vec4()
  colors[clr.FrameBgHovered]			    = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0x70):as_vec4()
  colors[clr.FrameBgActive]			      = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0x50):as_vec4()
  colors[clr.TitleBg]					        = ColorAccentsAdapter(gen_colors.accent2.color_700):apply_alpha(0xcc):as_vec4()
  colors[clr.TitleBgCollapsed]		    = ColorAccentsAdapter(gen_colors.accent2.color_700):apply_alpha(0x7f):as_vec4()
  colors[clr.TitleBgActive]			      = ColorAccentsAdapter(gen_colors.accent2.color_700):as_vec4()
  colors[clr.MenuBarBg]				        = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0x91):as_vec4()
  colors[clr.ScrollbarBg]				      = imgui.ImVec4(0,0,0,0)
  colors[clr.ScrollbarGrab]			      = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0x85):as_vec4()
  colors[clr.ScrollbarGrabHovered]	  = ColorAccentsAdapter(gen_colors.accent1.color_600):as_vec4()
  colors[clr.ScrollbarGrabActive]		  = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0xb3):as_vec4()
  colors[clr.CheckMark]				        = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0xcc):as_vec4()
  colors[clr.SliderGrab]				      = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0xcc):as_vec4()
  colors[clr.SliderGrabActive]		    = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0x80):as_vec4()
  colors[clr.Button]					        = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0xcc):as_vec4()
  colors[clr.ButtonHovered]			      = ColorAccentsAdapter(gen_colors.accent1.color_600):as_vec4()
  colors[clr.ButtonActive]			      = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0xb3):as_vec4()
  colors[clr.Header]					        = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0xcc):as_vec4()
  colors[clr.HeaderHovered]			      = ColorAccentsAdapter(gen_colors.accent1.color_600):as_vec4()
  colors[clr.HeaderActive]			      = ColorAccentsAdapter(gen_colors.accent1.color_600):apply_alpha(0xb3):as_vec4()
  colors[clr.ResizeGrip]				      = ColorAccentsAdapter(gen_colors.accent2.color_700):apply_alpha(0xcc):as_vec4()
  colors[clr.ResizeGripHovered]		    = ColorAccentsAdapter(gen_colors.accent2.color_700):as_vec4()
  colors[clr.ResizeGripActive]		    = ColorAccentsAdapter(gen_colors.accent2.color_700):apply_alpha(0xb3):as_vec4()
  colors[clr.PlotLines]				        = ColorAccentsAdapter(gen_colors.accent2.color_600):as_vec4()
  colors[clr.PlotLinesHovered]		    = ColorAccentsAdapter(gen_colors.accent1.color_600):as_vec4()
  colors[clr.PlotHistogram]			      = ColorAccentsAdapter(gen_colors.accent2.color_600):as_vec4()
  colors[clr.PlotHistogramHovered]	  = ColorAccentsAdapter(gen_colors.accent1.color_600):as_vec4()
  colors[clr.TextSelectedBg]			    = ColorAccentsAdapter(gen_colors.accent1.color_600):as_vec4()
  colors[clr.ModalWindowDimBg]		    = ColorAccentsAdapter(gen_colors.accent1.color_200):apply_alpha(0x26):as_vec4()
end
function imgui.CenterText(text)
  imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(text).x / 2)
  imgui.Text(text)
end
function findValue(array, value)
  for k, v in pairs(array) do
    if v == value then
      return true
    end
  end
  return false
end
function imgui.AddCursorPos(x, y)
  local pos = imgui.GetCursorPos()
  imgui.SetCursorPos(imgui.ImVec2(pos.x + x, pos.y + y))
end
function downloadAndCreateTexture(id, name)
  if not doesFileExist(CH_DIRECTORY_OBJECTS .. id .. ".png") then
    downloadUrlToFile("https://items.shinoa.tech/images/model/" .. id .. ".png", CH_DIRECTORY_OBJECTS .. id .. ".png", function(d, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        print(("Object Downloaded - %s"):format(name))
      end
    end)
  end
  object_icons[id] = imgui.CreateTextureFromFile(getGameDirectory() .. "\\" .. CH_DIRECTORY_OBJECTS .. id .. ".png")
end
function processItem(id, name)
  if not findValue(ids, id) then
    ids[#ids + 1] = id
    downloadAndCreateTexture(id, name)
  end
end
local print_orig = print
function print(...)
  local args = {...}
  function table.val_to_str( v )
    if "string" == type( v ) then
      v = string.gsub( v, "\n", "\\n" )
      if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
        return "'" .. v .. "'"
      end
      return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    else
      return "table" == type( v ) and table.tostring( v ) or tostring( v )
    end
  end
  function table.key_to_str( k )
    if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
      return k
    else
      return "[" .. table.val_to_str( k ) .. "]"
    end
  end
  function table.tostring( tbl )
    local result, done = {}, {}
    for k, v in ipairs( tbl ) do
      table.insert( result, table.val_to_str( v ) )
      done[ k ] = true
    end
    for k, v in pairs( tbl ) do
      if not done[ k ] then
        table.insert( result, table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
      end
    end
    return "{" .. table.concat( result, "," ) .. "}"
  end
  for i, arg in ipairs(args) do
    if type(arg) == 'table' then
      args[i] = table.tostring(arg)
    end
  end
  print_orig(table.unpack(args))
end
function imgui.Hint(str_id, hint, delay)
  local hovered = imgui.IsItemHovered()
  local col = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
  local animTime = 0.2
  local delay = delay or 0.00
  local show = true
  if not allHints then allHints = {} end
  if not allHints[str_id] then
    allHints[str_id] = {
      status = false,
      timer = 0
    }
  end
  if hovered then
    for k, v in pairs(allHints) do
      if k ~= str_id and os.clock() - v.timer <= animTime  then
        show = false
      end
    end
  end
  if show and allHints[str_id].status ~= hovered then
    allHints[str_id].status = hovered
    allHints[str_id].timer = os.clock() + delay
  end
  local showHint = function(text, alpha)
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 5)
    imgui.BeginTooltip()
    imgui.TextColored(imgui.ImVec4(col.x, col.y, col.z, 1.00), faicons("CIRCLE_INFO")..u8' Подсказка:')
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(0, 0))
    imgui.Text(text)
    imgui.PopStyleVar()
    imgui.EndTooltip()
    imgui.PopStyleVar(2)
  end
  if show then
    local btw = os.clock() - allHints[str_id].timer
    if btw <= animTime then
      local s = function(f) 
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
      end
      local alpha = hovered and s(btw / animTime) or s(1.00 - btw / animTime)
      showHint(hint, alpha)
    elseif hovered then
      showHint(hint, 1.00)
    end
  end
end
function findKey(array, key)
  for k,v in pairs(array) do
    if k == key then
      return true
    end
  end
  return false
end
function imgui.ToggleButton(str_id, bool)
  local rBool = false
  if LastActiveTime == nil then
    LastActiveTime = {}
  end
  if LastActive == nil then
    LastActive = {}
  end
  local function ImSaturate(f)
    return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
  end
  local p = imgui.GetCursorScreenPos()
  local draw_list = imgui.GetWindowDrawList()
  local height = imgui.GetTextLineHeightWithSpacing()
  local width = height * 1.70
  local radius = height * 0.50
  local ANIM_SPEED = 0.15
  local butPos = imgui.GetCursorPos()
  if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
    bool[0] = not bool[0]
    rBool = true
    LastActiveTime[tostring(str_id)] = os.clock()
    LastActive[tostring(str_id)] = true
  end
    imgui.SetCursorPos(imgui.ImVec2(butPos.x + width + 8, butPos.y + 2.5))
    imgui.Text( str_id:gsub('##.+', '') )
    local t = bool[0] and 1.0 or 0.0
  if LastActive[tostring(str_id)] then
    local time = os.clock() - LastActiveTime[tostring(str_id)]
    if time <= ANIM_SPEED then
      local t_anim = ImSaturate(time / ANIM_SPEED)
      t = bool[0] and t_anim or 1.0 - t_anim
    else
      LastActive[tostring(str_id)] = false
    end
  end
    u32_argb = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(80/255, 0.00, 156/255, 1.00))
    local col_circle = bool[0] and imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.Button]) or 0xFF606060
    draw_list:AddRectFilled(p, imgui.ImVec2(p.x + width, p.y + height), imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.FrameBg]), height * 0.5)
    draw_list:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 1.5, col_circle)
  return rBool
end
function string.nlower(s)
  s = string.lower(s)
  local len, res = #s, {}
  for i = 1, len do
    local ch = string.sub(s, i, i)
    res[i] = ul_rus[ch] or ch
  end
  return table.concat(res)
end
function string.nupper(s) 
  s = string.upper(s)
  local len, res = #s, {}
  for i = 1, len do
    local ch = string.sub(s, i, i)
    res[i] = lu_rus[ch] or ch
  end
  return table.concat(res)
end
--<<
-- Events
function processFoundItem(itemName, itemCount)
  local cleanedItemName = itemName:match("] (.+)") or itemName
  cleanedItemName = cleanedItemName:lower():gsub("%s+", "")
  for _, craft in ipairs(settingsJs['activeCraft']) do
    for _, requirement in pairs(craft.requirements) do
      local cleanedRequirementName = requirement.name:lower():gsub("%s+", "")
        if cleanedItemName == cleanedRequirementName then
        requirement.made = math.min(itemCount, requirement.amount)  
        break
        end
    end
  end
  json('settings.json'):Save(settingsJs)
end
function updateCraftStatistics()
  local foundItems = json('settings.json'):Load()
  for _, craft in ipairs(settingsJs['activeCraft']) do
      print(craft.name)
      for _, requirement in pairs(craft.requirements) do
      end
  end
  json('settings.json'):Save(settingsJs)
end
function ev.onShowDialog(dialogId, style, title, button1, button2, text)
  if dialogId == 235 and await['check_inv'] then
      sampSendDialogResponse(dialogId, 1, 0)
      return false
  end
  if dialogId == 25493 and await['check_inv'] then
      local items_inv = {}
      local isNext = false
      for n in text:gmatch("[^\n\r]+") do
        local name = n:match("%{%x%x%x%x%x%x%}(.+)%s%{%x%x%x%x%x%x%}")
        if name and name ~= "Название" then
          local sum = n:match("%[%d+%] .-\t{......}%[(%d+) шт%]")
            if sum then
              items_inv[#items_inv + 1] = {name = name, count = tonumber(sum)}
              tag(string.format("Обнаружен предмет: %s, количество: %s", name, sum))
              processFoundItem(name, tonumber(sum)) 
            end
        end
        if n:find(">>") then
          sampSendDialogResponse(dialogId, 1, 0)
          isNext = true
          break
        end
      end
      if not next(items_inv) then
        tagerr("Не удалось найти ни одного ресурса в инвентаре.")
        return false
      end
      updateCraftStatistics()
      sampSendDialogResponse(dialogId, 0, 0)
      return false
  end
end
--<<
-- IMGUI
local craftmenu = imgui.OnFrame(
  function() return craft_menu[0] end,
  function(player)
    imgui.SetNextWindowSize(imgui.ImVec2(sw/2, sh/2), imgui.Cond.Always)
    imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5 , sh * 0.5),imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.Begin(u8'Craft-Menu', craft_menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
    imgui.BeginGroup()
      imgui.PushFont(imFont[25])
      imgui.Text(faicons("hammer")..u8" Меню крафта")
      imgui.PushFont(imFont[15])
      imgui.SameLine(imgui.GetWindowWidth()-90)
      imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 1.00, 1.00, 0.00))
      imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 1.00, 1.00, 0.20))
      imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 1.00, 1.00, 0.10))
      if imgui.Button(faicons("GEAR"), imgui.ImVec2(28, 20)) then
        imgui.OpenPopup("GEAR")
      end
      imgui.PopStyleColor(3)
      imgui.SameLine(imgui.GetWindowWidth()-60)
      if imgui.Button(faicons("XMARK"), imgui.ImVec2(40, 20)) then
        craft_menu[0] = false
      end
    imgui.EndGroup()
    imgui.Separator()
    imgui.BeginChild("active", imgui.ImVec2(imgui.GetWindowWidth()/4, imgui.GetWindowHeight()/2), true)
      if #settingsJs['activeCraft'] == 0 then
        imgui.PushFont(imFont[25])
        imgui.SetCursorPosY(imgui.GetWindowHeight()/2-30)
        imgui.CenterText(faicons("sparkles"))
        imgui.PushFont(imFont[15])
        imgui.CenterText(u8"Выберите предметы для крафта")
      else
        imgui.PushFont(imFont[25])
        imgui.CenterText(u8"Активные предметы:")
        imgui.PushFont(imFont[15])
        imgui.Hint("delete", u8"Для удаления нажмите Правой Кнопкой Мыши по тексту")
        imgui.Separator()
        imgui.PushFont(imFont[12])
        for k,v in pairs(settingsJs['activeCraft']) do
          imgui.CenterText(u8(items[v.id].name))
          if imgui.IsItemClicked(1) then
            table.remove(settingsJs['activeCraft'], k)
            json('settings.json'):Save(settingsJs)
          end
        end
        imgui.PushFont(imFont[15])
      end
    imgui.EndChild()
    imgui.BeginChild("sections", imgui.ImVec2(imgui.GetWindowWidth()/4, -1), true)
      for k,v in pairs(nav) do
        if imgui.Button(v.name, imgui.ImVec2(-1, 25)) then
          otype = v.type
          currentObj = nil
        end
      end
    imgui.EndChild()
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/4+20, 45))
    imgui.BeginChild("main", imgui.ImVec2(-1, -1), false)
      imgui.PushItemWidth(-1)
      if imgui.InputText("##search", inputs['search'], sizeof(inputs['search'])) then
        currentObj = nil
      end
      imgui.PopItemWidth()
      if not imgui.IsItemActive() and str(inputs['search']) == "" then
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(u8"Поиск предметов").x / 2)
        imgui.TextDisabled(u8"Поиск предметов")
      end
      imgui.BeginChild("items", imgui.ImVec2(-1, -1), false)
        for i, v in pairs(items) do
          if not currentObj then
            if string.nlower(v.name):find(string.nlower(u8:decode(str(inputs['search'])))) or string.nlower(v.type):find(string.nlower(u8:decode(str(inputs['search'])))) then
              if otype and (otype == "All" or v.type == otype) then
                if imgui.Button(u8(v.name).."##"..i, imgui.ImVec2(-1, 25)) then
                  currentObj = i
                end
              end
            end
          else
            if currentObj == i then
              imgui.TextDisabled(u8"<< Назад")
              if imgui.IsItemHovered() then
                local ip = imgui.GetItemRectMin()
                local calc_text = imgui.CalcTextSize(u8"<< Назад")
                imgui.GetWindowDrawList():AddLine(imgui.ImVec2(ip.x, ip.y+calc_text.y+2), imgui.ImVec2(ip.x+calc_text.x, ip.y+calc_text.y+2), 0xAA808080, 1)
              end
              if imgui.IsItemClicked() then
                currentObj = nil
              end
              imgui.SameLine()
              imgui.PushFont(imFont[25])
              imgui.CenterText(u8(v.name))
              imgui.PushFont(imFont[15])
              imgui.BeginChild("##Info", imgui.ImVec2(200, 150), true)
                imgui.CenterText(u8"Предмет:")
                imgui.Text(u8"Использование: " .. u8(v.use == true and "Да" or "Нет"))
                imgui.Text(u8"Передача(trade): " .. u8(v.trade == true and "Да" or "Нет"))
                imgui.Text(u8"Выкидывать: " .. u8(v.drop == true and "Да" or "Нет"))
                imgui.Text(u8"Слот: " .. u8(v.slot == "-1" and "Нельзя надеть" or v.slot))
                imgui.Text(u8"Цвет: " .. u8(v.color == true and "Можно перекрасить" or "Нельзя перекрасить"))
              imgui.EndChild()
              imgui.SameLine(imgui.GetWindowWidth()-210)
              imgui.BeginChild("##PNG", imgui.ImVec2(200, 150), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
                imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2-75, 0))
                imgui.Image(object_icons[i], imgui.ImVec2(150, 150))
              imgui.EndChild()
              imgui.AddCursorPos(0, 30)
              imgui.PushFont(imFont[25])
              imgui.CenterText(u8"Крафт")
              imgui.PushFont(imFont[15])
              for k, r in pairs(v.requirements) do
                imgui.BeginChild(k, imgui.ImVec2(125, 200), false)
                  imgui.BeginChild(k.."Image", imgui.ImVec2(125, 125), true)
                    imgui.Image(object_icons[k], imgui.ImVec2(100, 100))
                    if imgui.IsItemHovered() then
                      imgui.BeginTooltip();
                      imgui.Text(u8(r.name))
                      if findKey(items, k) then
                        imgui.Text(u8"Данный предмет можно скрафтить.\nНажмите ЛКМ для быстрого перехода.")
                      end
                      imgui.EndTooltip();
                    end
                    if imgui.IsItemClicked() and findKey(items, k) then
                      currentObj = k
                    end
                imgui.EndChild()
                imgui.PushFont(imFont[15])
                imgui.CenterText(u8(r.amount.." шт."))
                imgui.EndChild()
                imgui.SameLine()
                imgui.AddCursorPos(10, 0)
              end
              imgui.NewLine()
              imgui.SetCursorPosY(imgui.GetWindowHeight()-30)
              if imgui.Button(faicons("PLAY")..u8" Начать крафт", imgui.ImVec2(-1, 25)) then
                currentObj = nil
                local requirements = v.requirements
                for _, v in pairs(requirements) do
                  v.made = 0
                end
                table.insert(settingsJs['activeCraft'], {id = i, requirements = requirements})
                json('settings.json'):Save(settingsJs)
              end
            end
          end
        end
      imgui.EndChild()
    imgui.EndChild()
    if imgui.BeginPopupModal("GEAR", null, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar) then
      imgui.SetWindowSizeVec2(imgui.ImVec2(sw/6, sh/7))
      imgui.BeginGroup()
        imgui.PushFont(imFont[25])
        imgui.Text(faicons("GEAR")..u8" Настройки")
        imgui.PushFont(imFont[15])
        imgui.SameLine(imgui.GetWindowWidth()-60)
        if imgui.Button(faicons("XMARK"), imgui.ImVec2(40, 20)) then
          imgui.CloseCurrentPopup()
        end
      imgui.EndGroup()
      imgui.Separator()
      imgui.NewLine()
      imgui.Text(u8"Частота обновления инвентаря: ")
      imgui.SameLine()
      imgui.PushItemWidth(50)
      if imgui.InputInt("##updateInventory", inputs['update_inv'], 0) then
        if inputs['update_inv'][0] < 10 then inputs['update_inv'][0] = 10 end
        if inputs['update_inv'][0] > 120 then inputs['update_inv'][0] = 120 end
        settingsJs['updateInv'] = inputs['update_inv'][0]
        json('settings.json'):Save(settingsJs)
      end; imgui.SameLine(); imgui.Text("c.")
      imgui.PopItemWidth();
      imgui.Text(u8"Отображать статистику крафта: ")
      imgui.SameLine()
      if imgui.ToggleButton("##statsCraft", toggles['showStats']) then
        settingsJs['showStats'] = toggles['showStats'][0]
        json('settings.json'):Save(settingsJs)
      end
      imgui.EndPopup()
    end
    imgui.End()
  end
)
imgui.OnFrame(
  function() return active_craft[0] end,
  function(player)
      if #settingsJs['activeCraft'] ~= 0 and settingsJs['showStats'] then
        imgui.SetNextWindowSize(imgui.ImVec2(sw / 6, sh / 6), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 1.2, sh / 1.4), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
          imgui.Begin(u8'Active Craft', active_craft, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
          imgui.PushFont(imFont[15])
          imgui.SetCursorPosX((imgui.GetWindowSize().x - imgui.CalcTextSize(u8"Активные крафты").x) / 2)
          imgui.Text(u8"Активные крафты")
          imgui.PopFont()
          for k, v in pairs(settingsJs['activeCraft']) do
            imgui.PushFont(imFont[15])
            imgui.Separator()
              if items then
                local totalAmount = 0
                local totalMade = 0
                  for _, requirement in pairs(v.requirements) do
                    totalAmount = totalAmount + tonumber(requirement["amount"])
                    totalMade = totalMade + tonumber(requirement["made"]) or 0
                  end
                  local percentage = (totalMade / totalAmount) * 100
                  local itemName = u8(items[v.id].name)
                  local itemNameSize = imgui.CalcTextSize(itemName).x
                  imgui.SetCursorPosX((imgui.GetWindowSize().x - itemNameSize) / 2)
                  imgui.Text(itemName)
                  if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.Image(object_icons[v.id], imgui.ImVec2(150, 150))
                    imgui.EndTooltip()
                  end
                    imgui.SameLine()
                    imgui.TextDisabled(("[%s]"):format(math.floor(percentage).."%%"))
                    imgui.Spacing()
                  for i, r in pairs(v.requirements) do
                        imgui.Text(u8(("%s - [%s/%s]"):format(r.name, tostring(r.made), r.amount)))
                  end
              end
            imgui.Separator()
          end
            if imgui.Button(u8'Сканер', imgui.ImVec2(-1, 25)) then
              checkInv()
            end
            imgui.End()
        end
    end
).HideCursor = true
imgui.OnInitialize(function()
  imgui.GetIO().IniFilename = nil
  local config = imgui.ImFontConfig()
  config.MergeMode = true
  config.PixelSnapH = true
  iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
  local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
  local mainFont = getWorkingDirectory() .. '\\Craft Helper\\fonts\\font.ttf'
  imFont = {}
  imgui.GetIO().Fonts:AddFontFromFileTTF(mainFont, 15.0, nil, glyph_ranges)
  imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 15, config, iconRanges)
  imFont[12] = imgui.GetIO().Fonts:AddFontFromFileTTF(mainFont, 12.0, nil, glyph_ranges)
  imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 12, config, iconRanges)
  imFont[15] = imgui.GetIO().Fonts:AddFontFromFileTTF(mainFont, 15.0, nil, glyph_ranges)
  imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 15, config, iconRanges)
  imFont[20] = imgui.GetIO().Fonts:AddFontFromFileTTF(mainFont, 20.0, nil, glyph_ranges)
  imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 20, config, iconRanges)
  imFont[25] = imgui.GetIO().Fonts:AddFontFromFileTTF(mainFont, 25.0, nil, glyph_ranges)
  imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 25, config, iconRanges)
  theme()
  ids = {}
  lua_thread.create(function()
    while not items do wait(0) end
    for k, v in pairs(items) do
      processItem(k, v.name)
      for i, l in pairs(v.requirements) do
        processItem(i, l.name)
      end
    end
  end)
end)
--<<
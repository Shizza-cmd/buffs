ADDON:ImportAPI(API_TYPE.CHAT.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)

ADDON:ImportObject(OBJECT_TYPE.BUTTON)
ADDON:ImportObject(OBJECT_TYPE.LABEL)
ADDON:ImportObject(OBJECT_TYPE.ICON_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.TEXT_STYLE)

-- Типы юнитов, за которыми будем следить
local unitTypes = { "target", "watchtarget" }

-- Смещение иконки относительно позиции юнита
local offsetX, offsetY = -103, -42
-- Размер иконки
local iconSize = 32
-- Дополнительное смещение иконок для эффектов, чтобы они не перекрывались
local effectIconSpacing = 35  -- Расстояние между иконками

local trackedDebuffs = {
    {name = "Использование щита", iconPath = "ui/icon/icon_skill_buff260.dds"},
    {name = "Очарование", iconPath = "ui/icon/icon_skill_buff75.dds"},
    {name = "Уязвимость", iconPath = "ui/icon/icon_skill_buff73.dds"},
    {name = "Аура беспомощности", iconPath = "ui/icon/icon_skill_buff84.dds"}
}

local iconMap = {
    ["target"] = {},
    ["watchtarget"] = {}
}

local function ConvertMilliseconds(ms)
    if ms < 1000 then
        return string.format("%dms", ms)
    elseif ms < 60000 then
        local seconds = ms / 1000
        return string.format("%ds", seconds)
    elseif ms < 3600000 then
        local minutes = math.floor(ms / 60000)
        return string.format("%dm", minutes)
    else
        local hours = math.floor(ms / 3600000)
        return string.format("%dh", hours)
    end
end

-- Функция для удаления всех иконок конкретного юнита
local function RemoveAllEffectIcons(unitType)
    if iconMap[unitType] then
        for _, iconData in ipairs(iconMap[unitType]) do
            if iconData.iconButton then
                iconData.iconButton:RemoveAllAnchors()
                iconData.iconButton:EnableHidingIsRemove(true)
                iconData.iconButton:Show(false)
            end
            if iconData.iconText then
                iconData.iconText:RemoveAllAnchors()
                iconData.iconText:EnableHidingIsRemove(true)
                iconData.iconText:Show(false)
            end
        end
        iconMap[unitType] = {} -- Очистка списка иконок для юнита
    end
end

-- Конвертация миллисекунд в человекочитаемый формат
local function ConvertMilliseconds(ms)
    if ms < 1000 then
        return string.format("%dms", ms)
    elseif ms < 60000 then
        local seconds = ms / 1000
        return string.format("%ds", seconds)
    elseif ms < 3600000 then
        local minutes = math.floor(ms / 60000)
        return string.format("%dm", minutes)
    else
        local hours = math.floor(ms / 3600000)
        return string.format("%dh", hours)
    end
end

-- Функция для создания или обновления иконки эффекта
local function CreateOrUpdateEffectIcon(unitType, effect, offsetY)
    local iconButton = UIParent:CreateWidget("button", string.format("%s_%s_Icon", unitType, effect.name),
        "UIParent", "")
    iconButton:SetExtent(iconSize, iconSize)

    local iconDrawable = iconButton:CreateIconDrawable("background")
    iconDrawable:AddAnchor("TOPLEFT", iconButton, 1, 1)
    iconDrawable:AddAnchor("BOTTOMRIGHT", iconButton, -1, -1)
    iconDrawable:ClearAllTextures()
    iconDrawable:AddTexture(effect.iconPath)
    iconButton:Show(true)

    local iconText = UIParent:CreateWidget("label", string.format("%s_%s_Text", unitType, effect.name),
        "UIParent", "")
    iconText:SetHeight(20)
    iconText.style:SetOutline(true)
    iconText.style:SetFontSize(16)
    iconText.style:SetAlign(ALIGN_CENTER)
    iconText:AddAnchor("CENTER", iconButton, 0, 0)
    iconText:Show(true)

    -- Устанавливаем позицию для иконки
    local posX, posY = X2Unit:GetUnitScreenPosition(unitType)
    if posX and posY then
        local newX = posX + offsetX
        local newY = posY + offsetY
        iconButton:RemoveAllAnchors()
        iconButton:AddAnchor("TOPLEFT", "UIParent", newX, newY)
        iconText:RemoveAllAnchors()
        iconText:AddAnchor("CENTER", iconButton, 0, 0)
    end

    -- Добавляем иконку в список для юнита
    table.insert(iconMap[unitType], {
        iconButton = iconButton,
        iconText = iconText
    })
end

local function IsTrackedDebuff(buffName)
    for _, debuff in ipairs(trackedDebuffs) do
        if debuff.name == buffName then
            return true
        end
    end
    return false
end

local function GetTrackedDebuffIconPath(buffName)
    for _, debuff in ipairs(trackedDebuffs) do
        if debuff.name == buffName then
            return debuff.iconPath
        end
    end
    return nil
end

-- Обновление всех эффектов для конкретного юнита
local function UpdateEffectsForUnit(unitType)
    -- Удаляем старые иконки
    RemoveAllEffectIcons(unitType)

    local lastYOffset = 0

    local buffCount = X2Unit:UnitBuffCount(unitType)
    if buffCount and buffCount > 0 then
        for i = 1, buffCount do
            local buffTooltip = X2Unit:UnitBuffTooltip(unitType, i)
            local buffName = buffTooltip.name
            local buffIconPath = GetTrackedDebuffIconPath(buffName) or buffTooltip.path

            -- Проверяем, отслеживается ли бафф
            if GetTrackedDebuffIconPath(buffName) then
                CreateOrUpdateEffectIcon(unitType, {name = buffName, iconPath = buffIconPath}, lastYOffset)
                lastYOffset = lastYOffset + effectIconSpacing
            end
        end
    end

    -- Обрабатываем скрытые баффы
    local hiddenBuffCount = X2Unit:UnitHiddenBuffCount(unitType)
    if hiddenBuffCount and hiddenBuffCount > 0 then
        for i = 1, hiddenBuffCount do
            local hiddenBuffTooltip = X2Unit:UnitHiddenBuffTooltip(unitType, i)
            local hiddenBuffName = hiddenBuffTooltip.name
            local hiddenBuffIconPath = GetTrackedDebuffIconPath(hiddenBuffName) or hiddenBuffTooltip.path

            -- Проверяем, отслеживается ли скрытый бафф
            if GetTrackedDebuffIconPath(hiddenBuffName) then
                CreateOrUpdateEffectIcon(unitType, {name = hiddenBuffName, iconPath = hiddenBuffIconPath}, lastYOffset)
                lastYOffset = lastYOffset + effectIconSpacing
            end
        end
    end

    local buffCount = X2Unit:UnitDeBuffCount(unitType)
    if buffCount and buffCount > 0 then
        for i = 1, buffCount do
            local buffTooltip = X2Unit:UnitDeBuffTooltip(unitType, i)
            local buffName = buffTooltip.name
            local buffIconPath = GetTrackedDebuffIconPath(buffName) or buffTooltip.iconPath

            -- Проверяем, отслеживается ли бафф
            if GetTrackedDebuffIconPath(buffName) then
                CreateOrUpdateEffectIcon(unitType, {name = buffName, iconPath = buffIconPath}, lastYOffset)
                lastYOffset = lastYOffset + effectIconSpacing
            end
        end
    end

    -- Обрабатываем скрытые баффы
    local hiddenBuffCount = X2Unit:UnitHiddenDeBuffCount(unitType)
    if hiddenBuffCount and hiddenBuffCount > 0 then
        for i = 1, hiddenBuffCount do
            local hiddenBuffTooltip = X2Unit:UnitHiddenDeBuffTooltip(unitType, i)
            local hiddenBuffName = hiddenBuffTooltip.name
            local hiddenBuffIconPath = GetTrackedDebuffIconPath(hiddenBuffName) or hiddenBuffTooltip.iconPath

            -- Проверяем, отслеживается ли скрытый бафф
            if GetTrackedDebuffIconPath(hiddenBuffName) then
                CreateOrUpdateEffectIcon(unitType, {name = hiddenBuffName, iconPath = hiddenBuffIconPath}, lastYOffset)
                lastYOffset = lastYOffset + effectIconSpacing
            end
        end
    end
end

-- Удаление всех эффектов
local function UpdateAllEffects()
    for _, unitType in ipairs(unitTypes) do
        UpdateEffectsForUnit(unitType)
    end
end

-- Обработчик событий для изменения цели
local function onUnitChangedEvent(unitType)
    if unitType and table.contains(unitTypes, unitType) then
        UpdateEffectsForUnit(unitType)
    end
end

-- Инициализация аддона
local function initialize()
    UIParent:SetEventHandler(UIEVENT_TYPE.TARGET_CHANGED, onUnitChangedEvent)
    UIParent:SetEventHandler(UIEVENT_TYPE.WATCH_TARGET_CHANGED, onUnitChangedEvent)

    local updateHandler = UIParent:CreateWidget("button", "EffectUpdateHandler", "UIParent", "")
    updateHandler:AddAnchor("TOPLEFT", "UIParent", 0, 0)
    updateHandler:Show(true)
    local updateInterval = 10.0
    local elapsedTime = 0

    function updateHandler:OnUpdate(dt)
        elapsedTime = elapsedTime + dt
        if elapsedTime >= updateInterval then
            UpdateAllEffects()
            elapsedTime = 0
        end
    end

    updateHandler:SetHandler("OnUpdate", updateHandler.OnUpdate)
end

UIParent:SetEventHandler(UIEVENT_TYPE.ENTERED_WORLD, initialize)

-- Проверка наличия элемента в таблице
function table.contains(tbl, element)
    for _, value in ipairs(tbl) do
        if value == element then return true end
    end
    return false
end

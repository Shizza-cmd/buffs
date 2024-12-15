ADDON:ImportAPI(API_TYPE.CHAT.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)

ADDON:ImportObject(OBJECT_TYPE.BUTTON)
ADDON:ImportObject(OBJECT_TYPE.LABEL)
ADDON:ImportObject(OBJECT_TYPE.ICON_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.TEXT_STYLE)

-- Определение типов юнитов, за которыми будем следить
local unitTypes = { "target", "watchtarget" }

-- Захардкоженный бафф и путь к иконке
local trackedDebuffIconPath = "Game/ui/icon/icon_skill_basic14.dds"
local trackedDebuffName = "552822 DO NOT TRANSLATE"
-- Максимальная длительность дебаффа в миллисекундах
local trackedDebuffDuration = 6 * 60 * 1000

local iconMap = {
    ["target"] = nil,
    ["watchtarget"] = nil
}

-- Смещение иконки относительно позиции юнита
local offsetX, offsetY = -103, -42
-- Размер иконки
local iconSize = 32

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

local function UpdateIconPositions(unitType)
    local iconData = iconMap[unitType]
    if not iconData then
        return
    end

    local posX, posY = X2Unit:GetUnitScreenPosition(unitType)
    if posX and posY then
        local newX = posX + offsetX
        local newY = posY + offsetY
        iconData.iconButton:RemoveAllAnchors()
        iconData.iconButton:AddAnchor("TOPLEFT", "UIParent", newX, newY)

        iconData.iconText:RemoveAllAnchors()
        iconData.iconText:AddAnchor("CENTER", iconData.iconButton, 0, 0)
    end
end

local function CreateOrUpdateDebuffIcon(unitType, debuff)
    if debuff.name ~= trackedDebuffName then
        return
    end

    local existingIcon = iconMap[unitType]

    if existingIcon then
        local timeLeft = debuff.timeLeft
        local duration = debuff.duration
        local remainingCountdown = trackedDebuffDuration - (duration - timeLeft)
        local timeText = (remainingCountdown > 0) and ConvertMilliseconds(remainingCountdown) or "Expired"
        existingIcon.iconText:SetText(timeText)
    else
        local iconButton = UIParent:CreateWidget("button", string.format("%s_%s_Icon", unitType, trackedDebuffName),
            "UIParent", "")
        iconButton:SetExtent(iconSize, iconSize)

        local iconDrawable = iconButton:CreateIconDrawable("background")
        iconDrawable:AddAnchor("TOPLEFT", iconButton, 1, 1)
        iconDrawable:AddAnchor("BOTTOMRIGHT", iconButton, -1, -1)
        iconDrawable:ClearAllTextures()
        iconDrawable:AddTexture(trackedDebuffIconPath)
        iconButton:Show(true)

        local iconText = UIParent:CreateWidget("label", string.format("%s_%s_Text", unitType, trackedDebuffName),
            "UIParent", "")
        iconText:SetHeight(20)
        iconText:SetText("")
        iconText.style:SetOutline(true)
        iconText.style:SetFontSize(16)
        iconText.style:SetAlign(ALIGN_CENTER)
        iconText:AddAnchor("CENTER", iconButton, 0, 0)
        iconText:Show(true)

        iconMap[unitType] = {
            iconButton = iconButton,
            iconText = iconText
        }
    end
end

local function RemoveDebuffIcon(unitType)
    local iconData = iconMap[unitType]
    if iconData then
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
        iconMap[unitType] = nil
    end
end

local function UpdateDebuffsForUnit(unitType)
    local debuffCount = X2Unit:UnitHiddenBuffCount(unitType)
    local debuffFound = false

    if debuffCount and debuffCount > 0 then
        for i = 1, debuffCount do
            local debuffTooltip = X2Unit:UnitHiddenBuffTooltip(unitType, i)
            local debuffName = debuffTooltip.name
            local duration = debuffTooltip.duration
            local timeLeft = debuffTooltip.timeLeft
            if debuffName and debuffName == trackedDebuffName and (timeLeft and duration and timeLeft >= duration - trackedDebuffDuration) then
                debuffFound = true
                CreateOrUpdateDebuffIcon(unitType, debuffTooltip)
                break
            end
        end
    end

    if not debuffFound then
        RemoveDebuffIcon(unitType)
    end

    UpdateIconPositions(unitType)
end

local function UpdateAllDebuffs()
    for _, unitType in ipairs(unitTypes) do
        UpdateDebuffsForUnit(unitType)
    end
end

local function onUnitChangedEvent(unitType)
    if unitType and table.contains(unitTypes, unitType) then
        UpdateDebuffsForUnit(unitType)
    end
end

local function initialize()
    UIParent:SetEventHandler(UIEVENT_TYPE.TARGET_CHANGED, onUnitChangedEvent)
    UIParent:SetEventHandler(UIEVENT_TYPE.WATCH_TARGET_CHANGED, onUnitChangedEvent)

    local updateHandler = UIParent:CreateWidget("button", "DebuffUpdateHandler", "UIParent", "")
    updateHandler:AddAnchor("TOPLEFT", "UIParent", 0, 0)
    updateHandler:Show(true)
    local updateInterval = 10.0
    local elapsedTime = 0

    function updateHandler:OnUpdate(dt)
        elapsedTime = elapsedTime + dt
        if elapsedTime >= updateInterval then
            UpdateAllDebuffs()
            elapsedTime = 0
        end
    end

    updateHandler:SetHandler("OnUpdate", updateHandler.OnUpdate)
end

UIParent:SetEventHandler(UIEVENT_TYPE.ENTERED_WORLD, initialize)

function table.contains(tbl, element)
    for _, value in ipairs(tbl) do
        if value == element then return true end
    end
    return false
end
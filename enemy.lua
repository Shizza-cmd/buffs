-------------- Original Author: Strawberry --------------
--- Extra thanks to Tamaki, Nidoran, Ingram & 우와앙  ---
--------------- The War Room lives on -------------------
----------------- Discord: exec.noir --------------------
-------------------- ADDON imports ----------------------
ADDON:ImportObject(OBJECT_TYPE.TEXT_STYLE)
ADDON:ImportObject(OBJECT_TYPE.BUTTON)
ADDON:ImportObject(OBJECT_TYPE.DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.NINE_PART_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.COLOR_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.WINDOW)
ADDON:ImportObject(OBJECT_TYPE.LABEL)
ADDON:ImportObject(OBJECT_TYPE.ICON_DRAWABLE)
ADDON:ImportObject(OBJECT_TYPE.IMAGE_DRAWABLE)

ADDON:ImportAPI(API_TYPE.OPTION.id)
ADDON:ImportAPI(API_TYPE.CHAT.id)
ADDON:ImportAPI(API_TYPE.ACHIEVEMENT.id)
ADDON:ImportAPI(API_TYPE.UNIT.id)
ADDON:ImportAPI(API_TYPE.LOCALE.id)

-- Create a basic invisible window to attach icons to
local buffAnchor = CreateEmptyWindow("buffAnchor", "UIParent")
buffAnchor:Show(true)

local buffAllString = ""
local lastBuffString = ""
local debuffAllString = ""
local lastdeBuffString = ""

local drawableNmyIcons = {} -- Table to store drawn icons, must be global
local drawableNmyLabels = {} -- Table to store drawn counters, must be global

------------------------ Icon drawing function ------------------------
local function drawIcon(w, iconPath, id, xOffset, yOffset, duration)
    -- If the icon already exists, don't redraw it, instead update it
    if drawableNmyIcons[id] ~= nil then
        if not drawableNmyIcons[id]:IsVisible() then
            drawableNmyIcons[id]:SetVisible(true)
            drawableNmyLabels[id]:Show(true)
        end
        drawableNmyIcons[id]:AddAnchor("LEFT", w, xOffset, yOffset) 
        drawableNmyLabels[id]:AddAnchor("LEFT", w, xOffset, yOffset) 
        drawableNmyLabels[id]:SetText(duration)
        return
    end
    -- Create an icon using iconPath
    local drawableIcon = w:CreateIconDrawable("artwork")
    drawableIcon:SetExtent(30,30) -- Width, height
    drawableIcon:ClearAllTextures() -- Every other usage of AddTexture called this first 🤷
    drawableIcon:AddTexture(iconPath) -- path to dds texture to load
    drawableIcon:SetVisible(true)
    -- Add a timer label using duration
    local lblDuration = w:CreateChildWidget("label", "lblDuration", 0, true)
    lblDuration:Show(true)
    lblDuration:EnablePick(false)
    lblDuration.style:SetColor(1, 1, 1, 1.0)
    lblDuration.style:SetOutline(true)
    lblDuration.style:SetAlign(ALIGN_LEFT)
    lblDuration:SetText(duration)
    -- Save the drawn icon to the global object array
    drawableNmyLabels[id] = lblDuration
    drawableNmyIcons[id] = drawableIcon
end

------------------------ Function called perpetually ------------------------
function buffAnchor:OnUpdate(dt)
    -- Find coordinates of nameplate
    local nScrX_Tar, nScrY_Tar, nScrZ_Tar = X2Unit:GetUnitScreenPosition("target")
    if nScrX_Tar == nil or nScrY_Tar == nil or nScrZ_Tar == nil then
        buffAnchor:AddAnchor("TOPLEFT", "UIParent", 5000, 5000) 
    elseif nScrZ_Tar > 0 then
        local x = math.floor(0.5+nScrX_Tar)
        local y = math.floor(0.5+nScrY_Tar)
        buffAnchor:Show(true)
        buffAnchor:Enable(true)
        buffAnchor:AddAnchor("TOPLEFT", "UIParent", x-103, y-'-10')

        -- Handle buffs
        buffAllString = ""
        debuffAllString = ""
        local UBuffCount = X2Unit:UnitBuffCount("target")
        local buffCounter = 0
        local currentBuffs = {}
        for i = 1, UBuffCount do
            local buff = X2Unit:UnitBuffTooltip("target", i)
            if target_buffs[buff["name"]] ~= nil then
                currentBuffs[buff["name"]] = true
                local iconPath = target_buffs[buff["name"]]
                local duration = buff["timeLeft"] and tostring(math.floor(buff["timeLeft"]/1000)) or ""
                drawIcon(buffAnchor, iconPath, buff["name"], 30 * buffCounter, 0, duration)
                buffCounter = buffCounter + 1
            end
            buffAllString = buffAllString .. "-" .. buff["name"]         
        end

        -- Handle debuffs
        local UDebuffCount = X2Unit:UnitDeBuffCount("target")
        local debuffCounter = 0
        for i = 1, UDebuffCount do
            local debuff = X2Unit:UnitDeBuffTooltip("target", i)
            if target_debuffs[debuff["name"]] ~= nil then
                currentBuffs[debuff["name"]] = true
                local iconPath = target_debuffs[debuff["name"]]
                local duration = debuff["timeLeft"] and tostring(math.floor(debuff["timeLeft"]/1000)) or ""
                drawIcon(buffAnchor, iconPath, debuff["name"], 30 * debuffCounter, 35, duration)
                debuffCounter = debuffCounter + 1
            end
            debuffAllString = debuffAllString .. "-" .. debuff["name"]     
        end
        if target_buffDebugMessages and (buffAllString ~= lastbuffString) then
           lastbuffString = buffAllString
        end
        if target_debuffDebugMessages and (debuffAllString ~= lastdebuffString) then
            lastdebuffString = debuffAllString
        end
        -- Disable icons no longer current
        for id, icon in pairs(drawableNmyIcons) do
            if not currentBuffs[id] and icon:IsVisible() then
                drawableNmyLabels[id]:Show(false)
                icon:SetVisible(false)
            end
        end
    end
end
buffAnchor:SetHandler("OnUpdate", buffAnchor.OnUpdate)

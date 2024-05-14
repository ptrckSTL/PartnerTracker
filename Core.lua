PatchTracker = LibStub("AceAddon-3.0"):NewAddon("PatchTracker", "AceConsole-3.0", "AceEvent-3.0")
local HBD = LibStub("HereBeDragons-2.0")
local frame = CreateFrame("FRAME", "FindPatch");
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("GROUP_JOINED");
frame:RegisterEvent("GROUP_LEFT")
local patchToon = ""
local patchDead = false
local inGroup = false

function PatchTracker:OnEnable()
    self:Print("@ @ @")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PARTY_INVITE_REQUEST")
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("GROUP_LEFT")
    frame:SetScript("OnUpdate", update_position)
    self:OnGroupChanged()
end

function PatchTracker:OnGroupChanged()
    local party = GetHomePartyInfo()
    inGroup = party ~= nil
    if not inGroup then
        patchToon = ""
        TomTom:ReleaseCrazyArrow()
        return
    end
    for _, member in pairs(party) do
        if self:playerIsPatch(member) then
            patchToon = member
            patchDead = UnitIsDeadOrGhost(member)
            UpdateTomTomArrow()
            return
        end
    end
end

function PatchTracker:GROUP_JOINED()
    self:OnGroupChanged()
end

function PatchTracker:GROUP_LEFT()
    self:OnGroupChanged()
end

function PatchTracker:COMBAT_LOG_EVENT_UNFILTERED()
    local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
    if (subevent == "UNIT_DIED" and self:playerIsPatch(destName)) then
        PlaySoundFile("Interface\\Addons\\PartnerTracker\\dead.mp3", "SFX")
        self:Print("Patch died!")
        TomTom:SetCrazyArrowTitle("he dead :(")
    end

end

function PatchTracker:PARTY_INVITE_REQUEST(_, inviter)
    self:Print(inviter)
    if self:playerIsPatch(inviter) then
        AcceptGroup()
        StaticPopup_Hide("PARTY_INVITE")
    end

end

function PatchTracker:playerIsPatch(player)
    local patchFound = player == "Dangerface" or player == "Restoke" or player == "Casht"
    return patchFound
end

function UpdateTomTomArrow()
    if not TomTom:CrazyArrowIsHijacked() then
        TomTom:HijackCrazyArrow(UpdateArrow())
        TomTom:SetCrazyArrowColor(1, 0.6, 0.8)
    end
    UpdateArrow(self, elapsed);
end

function update_position()
    if not inGroup then
        return
    end
    UpdateArrow()
end

function UpdateArrow()
    if (patchToon == "" or patchDead) then
        TomTom:ReleaseCrazyArrow()
        patchDead = UnitHealth(patchToon) < 1
        return
    end

    local px, py, player_instance = HBD:GetPlayerWorldPosition()
    local tx, ty, target_instance = HBD:GetUnitWorldPosition(patchToon)
    if (px and py and tx and ty ~= nil) then

        -- distance --
        local dist = HBD:GetWorldDistance(player_instance, px, py, tx, ty)
        if (dist) then
            TomTom:SetCrazyArrowTitle("Patch", floor(dist) .. " yards");
        else
            TomTom:SetCrazyArrowTitle("???");
        end
        local facing = GetPlayerFacing()
        if facing == nil then
            TomTom:ReleaseCrazyArrow();
            return
        end

        -- angle --
        local angle = HBD:GetWorldVector(player_instance, px, py, tx, ty)
        local arrow_angle = facing - angle
        arrow_angle = -arrow_angle
        TomTom:SetCrazyArrowDirection(arrow_angle);

    end
end

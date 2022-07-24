
local g = GLOBAL
local UpvalueHacker = g.require("tools/upvaluehacker")
PrefabFiles = {"beefalo_whip"}



AddRecipe2("beefalo_whip",
	{	Ingredient("rope", 2),
		Ingredient("beefalowool", 3),
		Ingredient("flint", 1) },
		g.TECH.NONE,
	{	atlas = "images/beefalo_whip.xml",
		image = "beefalo_whip.tex",
    }
)


g.STRINGS.NAMES.BEEFALO_WHIP = "皮鞭"
g.STRINGS.RECIPE_DESC.BEEFALO_WHIP = "用它来鞭笞你的牛牛"
g.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BEEFALO_WHIP = "更好的驯服牛牛"
g.STRINGS.CHARACTERS.WENDY.DESCRIBE.BEEFALO_WHIP = "被打一定很疼"

AddPrefabPostInit("beefalo", function(inst)
    if g.TheWorld.ismastersim then
        inst.count = 0
        function OnAttacked(inst, data)
            if inst._ridersleeptask ~= nil then
                inst._ridersleeptask:Cancel()
                inst._ridersleeptask = nil
            end
            inst._ridersleep = nil
            if inst.components.rideable:IsBeingRidden() then
                if not inst.components.domesticatable:IsDomesticated() or not inst.tendency == TENDENCY.ORNERY then
                    inst.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_ATTACKED_DOMESTICATION)
                    inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_ATTACKED_OBEDIENCE)
                end
                inst.components.domesticatable:DeltaTendency(TENDENCY.ORNERY, TUNING.BEEFALO_ORNERY_ATTACKED)
            else
                if data.attacker ~= nil and data.attacker:HasTag("player") then
                    local doer = data.attacker.components.inventory:GetEquippedItem(g.EQUIPSLOTS.HANDS)
                    if doer:HasTag("beefalo_whip") then
                        inst.count = inst.count + 1
                        if inst.count == 10 then
                            inst.components.domesticatable:DeltaDomestication(-0.01)    --减1%驯化度
                            inst.count = 0
                        end
                        -- inst.components.domesticatable:DeltaObedience(0.1)
                        inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_FEED_OBEDIENCE)  --每次被打加10%顺从度
                        inst.components.combat:SetTarget(nil)   --不对玩家有仇恨
                    else
                        --不是皮鞭则执行原代码
                        inst.count = 0
                        inst.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_DOMESTICATION)
                        inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_OBEDIENCE)
                        inst.components.combat:SetTarget(data.attacker)
                    end
                end

                inst.components.combat:ShareTarget(data.attacker, 30, CanShareTarget, 5)    --但是周围的牛还是有仇恨
            end
            if inst.components.hitchable and not inst.components.hitchable.canbehitched then
                inst.components.hitchable:Unhitch()
            end
        end
        UpvalueHacker.SetUpvalue(g.Prefabs.beefalo.fn, OnAttacked, "OnAttacked")
    end
end)

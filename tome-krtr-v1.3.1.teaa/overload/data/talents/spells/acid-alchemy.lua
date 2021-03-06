-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2015 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org
local Object = require "engine.Object"

newTalent{
	name = "Acid Infusion",
	kr_name = "산성 주입",
	type = {"spell/acid-alchemy", 1},
	mode = "sustained",
	require = spells_req1,
	sustain_mana = 30,
	points = 5,
	cooldown = 30,
	tactical = { BUFF = 2 },
	getIncrease = function(self, t) return self:combatTalentScale(t, 0.05, 0.25) * 100 end,
	sustain_slots = 'alchemy_infusion',
	activate = function(self, t)
		game:playSoundNear(self, "talents/arcane")
		local ret = {}
		self:talentTemporaryValue(ret, "inc_damage", {[DamageType.ACID] = t.getIncrease(self, t)})
		return ret
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local daminc = t.getIncrease(self, t)
		return ([[연금술 폭탄을 던질 때, 적을 실명시킬 수 있는 산성을 주입해 던집니다.
		또한, 모든 산성 피해량이 %d%% 증가합니다.]]):
		format(daminc)
	end,
}

newTalent{
	name = "Caustic Golem",
	kr_name = "부식성 골렘",
	type = {"spell/acid-alchemy", 2},
	require = spells_req2,
	mode = "passive",
	points = 5,
	getDuration = function(self, t) return math.floor(self:combatScale(self:combatSpellpower(0.03) * self:getTalentLevel(t), 2, 0, 10, 8)) end,
	getChance = function(self, t) return self:combatLimit(self:combatSpellpower(0.03) * self:getTalentLevel(t), 100, 20, 0, 55, 8) end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 5, 120) end,
	applyEffect = function(self, t, golem)
		local duration = t.getDuration(self, t)
		local chance = t.getChance(self, t)
		local dam = t.getDamage(self, t)
		golem:setEffect(golem.EFF_CAUSTIC_GOLEM, duration, {src = golem, chance=chance, dam=dam})
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		local chance = t.getChance(self, t)
		local dam = self.alchemy_golem and self.alchemy_golem:damDesc(engine.DamageType.ACID, t.getDamage(self, t)) or 0
		return ([[연금술 폭탄에 산성을 주입해서 던질 때, 골렘이 폭탄에 맞으면 %d 턴 동안 산성막으로 덮히게 됩니다.
		산성막에 덮힌 골렘이 근접 공격으로 공격당할 경우. %d%% 확률로 4 칸 반경의 원뿔형으로 산성이 뿜어져나와 %0.1f 산성 피해로 반격하게 됩니다. (한 턴에 최대 1 번까지만 효과가 발현됩니다)
		기술의 효과는 골렘의 피해량 변화 수치, 기술 레벨, 시전자의 주문력의 영향을 받아 증가합니다.]]):
		format(duration, chance, dam)
	end,
}

newTalent{
	name = "Caustic Mire",
	kr_name = "부식성 늪",
	type = {"spell/acid-alchemy",3},
	require = spells_req3,
	points = 5,
	mana = 50,
	cooldown = 30,
	tactical = { ATTACKAREA = { ACID = 3 }, DISABLE = 2 },
	range = 7,
	radius = 3,
	direct_hit = true,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t)}
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 7, 60) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 6, 10)) end,
	getSlow = function(self, t) return self:combatTalentLimit(t, 100, 10, 40) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, _, _, x, y = self:canProject(tg, x, y)
		-- Add a lasting map effect
		game.level.map:addEffect(self,
			x, y, t.getDuration(self, t),
			DamageType.CAUSTIC_MIRE, {dam=self:spellCrit(t.getDamage(self, t)), dur=2, slow=t.getSlow(self, t)},
			self:getTalentRadius(t),
			5, nil,
			{zdepth=6, type="mucus"},
			nil, 0, 0
		)

		game:playSoundNear(self, "talents/slime")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local slow = t.getSlow(self, t)
		local duration = t.getDuration(self, t)
		local radius = self:getTalentRadius(t)
		return ([[지정한 곳으로부터 주변 %d 칸 반경에 산성 늪지대가 만들어집니다.
		늪지대에 발을 내딛은 모든 적은 %d 턴 동안 매 턴마다 %0.1f 피해를 받으며, %d%% 감속됩니다.
		피해량은 주문력의 영향을 받아 증가합니다.]]):
		format(radius, damDesc(self, DamageType.ACID, damage), duration, slow)
	end,
}

newTalent{
	name = "Dissolving Acid",
	kr_name = "용해되는 산",
	type = {"spell/acid-alchemy",4},
	require = spells_req4,
	points = 5,
	mana = 45,
	cooldown = 12,
	refectable = true,
	range = 10,
	direct_hit = true,
	tactical = { ATTACK = { ACID = 2 }, DISABLE = 2 },
	requires_target = true,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 25, 320) end,
	getRemoveCount = function(self, t) return math.floor(self:combatTalentScale(t, 1, 3, "log")) end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local nb = t.getRemoveCount(self,t)
		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			DamageType:get(DamageType.ACID).projector(self, px, py, DamageType.ACID, (self:spellCrit(t.getDamage(self, t))))

			local effs = {}

			-- Go through all mental and physical effects
			for eff_id, p in pairs(target.tmp) do
				local e = target.tempeffect_def[eff_id]
				if (e.type == "mental" or e.type == "physical") and e.status == "beneficial" then
					effs[#effs+1] = {"effect", eff_id}
				end
			end

			-- Go through all mental sustains
			for tid, act in pairs(target.sustain_talents) do
				local t = self:getTalentFromId(tid)
				if act and t.is_mind then
					effs[#effs+1] = {"talent", tid}
				end
			end

			for i = 1, nb do
				if #effs == 0 then break end
				local eff = rng.tableRemove(effs)

				if self:checkHit(self:combatSpellpower(), target:combatSpellResist(), 0, 95, 5) then
					target:crossTierEffect(target.EFF_SPELLSHOCKED, self:combatSpellpower())
					if eff[1] == "effect" then
						target:removeEffect(eff[2])
					else
						target:forceUseTalent(eff[2], {ignore_energy=true})
					end
				end
			end

		end, nil, {type="acid"})
		game:playSoundNear(self, "talents/acid")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[대상 주변에 산을 분출시켜, %0.1f 산성 피해를 입힙니다.
		이 산성 공격은 극도로 집중을 방해하여, 최대 %d 개의 물리적 / 마법적 / 정신적 지속 효과를 제거합니다. (대상의 주문 내성에 따라 변화)
		피해량과 제거 가능한 효과의 개수는 주문력의 영향을 받아 증가합니다.]]):format(damDesc(self, DamageType.ACID, damage), t.getRemoveCount(self, t))
	end,
}

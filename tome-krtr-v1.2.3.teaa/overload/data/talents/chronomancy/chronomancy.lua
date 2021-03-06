﻿-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2014 Nicolas Casalini
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


newTalent{
	name = "Spacetime Tuning",
	kr_name = "시공간 조율",
	type = {"chronomancy/other", 1},
	points = 1,
	tactical = { PARADOX = 2 },
	no_npc_use = true,
	no_unlearn_last = true,
	on_learn = function(self, t)
		if not self.preferred_paradox then self.preferred_paradox = 0 end
	end,
	on_unlearn = function(self, t)
		if self.preferred_paradox then self.preferred_paradox = nil end
	end,
	getDuration = function(self, t) 
		local power = math.floor(self:combatSpellpower()/10)
		return math.max(20 - power, 10)
	end,
	action = function(self, t)
		function getQuantity(title, prompt, default, min, max)
			local result
			local co = coroutine.running()

			local dialog = engine.dialogs.GetQuantity.new(
				title,
				prompt,
				default,
				max,
				function(qty)
					result = qty
					coroutine.resume(co)
				end,
				min)
			dialog.unload = function(dialog)
				if not dialog.qty then coroutine.resume(co) end
			end

			game:registerDialog(dialog)
			coroutine.yield()
			return result
		end

		local paradox = getQuantity(
			"시공간 조율",
			"괴리 원천력을 몇으로 유지하시겠습니까?",
			math.floor(self.paradox))
		if not paradox then return end
		if paradox > 1000 then paradox = 1000 end
		self.preferred_paradox = paradox
		return true
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		local preference = self.preferred_paradox
		local multiplier = getParadoxModifier(self, pm)*100
		local _, will_modifier = self:getModifiedParadox()
		local after_will = self:getModifiedParadox()
		local _, failure = self:paradoxFailChance()
		local _, anomaly = self:paradoxAnomalyChance()
		local _, backfire = self:paradoxBackfireChance()
		return ([[선호하는 괴리 수치를 설정합니다. 휴식하는 동안, 괴리 원천력이 %d 턴에 걸쳐 선호하는 괴리 수치로 변경됩니다.
		괴리 수치를 조정하는데 걸리는 시간은 주문력의 영향을 받아 감소하며, 최소 10 턴까지 감소시킬 수 있습니다.
		
		선호하는 괴리 수치           : %d
		괴리 효과 배율   : %d%%
		의지를 통한 괴리 감소량  : %d
		의지 적용 후 괴리 수치     : %d
		현재 실패 확률              : %d%%
		현재 이상 현상 발생 확률    : %d%%
		현재 역효과 확률            : %d%%]]):format(duration, preference, multiplier, will_modifier, after_will, failure, anomaly, backfire) 
	end,
}

newTalent{
	name = "Precognition",
	kr_name = "예지",
	type = {"chronomancy/chronomancy",1},
	require = temporal_req1,
	points = 5,
	paradox = 5,
	cooldown = 10,
	no_npc_use = true,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 6, 14)) end,
	action = function(self, t)
		if checkTimeline(self) == true then
			return
		end
		game:playSoundNear(self, "talents/spell_generic")
		self:setEffect(self.EFF_PRECOGNITION, t.getDuration(self, t), {})
		return true
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		return ([[미래를 엿봐, %d 턴 동안 미래에 일어날 일을 직접 체험할 수 있게 됩니다. 예지 효과가 끝나면 처음 마법을 시전했던 순간으로 돌아가며, 예지 도중에 사망했을 경우 마법의 효과가 사라집니다.
		이 마법은 시간의 흐름을 분절시키기 때문에, 이 마법을 사용하는 도중에는 시간의 흐름을 나누는 다른 마법을 사용할 수 없습니다.
		또한 시간의 흐름을 분절시키는 것은 어려운 작업이기 때문에, 주문을 시전하는 1 턴 동안에는 보호받을 수 없습니다.]]):format(duration)
	end,
}

newTalent{
	name = "Foresight",
	kr_name = "예견",
	type = {"chronomancy/chronomancy",2},
	mode = "passive",
	require = temporal_req2,
	points = 5,
	getRadius = function(self, t) return math.floor(self:combatTalentScale(t, 5, 13)) end,
	do_precog_foresight = function(self, t)
		self:magicMap(t.getRadius(self, t))
		self:setEffect(self.EFF_SENSE, 1, {
			range = t.getRadius(self, t),
			actor = 1,
			object = 1,
			trap = 1,
		})
	end,
	info = function(self, t)
		local radius = t.getRadius(self, t)
		return ([[예지의 지속시간이 끝나면 주변 %d 칸 반경의 지형, 적, 물체, 함정 등의 위치를 파악할 수 있게 됩니다.]]):
		format(radius)
	end,
}

newTalent{
	name = "Moment of Prescience",
	kr_name = "통찰의 순간",
	type = {"chronomancy/chronomancy", 3},
	require = temporal_req3,
	points = 5,
	paradox = 10,
	cooldown = 18,
	getDuration = function(self, t) return math.floor(self:combatTalentLimit(t, 18, 3, 10.5)) end, -- Limit < 18
	getPower = function(self, t) return self:combatTalentScale(t, 4, 15) end, -- Might need a buff
	tactical = { BUFF = 4 },
	no_energy = true,
	no_npc_use = true,
	action = function(self, t)
		local power = t.getPower(self, t)
		-- check for Spin Fate
		local eff = self:hasEffect(self.EFF_SPIN_FATE)
		if eff then
			local bonus = math.max(0, (eff.cur_save_bonus or eff.save_bonus) / 2)
			power = power + bonus
		end

		self:setEffect(self.EFF_PRESCIENCE, t.getDuration(self, t), {power=power})
		return true
	end,
	info = function(self, t)
		local power = t.getPower(self, t)
		local duration = t.getDuration(self, t)
		return ([[현재 이 순간에 모든 신경을 집중해, %d 턴 동안 은신 감지력, 투명체 감지력, 회피도, 정확도가 %d 상승합니다.
		통찰의 순간 동안 '운명 왜곡' 효과가 발생하면, 내성 상승량의 50%% 에 해당하는 수치만큼 위의 네 가지 수치가 추가로 상승합니다.
		이 마법은 시전시간 없이 즉시 사용할 수 있습니다.]]):
		format(duration, power) --@ 변수 순서 조정
	end,
}

newTalent{
	name = "Spin Fate",
	kr_name = "운명 왜곡",
	type = {"chronomancy/chronomancy", 4},
	require = temporal_req4,
	mode = "passive",
	points = 5,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 2, 6, "log")) end,
	getSaveBonus = function(self, t) return self:combatTalentScale(t, 1, 5, 0.75) end,
	do_spin_fate = function(self, t, type)
		local save_bonus = t.getSaveBonus(self, t)
	
		if type ~= "defense" then
			if not self:hasEffect(self.EFF_SPIN_FATE) then
				game:playSoundNear(self, "talents/spell_generic")
			end
			self:setEffect(self.EFF_SPIN_FATE, t.getDuration(self, t), {max_bonus = t.getSaveBonus(self, t) * 5, save_bonus = t.getSaveBonus(self, t)})
		end
		
		return true
	end,
	info = function(self, t)
		local save = t.getSaveBonus(self, t)
		local duration = t.getDuration(self, t)
		return ([[미래의 일이 펼쳐질 때, 약간씩 그 미래를 수정할 수 있게 됩니다. 
		적들의 각종 상태이상 공격으로 인해 자신의 내성을 사용할 때마다, 모든 내성이 %d 증가합니다. (최대 %d 까지 증가)
		내성 증가는 %d 턴 동안 지속되지만, 내성 증가 효과가 발생할 때마다 지속시간이 초기화됩니다.]]):
		format(save, save * 5, duration)
	end,
}

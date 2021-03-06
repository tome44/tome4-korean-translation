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

require "engine.krtrUtils"
local Map = require "engine.Map"

newTalent{
	name = "Shadow Leash",
	kr_name = "그림자 올가미",
	type = {"cunning/ambush", 1},
	require = cuns_req_high1,
	points = 5,
	cooldown = 20,
	stamina = 15,
	mana = 15,
	range = 1,
	tactical = { DISABLE = {disarm = 2} },
	requires_target = true,
	is_melee = true,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 2, 6)) end,
	speed = "weapon",
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end

		if target:canBe("disarm") then
			target:setEffect(target.EFF_DISARMED, t.getDuration(self, t), {apply_power=self:combatAttack()})
		else
			game.logSeen(target, "%s 그림자를 저항했습니다!", (target.kr_name or target.name):capitalize():addJosa("가"))
		end

		return true
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		return ([[무기를 그림자 올가미로 즉시 변화시켜, 대상의 무장을 %d 턴 동안 해제시킵니다.
		명중률은 정확도 능력치의 영향을 받아 증가합니다.]]):
		format(duration)
	end,
}

newTalent{
	name = "Shadow Ambush",
	kr_name = "그림자 습격",
	type = {"cunning/ambush", 2},
	require = cuns_req_high2,
	points = 5,
	cooldown = 20,
	stamina = 15,
	mana = 15,
	range = 7,
	tactical = { DISABLE = {silence = 2}, CLOSEIN = 2 },
	requires_target = true,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 2, 6)) end,
	speed = "combat",
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		target = game.level.map(x, y, Map.ACTOR)
		if not target then return nil end

		local sx, sy = util.findFreeGrid(self.x, self.y, 5, true, {[engine.Map.ACTOR]=true})
		if not sx then return end

		target:move(sx, sy, true)

		if core.fov.distance(self.x, self.y, sx, sy) <= 1 then
			if target:canBe("stun") then
				target:setEffect(target.EFF_DAZED, 2, {apply_power=self:combatAttack()})
			end
			if target:canBe("silence") then
				target:setEffect(target.EFF_SILENCED, t.getDuration(self, t), {apply_power=self:combatAttack()})
			else
				game.logSeen(target, "%s 그림자를 저항했습니다!", (target.kr_name or target.name):capitalize():addJosa("가"))
			end
		end

		return true
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		return ([[대상에게 그림자 덩굴을 뻗어, 시전자가 있는 곳으로 대상을 끌어당기고 %d 턴 동안 침묵 및 혼절 효과를 줍니다.
		명중률은 정확도 능력치의 영향을 받아 증가합니다.]]):
		format(duration)
	end,
}

newTalent{
	name = "Ambuscade",
	kr_name = "매복",
	type = {"cunning/ambush", 3},
	points = 5,
	cooldown = 20,
	stamina = 35,
	mana = 35,
	require = cuns_req_high3,
	requires_target = true,
	tactical = { ATTACK = {DARKNESS = 3} },
	getStealthPower = function(self, t) return self:combatScale(self:getCun(15, true) * self:getTalentLevel(t), 25, 0, 100, 75) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	getHealth = function(self, t) return self:combatLimit(self:combatTalentSpellDamage(t, 20, 500), 1, 0.2, 0, 0.584, 384) end, -- Limit to < 100% health of summoner
	getDam = function(self, t) return self:combatLimit(self:combatTalentSpellDamage(t, 10, 500), 1.6, 0.4, 0, 0.761 , 361) end, -- Limit to <160% Nerf?
	speed = "spell",
	action = function(self, t)
		-- Find space
		local x, y = util.findFreeGrid(self.x, self.y, 1, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "그림자를 일으킬 공간이 없습니다!")
			return
		end

		local m = self:cloneFull{
			shader = "shadow_simulacrum",
			no_drops = true, keep_inven_on_death = false,
			faction = self.faction,
			summoner = self, summoner_gain_exp=true,
			summon_time = t.getDuration(self, t),
			ai_target = {actor=nil},
			ai = "summoned", ai_real = "tactical",
			kr_name = (self.kr_name or self.name).."의 그림자",
			name = "Shadow of "..self.name,
			desc = [[자신을 꼭 닮은, 어두운 그림자입니다.]],
		}
		m:removeAllMOs()
		m.make_escort = nil
		m.on_added_to_level = nil

		m.energy.value = 0
		m.player = nil
		m.max_life = m.max_life * t.getHealth(self, t)
		m.life = util.bound(m.life, 0, m.max_life)
		m.forceLevelup = function() end
		m.die = nil
		m.on_die = function(self) self:removeEffect(self.EFF_ARCANE_EYE,true) end
		m.on_acquire_target = nil
		m.seen_by = nil
		m.puuid = nil
		m.on_takehit = nil
		m.can_talk = nil
		m.clone_on_hit = nil
		m.exp_worth = 0
		m.no_inventory_access = true
		m.no_levelup_access = true
		m.cant_teleport = true
		m:unlearnTalent(m.T_AMBUSCADE,m:getTalentLevelRaw(m.T_AMBUSCADE))
		m:unlearnTalent(m.T_PROJECTION,m:getTalentLevelRaw(m.T_PROJECTION)) -- no recurssive projections
		m:unlearnTalent(m.T_STEALTH,m:getTalentLevelRaw(m.T_STEALTH))
		m:unlearnTalent(m.T_HIDE_IN_PLAIN_SIGHT,m:getTalentLevelRaw(m.T_HIDE_IN_PLAIN_SIGHT))
		m.stealth = t.getStealthPower(self, t)

		self:removeEffect(self.EFF_SHADOW_VEIL) -- Remove shadow veil from creator
		m.remove_from_party_on_death = true
		m.resists[DamageType.LIGHT] = -100
		m.resists[DamageType.DARKNESS] = 130
		m.resists.all = -30
		m.inc_damage.all = ((100 + (m.inc_damage.all or 0)) * t.getDam(self, t)) - 100
		m.force_melee_damage_type = DamageType.DARKNESS

		m.on_act = function(self)
			if self.summoner.dead or not self:hasLOS(self.summoner.x, self.summoner.y) then
				if not self:hasEffect(self.EFF_AMBUSCADE_OFS) then
					self:setEffect(self.EFF_AMBUSCADE_OFS, 2, {})
				end
			else
				if self:hasEffect(self.EFF_AMBUSCADE_OFS) then
					self:removeEffect(self.EFF_AMBUSCADE_OFS)
				end
			end
		end,

		game.zone:addEntity(game.level, m, "actor", x, y)
		game.level.map:particleEmitter(x, y, 1, "shadow")

		if game.party:hasMember(self) then
			game.party:addMember(m, {
				control="full",
				type="shadow",
				title="Shadow of "..self.name, kr_title=(self.kr_name or self.name).."의 그림자",
				temporary_level=1,
				orders = {target=true},
				on_control = function(self)
					self.summoner.ambuscade_ai = self.summoner.ai
					self.summoner.ai = "none"
				end,
				on_uncontrol = function(self)
					self.summoner.ai = self.summoner.ambuscade_ai
					game:onTickEnd(function() game.party:removeMember(self) self:removeEffect(self.EFF_ARCANE_EYE, true) self:disappear() end)
				end,
			})
		end
		game:onTickEnd(function() game.party:setPlayer(m) end)

		game:playSoundNear(self, "talents/spell_generic2")
		return true
	end,
	info = function(self, t)
		return ([[%d 턴 동안 자신의 그림자를 조작할 수 있게 됩니다.
		그림자는 본체와 같은 기술과 능력치를 가지고 있지만, 그림자의 생명력은 본체의 %d%% / 그림자가 줄 수 있는 피해량은 본체의 %d%% 만큼으로 제한됩니다. 또한 그림자의 전체 저항력은 본체보다 30%% 낮으며, 빛 저항력은 언제나 -100%% / 어둠 저항력은 언제나 100%% 입니다.
		그림자는 영구적으로 은신 상태이며 (은신 수치 +%d), 모든 근접 공격은 어둠 속성을 가집니다.
		그림자의 조작을 종료하거나 그림자가 오랫동안 시야 바깥에 있으면, 그림자는 사라집니다.]]):
		format(t.getDuration(self, t), t.getHealth(self, t) * 100, t.getDam(self, t) * 100, t.getStealthPower(self, t))
	end,
}

newTalent{
	name = "Shadow Veil",
	kr_name = "그림자의 장막",
	type = {"cunning/ambush", 4},
	points = 5,
	cooldown = 18,
	stamina = 30,
	mana = 60,
	require = cuns_req_high4,
	requires_target = true,
	range = 5,
	tactical = { ATTACK = {DARKNESS = 2}, DEFEND = 1 },
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.9, 2.0) end, -- Nerf?
	getDuration = function(self, t) return math.floor(self:combatTalentLimit(t, 18, 4, 8)) end, -- Limit to <18
	getDamageRes = function(self, t) return self:combatTalentScale(t, 15, 35) end,
	getBlinkRange = function(self, t) return math.floor(self:combatTalentScale(t, 5, 7)) end,
	speed = "spell",
	action = function(self, t)
		self:setEffect(self.EFF_SHADOW_VEIL, t.getDuration(self, t), {res=t.getDamageRes(self, t), dam=t.getDamage(self, t), range=t.getBlinkRange(self, t)})
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local duration = t.getDuration(self, t)
		local res = t.getDamageRes(self, t)
		return ([[%d 턴 동안 그림자의 장막 속으로 들어가, 그림자에게 자신의 통제권을 넘겨줍니다.
		그림자 속에서는 상태효과에 완전한 면역을 가지며, 적에게 받는 피해량이 %d%% 감소합니다. 그리고 매 턴마다 %d 칸 이내의 적에게로 순간이동하여, %d%% 무기 피해를 어둠 속성으로 줍니다.
		기술의 효과는 시전자가 죽지 않는 한 멈추지 않으며, 효과가 지속되는 동안에는 캐릭터를 조작할 수 없습니다.]]):
		format(duration, res, t.getBlinkRange(self, t), 100 * damage)
	end,
}


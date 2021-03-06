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
	name = "Shadow Tunnel",
	kr_name = "그림자 통로",
	type = {"spell/shades",1},
	require = spells_req_high1,
	points = 5,
	random_ego = "attack",
	mana = 25,
	cooldown = 20,
	range = 10,
	tactical = { DEFEND = 2 },
	requires_target = true,
	getChance = function(self, t) return 20 + self:combatTalentSpellDamage(t, 15, 60) end,
	action = function(self, t)
		local list = {}
		if game.party and game.party:hasMember(self) then
			for act, def in pairs(game.party.members) do
				if act.summoner and act.summoner == self and act.necrotic_minion then list[#list+1] = act end
			end
		else
			for uid, act in pairs(game.level.entities) do
				if act.summoner and act.summoner == self and act.necrotic_minion then list[#list+1] = act end
			end
		end

		local empower = necroEssenceDead(self)
		for i, m in ipairs(list) do
			local x, y = util.findFreeGrid(self.x, self.y, 5, true, {[Map.ACTOR]=true})
			if x and y then
				m:move(x, y, true)
				game.level.map:particleEmitter(x, y, 1, "summon")
			end
			m:setEffect(m.EFF_EVASION, 5, {chance=t.getChance(self, t)})
			if empower then
				m:heal(m.max_life * 0.3)
				if core.shader.active(4) then
					m:addParticles(Particles.new("shader_shield_temp", 1, {toback=true , size_factor=1.5, y=-0.3, img="healdark", life=25}, {type="healing", time_factor=6000, beamsCount=15, noup=2.0, beamColor1={0xcb/255, 0xcb/255, 0xcb/255, 1}, beamColor2={0x35/255, 0x35/255, 0x35/255, 1}}))
					m:addParticles(Particles.new("shader_shield_temp", 1, {toback=false, size_factor=1.5, y=-0.3, img="healdark", life=25}, {type="healing", time_factor=6000, beamsCount=15, noup=1.0, beamColor1={0xcb/255, 0xcb/255, 0xcb/255, 1}, beamColor2={0x35/255, 0x35/255, 0x35/255, 1}}))
				end
			end
		end
		if empower then empower() end

		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	info = function(self, t)
		local chance = t.getChance(self, t)
		return ([[언데드 추종자들에게 어둠의 장막을 둘러, 시전자 곁으로 추종자들을 불러들입니다. 또한 언데드 추종자들이 5 턴 동안 %d%% 확률로 근접 공격을 회피할 수 있게 됩니다.
		회피율은 주문력의 영향을 받아 증가합니다.]]):
		format(chance)
	end,
}

newTalent{
	name = "Curse of the Meek",
	kr_name = "연약함의 저주",
	type = {"spell/shades",2},
	require = spells_req_high2,
	points = 5,
	mana = 50,
	cooldown = 30,
	range = 10,
	tactical = { DEFEND = 3 },
	action = function(self, t)
		local nb = math.ceil(self:getTalentLevel(t))
		for i = 1, nb do
			local x, y = util.findFreeGrid(self.x, self.y, 5, true, {[Map.ACTOR]=true})
			if x and y then
				local NPC = require "mod.class.NPC"
				local m = NPC.new{
					type = "humanoid", display = "p",
					color=colors.WHITE,

					combat = { dam=resolvers.rngavg(1,2), atk=2, apr=0, dammod={str=0.4} },

					body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
					lite = 3,

					life_rating = 10,
					rank = 2,
					size_category = 3,

					autolevel = "warrior",
					stats = { str=12, dex=8, mag=6, con=10 },
					ai = "summoned", ai_real = "dumb_talented_simple", ai_state = { talent_in=2, },
					level_range = {1, 3},

					max_life = resolvers.rngavg(30,40),
					combat_armor = 2, combat_def = 0,

					summoner = self,
					summoner_gain_exp=false,
					summon_time = 8,
				}

				m.level = 1
				local race = 5 -- rng.range(1, 5)
				if race == 1 then
					m.name = "human farmer"
					m.kr_name = "인간 농부"
					m.subtype = "human"
					m.image = "npc/humanoid_human_human_farmer.png"
					m.desc = [[평범한 인간 농부로, 뭐가 어떻게 된 것인지 모르겠다는 표정을 하고 있습니다.]]
				elseif race == 2 then
					m.name = "halfling gardener"
					m.kr_name = "하플링 정원사"
					m.subtype = "halfling"
					m.desc = [[무뚝뚝한 하플링 정원사로, 지금 여기서 무슨 일이 일어나는지 혼란스러운 것 같습니다.]]
					m.image = "npc/humanoid_halfling_halfling_gardener.png"
				elseif race == 3 then
					m.name = "shalore scribe"
					m.kr_name = "샬로레 필경사"
					m.subtype = "shalore"
					m.desc = [[비쩍 마른 엘프 필경사로,주변 환경에 당황한 것 같습니다.]]
					m.image = "npc/humanoid_shalore_shalore_rune_master.png"
				elseif race == 4 then
					m.name = "dwarven lumberjack"
					m.kr_name = "드워프 나무꾼"
					m.subtype = "dwarf"
					m.desc = [[건장한 드워프 나무꾼으로, 갑작스러운 환경 변화에 살짝 화가 난 것 같습니다.]]
					m.image = "npc/humanoid_dwarf_lumberjack.png"
				elseif race == 5 then
					m.name = "cute bunny"
					m.kr_name = "귀여운 토끼"
					m.type = "vermin" m.subtype = "rodent"
					m.desc = [[귀여운 토끼입니다!]]
					m.image = "npc/vermin_rodent_cute_little_bunny.png"
				end
				m.faction = self.faction
				m.no_necrotic_soul = true

				m:resolve() m:resolve(nil, true)
				m:forceLevelup(self.level)
				game.zone:addEntity(game.level, m, "actor", x, y)
				game.level.map:particleEmitter(x, y, 1, "summon")
				m:setEffect(m.EFF_CURSE_HATE, 100, {src=self})
				m.on_die = function(self, src)
					local p = self.summoner:isTalentActive(self.summoner.T_NECROTIC_AURA)
					if p and src and src.reactionToward and src:reactionToward(self) < 0 and rng.percent(70) then
						self.summoner:incSoul(1)
						self.summoner.changed = true
					end
				end
			end
		end
		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	info = function(self, t)
		return ([[그림자를 이용하여, 무해한 생명체를 %d 마리 소환하고 이 생명체들에게 '증오의 저주' 를 겁니다. 
		'증오의 저주' 효과로 인해, 모든 적들이 이 생명체를 최우선적으로 죽이고 싶어하게 됩니다.
		적들에 의해 소환된 생명체가 사망할 경우, 70%% 확률로 영혼을 획득합니다.]]):
		format(math.ceil(self:getTalentLevel(t)))
	end,
}

newTalent{
	name = "Forgery of Haze",
	kr_name = "아지랑이 환영",
	type = {"spell/shades",3},
	require = spells_req_high3,
	points = 5,
	mana = 70,
	cooldown = 30,
	range = 10,
	tactical = { ATTACK = 2, },
	requires_target = true,
	getDuration = function(self, t) return math.floor(self:combatTalentLimit(t, 30, 4, 8.1)) end, -- Limit <30
	getHealth = function(self, t) return self:combatLimit(self:combatTalentSpellDamage(t, 20, 500), 1.0, 0.2, 0, 0.58, 384) end,  -- Limit health < 100%
	getDam = function(self, t) return self:combatLimit(self:combatTalentSpellDamage(t, 10, 500), 1.40, 0.4, 0, 0.76, 361) end,  -- Limit damage < 140%
	action = function(self, t)
		-- Find space
		local x, y = util.findFreeGrid(self.x, self.y, 1, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "소환할 공간이 부족합니다!")
			return
		end

		local m = require("mod.class.NPC").new(self:cloneFull{
			shader = "shadow_simulacrum",
			no_drops = true,
			faction = self.faction,
			summoner = self, summoner_gain_exp=true,
			summon_time = t.getDuration(self, t),
			ai_target = {actor=nil},
			ai = "summoned", ai_real = "tactical",
			kr_name = "아지랑이 환영 ("..(self.kr_name or self.name)..")",
			name = "Forgery of Haze ("..self.name..")",
			desc = [[당신을 닮은, 아지랑이 환영입니다.]],
		})
		m:removeAllMOs()
		m.make_escort = nil
		m.on_added_to_level = nil

		m.energy.value = 0
		m.player = nil
		m.max_life = m.max_life * t.getHealth(self, t)
		m.life = util.bound(m.life, 0, m.max_life)
		m.forceLevelup = function() end
		m.die = nil
		m.on_die = nil
		m.on_acquire_target = nil
		m.seen_by = nil
		m.can_talk = nil
		m.puuid = nil
		m.on_takehit = nil
		m.exp_worth = 0
		m.no_inventory_access = true
		m.clone_on_hit = nil
		m:unlearnTalentFull(m.T_CREATE_MINIONS)
		m:unlearnTalentFull(m.T_FORGERY_OF_HAZE)
		m.remove_from_party_on_death = true
		m.inc_damage.all = ((100 + (m.inc_damage.all or 0)) * t.getDam(self, t)) - 100

		game.zone:addEntity(game.level, m, "actor", x, y)
		game.level.map:particleEmitter(x, y, 1, "shadow")

		if game.party:hasMember(self) then
			game.party:addMember(m, {
				control="no",
				type="minion",
				title="Forgery of Haze", kr_title="아지랑이 환영",
				orders = {target=true},
			})
		end

		game:playSoundNear(self, "talents/spell_generic2")
		return true
	end,
	info = function(self, t)
		return ([[그림자를 이용하여, 시전자의 분신을 %d 턴 동안 만들어냅니다.
		분신은 시전자의 능력치와 기술을 그대로 가지고 있으며, 생명력은 시전자의 %d%% 만큼 가지고 있고, 피해량은 시전자의 %d%% 만큼 줄 수 있습니다.]]):
		format(t.getDuration(self, t), t.getHealth(self, t) * 100, t.getDam(self, t) * 100)
	end,
}

newTalent{
	name = "Frostdusk",
	kr_name = "서리황혼",
	type = {"spell/shades",4},
	require = spells_req_high4,
	points = 5,
	mode = "sustained",
	sustain_mana = 50,
	cooldown = 30,
	tactical = { BUFF = 2 },
	getDarknessDamageIncrease = function(self, t) return self:getTalentLevelRaw(t) * 2 end,
	getResistPenalty = function(self, t) return self:combatTalentLimit(t, 100, 17, 50, true) end,  -- Limit to < 100%
	getAffinity = function(self, t) return self:combatTalentLimit(t, 100, 10, 50) end, -- Limit < 100%
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic")
		local ret = {
			dam = self:addTemporaryValue("inc_damage", {[DamageType.DARKNESS] = t.getDarknessDamageIncrease(self, t), [DamageType.COLD] = t.getDarknessDamageIncrease(self, t)}),
			resist = self:addTemporaryValue("resists_pen", {[DamageType.DARKNESS] = t.getResistPenalty(self, t)}),
			affinity = self:addTemporaryValue("damage_affinity", {[DamageType.DARKNESS] = t.getAffinity(self, t)}),
		}
		local particle
		if core.shader.active(4) then
			ret.particle1 = self:addParticles(Particles.new("shader_ring_rotating", 1, {rotation=0, radius=1.1, img="spinningwinds_black"}, {type="spinningwinds", ellipsoidalFactor={1,1}, time_factor=6000, noup=2.0, verticalIntensityAdjust=-3.0}))
			ret.particle1.toback = true
			ret.particle2 = self:addParticles(Particles.new("shader_ring_rotating", 1, {rotation=0, radius=1.1, img="spinningwinds_black"}, {type="spinningwinds", ellipsoidalFactor={1,1}, time_factor=6000, noup=1.0, verticalIntensityAdjust=-3.0}))
		else
			ret.particle1 = self:addParticles(Particles.new("ultrashield", 1, {rm=0, rM=0, gm=0, gM=0, bm=10, bM=100, am=70, aM=180, radius=0.4, density=60, life=14, instop=20}))
		end
		return ret
	end,
	deactivate = function(self, t, p)
		if p.particle1 then self:removeParticles(p.particle1) end
		if p.particle2 then self:removeParticles(p.particle2) end
		self:removeTemporaryValue("inc_damage", p.dam)
		self:removeTemporaryValue("resists_pen", p.resist)
		self:removeTemporaryValue("damage_affinity", p.affinity)
		return true
	end,
	info = function(self, t)
		local damageinc = t.getDarknessDamageIncrease(self, t)
		local ressistpen = t.getResistPenalty(self, t)
		local affinity = t.getAffinity(self, t)
		return ([[시전자 주변에 황혼이 지고, 서리가 낍니다. 모든 암흑 피해와 냉기 피해가 %d%% 상승하며, 적들의 암흑 저항력을 %d%% 무시할 수 있게 됩니다.
		그리고, 암흑 피해를 받으면 피해량의 %d%% 만큼 생명력을 회복하게 됩니다.]])
		:format(damageinc, ressistpen, affinity)
	end,
}

# God Quest System

## Overview
Each god provides a unique storyline with multiple chapters. These quests are designed to match the god's role and teach players how to excel in their chosen path.

## Quest Structure

### Chapter System
Each god has 5 chapters:
- **Chapter 1**: Introduction & Skill Unlock (unlocks god's special skill)
- **Chapter 2**: Intermediate challenges
- **Chapter 3**: Advanced techniques
- **Chapter 4**: God's personal story arc
- **Chapter 5**: Epic finale (boss fight related to the god)

### Quest Design Philosophy

#### Good Gods (Athena, Zeus, Venus, Asclepius)
- Focus on protection, strategy, and helping others
- Quests involve defending, healing, or supporting
- Rewards emphasize teamwork and utility

#### Evil Gods (Hades, Ares)
- Focus on power, domination, and combat prowess
- Quests involve defeating powerful enemies
- Rewards emphasize damage and control

#### Fallen Angels (Titan, Gigantes)
- Focus on chaos, raw power, and destruction
- Quests involve overwhelming force
- Rewards emphasize hybrid abilities

## God-Specific Quest Examples

### Athena (Tank)
**Chapter 1: Shield of Wisdom**
- Defend village without letting villagers die
- Block 50 attacks
- Protect allies 20 times
- **Reward**: Aegis Shield skill

**Chapter 2: Tactical Mind**
- Complete dungeon using only defensive abilities
- Save 5 allies from fatal damage
- **Reward**: Tactical Stance ability

### Zeus (Ranged DPS Magic)
**Chapter 1: Storm's Fury**
- Defeat 50 enemies with magic
- Hit from long range 30 times
- Multi-target 10 times
- **Reward**: Lightning Bolt skill

**Chapter 2: Olympian Wrath**
- Defeat boss using only ranged attacks
- Chain lightning to hit 5+ enemies
- **Reward**: Storm Call ability

### Venus (Support Buffer/Debuffer)
**Chapter 1: Divine Charm**
- Buff allies 100 times
- Debuff enemies 50 times
- Win battle without dealing damage
- **Reward**: Divine Charm skill

### Asclepius (Healer)
**Chapter 1: Sacred Healing**
- Heal 10,000 HP total
- Save ally from death 10 times
- Complete dungeon without anyone dying
- **Reward**: Divine Restoration skill

### Hades (Off-Tank/Control)
**Chapter 1: Shadow's Embrace**
- Control 50 enemies with CC
- Survive 5 minutes surrounded by enemies
- Defeat enemies using DoT effects
- **Reward**: Shadow Grasp skill

### Ares (Melee DPS)
**Chapter 1: Bloodlust**
- Defeat 100 enemies in melee combat
- Achieve 10 kill streaks
- Win duel without taking damage
- **Reward**: Berserker Rage skill

### Titan (Fallen - Hybrid)
**Chapter 1: Primordial Power**
- Defeat 50 enemies with raw power
- Destroy 20 structures
- Survive overwhelming odds
- **Reward**: Titanic Fury skill

### Gigantes (Fallen - Hybrid)
**Chapter 1: Giant's Might**
- Defeat 3 bosses in succession
- Deal 50,000 damage in one battle
- Crush 30 enemies with heavy attacks
- **Reward**: Giant's Wrath skill

## Implementation

### Creating a God Quest

1. Create quest file in `quests/god_quests/`
2. Define QUEST_DATA dictionary with:
   - id, title, description
   - god_required (god ID)
   - chapter number
   - objectives array
   - rewards (including skill_unlock)
   - dialogue (start, progress, complete)

3. Implement `can_start_quest()` to check god requirement
4. Implement `on_quest_complete()` to unlock god skill

### Quest Validation

```gdscript
func can_accept_quest(quest_id: String) -> bool:
	var quest = load("res://quests/god_quests/" + quest_id + ".gd").new()
	
	# Check god requirement
	if not quest.can_start_quest():
		return false
	
	# Check chapter order
	var chapter = quest.QUEST_DATA.chapter
	if chapter > 1:
		var prev_chapter = "ch" + str(chapter - 1)
		if not is_chapter_complete(prev_chapter):
			return false
	
	return true
```

### Tracking Progress

God quest progress is stored in the `god_quests` database table:

```sql
SELECT * FROM god_quests 
WHERE player_id = ? AND god_id = ?
```

## Quest Rewards

### Skill Unlocks
Each Chapter 1 quest unlocks the god's signature skill:
- Athena: Aegis Shield (massive damage reduction)
- Zeus: Lightning Bolt (devastating ranged attack)
- Venus: Divine Charm (buff/debuff)
- Asclepius: Divine Restoration (powerful heal)
- Hades: Shadow Grasp (immobilize enemies)
- Ares: Berserker Rage (damage + attack speed)
- Titan: Titanic Fury (AoE damage)
- Gigantes: Giant's Wrath (size + power increase)

### Progression Rewards
Later chapters provide:
- Enhanced versions of god skills
- God-themed equipment
- Unique titles
- Lore and story progression

## Dialogue System Integration

God quests use rich dialogue to tell the story:

```gdscript
func show_quest_dialogue(stage: String) -> void:
	var quest = current_god_quest
	var dialogue_lines = quest.QUEST_DATA.dialogue[stage]
	
	for line in dialogue_lines:
		DialogSystem.show_dialogue(quest.QUEST_DATA.quest_giver, line)
		await DialogSystem.dialogue_finished
```

## Future Enhancements

### God Reputation System
- Track player actions that align with god's values
- Unlock bonus rewards for high reputation
- Special dialogue for devoted followers

### Cross-God Interactions
- Some quests involve multiple gods
- Good vs Evil storylines
- Fallen angels offer alternative paths

### Endgame God Trials
- Ultimate challenges for each god
- Unlock legendary god-themed equipment
- Transform into god's avatar temporarily

## Testing God Quests

1. Select god during character creation
2. Check quest log for Chapter 1 quest
3. Complete objectives
4. Verify skill unlock
5. Check database for quest completion
6. Test next chapter availability

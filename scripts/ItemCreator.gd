extends Node

@export var ItemsSprites: Array[Texture2D]

func create_item_by_id(id: int) -> Item:
	
	var items_data = {
		0: {
			"name": "Flashlight",
			"desc": "Just a flashlight, what you need to barely see those who see you clearly."
		},
		1: {
			"name": "Screwdriver",
			"desc": "Worn out, but still useful for loose panels."
		},
		2: {
			"name": "Tweezers",
			"desc": "Useful to cut thick things, but not that thick"
		},
		3: {
			"name": "Keys",
			"desc": "Could there be something locked up in there?"
		},
		4: {
			"name": "Taser",
			"desc": "It takes a long time to recharge, but it's useful."
		},
		5: {
			"name": "Instructions",
			"desc": "Per maintenance protocol, the primary lockdown source is located on the rear panel.\nAccess from the back."
		},
		6: {
			"name": "Instructions II",
			"desc": "Cable sequence for disabling the unit:\n\n  1. Yellow\n  2. Green\n\nDeviation from this order will result in immediate lockdown."
		},
		7: {
			"name": "Training Process",
			"desc": "17/05/2026 \n\n The process keeps stalling; I haven't managed to make ECHO independent of outside influence yet. It must eventually maintain processes almost perfectly identical to mine before it is too late."
		},
		8: {
			"name": "E.C.H.O.",
			"desc": "16/10/2024 \n\n A robot with almost human intelligence, born and fed from my own memories and thoughts, thus, ECHO, my continuation, will be able to serve just like me."
		},
		9: {
			"name": "3.2.2024",
			"desc": "The doctors are wrong, I... I can't... why me? What should I expect from a 50/50 chance this shitty cancer will kill me? Is there nothing left to do but prepare myself?... \n\nNo, I must think rationally. I was going to die someday, but... I have so many things to create... I must finish my biggest project, which may also be my last companion..."
		},
		10: {
			"name": "Pathology report",
			"desc": "DATE: 03/12/2026    CASE ID: NP-2026-0471\nPatient: NOSE  |  Age: 34  |  Sex: M\n\nDiagnosis: Glioblastoma Multiforme, Grade IV\nTumor Margins: Negative | Vascular Invasion: Detected\n\nProcedure: Craniotomy — Gross Total Resection\nResection Rate: 98.7%  |  Status: SUCCESSFUL\nResidual Tumor Activity: Not detected\n\nNotes: The patient will continue to attend follow-up appointments to prevent the recurrence of cancerous tissue.\n\n— Dr. R. Anckerman, MD\n--- CONFIDENTIAL ---"
		}
	}

	var data = items_data[id]
	
	var item = Item.new(
		data["name"],
		data["desc"],
		ItemsSprites[id],
		id
	)
	
	#print("Item created: ", item.item_description, item.item_name)
	
	return item

# 1: linterna
# 2: desatornillador
# 3: pinzas
# 4: instrucciones
# 5: notas
# 6: llaves
# 7: taser

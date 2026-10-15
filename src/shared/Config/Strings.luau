--!strict
-- Player-facing strings. Every key must exist in every language (enforced by tests/config.spec).
-- Placeholders: {name} style, filled by Util/Locale.format.
-- Arabic text is a first draft and must be reviewed by a native speaker before release.

local en: { [string]: string } = {
	-- HUD
	["hud.currency"] = "{n} qirsh",
	["hud.quest_header"] = "Errand",
	["hud.no_quest"] = "Talk to the neighbors to find work.",
	["hud.language"] = "عربي",
	["hud.close"] = "Close",

	-- Prompts
	["prompt.talk"] = "Talk",

	-- NPCs
	["npc.abu_nadim.name"] = "Abu Nadim",
	["npc.abu_nadim.role"] = "Baker",
	["npc.sitt_wardeh.name"] = "Sitt Wardeh",
	["npc.sitt_wardeh.role"] = "Neighbor",
	["npc.khalil_tailor.name"] = "Khalil",
	["npc.khalil_tailor.role"] = "Tailor",

	-- Items
	["item.basket_kaak.name"] = "Basket of ka'ak",
	["item.basket_kaak.desc"] = "Warm sesame ka'ak from Abu Nadim's oven.",
	["item.tarboosh_red.name"] = "Red tarboosh",
	["item.tarboosh_red.desc"] = "A felt tarboosh with a black silk tassel, pressed by Khalil himself.",

	-- Quest
	["quest.delivery_kaak.title"] = "Warm ka'ak for Sitt Wardeh",
	["quest.delivery_kaak.obj_active"] = "Bring the basket to Sitt Wardeh's house, south of the fountain.",
	["quest.delivery_kaak.obj_completed"] = "Delivered. Abu Nadim is grateful.",

	-- Shop
	["shop.khalil_tailor.title"] = "Khalil's tailoring",
	["shop.buy"] = "Buy · {price}",
	["shop.equip"] = "Wear",
	["shop.unequip"] = "Take off",
	["shop.owned"] = "Owned",

	-- Dialogue (common)
	["dlg.common.not_now"] = "Not right now.",
	["dlg.common.on_my_way"] = "I'm on my way.",
	["dlg.common.goodbye"] = "Goodbye.",
	["dlg.common.thank_you"] = "Thank you.",
	["dlg.common.one_moment"] = "One moment.",
	["dlg.common.maybe_later"] = "Maybe later.",

	-- Dialogue: Abu Nadim
	["dlg.abu_nadim.offer"] = "Ahlan, newcomer! My hands are deep in dough and Sitt Wardeh is waiting for her ka'ak. Could you carry this basket to her house, past the fountain?",
	["dlg.abu_nadim.offer.accept"] = "Of course, I'll take it.",
	["dlg.abu_nadim.accepted"] = "Bless your hands! And mind you don't nibble any on the way.",
	["dlg.abu_nadim.accepted.ok"] = "Not a single crumb!",
	["dlg.abu_nadim.waiting"] = "The ka'ak is getting cold! Sitt Wardeh lives south, past the fountain.",
	["dlg.abu_nadim.thanks"] = "Sitt Wardeh says you were quicker than my own son. Come back soon, there's always work at the oven.",

	-- Dialogue: Sitt Wardeh
	["dlg.sitt_wardeh.greet"] = "Welcome to our lane, my child. If you're looking for work, Abu Nadim the baker always needs a hand.",
	["dlg.sitt_wardeh.delivery"] = "Is that Abu Nadim's ka'ak I smell? Come in, come in, put it right here.",
	["dlg.sitt_wardeh.delivery.give"] = "Here you are, Sitt Wardeh.",
	["dlg.sitt_wardeh.delivered"] = "Still warm! Take these fifty qirsh, and no arguing. Go and buy yourself something proper from Khalil.",
	["dlg.sitt_wardeh.after"] = "May God keep you. The whole lane is talking about the helpful newcomer.",

	-- Dialogue: Khalil
	["dlg.khalil_tailor.greet"] = "A bare head on a fine day like this? That won't do. My tarboosh are the best in the city.",
	["dlg.khalil_tailor.greet.shop"] = "Show me your work.",

	-- Season 1 · Episode 1
	["npc.hajj_rashid.name"] = "Hajj Rashid",
	["npc.hajj_rashid.role"] = "Spice merchant",
	["prompt.inspect"] = "Inspect",
	["hud.episode"] = "Season 1 · Episode {n}",
	["hud.clues"] = "Clues {n}/{total}",
	["quest.s1e1.title"] = "Wedding Eve",
	["quest.s1e1.obj_active"] = "Search the lane for traces: by Hajj Rashid's chest, at the gate, around the fountain.",
	["quest.s1e1.obj_ready"] = "Bring what you found to Hajj Rashid.",
	["quest.s1e1.obj_completed"] = "Episode 1 complete. To be continued…",
	["clue.slipper.name"] = "Slipper print",
	["clue.slipper.text"] = "A soft slipper print in spilled cumin beside the chest. Not a boot: whoever did this belongs to the house, or the lane.",
	["clue.thread.name"] = "Indigo thread",
	["clue.thread.text"] = "A torn indigo thread caught on a nail of the gate door. Someone squeezed through the locked gate in the night.",
	["clue.token.name"] = "Copper token",
	["clue.token.text"] = "A copper token stamped with a crescent, dropped beside a bench. No shop in our lane gives tokens like this.",
	["clue.close"] = "Noted",
	["notify.clue_found"] = "Clue found: {clue} ({n}/{total})",
	["dlg.hajj_rashid.busy"] = "Not now, child, not now. A wedding tomorrow and a thousand things to do!",
	["dlg.hajj_rashid.plea"] = "You're the newcomer who helped Sitt Wardeh? Then come closer, and keep your voice down.",
	["dlg.hajj_rashid.plea.ask"] = "What's wrong, Hajj?",
	["dlg.hajj_rashid.plea2"] = "Layla's necklace, the diamonds her mother wore on her own wedding day, is gone from my chest. The gate was locked all night. One of our own took it.",
	["dlg.hajj_rashid.plea2.accept"] = "I'll find out what happened.",
	["dlg.hajj_rashid.plea2.decline"] = "This isn't my business.",
	["dlg.hajj_rashid.accepted"] = "God bless you. Look quietly: by my chest, at the gate, around the fountain. And not a word to Mansour the qabaday. He shouts first and thinks later.",
	["dlg.hajj_rashid.searching"] = "Anything yet? Someone must have left a trace. Try my chest, the gate, and the fountain.",
	["dlg.hajj_rashid.report"] = "A slipper print… indigo thread on the gate… and a copper token from outside the lane? Then someone left at night.",
	["dlg.hajj_rashid.report.give"] = "Here's everything I found.",
	["dlg.hajj_rashid.reported"] = "Take this for your trouble. But keep your eyes open. Mansour will want a name by sunset, and I fear he'll pick the wrong one.",
	["dlg.hajj_rashid.reported.ok"] = "I'll keep watching.",
	["dlg.hajj_rashid.after"] = "Layla tells me to be patient. Patient! With her wedding hanging by a thread…",

	-- Notifications
	["notify.quest_accepted"] = "New errand: {title}",
	["notify.item_received"] = "Received: {item}",
	["notify.quest_completed"] = "Errand complete! +{n} qirsh",
	["notify.purchased"] = "Purchased: {item}",
	["notify.equipped"] = "You're wearing the {item}",
	["notify.unequipped"] = "You took off the {item}",
	["notify.too_far"] = "You're too far away.",
	["notify.cannot_afford"] = "You don't have enough qirsh.",
	["notify.already_owned"] = "You already own that.",
	["notify.error"] = "Something went wrong. Please try again.",
	["notify.slow_down"] = "Slow down a little!",
	["notify.persistence_disabled"] = "Test mode: progress will not be saved.",

	-- Kick messages (shown by Roblox, English and Arabic together)
	["kick.load_failed"] = "We couldn't load your progress. Your data is safe, please rejoin in a minute.",
	["kick.session_locked"] = "Your progress is still open on another server. Please rejoin in a minute.",
	["kick.newer_schema"] = "The game was updated. Please rejoin to get the latest version.",
	["kick.session_lost"] = "You joined from another server, so this session was closed.",
}

local ar: { [string]: string } = {
	["hud.currency"] = "{n} قرش",
	["hud.quest_header"] = "مشوار",
	["hud.no_quest"] = "احكِ مع الجيران لتلاقي شغل.",
	["hud.language"] = "English",
	["hud.close"] = "إغلاق",

	["prompt.talk"] = "احكِ",

	["npc.abu_nadim.name"] = "أبو نديم",
	["npc.abu_nadim.role"] = "الفرّان",
	["npc.sitt_wardeh.name"] = "الست وردة",
	["npc.sitt_wardeh.role"] = "جارة",
	["npc.khalil_tailor.name"] = "خليل",
	["npc.khalil_tailor.role"] = "الخيّاط",

	["item.basket_kaak.name"] = "سلّة كعك",
	["item.basket_kaak.desc"] = "كعك بالسمسم سخن من فرن أبو نديم.",
	["item.tarboosh_red.name"] = "طربوش أحمر",
	["item.tarboosh_red.desc"] = "طربوش جوخ بشرّابة حرير سوداء، كبسه خليل بإيده.",

	["quest.delivery_kaak.title"] = "كعك سخن للست وردة",
	["quest.delivery_kaak.obj_active"] = "وصّل السلّة لبيت الست وردة، جنوب البحرة.",
	["quest.delivery_kaak.obj_completed"] = "تمّ التوصيل. أبو نديم ممنون منك.",

	["shop.khalil_tailor.title"] = "خياطة خليل",
	["shop.buy"] = "اشترِ · {price}",
	["shop.equip"] = "البس",
	["shop.unequip"] = "اشلح",
	["shop.owned"] = "عندك",

	["dlg.common.not_now"] = "مش هلّق.",
	["dlg.common.on_my_way"] = "أنا بالطريق.",
	["dlg.common.goodbye"] = "مع السلامة.",
	["dlg.common.thank_you"] = "شكراً.",
	["dlg.common.one_moment"] = "لحظة.",
	["dlg.common.maybe_later"] = "يمكن بعدين.",

	["dlg.abu_nadim.offer"] = "أهلين بالجار الجديد! إيديّ غرقانين بالعجين والست وردة ناطرة كعكاتها. بتوصّل هالسلّة لبيتها، ورا البحرة؟",
	["dlg.abu_nadim.offer.accept"] = "أكيد، هاتها.",
	["dlg.abu_nadim.accepted"] = "تسلم إيديك! وانتبه لا تاكل شي بالطريق.",
	["dlg.abu_nadim.accepted.ok"] = "ولا فتفوتة!",
	["dlg.abu_nadim.waiting"] = "الكعك عم يبرد! بيت الست وردة جنوب، ورا البحرة.",
	["dlg.abu_nadim.thanks"] = "الست وردة بتقول إنك أسرع من ابني. ارجع قريباً، الشغل عالفرن ما بيخلص.",

	["dlg.sitt_wardeh.greet"] = "أهلاً بحارتنا يا ابني. إذا بدك شغل، أبو نديم الفرّان دايماً بدّه حدا يساعده.",
	["dlg.sitt_wardeh.delivery"] = "هيدي ريحة كعك أبو نديم؟ تفضّل تفضّل، حطّها هون.",
	["dlg.sitt_wardeh.delivery.give"] = "تفضّلي يا ست وردة.",
	["dlg.sitt_wardeh.delivered"] = "بعدها سخنة! خود هالخمسين قرش وبلا نقاش. روح اشتري شي يليق فيك من عند خليل.",
	["dlg.sitt_wardeh.after"] = "الله يحميك. كل الحارة عم تحكي عن الجار الجديد الشاطر.",

	["dlg.khalil_tailor.greet"] = "راسك مكشوف بهيك نهار حلو؟ ما بيصير. طرابيشي أحسن طرابيش بالبلد.",
	["dlg.khalil_tailor.greet.shop"] = "فرجيني شغلك.",

	["npc.hajj_rashid.name"] = "الحاج رشيد",
	["npc.hajj_rashid.role"] = "العطّار",
	["prompt.inspect"] = "افحص",
	["hud.episode"] = "الموسم ١ · الحلقة {n}",
	["hud.clues"] = "الأدلّة {n}/{total}",
	["quest.s1e1.title"] = "ليلة العرس",
	["quest.s1e1.obj_active"] = "دوّر بالحارة على أثر: جنب صندوق الحاج رشيد، عند البوابة، وحوالي البحرة.",
	["quest.s1e1.obj_ready"] = "خود اللي لقيته للحاج رشيد.",
	["quest.s1e1.obj_completed"] = "خلصت الحلقة الأولى. يتبع…",
	["clue.slipper.name"] = "أثر شحّاطة",
	["clue.slipper.text"] = "أثر شحّاطة طرية بالكمّون المكبوب جنب الصندوق. مش جزمة: اللي عملها من أهل البيت، أو من الحارة.",
	["clue.thread.name"] = "خيط نيلي",
	["clue.thread.text"] = "خيط نيلي مقطوع علقان بمسمار باب البوابة. حدا انسلّ من البوابة المسكّرة بالليل.",
	["clue.token.name"] = "فيشة نحاس",
	["clue.token.text"] = "فيشة نحاس مختومة بهلال، واقعة جنب مقعد. ولا دكان بحارتنا بيعطي هيك فيش.",
	["clue.close"] = "تمام",
	["notify.clue_found"] = "لقيت دليل: {clue} ({n}/{total})",
	["dlg.hajj_rashid.busy"] = "مش هلّق يا ابني، مش هلّق. العرس بكرة وعندي ألف شغلة!",
	["dlg.hajj_rashid.plea"] = "إنت الجار الجديد اللي ساعد الست وردة؟ طيب قرّب، ووطّي صوتك.",
	["dlg.hajj_rashid.plea.ask"] = "خير يا حاج؟",
	["dlg.hajj_rashid.plea2"] = "عقد ليلى، الألماس اللي لبسته إمها يوم عرسها، راح من صندوقي. البوابة كانت مسكّرة طول الليل. واحد منّا أخده.",
	["dlg.hajj_rashid.plea2.accept"] = "رح أعرف شو صار.",
	["dlg.hajj_rashid.plea2.decline"] = "هاد مش شغلي.",
	["dlg.hajj_rashid.accepted"] = "الله يرضى عليك. دوّر بهدوء: جنب صندوقي، عند البوابة، وحوالي البحرة. وولا كلمة لمنصور القبضاي، بيصرّخ أول وبيفكّر بعدين.",
	["dlg.hajj_rashid.searching"] = "لقيت شي؟ أكيد حدا ترك أثر. شوف جنب صندوقي، والبوابة، والبحرة.",
	["dlg.hajj_rashid.report"] = "أثر شحّاطة… خيط نيلي عالبوابة… وفيشة نحاس من برّا الحارة؟ يعني حدا طلع بالليل.",
	["dlg.hajj_rashid.report.give"] = "هاد كل شي لقيته.",
	["dlg.hajj_rashid.reported"] = "خود هدول عتعبك. بس خلّي عيونك مفتّحة. منصور رح يطلب اسم قبل المغرب، وخايف ينقّي الاسم الغلط.",
	["dlg.hajj_rashid.reported.ok"] = "رح ضلّ منتبه.",
	["dlg.hajj_rashid.after"] = "ليلى بتقلّي اصبر. أصبر! وعرسها معلّق بشعرة…",

	["notify.quest_accepted"] = "مشوار جديد: {title}",
	["notify.item_received"] = "استلمت: {item}",
	["notify.quest_completed"] = "خلص المشوار! +{n} قرش",
	["notify.purchased"] = "اشتريت: {item}",
	["notify.equipped"] = "لبست {item}",
	["notify.unequipped"] = "شلحت {item}",
	["notify.too_far"] = "إنت بعيد كتير.",
	["notify.cannot_afford"] = "ما معك قروش كفاية.",
	["notify.already_owned"] = "هاد عندك من قبل.",
	["notify.error"] = "صار في غلط. جرّب مرة تانية.",
	["notify.slow_down"] = "شوي شوي!",
	["notify.persistence_disabled"] = "وضع التجربة: التقدّم ما رح ينحفظ.",

	["kick.load_failed"] = "ما قدرنا نحمّل تقدّمك. بياناتك بأمان، ارجع بعد دقيقة.",
	["kick.session_locked"] = "تقدّمك لسا مفتوح على سيرفر تاني. ارجع بعد دقيقة.",
	["kick.newer_schema"] = "انعمل تحديث للعبة. ارجع لتاخد آخر نسخة.",
	["kick.session_lost"] = "فتت من سيرفر تاني، فانسكّرت هالجلسة.",
}

return {
	en = en,
	ar = ar,
	languages = { "en", "ar" },
	rtl = { ar = true },
}

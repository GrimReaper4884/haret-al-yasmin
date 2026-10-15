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

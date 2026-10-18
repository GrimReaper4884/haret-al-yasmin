# Arabic strings: native-speaker review pack

*Generated 2026-10-16 from `src/shared/Config/Strings.luau` (branch `feat/vertical-slice`, commit 2b0b800). 800 keys in 18 screens; Claude flagged 62 of them. Regenerate with `python -I docs/review/build_arabic_review.py .` after edits rather than hand-editing the Arabic column.*

## For the reviewer

The game is set in a 1930s Damascus lane (*hara*). Every Arabic line was drafted by an AI (Claude) and **no native speaker has read it yet**. We want natural **Damascene / Shami** colloquial for dialogue and short, clear colloquial for buttons. Players are mostly children and teenagers across the Arab world, so it should also be easy for a Gulf or Egyptian kid to read.

How to review:

1. Read each row. The **Claude flag** column is our own guess at a problem; it may be wrong. Agree, disagree or ignore it.
2. If the Arabic is fine, put `OK` in the last column. If not, write your version in **Correction** (keep `{n}`, `{name}` and other `{…}` placeholders exactly as they are; they are replaced by numbers or names in the game).
3. Tell us about anything that sounds Lebanese, Egyptian, Gulf or too formal (فصحى) where a Damascene would speak differently.
4. Tell us if anything is rude, religiously insensitive, embarrassing for kids, or sounds like it was copied from the TV series *Bab al-Hara* (names, catch-phrases).
5. Return this file (or a copy with the last two columns filled). Name and date at the bottom, please.

Tag legend in the flag column: **MEANING** may say the wrong thing · **DIALECT** not Damascene · **STYLE** awkward or inconsistent · **NAME** character-name check.

## Questions that cut across many rows

1. **Gender of address.** Dialogue says «يا ابني», «إنت», masculine imperatives (روح، خود، اكبس). The player can be a girl. Keep masculine as the generic, or rephrase lines to be neutral? (The game has no gender setting today.)
2. **«الرجال» for units.** The defenders include a woman (Umm Zaki) and a cat, but the UI calls them «الرجال / رجّال». Keep it as period flavour, or use «المدافعين»?
3. **Digits.** Hard-coded numbers use Arabic-Indic digits (١٠٠، ٢٠ موجة), but every `{n}` placeholder is filled with Western digits (1, 2, 3) and some strings use «3x», «R$», «$». So players will see «الموسم ١ · الحلقة 1». Which do you prefer for kids in Syria, the Gulf and Egypt: all Western digits, or all Arabic-Indic? (Code change; just tell us which.)
4. **Number agreement.** Strings like «{n} يوم», «{n} حجر صفات», «{n}/{max} لاعبين» are right for some numbers and wrong for others (3–10 take the plural). Tell us which rows matter most; we can add proper plural forms.
5. **«مش» vs «مو».** We used «مش» in several places; we believe Damascene speech uses «مو». Rows are flagged; confirm.
6. **Gate vs portal.** The lane gate is «الباب» in the tower-defense screens but «البوابة» in the Episode 1 story, and the portals in the square are also «بوابة». Suggest one word for each.
7. **Character names (copyright register C-013).** Abu Fares (watchman) and Abu Khater (blacksmith) also appear as minor names in *Bab al-Hara*. Do they make you think of the show? If yes, suggest replacements. Same question for any other name in section 11.
8. **Not in this file:** `src/server/World/Arena.luau` line 113 hard-codes the sign «حارة الياسمين» (same as `sign.lane`).

## Contents

- [1. Main HUD and buttons](#1-main-hud-and-buttons) — 24 strings, 4 flagged
- [2. Lane neighbours and the first errand](#2-lane-neighbours-and-the-first-errand) — 28 strings, 5 flagged
- [3. Story: Season 1 · Episode 1 (Wedding Eve)](#3-story-season-1--episode-1-wedding-eve) — 27 strings, 6 flagged
- [4. Wardrobe and tailor shop](#4-wardrobe-and-tailor-shop) — 37 strings, 3 flagged
- [5. Store and Robux products](#5-store-and-robux-products) — 40 strings, 4 flagged
- [6. Notifications (toasts)](#6-notifications-toasts) — 21 strings, 1 flagged
- [7. Disconnect messages (shown by Roblox)](#7-disconnect-messages-shown-by-roblox) — 4 strings, 1 flagged
- [8. Tower defense: modes, arenas and party queue](#8-tower-defense-modes-arenas-and-party-queue) — 43 strings, 4 flagged
- [9. Tower defense: match HUD](#9-tower-defense-match-hud) — 81 strings, 10 flagged
- [10. Enemies](#10-enemies) — 30 strings, 2 flagged
- [11. Defender roster, rarities, roles and traits](#11-defender-roster-rarities-roles-and-traits) — 109 strings, 10 flagged
- [12. Units screen](#12-units-screen) — 29 strings, 1 flagged
- [13. Summon screen](#13-summon-screen) — 21 strings, 3 flagged
- [14. Lane Diary (season pass)](#14-lane-diary-season-pass) — 13 strings, 1 flagged
- [15. Codes, daily reward and reward labels](#15-codes-daily-reward-and-reward-labels) — 22 strings, 2 flagged
- [16. Lobby NPCs (tower-defense square)](#16-lobby-npcs-tower-defense-square) — 15 strings, 4 flagged
- [17. World signs (3D text in the lane)](#17-world-signs-3d-text-in-the-lane) — 7 strings, 1 flagged
- [18. Other screens (AFK room, settings, Play, story, events, touch HUD)](#18-other-screens-afk-room-settings-play-story-events-touch-hud) — 249 strings, 0 flagged

## 1. Main HUD and buttons

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `hud.currency` | {n} qirsh | {n} قرش |  |  |  |
| 2 | `hud.quest_header` | Errand | مشوار |  |  |  |
| 3 | `hud.no_quest` | Talk to the neighbors to find work. | احكِ مع الجيران لتلاقي شغل. |  |  |  |
| 4 | `hud.language` | عربي | English |  |  |  |
| 5 | `hud.close` | Close | إغلاق | STYLE: MSA «إغلاق» in an otherwise colloquial UI. Fine for a button; colloquial alt «سكّر». |  |  |
| 6 | `prompt.talk` | Talk | احكِ |  |  |  |
| 7 | `prompt.inspect` | Inspect | افحص |  |  |  |
| 8 | `hud.episode` | Season 1 · Episode {n} | الموسم ١ · الحلقة {n} |  |  |  |
| 9 | `hud.clues` | Clues {n}/{total} | الأدلّة {n}/{total} |  |  |  |
| 10 | `hud.wardrobe` | Wardrobe | الخزانة |  |  |  |
| 11 | `hud.lira` | {n} lira | {n} ليرة |  |  |  |
| 12 | `hud.units` | Units | الرجال | MEANING: «الرجال» (the men) labels a roster that includes Umm Zaki and the cat. Suggest «المدافعين» or «رجال الحارة» if the male framing is intended. Same issue in units.title, units.empty, pass.reward.unit, notify.unit_new, pass.extra_slot.desc, match.err.unit_cap. |  |  |
| 13 | `hud.summon` | Summon | استدعاء |  |  |  |
| 14 | `hud.pass` | Diary | الدفتر |  |  |  |
| 15 | `hud.codes` | Codes | أكواد |  |  |  |
| 16 | `hud.daily` | Daily | يومي | STYLE: bare «يومي» (daily, adj.) as a button. Suggest «جائزة اليوم» or «اليومية». |  |  |
| 17 | `hud.defend` | Defend the gate: walk into the Play arch in the square. | دافع عن الباب: فوت من قوس اللعب بالساحة. | MEANING: the lane gate is «الباب» here but «البوابة» in the Episode 1 clues, and the queue portals are also «بوابة». Pick one word for the gate and another for the portal (e.g. portal «الدائرة»/«نقطة التجمّع»). |  |  |
| 18 | `hud.more` | More | المزيد |  |  |  |
| 19 | `hud.settings` | Settings | إعدادات |  |  |  |
| 20 | `hud.music_on` | Music on (tap to mute) | الموسيقى شغّالة (اكبس لتسكيتها) |  |  |  |
| 21 | `hud.music_off` | Music off (tap to play) | الموسيقى مطفية (اكبس لتشغيلها) |  |  |  |
| 22 | `hud.play` | Play | العب |  |  |  |
| 23 | `hud.event` | Event | مناسبة |  |  |  |
| 24 | `hud.afk` | AFK | الحكواتي |  |  |  |

## 2. Lane neighbours and the first errand

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `npc.abu_nadim.name` | Abu Nadim | أبو نديم |  |  |  |
| 2 | `npc.abu_nadim.role` | Baker | الفرّان |  |  |  |
| 3 | `npc.sitt_wardeh.name` | Sitt Wardeh | الست وردة |  |  |  |
| 4 | `npc.sitt_wardeh.role` | Neighbor | جارة |  |  |  |
| 5 | `npc.khalil_tailor.name` | Khalil | خليل |  |  |  |
| 6 | `npc.khalil_tailor.role` | Tailor | الخيّاط |  |  |  |
| 7 | `quest.delivery_kaak.title` | Warm ka'ak for Sitt Wardeh | كعك سخن للست وردة |  |  |  |
| 8 | `quest.delivery_kaak.obj_active` | Bring the basket to Sitt Wardeh's house, south of the fountain. | وصّل السلّة لبيت الست وردة، جنوب البحرة. |  |  |  |
| 9 | `quest.delivery_kaak.obj_completed` | Delivered. Abu Nadim is grateful. | تمّ التوصيل. أبو نديم ممنون منك. | STYLE: MSA «تمّ التوصيل» next to colloquial text. Alt «وصلت السلّة». |  |  |
| 10 | `dlg.common.not_now` | Not right now. | مش هلّق. | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «مو هلّق». |  |  |
| 11 | `dlg.common.on_my_way` | I'm on my way. | أنا بالطريق. |  |  |  |
| 12 | `dlg.common.goodbye` | Goodbye. | مع السلامة. |  |  |  |
| 13 | `dlg.common.thank_you` | Thank you. | شكراً. |  |  |  |
| 14 | `dlg.common.one_moment` | One moment. | لحظة. |  |  |  |
| 15 | `dlg.common.maybe_later` | Maybe later. | يمكن بعدين. |  |  |  |
| 16 | `dlg.abu_nadim.offer` | Ahlan, newcomer! My hands are deep in dough and Sitt Wardeh is waiting for her ka'ak. Could you carry this basket to her house, past the fountain? | أهلين بالجار الجديد! إيديّ غرقانين بالعجين والست وردة ناطرة كعكاتها. بتوصّل هالسلّة لبيتها، ورا البحرة؟ |  |  |  |
| 17 | `dlg.abu_nadim.offer.accept` | Of course, I'll take it. | أكيد، هاتها. |  |  |  |
| 18 | `dlg.abu_nadim.accepted` | Bless your hands! And mind you don't nibble any on the way. | تسلم إيديك! وانتبه لا تاكل شي بالطريق. |  |  |  |
| 19 | `dlg.abu_nadim.accepted.ok` | Not a single crumb! | ولا فتفوتة! |  |  |  |
| 20 | `dlg.abu_nadim.waiting` | The ka'ak is getting cold! Sitt Wardeh lives south, past the fountain. | الكعك عم يبرد! بيت الست وردة جنوب، ورا البحرة. |  |  |  |
| 21 | `dlg.abu_nadim.thanks` | Sitt Wardeh says you were quicker than my own son. Come back soon, there's always work at the oven. | الست وردة بتقول إنك أسرع من ابني. ارجع قريباً، الشغل عالفرن ما بيخلص. | STYLE: MSA «قريباً». Colloquial alt «لا تطوّل علينا» / «ارجع عن قريب». |  |  |
| 22 | `dlg.sitt_wardeh.greet` | Welcome to our lane, my child. If you're looking for work, Abu Nadim the baker always needs a hand. | أهلاً بحارتنا يا ابني. إذا بدك شغل، أبو نديم الفرّان دايماً بدّه حدا يساعده. | MEANING: «يا ابني» and all imperatives address a boy. The player may be a girl. Decide: keep masculine as the generic, or rephrase neutrally (e.g. «يا عيني»). Applies to every dialogue line. |  |  |
| 23 | `dlg.sitt_wardeh.delivery` | Is that Abu Nadim's ka'ak I smell? Come in, come in, put it right here. | هيدي ريحة كعك أبو نديم؟ تفضّل تفضّل، حطّها هون. | DIALECT: «هيدي» is Lebanese; Damascene «هاي». Suggest «هاي ريحة كعك أبو نديم؟». |  |  |
| 24 | `dlg.sitt_wardeh.delivery.give` | Here you are, Sitt Wardeh. | تفضّلي يا ست وردة. |  |  |  |
| 25 | `dlg.sitt_wardeh.delivered` | Still warm! Take these fifty qirsh, and no arguing. Go and buy yourself something proper from Khalil. | بعدها سخنة! خود هالخمسين قرش وبلا نقاش. روح اشتري شي يليق فيك من عند خليل. |  |  |  |
| 26 | `dlg.sitt_wardeh.after` | May God keep you. The whole lane is talking about the helpful newcomer. | الله يحميك. كل الحارة عم تحكي عن الجار الجديد الشاطر. |  |  |  |
| 27 | `dlg.khalil_tailor.greet` | A bare head on a fine day like this? That won't do. My tarboosh are the best in the city. | راسك مكشوف بهيك نهار حلو؟ ما بيصير. طرابيشي أحسن طرابيش بالبلد. |  |  |  |
| 28 | `dlg.khalil_tailor.greet.shop` | Show me your work. | فرجيني شغلك. |  |  |  |

## 3. Story: Season 1 · Episode 1 (Wedding Eve)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `npc.hajj_rashid.name` | Hajj Rashid | الحاج رشيد |  |  |  |
| 2 | `npc.hajj_rashid.role` | Spice merchant | العطّار |  |  |  |
| 3 | `quest.s1e1.title` | Wedding Eve | ليلة العرس |  |  |  |
| 4 | `quest.s1e1.obj_active` | Search the lane for traces: by Hajj Rashid's chest, at the gate, around the fountain. | دوّر بالحارة على أثر: جنب صندوق الحاج رشيد، عند البوابة، وحوالي البحرة. | DIALECT: «حوالي» → Damascene «حوالين البحرة». Also see hud.defend on gate = «البوابة» vs «الباب». |  |  |
| 5 | `quest.s1e1.obj_ready` | Bring what you found to Hajj Rashid. | خود اللي لقيته للحاج رشيد. |  |  |  |
| 6 | `quest.s1e1.obj_completed` | Episode 1 complete. To be continued… | خلصت الحلقة الأولى. يتبع… |  |  |  |
| 7 | `clue.slipper.name` | Slipper print | أثر شحّاطة |  |  |  |
| 8 | `clue.slipper.text` | A soft slipper print in spilled cumin beside the chest. Not a boot: whoever did this belongs to the house, or the lane. | أثر شحّاطة طرية بالكمّون المكبوب جنب الصندوق. مش جزمة: اللي عملها من أهل البيت، أو من الحارة. | STYLE + DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «مو جزمة». «شحّاطة طرية» (soft slipper) sounds odd; alt «أثر شحّاطة خفيفة». |  |  |
| 9 | `clue.thread.name` | Indigo thread | خيط نيلي |  |  |  |
| 10 | `clue.thread.text` | A torn indigo thread caught on a nail of the gate door. Someone squeezed through the locked gate in the night. | خيط نيلي مقطوع علقان بمسمار باب البوابة. حدا انسلّ من البوابة المسكّرة بالليل. |  |  |  |
| 11 | `clue.token.name` | Copper token | فيشة نحاس |  |  |  |
| 12 | `clue.token.text` | A copper token stamped with a crescent, dropped beside a bench. No shop in our lane gives tokens like this. | فيشة نحاس مختومة بهلال، واقعة جنب مقعد. ولا دكان بحارتنا بيعطي هيك فيش. |  |  |  |
| 13 | `clue.close` | Noted | تمام |  |  |  |
| 14 | `notify.clue_found` | Clue found: {clue} ({n}/{total}) | لقيت دليل: {clue} ({n}/{total}) |  |  |  |
| 15 | `dlg.hajj_rashid.busy` | Not now, child, not now. A wedding tomorrow and a thousand things to do! | مش هلّق يا ابني، مش هلّق. العرس بكرة وعندي ألف شغلة! | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «مو هلّق يا ابني، مو هلّق». |  |  |
| 16 | `dlg.hajj_rashid.plea` | You're the newcomer who helped Sitt Wardeh? Then come closer, and keep your voice down. | إنت الجار الجديد اللي ساعد الست وردة؟ طيب قرّب، ووطّي صوتك. |  |  |  |
| 17 | `dlg.hajj_rashid.plea.ask` | What's wrong, Hajj? | خير يا حاج؟ |  |  |  |
| 18 | `dlg.hajj_rashid.plea2` | Layla's necklace, the diamonds her mother wore on her own wedding day, is gone from my chest. The gate was locked all night. One of our own took it. | عقد ليلى، الألماس اللي لبسته إمها يوم عرسها، راح من صندوقي. البوابة كانت مسكّرة طول الليل. واحد منّا أخده. |  |  |  |
| 19 | `dlg.hajj_rashid.plea2.accept` | I'll find out what happened. | رح أعرف شو صار. |  |  |  |
| 20 | `dlg.hajj_rashid.plea2.decline` | This isn't my business. | هاد مش شغلي. | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «هاد مو شغلي». |  |  |
| 21 | `dlg.hajj_rashid.accepted` | God bless you. Look quietly: by my chest, at the gate, around the fountain. And not a word to Mansour the qabaday. He shouts first and thinks later. | الله يرضى عليك. دوّر بهدوء: جنب صندوقي، عند البوابة، وحوالي البحرة. وولا كلمة لمنصور القبضاي، بيصرّخ أول وبيفكّر بعدين. | DIALECT: «حوالي» → «حوالين». |  |  |
| 22 | `dlg.hajj_rashid.searching` | Anything yet? Someone must have left a trace. Try my chest, the gate, and the fountain. | لقيت شي؟ أكيد حدا ترك أثر. شوف جنب صندوقي، والبوابة، والبحرة. |  |  |  |
| 23 | `dlg.hajj_rashid.report` | A slipper print… indigo thread on the gate… and a copper token from outside the lane? Then someone left at night. | أثر شحّاطة… خيط نيلي عالبوابة… وفيشة نحاس من برّا الحارة؟ يعني حدا طلع بالليل. |  |  |  |
| 24 | `dlg.hajj_rashid.report.give` | Here's everything I found. | هاد كل شي لقيته. |  |  |  |
| 25 | `dlg.hajj_rashid.reported` | Take this for your trouble. But keep your eyes open. Mansour will want a name by sunset, and I fear he'll pick the wrong one. | خود هدول عتعبك. بس خلّي عيونك مفتّحة. منصور رح يطلب اسم قبل المغرب، وخايف ينقّي الاسم الغلط. | STYLE: «خود هدول عتعبك» — «هدول» has no referent on screen (coins?). Alt «خود هالقروش على تعبك». |  |  |
| 26 | `dlg.hajj_rashid.reported.ok` | I'll keep watching. | رح ضلّ منتبه. |  |  |  |
| 27 | `dlg.hajj_rashid.after` | Layla tells me to be patient. Patient! With her wedding hanging by a thread… | ليلى بتقلّي اصبر. أصبر! وعرسها معلّق بشعرة… |  |  |  |

## 4. Wardrobe and tailor shop

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `item.basket_kaak.name` | Basket of ka'ak | سلّة كعك |  |  |  |
| 2 | `item.basket_kaak.desc` | Warm sesame ka'ak from Abu Nadim's oven. | كعك بالسمسم سخن من فرن أبو نديم. |  |  |  |
| 3 | `item.tarboosh_red.name` | Red tarboosh | طربوش أحمر |  |  |  |
| 4 | `item.tarboosh_red.desc` | A felt tarboosh with a black silk tassel, pressed by Khalil himself. | طربوش جوخ بشرّابة حرير سوداء، كبسه خليل بإيده. |  |  |  |
| 5 | `shop.khalil_tailor.title` | Khalil's tailoring | خياطة خليل |  |  |  |
| 6 | `shop.buy` | Buy · {price} | اشترِ · {price} |  |  |  |
| 7 | `shop.equip` | Wear | البس |  |  |  |
| 8 | `shop.unequip` | Take off | اشلح |  |  |  |
| 9 | `shop.owned` | Owned | عندك |  |  |  |
| 10 | `item.tarboosh_black.name` | Black tarboosh | طربوش أسود |  |  |  |
| 11 | `item.tarboosh_black.desc` | Sober black felt with a red tassel, for the serious gentleman. | جوخ أسود رزين بشرّابة حمرا، للأفندي الجدّي. |  |  |  |
| 12 | `item.taqiyah_white.name` | White cap | طاقية بيضا |  |  |  |
| 13 | `item.taqiyah_white.desc` | A light cotton cap, cool in the summer sun. | طاقية قطن خفيفة، بتبرّد الراس بشمس الصيف. |  |  |  |
| 14 | `item.hatta_agal.name` | Hatta and agal | حطّة وعقال |  |  |  |
| 15 | `item.hatta_agal.desc` | A cream headcloth held by a black cord, as worn by travellers from the countryside. | حطّة بلون القشطة مع عقال أسود، متل ما بيلبسوا المسافرين من الريف. |  |  |  |
| 16 | `item.tarboosh_gold.name` | Gold-banded tarboosh | طربوش بزنّار دهبي | MEANING: «زنّار» is a waist sash (and is the name of item.zunnar_sash). For a hat band suggest «طربوش بشريط دهبي». |  |  |
| 17 | `item.tarboosh_gold.desc` | Deep red felt with a gold band and gold tassel. Made for wedding nights. | جوخ أحمر غامق بزنّار وشرّابة دهب. مخصوص لليالي الأعراس. | MEANING: same «زنّار» issue; suggest «بشريط وشرّابة دهب». |  |  |
| 18 | `item.sidriyye_black.name` | Black waistcoat (sidriyye) | صدرية سودا |  |  |  |
| 19 | `item.sidriyye_black.desc` | A short black waistcoat with gold trim, worn over a white shirt. | صدرية قصيرة سودا بحاشية دهبية، فوق قميص أبيض. |  |  |  |
| 20 | `item.qumbaz_striped.name` | Striped qumbaz | قنباز مقلّم |  |  |  |
| 21 | `item.qumbaz_striped.desc` | A long striped robe, the everyday dress of a respectable merchant. | ثوب طويل مقلّم، لبس التاجر المحترم كل يوم. |  |  |  |
| 22 | `item.qumbaz_wedding.name` | Wedding qumbaz | قنباز العرس |  |  |  |
| 23 | `item.qumbaz_wedding.desc` | Cream silk with gold embroidery down the front. Fit for the zaffeh. | حرير بلون القشطة مطرّز دهب عالصدر. بيليق بالزفّة. |  |  |  |
| 24 | `item.sherwal_black.name` | Black sherwal | شروال أسود |  |  |  |
| 25 | `item.sherwal_black.desc` | Wide black trousers gathered below the knee. Made for long walks and wide strides. | شروال أسود عريض مزموم تحت الركبة. للمشي الطويل والخطوة الواسعة. |  |  |  |
| 26 | `item.sherwal_indigo.name` | Indigo sherwal | شروال نيلي |  |  |  |
| 27 | `item.sherwal_indigo.desc` | Wide trousers dyed deep indigo in Khalil's own vats. | شروال عريض مصبوغ نيلي غامق بأحواض خليل. | STYLE: «بأحواض خليل» (in Khalil's basins) for dye vats; reviewer to confirm the natural word. |  |  |
| 28 | `item.zunnar_sash.name` | Red sash | زنّار أحمر |  |  |  |
| 29 | `item.zunnar_sash.desc` | A long red sash wound around the waist, its end left hanging. | زنّار أحمر طويل ملفوف عالخصر وطرفه متدلّي. |  |  |  |
| 30 | `item.abaya_brown.name` | Brown abaya | عباية بنّية |  |  |  |
| 31 | `item.abaya_brown.desc` | A warm woollen cloak for cold evenings in the lane. | عباية صوف دافية لليالي البرد بالحارة. |  |  |  |
| 32 | `item.shawl_embroidered.name` | Embroidered shawl | شال مطرّز |  |  |  |
| 33 | `item.shawl_embroidered.desc` | A turquoise shawl with a gold border, embroidered by the women of the lane. | شال فيروزي بحاشية دهبية، طرّزوه نسوان الحارة. |  |  |  |
| 34 | `wardrobe.title` | Your wardrobe | خزانتك |  |  |  |
| 35 | `wardrobe.empty` | Nothing here yet. Visit Khalil the tailor in the lane. | لسا ما في شي. زور خليل الخيّاط بالحارة. |  |  |  |
| 36 | `wardrobe.errand_item` | Errand item | غرض مشوار |  |  |  |
| 37 | `shop.premium` | Premium | مميّز |  |  |  |

## 5. Store and Robux products

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `store.title` | Qirsh store | سوق القروش |  |  |  |
| 2 | `store.open` | + | + |  |  |  |
| 3 | `store.robux` | R$ {n} | R$ {n} |  |  |  |
| 4 | `store.soon` | Coming soon | قريباً |  |  |  |
| 5 | `store.packs` | Coin purses | صُرر القروش | STYLE: «صُرر» is a bookish plural. Alt «أكياس القروش». |  |  |
| 6 | `store.passes` | Passes | البطاقات | MEANING: «البطاقات» (cards) for Roblox game passes. Check the term Roblox's own Arabic UI uses for Game Pass and match it. |  |  |
| 7 | `product.qirsh_pouch` | Pouch of 100 qirsh | صرّة ١٠٠ قرش |  |  |  |
| 8 | `product.qirsh_purse` | Purse of 450 qirsh | كيس ٤٥٠ قرش |  |  |  |
| 9 | `product.qirsh_chest` | Chest of 1,000 qirsh | صندوق ١٠٠٠ قرش |  |  |  |
| 10 | `pass.lane_patron.name` | Lane Patron | راعي الحارة |  |  |  |
| 11 | `pass.lane_patron.desc` | Support the lane! Get the gold-banded tarboosh and the embroidered shawl. | ادعم الحارة! بتاخد الطربوش بالزنّار الدهبي والشال المطرّز. |  |  |  |
| 12 | `notify.qirsh_added` | +{n} qirsh added. Thank you! | +{n} قرش انضافوا. يسلموا إيديك! |  |  |  |
| 13 | `notify.pass_unlocked` | Unlocked: {pass} | انفتح: {pass} |  |  |  |
| 14 | `notify.coming_soon` | This isn't available yet. | هاد لسا مش متوفّر. | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «هاد لسا مو متوفّر». |  |  |
| 15 | `store.lira` | Lira | ليرات |  |  |  |
| 16 | `store.extras` | Extras | إضافات |  |  |  |
| 17 | `product.lira_100` | 100 lira | ١٠٠ ليرة |  |  |  |
| 18 | `product.lira_300` | 320 lira | ٣٢٠ ليرة |  |  |  |
| 19 | `product.lira_650` | 700 lira | ٧٠٠ ليرة |  |  |  |
| 20 | `product.lira_1500` | 1,650 lira | ١٦٥٠ ليرة |  |  |  |
| 21 | `product.lira_4000` | 4,500 lira | ٤٥٠٠ ليرة |  |  |  |
| 22 | `product.stones_3` | 3 trait stones | ٣ أحجار صفات |  |  |  |
| 23 | `product.stones_10` | 10 trait stones | ١٠ أحجار صفات |  |  |  |
| 24 | `product.pass_premium` | Lane Diary · Premium track | دفتر الحارة · المسار المميّز |  |  |  |
| 25 | `product.pass_premium.desc` | Double lira on every level, trait stones, two cosmetics and Al-'Akeed Abu Shehan at level 50. | ضعف الليرات بكل مستوى، أحجار صفات، قطعتين لبس، والعكيد أبو شهان بالمستوى ٥٠. |  |  |  |
| 26 | `product.pass_skip` | Skip 10 Diary levels | تخطّى ١٠ مستويات بالدفتر |  |  |  |
| 27 | `product.starter_pack` | Newcomer's bundle | صرّة الجديد |  |  |  |
| 28 | `product.starter_pack.desc` | 300 lira, the 'Akeed and a red tarboosh. Once per player. | ٣٠٠ ليرة والعكيد وطربوش أحمر. مرة وحدة لكل لاعب. |  |  |  |
| 29 | `pass.vip.name` | VIP | VIP |  |  |  |
| 30 | `pass.vip.desc` | 20% off summons, +25% lira from matches, an embroidered shawl and a golden name. | خصم ٢٠٪ على الاستدعاء، +٢٥٪ ليرات من الجولات، شال مطرّز واسم دهبي. |  |  |  |
| 31 | `pass.fast_mode.name` | Fast Mode | السرعة |  |  |  |
| 32 | `pass.fast_mode.desc` | 3x match speed when you host. | سرعة 3x بالجولة لما تكون صاحب الشلّة. |  |  |  |
| 33 | `pass.extra_slot.name` | Extra slot | خانة زيادة |  |  |  |
| 34 | `pass.extra_slot.desc` | A seventh defender in your loadout. | رجّال سابع بتشكيلتك. |  |  |  |
| 35 | `notify.lira_added` | +{n} lira. Thank you! | +{n} ليرة. يسلمو! | STYLE: spelled «يسلمو» here but «يسلموا» in notify.qirsh_added. Pick one. |  |  |
| 36 | `notify.stones_added` | +{n} trait stones. | +{n} حجر صفات. |  |  |  |
| 37 | `notify.premium_unlocked` | Premium Diary unlocked! | انفتح الدفتر المميّز! |  |  |  |
| 38 | `notify.levels_added` | +10 Diary levels! | +١٠ مستويات بالدفتر! |  |  |  |
| 39 | `notify.bundle_granted` | Newcomer's bundle received! | استلمت صرّة الجديد! |  |  |  |
| 40 | `notify.restricted` | This purchase isn't available in your region. | هالشراء مش متوفّر بمنطقتك. |  |  |  |

## 6. Notifications (toasts)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `notify.quest_accepted` | New errand: {title} | مشوار جديد: {title} |  |  |  |
| 2 | `notify.item_received` | Received: {item} | استلمت: {item} |  |  |  |
| 3 | `notify.quest_completed` | Errand complete! +{n} qirsh | خلص المشوار! +{n} قرش |  |  |  |
| 4 | `notify.purchased` | Purchased: {item} | اشتريت: {item} |  |  |  |
| 5 | `notify.equipped` | You're wearing the {item} | لبست {item} |  |  |  |
| 6 | `notify.unequipped` | You took off the {item} | شلحت {item} |  |  |  |
| 7 | `notify.too_far` | You're too far away. | إنت بعيد كتير. |  |  |  |
| 8 | `notify.cannot_afford` | You don't have enough qirsh. | ما معك قروش كفاية. |  |  |  |
| 9 | `notify.already_owned` | You already own that. | هاد عندك من قبل. |  |  |  |
| 10 | `notify.error` | Something went wrong. Please try again. | صار في غلط. جرّب مرة تانية. |  |  |  |
| 11 | `notify.slow_down` | Slow down a little! | شوي شوي! |  |  |  |
| 12 | `notify.persistence_disabled` | Test mode: progress will not be saved. | وضع التجربة: التقدّم ما رح ينحفظ. |  |  |  |
| 13 | `notify.match_rewards` | Match rewards: +{lira} lira, +{qirsh} qirsh, +{xp} XP | جوائز الجولة: +{lira} ليرة، +{qirsh} قرش، +{xp} خبرة |  |  |  |
| 14 | `notify.unit_new` | New defender: {unit}! | رجّال جديد: {unit}! |  |  |  |
| 15 | `notify.trait_rolled` | New trait: {trait} | صفة جديدة: {trait} |  |  |  |
| 16 | `notify.loadout_saved` | Loadout saved. | انحفظت التشكيلة. |  |  |  |
| 17 | `notify.daily_claimed` | Daily reward claimed! | استلمت جائزة اليوم! |  |  |  |
| 18 | `notify.leaderboard` | Best endless run: wave {n} | أحسن جولة ليل: موجة {n} | MEANING: «أحسن جولة ليل» does not clearly name the Endless mode. Suggest «أحسن رقم بليل ما بيخلص: موجة {n}». |  |  |
| 19 | `notify.global_pull` | {name} found a {rarity}: {unit}! | {name} لقى {rarity}: {unit}! |  |  |  |
| 20 | `notify.secret_unit` | The night guard joins you: {unit}! | حارس الليل صار معك: {unit}! |  |  |  |
| 21 | `notify.gift_unit` | {unit} joins your defenders! | صار مع المدافعين: {unit}! |  |  |  |

## 7. Disconnect messages (shown by Roblox)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `kick.load_failed` | We couldn't load your progress. Your data is safe, please rejoin in a minute. | ما قدرنا نحمّل تقدّمك. بياناتك بأمان، ارجع بعد دقيقة. |  |  |  |
| 2 | `kick.session_locked` | Your progress is still open on another server. Please rejoin in a minute. | تقدّمك لسا مفتوح على سيرفر تاني. ارجع بعد دقيقة. |  |  |  |
| 3 | `kick.newer_schema` | The game was updated. Please rejoin to get the latest version. | انعمل تحديث للعبة. ارجع لتاخد آخر نسخة. |  |  |  |
| 4 | `kick.session_lost` | You joined from another server, so this session was closed. | فتت من سيرفر تاني، فانسكّرت هالجلسة. | STYLE: «فتت من سيرفر تاني، فانسكّرت هالجلسة» is understandable but stiff; reviewer to smooth. |  |  |

## 8. Tower defense: modes, arenas and party queue

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `prompt.portal` | Join | انضم | STYLE: MSA «انضم». Colloquial alt «فوت». |  |  |
| 2 | `mode.ep1.name` | Episode 1 · Night of the Thieves | الحلقة ١ · ليلة الحرامية |  |  |  |
| 3 | `mode.ep1.desc` | Thieves and gendarmes test the gate. 20 waves. | حرامية ودرك بيجرّبوا الباب. ٢٠ موجة. |  |  |  |
| 4 | `mode.ep2.name` | Episode 2 · The Rival Lane | الحلقة ٢ · الحارة التانية |  |  |  |
| 5 | `mode.ep2.desc` | The next lane sends its thugs and their za'im. 30 waves. | الحارة الجارة بتبعت زعرانها وزعيمها. ٣٠ موجة. |  |  |  |
| 6 | `mode.ep3.name` | Episode 3 · The Siege | الحلقة ٣ · الحصار |  |  |  |
| 7 | `mode.ep3.desc` | The commandant marches on the quarter. 40 waves. | القومندان زاحف على الحي. ٤٠ موجة. |  |  |  |
| 8 | `mode.ep4.name` | Episode 4 · The Lost Shoe | الحلقة ٤ · الصرماية |  |  |  |
| 9 | `mode.ep4.desc` | Pickpockets swarm the square while the gendarmes search every house. 40 waves. | النشّالة مالين الساحة والدرك عم يفتّشوا كل بيت. ٤٠ موجة. |  |  |  |
| 10 | `mode.ep5.name` | Episode 5 · Fire at the Warehouse | الحلقة ٥ · حريق البوايكية |  |  |  |
| 11 | `mode.ep5.desc` | Torches in the orchard: keep water near the door. 45 waves. | مشاعل بالبساتين: خلّي المي قريبة من الباب. ٤٥ موجة. |  |  |  |
| 12 | `mode.ep6.name` | Episode 6 · The Blind Beggar | الحلقة ٦ · الشحّاد الأعمى |  |  |  |
| 13 | `mode.ep6.desc` | Not every neighbour is a neighbour tonight. Bring lanterns. 50 waves. | مو كل جار جار الليلة. جيبوا فوانيس. ٥٠ موجة. |  |  |  |
| 14 | `mode.ep7.name` | Episode 7 · The Police Post | الحلقة ٧ · المخفر |  |  |  |
| 15 | `mode.ep7.desc` | The whole post marches on the lane. Riflemen pin your defenders down. 50 waves. | المخفر كله نازل عالحارة. البندقجية بيعطّلوا المدافعين. ٥٠ موجة. |  |  |  |
| 16 | `mode.ep8.name` | Episode 8 · The Two Lanes | الحلقة ٨ · الحارتين |  |  |  |
| 17 | `mode.ep8.desc` | Two gates, two roads, one rival lane. Watch both. 55 waves. | بوابتين وطريقين وحارة غريمة. ديروا بالكم عالتنتين. ٥٥ موجة. |  |  |  |
| 18 | `mode.ep9.name` | Episode 9 · The Confession | الحلقة ٩ · الاعتراف |  |  |  |
| 19 | `mode.ep9.desc` | At dusk the night guard stands at the gate. Hold it with him. 60 waves. | عالمغرب حارس الليل واقف عالباب. اصمدوا معه. ٦٠ موجة. |  |  |  |
| 20 | `mode.infinite.name` | Endless Night | ليل ما بيخلص |  |  |  |
| 21 | `mode.infinite.desc` | Hold the gate as long as you can. Rewards every 10 waves. | صمّد على الباب أطول ما فيك. جوائز كل ١٠ موجات. | STYLE: «صمّد» (causative, 'make hold') used as 'hold out'. Suggest «اصمد عالباب قدّ ما فيك». |  |  |
| 22 | `arena.orchard.name` | The Orchard Road | طريق البساتين |  |  |  |
| 23 | `arena.siege.name` | Under the Walls | تحت السور |  |  |  |
| 24 | `arena.rival_lane.name` | The Rival Lane | الحارة التانية |  |  |  |
| 25 | `arena.olive_press.name` | The Olive Press | المعصرة |  |  |  |
| 26 | `arena.saha.name` | The Fountain Square | ساحة البحرة |  |  |  |
| 27 | `arena.warehouse.name` | The Warehouse Yard | ساحة البوايكية |  |  |  |
| 28 | `arena.post_road.name` | The Police Post Road | طريق المخفر |  |  |  |
| 29 | `arena.twin_gates.name` | The Twin Gates | البوابتين |  |  |  |
| 30 | `difficulty.normal` | Normal | عادي |  |  |  |
| 31 | `difficulty.hard` | Hard | صعب |  |  |  |
| 32 | `difficulty.nightmare` | Nightmare | كابوس |  |  |  |
| 33 | `mode.locked` | Locked: clear {mode} first | مقفول: خلّص {mode} أول |  |  |  |
| 34 | `mode.locked_difficulty` | Clear the easier difficulty first | خلّص المستوى الأسهل أول |  |  |  |
| 35 | `queue.title` | Party | الشلّة |  |  |  |
| 36 | `queue.players` | {n}/{max} players | {n}/{max} لاعبين | STYLE: plural agreement: «لاعبين» is right for 3–10 but the count is a placeholder (see general note 4). |  |  |
| 37 | `queue.starting` | Starting in {n}s | بنبلّش بعد {n} ث | DIALECT: «بنبلّش» is Lebanese/Palestinian 1st-person plural; Damascene «منبلّش». |  |  |
| 38 | `queue.leave` | Leave | اطلع |  |  |  |
| 39 | `queue.host` | Host picks the difficulty | صاحب الشلّة بيختار الصعوبة |  |  |  |
| 40 | `queue.joined` | {name} joined the party | {name} انضم للشلّة |  |  |  |
| 41 | `queue.left` | {name} left the party | {name} طلع من الشلّة |  |  |  |
| 42 | `mode.ev_olive.name` | Orchard Raid | غارة البستان |  |  |  |
| 43 | `mode.ev_olive.desc` | Bandits and riders come for the harvest. 15 waves. | حرامية وخيّالة جايين عالموسم. ١٥ موجة. |  |  |  |

## 9. Tower defense: match HUD

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `match.wave` | Wave {n}/{total} | موجة {n}/{total} |  |  |  |
| 2 | `match.wave_infinite` | Wave {n} | موجة {n} |  |  |  |
| 3 | `match.next_in` | Next wave in {n}s | الموجة الجاية بعد {n} ث |  |  |  |
| 4 | `match.gate` | The Gate | الباب |  |  |  |
| 5 | `match.cash` | ${n} | ${n} |  |  |  |
| 6 | `match.skip` | Skip ({n}/{total}) | تخطّي ({n}/{total}) | STYLE: noun «تخطّي» here, imperative spelled «تخطّى» in pass.skip / product.pass_skip. Make consistent. |  |  |
| 7 | `match.speed` | {n}x | {n}x |  |  |  |
| 8 | `match.leave` | Leave | اطلع |  |  |  |
| 9 | `match.place` | Tap the ground to place {unit} | كبس على الأرض لتحطّ {unit} | DIALECT: «كبس» is past tense; imperative is «اكبس». Suggest «اكبس عالأرض لتحطّ {unit}». |  |  |
| 10 | `match.cancel` | Cancel | إلغاء |  |  |  |
| 11 | `match.upgrade` | Upgrade · ${n} | طوّر · ${n} |  |  |  |
| 12 | `match.max_level` | Max level | أعلى مستوى |  |  |  |
| 13 | `match.sig_pick` | Pick a path | اختار طريق |  |  |  |
| 14 | `match.sig_confirm` | Choose · ${n} | اختار · ${n} |  |  |  |
| 15 | `match.sig_cost` | ${n} | ${n} |  |  |  |
| 16 | `match.sell` | Sell · ${n} | بيع · ${n} |  |  |  |
| 17 | `match.target` | Target: {mode} | الهدف: {mode} |  |  |  |
| 18 | `target.first` | First | الأول |  |  |  |
| 19 | `target.last` | Last | الأخير |  |  |  |
| 20 | `target.strong` | Strongest | الأقوى |  |  |  |
| 21 | `target.close` | Closest | الأقرب |  |  |  |
| 22 | `match.level` | Lv {n} | مستوى {n} |  |  |  |
| 23 | `match.stat_damage` | Damage {n} | ضرب {n} | STYLE: «ضرب» (hitting) for Damage; gamers expect «ضرر». |  |  |
| 24 | `match.stat_range` | Range {n} | مدى {n} |  |  |  |
| 25 | `match.stat_cooldown` | Speed {n}s | سرعة {n} ث |  |  |  |
| 26 | `match.stat_speed_label` | Speed | سرعة |  |  |  |
| 27 | `match.stat_income` | Income ${n}/wave | دخل ${n}/موجة |  |  |  |
| 28 | `match.stat_buff` | Buff +{n}% | تقوية +{n}% |  |  |  |
| 29 | `match.buffed` | Boosted +{n}% by a support nearby | مقوّى +{n}% من داعم قريب |  |  |  |
| 30 | `match.stat_heal` | Repairs {n} HP/wave | ترميم {n} نقطة/موجة |  |  |  |
| 31 | `match.sees_stealth` | Sees hidden thieves | بيشوف الحرامية المخفيين |  |  |  |
| 32 | `match.no_stealth` | Can't see hidden thieves | ما بيشوف الحرامية المخفيين |  |  |  |
| 33 | `match.sees_stealth_lit` | Sees hidden thieves: lit by {name}'s lantern | بيشوف الحرامية المخفيين: ضو فانوس {name} |  |  |  |
| 34 | `match.reveals_stealth` | Lantern: defenders in its range see hidden thieves | الفانوس: المدافعين بمداه بيشوفوا الحرامية المخفيين |  |  |  |
| 35 | `match.reveals_count` | Defenders in his light: {n} | مدافعين بضوّه: {n} |  |  |  |
| 36 | `match.sabotaged` | Sabotaged: can't attack for now | مخرَّب: ما بيقدر يضرب هلّق |  |  |  |
| 37 | `match.pinned` | Pinned! | مثبّت! |  |  |  |
| 38 | `match.ally` | Ally | حليف |  |  |  |
| 39 | `match.lantern_out` | Lantern out: no hidden thieves revealed | الفانوس مطفي: ما في كشف للحرامية |  |  |  |
| 40 | `match.wave_start` | Wave {n} | موجة {n} |  |  |  |
| 41 | `match.boss_wave` | {boss} is coming! | {boss} جاي! |  |  |  |
| 42 | `match.summon` | {boss} calls {n} × {enemy}! | {boss} نادى {n} × {enemy}! |  |  |  |
| 43 | `match.gate_closing` | The watchman bars the gate. Hold the lane! | الناطور سكّر الباب. صمّدوا يا رجال الحارة! | STYLE: «صمّدوا» → «اصمدوا». |  |  |
| 44 | `match.gate_breached` | The gate took a hit! | الباب أكل ضربة! |  |  |  |
| 45 | `match.victory` | The lane is safe! | الحارة بأمان! |  |  |  |
| 46 | `match.defeat` | The gate has fallen… | وقع الباب… |  |  |  |
| 47 | `match.waves_held` | Waves held: {n} | موجات صمّدتوها: {n} | STYLE: «موجات صمّدتوها: {n}» is awkward. Suggest «صمدتوا {n} موجة». |  |  |
| 48 | `match.rewards` | Rewards | الجوائز |  |  |  |
| 49 | `match.first_clear` | First clear bonus ×2 | أول مرة بتخلّصها: ×٢ |  |  |  |
| 50 | `match.back` | Back to the lane | رجوع للحارة |  |  |  |
| 51 | `match.vote_skip` | {name} voted to skip | {name} صوّت للتخطّي |  |  |  |
| 52 | `match.shabriyeh` | Shabriyeh! | يا شبرية! | MEANING: «يا شبرية!» as a battle-cry reads oddly (vocative to a dagger). Reviewer: is there a natural shout, or just «شبرية!»? |  |  |
| 53 | `match.camera_overhead` | Watchtower view | منظر البرج |  |  |  |
| 54 | `match.camera_walk` | Walk | مشي |  |  |  |
| 55 | `match.view_tower` | Tower | البرج |  |  |  |
| 56 | `match.view_walk` | Walk | مشي |  |  |  |
| 57 | `match.skip_votes` | {n}/{total} | {n}/{total} |  |  |  |
| 58 | `match.menu` | Menu | القائمة |  |  |  |
| 59 | `match.leave_confirm` | Leave the match? | بدك تطلع من المعركة؟ |  |  |  |
| 60 | `match.leave_back` | Stay | خليك |  |  |  |
| 61 | `match.place_confirm` | Place | حطّ |  |  |  |
| 62 | `match.place_cost` | ${n} | ${n} |  |  |  |
| 63 | `match.place_touch` | Drag to aim {unit}, then press Place | اسحب لتختار مطرح {unit}، وبعدين كبس حطّ |  |  |  |
| 64 | `match.err.on_path` | Not on the road. | مش على الطريق. | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «مو على الطريق». |  |  |
| 65 | `match.err.too_close` | Too close to another defender. | قريب كتير من واحد تاني. |  |  |  |
| 66 | `match.err.cannot_afford` | Not enough cash. | ما معك مصاري كفاية. |  |  |  |
| 67 | `match.err.unit_cap` | You placed the maximum of this unit. | حطّيت أكبر عدد من هالرجّال. | STYLE: «أكبر عدد من هالرجّال» → «الحدّ الأقصى من هالمدافع» (see hud.units). |  |  |
| 68 | `match.err.tower_cap` | You placed the maximum number of defenders. | حطّيت أكبر عدد من المدافعين. |  |  |  |
| 69 | `match.err.out_of_bounds` | Outside the arena. | برّا الساحة. |  |  |  |
| 70 | `match.err.not_in_loadout` | Not in your loadout. | مش بتشكيلتك. | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «مو بتشكيلتك». |  |  |
| 71 | `match.err.max_level` | Already at max level. | وصل لأعلى مستوى. |  |  |  |
| 72 | `match.err.match_over` | The match is over. | خلصت الجولة. |  |  |  |
| 73 | `match.err.fast_pass` | 3x speed needs the Fast Mode pass. | سرعة 3x بدها بطاقة السرعة. | STYLE: Latin «3x» mixed into Arabic (see general note 3). |  |  |
| 74 | `match.replay` | Replay | عيدها |  |  |  |
| 75 | `match.next` | Next | اللي بعدها |  |  |  |
| 76 | `match.replay_waiting` | Waiting for the team… | عم نستنى الشلّة… |  |  |  |
| 77 | `match.ult_auto` | Auto | تلقائي |  |  |  |
| 78 | `match.err.ult_not_ready` | The ultimate is still recovering. | الضربة الكبرى لسا عم ترتاح. |  |  |  |
| 79 | `match.wave_cleared` | Wave {n} cleared! | خلصت الموجة {n}! |  |  |  |
| 80 | `match.wave_bonus` | +{n} cash | +{n} مصاري |  |  |  |
| 81 | `match.err.bad_path` | Choose a level-7 path. | اختار طريق المستوى ٧. |  |  |  |

## 10. Enemies

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `enemy.gendarme.name` | Gendarme | دركي |  |  |  |
| 2 | `enemy.thief.name` | Night thief | حرامي الليل |  |  |  |
| 3 | `enemy.bandit.name` | Orchard bandit | قاطع طريق |  |  |  |
| 4 | `enemy.thug.name` | Rival-lane thug | زعران الحارة التانية | MEANING: «زعران» is plural for a single enemy. Suggest «أزعر من الحارة التانية». |  |  |
| 5 | `enemy.rider.name` | Mounted officer | ضابط خيّال |  |  |  |
| 6 | `enemy.sapper.name` | Sapper | نقّاب | STYLE: «نقّاب» (digger) for Sapper; reviewer to confirm or suggest «لغّام». |  |  |
| 7 | `enemy.spy.name` | Al-Nimr | النمر |  |  |  |
| 8 | `enemy.sergeant.name` | The Sergeant | الشاويش |  |  |  |
| 9 | `enemy.chief_thief.name` | Al-Adashari | العدشري |  |  |  |
| 10 | `enemy.rival_zaim.name` | Abu al-Nahr | أبو النهر |  |  |  |
| 11 | `enemy.colonel.name` | The Commandant | القومندان |  |  |  |
| 12 | `enemy.pickpocket.name` | Pickpocket | نشّال |  |  |  |
| 13 | `enemy.drummer.name` | Rival-lane Drummer | طبّال الحارة التانية |  |  |  |
| 14 | `enemy.torchbearer.name` | Torchbearer | مشعلجي |  |  |  |
| 15 | `enemy.porter.name` | Porter with a Crate | عتّال |  |  |  |
| 16 | `enemy.disguised.name` | A "Neighbour" | واحد من الحارة |  |  |  |
| 17 | `enemy.beggar.name` | False Beggar | شحّاد كذّاب |  |  |  |
| 18 | `enemy.corporal.name` | Corporal Houri | العريف حوري |  |  |  |
| 19 | `enemy.corporal_minion.name` | The Corporal's Gendarme | دركي العريف |  |  |  |
| 20 | `enemy.abu_jawdan.name` | Sergeant Abu Jawdan | الرقيب أبو جودان |  |  |  |
| 21 | `enemy.abu_shatour.name` | Abu Shatour | أبو شاطور |  |  |  |
| 22 | `enemy.lateef.name` | Lateef the "Blind" | لطيف "الأعمى" |  |  |  |
| 23 | `enemy.rifleman.name` | Tirailleur | بندقجي |  |  |  |
| 24 | `enemy.cart.name` | Donkey Cart | عربية حمار |  |  |  |
| 25 | `enemy.hakim_rival.name` | Rival-lane Hakim | حكيم الحارة التانية |  |  |  |
| 26 | `enemy.snake.name` | Grave Snake | حيّة القبر |  |  |  |
| 27 | `enemy.brute.name` | Rival-lane Brute | زكرت الحارة التانية |  |  |  |
| 28 | `enemy.fakhr.name` | Fakhr Abu al-Hokm | فخر أبو الحكم |  |  |  |
| 29 | `enemy.abu_zira.name` | Abu Zira' | أبو زراع |  |  |  |
| 30 | `enemy.rival_zaim_enraged.name` | Al-'Akeed Abu al-Nahr, enraged | العكيد أبو النهر، معصّب |  |  |  |

## 11. Defender roster, rarities, roles and traits

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `unit.walad.name` | Lane Boy | ولد الحارة |  |  |  |
| 2 | `unit.walad.desc` | Quick with a sling and quicker with excuses. Cheap, plentiful, everywhere at once. | سريع بالمقلاع وأسرع بالأعذار. رخيص وكتير وبكل مكان. |  |  |  |
| 3 | `unit.natour.name` | Abu Hares the Watchman | أبو حارس الناطور | NAME: Abu Fares is also a minor name in the TV series (COPYRIGHT_REGISTER C-013). Reviewer: does it evoke that show? If yes, propose a swap. |  |  |
| 4 | `unit.natour.desc` | Bars the gate every night. His lantern reveals night thieves to every defender in its light and slows anyone it shines on. | بيسكّر الباب كل ليلة. فانوسه بيكشف الحرامية لكل مدافع بضوّه وبيبطّئ كل مين بيوقع عليه الضو. |  |  |  |
| 5 | `unit.qabilah.name` | Umm Baki the Midwife | أم باقي الداية |  |  |  |
| 6 | `unit.hummus.name` | Abu Samih the Hummus Seller | أبو سميح بيّاع الحمّص |  |  |  |
| 7 | `unit.hummus.desc` | Hummus, fava and gossip from one brass pot. Every rascal who falls near his cart pays for the bowl. | حمّص وفول وأخبار من نفس الجرّة النحاس. كل أزعر بيوقع جنب عربيته بيدفع حق الصحن. |  |  |  |
| 8 | `unit.iskafi.name` | Abu Hamoud the Cobbler | أبو حمود الإسكافي |  |  |  |
| 9 | `unit.iskafi.desc` | Small, bent and never short of nails. He scatters them on the road, and whoever steps on them limps. | زغير ومحني وما بيخلص عنده المسامير. بيرشّها عالطريق، واللي بيدعس عليها بيعرج. |  |  |  |
| 10 | `unit.hammam.name` | Abu Basim of the Hammam | أبو باسم صاحب الحمّام |  |  |  |
| 11 | `unit.hammam.desc` | Opens the bathhouse doors and the steam rolls out: the crowd slows, and the fire on the gate hisses out. | بيفتح باب الحمّام وبيطلع البخار: الجمهرة بتبطّئ، والنار عالباب بتنطفي. |  |  |  |
| 12 | `unit.matriarch.name` | Su'da Khanum | سعدى خانم |  |  |  |
| 13 | `unit.matriarch.desc` | The lane's matriarch. When she cries out, the whole road stops to listen. | كبيرة الحارة. لما بتصرخ، الطريق كله بيوقف يسمع. |  |  |  |
| 14 | `unit.hammam.sig.scald.name` | Scalding Steam | بخار حامي |  |  |  |
| 15 | `unit.hammam.sig.scald.desc` | Each cloud takes two burn stacks off the gate. | كل غيمة بتطفي جمرتين عن الباب. |  |  |  |
| 16 | `unit.hammam.sig.fog.name` | Thick Fog | ضباب كثيف |  |  |  |
| 17 | `unit.hammam.sig.fog.desc` | The steam slows the crowd to a crawl. | البخار بيخلّي الجمهرة تزحف زحف. |  |  |  |
| 18 | `unit.matriarch.sig.wail.name` | The Long Wail | الصرخة الطويلة |  |  |  |
| 19 | `unit.matriarch.sig.wail.desc` | The Cry carries further down the road. | الصرخة بتوصل لأبعد عالطريق. |  |  |  |
| 20 | `unit.matriarch.sig.silence.name` | Dead Silence | سكوت تام |  |  |  |
| 21 | `unit.matriarch.sig.silence.desc` | Whoever hears The Cry stands frozen longer. | اللي بيسمع الصرخة بيضل متجمّد أطول. |  |  |  |
| 22 | `unit.qabilah.desc` | She has brought half the lane into the world and knows every face in it. Her little lamp shows who is hiding and who is only pretending to be a neighbour. | خلّفت نص الحارة بإيديها وبتعرف كل وجه فيها. سراجها الزغير بيبيّن مين مخبّى ومين عامل حاله جار. |  |  |  |
| 23 | `unit.farran.name` | Abu Baseer the Baker | أبو بصير الفرّان |  |  |  |
| 24 | `unit.farran.desc` | Hurls loaves straight from the oven. Hits a whole group at once. | بيرمي الأرغفة من الفرن مباشرة. بيضرب مجموعة كاملة بضربة. | STYLE: MSA «الأرغفة … مباشرة». Colloquial «بيرمي الرغفان طازة من الفرن». |  |  |
| 25 | `unit.saqqa.name` | Fawza | فوزة |  |  |  |
| 26 | `unit.saqqa.desc` | Abu Bader's wife, and nobody's fool. One sweep of her broom and the whole road gets out of the way. | مرت أبو بادر، وما حدا بيضحك عليها. ضربة مكنسة وحدة والطريق كله بيوسّع. |  |  |  |
| 27 | `unit.hallaq.name` | Hissam, the Barber's Son | حسام ابن أبو حسام |  |  |  |
| 28 | `unit.hallaq.desc` | Abu Hissam's eldest and his apprentice at the chair. Calm hands, sharp razor, never leaves his father's side. | الابن الكبير لأبو حسام وصانعه بالدكان. إيد هادية وموس حاد، وما بيترك جنب أبوه. |  |  |  |
| 29 | `unit.khayyat.name` | Abu Ghadeb the Chickpea Seller | أبو غاضب بيّاع البليلة |  |  |  |
| 30 | `unit.khayyat.desc` | Sells hot chickpeas and hotter gossip. Throws both further than anyone in the lane. | بيبيع بليلة سخنة وحكي أسخن. وبيرمي الاتنين أبعد من أي حدا بالحارة. | DIALECT: «بيلضم الإبرة» — reviewer to confirm Damascene verb (some say «بيشكّ الإبرة»). |  |  |
| 31 | `unit.qahwaji.name` | Abu Hazem of the Coffee House | أبو حازم صاحب القهوة |  |  |  |
| 32 | `unit.qahwaji.desc` | Owner of the lane's coffee house, proud of every cup. Pays you cash at the end of every wave, and throws a tea glass at anyone who gets too close. | صاحب قهوة الحارة وفخور بكل فنجان. بيدفعلك مصاري بآخر كل موجة، وبيرمي كاسة شاي على كل مين بيقرّب. | STYLE: «بيقدّم» (serves) is flat; «بيضيّف» is the natural word for a coffee-house keeper. |  |  |
| 33 | `unit.qabaday.name` | Mo'ez | معز |  |  |  |
| 34 | `unit.qabaday.desc` | Abu Hissam's hot-headed younger son, who rose to be the lane's 'akeed. First to draw: every few seconds his shabriyeh strike deals massive damage. | ابن أبو حسام الزغير، الحامي اللي صار عكيد الحارة. أول مين بيسحب: كل كم ثانية ضربة شبريته بتعمل ضرر هائل. | STYLE: MSA «ضرر هائل». Alt «ضربة شبريته بتهدّ». |  |  |
| 35 | `unit.haddad.name` | Abu Shater the Blacksmith | أبو شاطر الحدّاد | NAME: Abu Khater is also a minor name in the TV series (C-013). Same question as Abu Fares. |  |  |
| 36 | `unit.haddad.desc` | One hammer blow stuns and shakes the whole road. | ضربة مطرقة وحدة بتدوّخ وبتهزّ الطريق كله. |  |  |  |
| 37 | `unit.mukhtar.name` | Abu Bader | أبو بادر |  |  |  |
| 38 | `unit.mukhtar.desc` | Loudest voice in the lane, bravest from behind a door. His shouting somehow makes the defenders near him hit harder. | أعلى صوت بالحارة وأشجع واحد ورا الباب. صياحه، ما حدا بيعرف كيف، بيخلّي المدافعين حدّه يضربوا أقوى. |  |  |  |
| 39 | `unit.zaim.name` | Za'im Abu Faleh | الزعيم أبو فالح |  |  |  |
| 40 | `unit.zaim.desc` | Elder and judge of the lane. Rarely draws the shabriyeh, and when he does, it ends the matter. | كبير الحارة وقاضيها. نادراً ما بيسحب الشبرية، وإذا سحبها خلصت القصة. |  |  |  |
| 41 | `unit.pahlawan.name` | The Strongman | البهلوان | MEANING (high): in modern Levantine «بهلوان» means acrobat/clown, not strongman. Historic Damascene 'pahlavan' wrestler sense may be lost on kids. Suggest «المصارع» or «أبو العضلات». Also banner.pahlawan.name. |  |  |
| 42 | `unit.pahlawan.desc` | Wrestler from the hammam. Sweeps the road clear with his bare arms. | مصارع الحمّام. بيكنّس الطريق بذراعيه. |  |  |  |
| 43 | `unit.umm_hara.name` | Abu Hissam, the Barber-Hakim | أبو حسام، الحلاق والحكيم |  |  |  |
| 44 | `unit.umm_hara.desc` | The lane's barber and its hakim. Between shaves he sets bones and mixes remedies: after every wave he patches the gate and steadies the men around him. | حلاق الحارة وحكيمها. بين الحلاقة والتانية بيجبّر وبيركّب الدوا: بعد كل موجة بيرمّم الباب وبيقوّي قلوب الرجال حواليه. |  |  |  |
| 45 | `unit.arada.name` | The 'Arada Troupe | فرقة العراضة |  |  |  |
| 46 | `unit.arada.desc` | Sword and shield dancers of the wedding procession. Their swing cuts a wide arc. | رقّاصين السيف والترس بالزفّة. ضربتهم بتقطع قوس واسع. | MEANING: «رقّاصين» (dancers) can sound belittling for 'arada performers; usual phrase «لعّيبة السيف والترس». |  |  |
| 47 | `unit.zaim_akbar.name` | Al-'Akeed Abu Shehan | العكيد أبو شهان |  |  |  |
| 48 | `unit.zaim_akbar.desc` | The 'akeed the whole lane swears by. One drawn shabriyeh and the road is silent. | العكيد اللي الحارة كلها بتحلف بإسمه. شبرية وحدة والطريق بيسكت. |  |  |  |
| 49 | `rarity.rare` | Rare | نادر |  |  |  |
| 50 | `rarity.epic` | Epic | ملحمي |  |  |  |
| 51 | `rarity.legendary` | Legendary | أسطوري |  |  |  |
| 52 | `rarity.mythic` | Mythic | خرافي |  |  |  |
| 53 | `rarity.secret` | Secret | سرّي |  |  |  |
| 54 | `role.melee` | Melee | قريب |  |  |  |
| 55 | `role.ranged` | Ranged | بعيد |  |  |  |
| 56 | `role.splash` | Area | منطقة | STYLE: «منطقة» (area) alone is unclear; alt «ضرب جماعي». |  |  |
| 57 | `role.support` | Support | دعم |  |  |  |
| 58 | `role.farm` | Income | دخل |  |  |  |
| 59 | `role.healer` | Repair | ترميم |  |  |  |
| 60 | `trait.steady.name` | Steady | ثابت |  |  |  |
| 61 | `trait.swift.name` | Swift | سريع |  |  |  |
| 62 | `trait.keen.name` | Keen-eyed | عينه قوية | MEANING: «عينه قوية» in Levantine usually means bold/cheeky, not sharp-sighted. Suggest «نظره حاد». |  |  |
| 63 | `trait.sharp.name` | Sharp | حاد |  |  |  |
| 64 | `trait.golden.name` | Golden hands | إيده دهب |  |  |  |
| 65 | `trait.hawk.name` | Hawk | صقر |  |  |  |
| 66 | `trait.zaim.name` | Za'im's blood | دم الزعيم |  |  |  |
| 67 | `trait.legend.name` | Legend | أسطورة |  |  |  |
| 68 | `trait.lantern.name` | Lantern | فانوس |  |  |  |
| 69 | `trait.fireproof.name` | Fireproof | ما بيحرق |  |  |  |
| 70 | `trait.miser.name` | Miser | بخيل |  |  |  |
| 71 | `trait.twin.name` | Twins | توأم |  |  |  |
| 72 | `unit.qabaday.sig.rage.name` | Rage | الغضب |  |  |  |
| 73 | `unit.qabaday.sig.rage.desc` | His shabriyeh comes every 8 s instead of 12. | ضربة الشبرية كل ٨ ثواني بدل ١٢. |  |  |  |
| 74 | `unit.qabaday.sig.guard.name` | Guard | الحراسة |  |  |  |
| 75 | `unit.qabaday.sig.guard.desc` | Every hit stuns for 0.3 s. | كل ضربة بتجمّد ٠٫٣ ثانية. |  |  |  |
| 76 | `unit.haddad.sig.anvil.name` | Anvil | السندان |  |  |  |
| 77 | `unit.haddad.sig.anvil.desc` | His stun lasts 1.4 s instead of 1. | التجميد بيطوّل ١٫٤ ثانية بدل ثانية. |  |  |  |
| 78 | `unit.haddad.sig.forge.name` | Forge | الكور |  |  |  |
| 79 | `unit.haddad.sig.forge.desc` | His splash grows from 7 to 9 studs. | الضربة بتوسع من ٧ لـ ٩. |  |  |  |
| 80 | `unit.mukhtar.sig.loud.name` | Loud | الصوت العالي |  |  |  |
| 81 | `unit.mukhtar.sig.loud.desc` | His boost rises from +65 % to +80 %. | التشجيع بيطلع من ٦٥٪ لـ ٨٠٪. |  |  |  |
| 82 | `unit.mukhtar.sig.brave.name` | Brave | الشجاع |  |  |  |
| 83 | `unit.mukhtar.sig.brave.desc` | He finally joins in: 6 damage every 1.2 s. | أخيراً بيضرب: ٦ ضرر كل ١٫٢ ثانية. |  |  |  |
| 84 | `unit.zaim.sig.judgment.name` | Judgment | الحكم |  |  |  |
| 85 | `unit.zaim.sig.judgment.desc` | His shabriyeh hits ×14 instead of ×10. | ضربة الشبرية ×١٤ بدل ×١٠. |  |  |  |
| 86 | `unit.zaim.sig.mercy.name` | Mercy | الرحمة |  |  |  |
| 87 | `unit.zaim.sig.mercy.desc` | His shabriyeh also slows the target by half for 3 s. | ضربة الشبرية كمان بتبطّئ الهدف للنص ٣ ثواني. |  |  |  |
| 88 | `unit.pahlawan.sig.iron.name` | Iron | الحديد |  |  |  |
| 89 | `unit.pahlawan.sig.iron.desc` | His sweep reaches 12 studs instead of 9. | الكنسة بتوصل ١٢ بدل ٩. |  |  |  |
| 90 | `unit.pahlawan.sig.pin.name` | Pin | التثبيت |  |  |  |
| 91 | `unit.pahlawan.sig.pin.desc` | His sweep stuns everything it hits for 1.5 s. | الكنسة بتجمّد كل اللي بتضربه ١٫٥ ثانية. |  |  |  |
| 92 | `unit.umm_hara.sig.hakim.name` | Hakim | الحكيم |  |  |  |
| 93 | `unit.umm_hara.sig.hakim.desc` | He mends the gate by 44 per wave instead of 32. | بيصلّح الباب ٤٤ بكل موجة بدل ٣٢. |  |  |  |
| 94 | `unit.umm_hara.sig.elder.name` | Elder | الكبير |  |  |  |
| 95 | `unit.umm_hara.sig.elder.desc` | His blessing rises from +45 % to +60 %. | البركة بتطلع من ٤٥٪ لـ ٦٠٪. |  |  |  |
| 96 | `unit.arada.sig.drums.name` | Drums | الطبول |  |  |  |
| 97 | `unit.arada.sig.drums.desc` | The troupe strikes 20 % faster. | الفرقة بتضرب أسرع بـ ٢٠٪. |  |  |  |
| 98 | `unit.arada.sig.swords.name` | Swords | السيوف |  |  |  |
| 99 | `unit.arada.sig.swords.desc` | Their swords flash: defenders in range see hidden and disguised attackers. | بريق السيوف: رجالك بالمدى بيشوفوا المخفيين والمتنكرين. |  |  |  |
| 100 | `unit.zaim_akbar.sig.akeed.name` | 'Akeed | العكيد |  |  |  |
| 101 | `unit.zaim_akbar.sig.akeed.desc` | His shabriyeh hits ×20 instead of ×15. | ضربة الشبرية ×٢٠ بدل ×١٥. |  |  |  |
| 102 | `unit.zaim_akbar.sig.rally.name` | Rally | النخوة |  |  |  |
| 103 | `unit.zaim_akbar.sig.rally.desc` | Defenders within 10 studs strike 10 % faster. | رجالك ضمن ١٠ بيضربوا أسرع بـ ١٠٪. |  |  |  |
| 104 | `unit.adashari.name` | Al-Adashari, the Night Guard | العدشري، حارس الليل |  |  |  |
| 105 | `unit.adashari.desc` | The thief who confessed. One arm, one lantern, one oath: the strongest enemy he marks takes 40 % more from everyone. (Secret: Episode 9 wins only) | الحرامي اللي اعترف. إيد وحدة، وفانوس واحد، ويمين واحد: أقوى عدو بيعلّم عليه بياخد ٤٠٪ زيادة من الكل. (سرّي: من انتصارات الحلقة ٩ بس) |  |  |  |
| 106 | `unit.adashari.sig.repentance.name` | Repentance | التوبة |  |  |  |
| 107 | `unit.adashari.sig.repentance.desc` | His oath marks two enemies at once. | يمينه بيعلّم على عدوّين مع بعض. |  |  |  |
| 108 | `unit.adashari.sig.warehouse.name` | Guard of the Warehouse | حارس البوايكية |  |  |  |
| 109 | `unit.adashari.sig.warehouse.desc` | Each blow puts out two burn stacks on the gate. | كل ضربة بتطفي حرقتين عن الباب. |  |  |  |

## 12. Units screen

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `units.title` | Your defenders | رجالك |  |  |  |
| 2 | `units.loadout` | Loadout ({n}/{max}) | التشكيلة ({n}/{max}) |  |  |  |
| 3 | `units.add` | Add to loadout | ضيف للتشكيلة |  |  |  |
| 4 | `units.remove` | Remove | شيل |  |  |  |
| 5 | `units.stars` | {n}★ | {n}★ |  |  |  |
| 6 | `units.copies` | Copies to next star: {n} | نسخ للنجمة الجاية: {n} |  |  |  |
| 7 | `units.trait` | Trait: {trait} | الصفة: {trait} |  |  |  |
| 8 | `units.reroll` | Reroll trait · 1 stone | غيّر الصفة · حجر واحد |  |  |  |
| 9 | `units.stones` | {n} trait stones | {n} حجر صفات |  |  |  |
| 10 | `units.empty` | Summon defenders to fill your lane. | استدعي رجال لتملّي حارتك. | STYLE: see hud.units («رجال»). |  |  |
| 11 | `units.loadout_full` | Loadout is full. | التشكيلة مليانة. |  |  |  |
| 12 | `units.rates` | Rates | النسب |  |  |  |
| 13 | `units.rates_title` | Trait reroll rates (this defender) | نسب تغيير الصفة (لهالرجل) |  |  |  |
| 14 | `units.rates_current` | (current) | (الحالية) |  |  |  |
| 15 | `units.rates_note` | If a reroll lands on the current trait it is rolled once more; these rates already include that. Shown rounded; they add up to 100%. | إذا طلعت نفس الصفة الحالية، بتنسحب مرة تانية؛ هالنسب محسوبة على هالأساس. النسب مقرّبة للعرض ومجموعها 100%. |  |  |  |
| 16 | `units.trait2` | 2nd trait: {trait} | الصفة التانية: {trait} |  |  |  |
| 17 | `units.trait2_empty` | 2nd trait: not rolled yet | الصفة التانية: لسّا ما انسحبت |  |  |  |
| 18 | `units.trait2_locked` | 2nd trait opens at {n}★ | الصفة التانية بتنفتح عند {n}★ |  |  |  |
| 19 | `units.reroll1` | Reroll 1st · 1 stone | غيّر الأولى · حجر |  |  |  |
| 20 | `units.reroll2` | Reroll 2nd · 1 stone | غيّر التانية · حجر |  |  |  |
| 21 | `units.rates_title2` | Second trait reroll rates (this defender) | نسب تغيير الصفة التانية (لهالرجل) |  |  |  |
| 22 | `units.rates_switch` | 1st / 2nd | الأولى / التانية |  |  |  |
| 23 | `units.signature` | Level 7 · choose one: | المستوى ٧ · اختار وحدة: |  |  |  |
| 24 | `units.beads` | {n} shabriyeh beads | {n} خرزات شبرية |  |  |  |
| 25 | `units.beads_title` | Beads | خرزات |  |  |  |
| 26 | `units.bead_empty` | Empty | فاضي |  |  |  |
| 27 | `units.bead_pick` | Slot {n}: thread a bead (1 bead) | الخانة {n}: لضم خرزة (خرزة وحدة) |  |  |  |
| 28 | `units.err.no_beads` | No beads yet: win Episode 5 or 7–9 on Hard. | ما عندك خرزات لسّا: اربح الحلقة ٥ أو ٧–٩ عالصعب. |  |  |  |
| 29 | `units.err.same_bead` | That bead is already on this slot. | هالخرزة أصلاً على هالخانة. |  |  |  |

## 13. Summon screen

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `summon.title` | Summon | استدعاء |  |  |  |
| 2 | `summon.banner` | Banner: {name} | اللافتة: {name} | STYLE: «اللافتة» (street sign) for a gacha banner. Arab players usually say «البانر». Also summon.rotates. |  |  |
| 3 | `summon.featured` | Featured | مميّز | STYLE: «مميّز» is also used for Premium. Suggest «بالواجهة» or «النجم» for Featured. |  |  |
| 4 | `summon.rotates` | New banner in {n} | لافتة جديدة بعد {n} |  |  |  |
| 5 | `summon.one` | Summon ×1 · {n} lira | استدعاء ×١ · {n} ليرة |  |  |  |
| 6 | `summon.x1` | Summon ×1 | استدعاء ×١ |  |  |  |
| 7 | `summon.x10` | Summon ×10 | استدعاء ×١٠ |  |  |  |
| 8 | `summon.ten` | Summon ×10 · {n} lira | استدعاء ×١٠ · {n} ليرة |  |  |  |
| 9 | `summon.rates` | Rates | النسب |  |  |  |
| 10 | `summon.rates_title` | Drop rates (this pull) | نسب الظهور (هالسحبة) |  |  |  |
| 11 | `summon.pity` | Guaranteed Legendary within {l} pulls ({a} left) · Mythic within {m} pulls ({b} left) | أسطوري مضمون خلال {l} سحبة (باقي {a}) · خرافي خلال {m} سحبة (باقي {b}) |  |  |  |
| 12 | `summon.new` | NEW | جديد |  |  |  |
| 13 | `summon.copy` | Copy | نسخة |  |  |  |
| 14 | `summon.again` | Again | كمان |  |  |  |
| 15 | `summon.no_lira` | Not enough lira. | ما معك ليرات كفاية. |  |  |  |
| 16 | `summon.get_lira` | Get lira | جيب ليرات |  |  |  |
| 17 | `summon.restricted` | Lira can't be bought in your region. Earn it from matches, dailies and codes. | ما فيك تشتري ليرات بمنطقتك. اجمعها من الجولات واليومي والأكواد. |  |  |  |
| 18 | `banner.zaim.name` | The Za'im returns | رجع الزعيم |  |  |  |
| 19 | `banner.pahlawan.name` | Night of the Strongman | ليلة البهلوان | MEANING: see unit.pahlawan.name. |  |  |
| 20 | `banner.umm_hara.name` | The Hakim of the Lane | حكيم الحارة |  |  |  |
| 21 | `summon.new_stamp` | NEW! | جديد! |  |  |  |

## 14. Lane Diary (season pass)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `pass.season.s1.name` | Lane Diary · Season 1: The Night Guard | دفتر الحارة · الموسم ١: الحارس الليلي |  |  |  |
| 2 | `pass.title` | Lane Diary | دفتر الحارة |  |  |  |
| 3 | `pass.level` | Level {n} | مستوى {n} |  |  |  |
| 4 | `pass.xp` | {n}/{total} XP | {n}/{total} خبرة |  |  |  |
| 5 | `pass.free` | Free | مجاني |  |  |  |
| 6 | `pass.premium` | Premium | مميّز |  |  |  |
| 7 | `pass.claim` | Claim | استلم |  |  |  |
| 8 | `pass.claimed` | Claimed | مستلَم |  |  |  |
| 9 | `pass.locked` | Locked | مقفول |  |  |  |
| 10 | `pass.buy_premium` | Unlock premium | افتح المميّز |  |  |  |
| 11 | `pass.skip` | Skip 10 levels | تخطّى ١٠ مستويات |  |  |  |
| 12 | `pass.ends` | Season ends in {n} days | الموسم بيخلص بعد {n} يوم | STYLE: plural agreement: «{n} يوم» is right for 11+ only (3–10 needs «أيام»). See general note 4. |  |  |
| 13 | `pass.reward.unit` | Unit: {unit} | رجّال: {unit} |  |  |  |

## 15. Codes, daily reward and reward labels

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `codes.title` | Codes | أكواد |  |  |  |
| 2 | `codes.hint` | Codes are posted on the community channels on update day. | الأكواد بتنزل على قنوات المجتمع يوم التحديث. |  |  |  |
| 3 | `codes.redeem` | Redeem | فعّل |  |  |  |
| 4 | `codes.placeholder` | ENTER CODE | اكتب الكود |  |  |  |
| 5 | `codes.ok` | Code redeemed! | تفعّل الكود! |  |  |  |
| 6 | `codes.unknown` | Unknown code. | كود مش معروف. |  |  |  |
| 7 | `codes.expired` | This code has expired. | هالكود خلص وقته. |  |  |  |
| 8 | `codes.already` | You already used this code. | استعملت هالكود من قبل. |  |  |  |
| 9 | `codes.match_only` | This code only works during a match. | هالكود بيشتغل بس جوّا المعركة. |  |  |  |
| 10 | `daily.title` | Daily reward | جائزة اليوم |  |  |  |
| 11 | `daily.day` | Day {n} | يوم {n} |  |  |  |
| 12 | `daily.claim` | Claim | استلم |  |  |  |
| 13 | `daily.claimed` | Come back tomorrow | ارجع بكرا | STYLE: spelled «بكرا» here, «بكرة» in dlg.hajj_rashid.busy. Pick one. |  |  |
| 14 | `daily.streak` | Streak: {n} days | متتالية: {n} يوم | STYLE: «متتالية: {n} يوم» is stiff. Suggest «صرلك {n} يوم ورا بعض». |  |  |
| 15 | `reward.lira` | +{n} lira | +{n} ليرة |  |  |  |
| 16 | `reward.qirsh` | +{n} qirsh | +{n} قرش |  |  |  |
| 17 | `reward.xp` | +{n} XP | +{n} خبرة |  |  |  |
| 18 | `reward.stones` | +{n} trait stone(s) | +{n} حجر صفات |  |  |  |
| 19 | `reward.item` | {item} | {item} |  |  |  |
| 20 | `reward.unit` | {unit} | {unit} |  |  |  |
| 21 | `reward.units` | +{n} new defenders | +{n} رجال جدد |  |  |  |
| 22 | `reward.cash` | +{n} cash | +{n} مصاري |  |  |  |

## 16. Lobby NPCs (tower-defense square)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `npc.barber.name` | Abu Hissam | أبو حسام |  |  |  |
| 2 | `npc.barber.role` | Barber | حلاق | STYLE: no article («حلاق», «قهوجي») while older roles use one («الفرّان», «الخيّاط»). Make consistent. |  |  |
| 3 | `npc.qahwaji.name` | Abu Hazem | أبو حازم |  |  |  |
| 4 | `npc.qahwaji.role` | Coffee-house keeper | قهوجي |  |  |  |
| 5 | `npc.natour.name` | Abu Hares | أبو حارس | NAME: see unit.natour.name. |  |  |
| 6 | `npc.natour.role` | Night watchman | ناطور الحارة |  |  |  |
| 7 | `dlg.barber.greet` | Sit, sit! A shave, a trim, and all the news of the lane for free. They say thieves are testing the gate at night… | اقعد اقعد! حلاقة وتزيين وأخبار الحارة كلها ببلاش. بيقولوا في حرامية عم يجرّبوا الباب بالليل… |  |  |  |
| 8 | `dlg.barber.greet.ok` | Then I'd better go defend it. | لكان أحسن روح دافع عنه. | STYLE: «لكان أحسن روح دافع عنه» is a bit clipped; alt «لكان لازم روح دافع عنه». |  |  |
| 9 | `dlg.qahwaji.greet` | Tea or coffee? Sit by the fountain. The men gather here before the gate closes. | شاي ولا قهوة؟ اقعد جنب البحرة. الرجال بيتجمّعوا هون قبل ما يتسكّر الباب. |  |  |  |
| 10 | `dlg.qahwaji.greet.ok` | Later, Abu Hazem. | بعدين يا أبو حازم. |  |  |  |
| 11 | `dlg.natour.greet` | After the evening prayer I bar this gate, and nobody enters without a name. Want to help hold it? The Play arch is in the square. | بعد صلاة العشا بسكّر هالباب وما حدا بيفوت بلا اسم. بدك تساعد تصمّده؟ قوس اللعب بالساحة. | STYLE: «بدك تساعد تصمّده؟» awkward (see «صمّد» note); «البوابات» = portals collides with the gate word. Alt «بدك تساعدنا نحميه؟ نقاط التجمّع بالساحة». |  |  |
| 12 | `dlg.natour.greet.ok` | I'll be there. | جاي. |  |  |  |
| 13 | `dlg.qahwaji.greet.hakawati` | Is the hakawati upstairs? | الحكواتي فوق؟ |  |  |  |
| 14 | `dlg.qahwaji.hakawati` | Abu Tawfiq? He never leaves! Take the stairs at the back. Sit, drink, listen. My tea pays while you rest. | أبو توفيق؟ ما بيطلع من هون! اطلع عالدرج اللي بالآخر. اقعد واشرب واسمع. شايي بيعطيك وإنت مرتاح. |  |  |  |
| 15 | `dlg.qahwaji.hakawati.go` | Take me up | طلّعني |  |  |  |

## 17. World signs (3D text in the lane)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `sign.lane` | حارة الياسمين | حارة الياسمين |  |  |  |
| 2 | `sign.bakery` | فرن أبو نديم | فرن أبو نديم |  |  |  |
| 3 | `sign.tailor` | خياطة خليل | خياطة خليل | STYLE: «خياطة خليل» = 'Khalil's sewing'. Shop sign alt «خيّاط خليل» or «محل خليل الخيّاط». Same text in shop.khalil_tailor.title. |  |  |
| 4 | `sign.spice` | عطارة الحاج رشيد | عطارة الحاج رشيد |  |  |  |
| 5 | `sign.barber` | حلاق الحارة | حلاق الحارة |  |  |  |
| 6 | `sign.coffee` | قهوة الحارة | قهوة الحارة |  |  |  |
| 7 | `sign.board` | لوحة الحارة | لوحة الحارة |  |  |  |

## 18. Other screens (AFK room, settings, Play, story, events, touch HUD)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `settings.title` | Settings | الإعدادات |  |  |  |
| 2 | `settings.effects` | Effects | المؤثرات |  |  |  |
| 3 | `settings.effects.full` | Full | كاملة |  |  |  |
| 4 | `settings.effects.reduced` | Reduced | مخففة |  |  |  |
| 5 | `settings.effects.off` | Off | مطفأة |  |  |  |
| 6 | `settings.effects.hint` | Lower this if the game stutters on your phone. | خففها إذا اللعبة عم تعلّق عالموبايل. |  |  |  |
| 7 | `settings.skipSummon` | Summon animation | حركة الاستدعاء |  |  |  |
| 8 | `settings.camera` | Match camera | كاميرا المعركة |  |  |  |
| 9 | `settings.camera.walk` | On foot | مشي |  |  |  |
| 10 | `settings.camera.overhead` | Watchtower | البرج |  |  |  |
| 11 | `settings.autoUlt` | Auto ultimate | الضربة الكبرى تلقائياً |  |  |  |
| 12 | `settings.autoSkip` | Auto skip waves | تخطّي الانتظار تلقائياً |  |  |  |
| 13 | `settings.music` | Music | الموسيقى |  |  |  |
| 14 | `settings.cutscenes` | Boss intros | مقدمة الزعيم |  |  |  |
| 15 | `settings.sfx` | Sound effects | المؤثرات الصوتية |  |  |  |
| 16 | `settings.on` | On | شغّال |  |  |  |
| 17 | `settings.off` | Off | مطفي |  |  |  |
| 18 | `settings.show` | Show | اعرض |  |  |  |
| 19 | `settings.skip` | Skip | تخطّى |  |  |  |
| 20 | `play.hall` | PLAY | العب |  |  |  |
| 21 | `play.title` | Play | العب |  |  |  |
| 22 | `play.tab.story` | Story | القصة |  |  |  |
| 23 | `play.tab.infinite` | Endless | بلا نهاية |  |  |  |
| 24 | `play.tab.event` | Event | المناسبة |  |  |  |
| 25 | `play.waves` | {n} waves | {n} موجة |  |  |  |
| 26 | `play.waves_endless` | Endless waves | موجات بلا نهاية |  |  |  |
| 27 | `play.rewards` | Rewards | الجوائز |  |  |  |
| 28 | `play.first_clear` | First clear ×2 | أول فوز ×٢ |  |  |  |
| 29 | `play.enemies` | Enemies | الأعداء |  |  |  |
| 30 | `play.bosses` | Bosses | الزعماء |  |  |  |
| 31 | `play.create` | Create party | افتح شلّة |  |  |  |
| 32 | `play.start_now` | Start now | بلّش هلّق |  |  |  |
| 33 | `play.parties` | Open parties | شلل مفتوحة |  |  |  |
| 34 | `play.no_parties` | No open parties. Create one! | ما في شلل مفتوحة. افتح وحدة! |  |  |  |
| 35 | `play.join` | Join | انضم |  |  |  |
| 36 | `play.party_of` | {name}'s party | شلّة {name} |  |  |  |
| 37 | `play.cleared` | Cleared: {d} | انتصرت: {d} |  |  |  |
| 38 | `play.locked` | Locked | مقفول |  |  |  |
| 39 | `play.event_none` | No event is running right now. | ما في مناسبة هلّق. |  |  |  |
| 40 | `play.hint` | Walk into the Play arch or tap Play. | فوت من قوس اللعب أو كبس العب. |  |  |  |
| 41 | `play.soon` | Coming soon | قريباً |  |  |  |
| 42 | `play.soon_name` | Episode {n} · {title} | الحلقة {n} · {title} |  |  |  |
| 43 | `play.hakawati` | The Hakawati: | بيحكي الحكواتي: |  |  |  |
| 44 | `play.mechanics` | New here: | جديد هون: |  |  |  |
| 45 | `play.first_gift` | First {d} clear: | أول فوز {d}: |  |  |  |
| 46 | `play.secret` | Every win: {pct}% chance of {unit} | كل فوز: فرصة {pct}٪ لـ{unit} |  |  |  |
| 47 | `play.secret_pity` | Sure after {n} wins without him · the first Nightmare clear always brings him | أكيد بعد {n} فوز بدونه · وأول فوز بالكابوس بيجيبه دايماً |  |  |  |
| 48 | `mech.stealth` | Hidden thieves | حرامية مخفيين |  |  |  |
| 49 | `mech.armor` | Armour | دروع |  |  |  |
| 50 | `mech.fast` | Fast riders | خيّالة سريعين |  |  |  |
| 51 | `mech.sapper` | Wall breakers | هدّامين حيطان |  |  |  |
| 52 | `mech.swarm` | Swarms | أسراب |  |  |  |
| 53 | `mech.aura` | War drums | طبول |  |  |  |
| 54 | `mech.two_paths` | Two roads | طريقين |  |  |  |
| 55 | `mech.burn` | Fire | حريق |  |  |  |
| 56 | `mech.shield` | Shields | تروس |  |  |  |
| 57 | `mech.disguised` | Disguised | متنكّرين |  |  |  |
| 58 | `mech.teleport` | Sudden jumps | نطّات فجأة |  |  |  |
| 59 | `mech.sabotage` | Snipers | قنّاصة |  |  |  |
| 60 | `mech.summon` | Reinforcements | نجدات |  |  |  |
| 61 | `mech.split` | Splitting carts | عربيات بتنفلق |  |  |  |
| 62 | `mech.heal` | Healers | مداوين |  |  |  |
| 63 | `mech.ally` | An ally | حليف |  |  |  |
| 64 | `ult.qabaday` | Qabaday's Cry | صرخة القبضاي |  |  |  |
| 65 | `ult.zaim` | The Za'im's Word | كلمة الزعيم |  |  |  |
| 66 | `ult.pahlawan` | Strongman's Spin | دورة البهلوان |  |  |  |
| 67 | `ult.arada` | Sword-and-Shield Dance | رقصة السيف والترس |  |  |  |
| 68 | `ult.zaim_akbar` | The 'Akeed's Charge | هجمة العكيد |  |  |  |
| 69 | `ult.matriarch` | The Cry | الصرخة |  |  |  |
| 70 | `ult.adashari` | The Oath | اليمين |  |  |  |
| 71 | `afk.room` | The Hakawati's Room | مجلس الحكواتي |  |  |  |
| 72 | `afk.intro` | Upstairs in the coffee house the storyteller tells the old tales all night. Sit and listen: every {min} minutes he pours a cup of tea that pays {cup}, and every finished tale pays {tale} more. Up to {cap} lira a day; after that the tea still pays a little qirsh. Your time is kept if you leave or lose connection. | بالطابق الفوقاني من القهوة الحكواتي بيحكي الحكايات القديمة طول الليل. اقعد واسمع: كل {min} دقايق بيصبّلك كاسة شاي فيها {cup}، وكل حكاية بتخلص إلها {tale} زيادة. لحد {cap} ليرة باليوم، وبعدها الشاي بيضل يعطي شوية قروش. وقتك محفوظ إذا طلعت أو انقطع النت. |  |  |  |
| 73 | `afk.intro.mult` | Your bonus: ×{mult} pay and lira cap. | مكافأتك: ×{mult} عالجائزة وعالحد. |  |  |  |
| 74 | `afk.intro.vip` | VIP doubles the pay and the cap; Roblox Premium adds half. | الـVIP بيضاعف الجائزة والحد، وبريميوم روبلوكس بيزيد النص. |  |  |  |
| 75 | `afk.today` | Today {n} / {cap} lira | اليوم {n} / {cap} ليرة |  |  |  |
| 76 | `afk.enter` | Go upstairs | اطلع لفوق |  |  |  |
| 77 | `afk.leave` | Back to the lane | ارجع عالحارة |  |  |  |
| 78 | `afk.next_cup` | Next cup in {t} | الكاسة الجاية بعد {t} |  |  |  |
| 79 | `afk.tale` | {tale} · part {n} of {total} | {tale} · الجزء {n} من {total} |  |  |  |
| 80 | `afk.session` | This visit {t} | هالقعدة {t} |  |  |  |
| 81 | `afk.capped` | Today's lira are in. The tea still pays qirsh. | ليرات اليوم اكتملت. الشاي بيضل يعطي قروش. |  |  |  |
| 82 | `afk.bonus` | ×{mult} bonus | مكافأة ×{mult} |  |  |  |
| 83 | `afk.cup` | A cup of tea: {reward} | كاسة شاي: {reward} |  |  |  |
| 84 | `afk.tale_done` | The tale of {tale} is over: {reward} | خلصت حكاية {tale}: {reward} |  |  |  |
| 85 | `afk.summary` | You sat {t} with the hakawati: {reward} | قعدت {t} عند الحكواتي: {reward} |  |  |  |
| 86 | `afk.summary.none` | You sat {t} with the hakawati. | قعدت {t} عند الحكواتي. |  |  |  |
| 87 | `afk.welcome_back` | Your seat was kept. The tale goes on. | محلّك محفوظ. والحكاية لسّا مكمّلة. |  |  |  |
| 88 | `afk.hop` | Pouring you a fresh cup… | عم نصبّلك كاسة جديدة… |  |  |  |
| 89 | `afk.hop_studio` | (Studio) The anti-idle hop only runs in a live server. | (ستوديو) قفزة منع الخمول بتشتغل بس بسيرفر حقيقي. |  |  |  |
| 90 | `afk.hop_failed` | Couldn't refresh your seat. Move a little so Roblox doesn't think you've left. | ما قدرنا نجدّد محلّك. تحرّك شوي لحتى روبلوكس ما يفكّرك رحت. |  |  |  |
| 91 | `afk.idle_moved` | You looked tired, so we walked you up to the hakawati. | شكلك تعبان، فطلّعناك عند الحكواتي. |  |  |  |
| 92 | `afk.err.in_match` | Finish your match first. | خلّص معركتك أوّل. |  |  |  |
| 93 | `afk.err.not_loaded` | Still loading, try again in a moment. | لسّا عم يحمّل، جرّب كمان شوي. |  |  |  |
| 94 | `afk.err.no_character` | Wait until you're back on your feet. | استنى لترجع توقف على رجليك. |  |  |  |
| 95 | `afk.err.in_afk` | You're upstairs with the hakawati. Come back down first. | إنت فوق عند الحكواتي. انزل أوّل. |  |  |  |
| 96 | `settings.autoAfk` | Idle → hakawati | الخمول ← الحكواتي |  |  |  |
| 97 | `settings.uiScale` | UI size | حجم الواجهة |  |  |  |
| 98 | `settings.uiScale.small` | Small | صغير |  |  |  |
| 99 | `settings.uiScale.default` | Normal | عادي |  |  |  |
| 100 | `settings.uiScale.large` | Large | كبير |  |  |  |
| 101 | `settings.uiScale.huge` | Huge | كبير كتير |  |  |  |
| 102 | `settings.panelSide` | Defender panel | لوحة المدافع |  |  |  |
| 103 | `settings.panelSide.auto` | Auto | تلقائي |  |  |  |
| 104 | `settings.panelSide.side` | Side | جنب |  |  |  |
| 105 | `settings.panelSide.bottom` | Bottom | تحت |  |  |  |
| 106 | `settings.quickPlace` | Tap to place | حطّ بكبسة |  |  |  |
| 107 | `settings.railSide` | Buttons side | جهة الأزرار |  |  |  |
| 108 | `settings.railSide.right` | Right | يمين |  |  |  |
| 109 | `settings.railSide.left` | Left | يسار |  |  |  |
| 110 | `settings.language` | Language | اللغة |  |  |  |
| 111 | `settings.language.en` | English | English |  |  |  |
| 112 | `settings.language.ar` | عربي | عربي |  |  |  |
| 113 | `npc.hakawati.name` | Abu Tawfiq | أبو توفيق |  |  |  |
| 114 | `npc.hakawati.role` | Hakawati (storyteller) | حكواتي |  |  |  |
| 115 | `dlg.hakawati.greet` | Sit, sit, the tea is coming. Every cup a little more of the tale. Stay as long as you like; your seat is yours. | اقعد اقعد، الشاي جاي. كل كاسة شوية من الحكاية. اقعد قدّ ما بدّك، المحل محلّك. |  |  |  |
| 116 | `dlg.hakawati.greet.ok` | Go on, Abu Tawfiq. | كمّل يا أبو توفيق. |  |  |  |
| 117 | `afk.tale.antar` | Antar and Abla | عنترة وعبلة |  |  |  |
| 118 | `afk.tale.baybars` | Al-Zahir Baybars | الظاهر بيبرس |  |  |  |
| 119 | `afk.tale.hilali` | The Banu Hilal | تغريبة بني هلال |  |  |  |
| 120 | `afk.tale.zir` | Al-Zir Salem | الزير سالم |  |  |  |
| 121 | `afk.tale.sayf` | Sayf ibn Dhi Yazan | سيف بن ذي يزن |  |  |  |
| 122 | `afk.tale.lane` | The Night the Gate Held | ليلة صمد الباب |  |  |  |
| 123 | `afk.line.antar.1` | Antar was born a slave, but his sword had no master… | انولد عنترة عبد، بس سيفه ما إله سيّد… |  |  |  |
| 124 | `afk.line.antar.2` | For one look from Abla he would ride against a thousand horsemen. | كرمال نظرة من عبلة كان يهجم على ألف فارس. |  |  |  |
| 125 | `afk.line.antar.3` | And the poets hung his verses where all Arabia could read them! | وعلّقوا شعره لتقراه كل العرب! |  |  |  |
| 126 | `afk.line.baybars.1` | A boy sold in the slave market of Damascus, listen well… | ولد انباع بسوق الشام، اسمعوا منيح… |  |  |  |
| 127 | `afk.line.baybars.2` | He put on a beggar's cloak and walked among his enemies unseen. | لبس عباية شحّاد ومشي بين أعداؤه وما حدا عرفه. |  |  |  |
| 128 | `afk.line.baybars.3` | And the city that sold him crowned him sultan. | والمدينة اللي باعته، توّجته سلطان. |  |  |  |
| 129 | `afk.line.hilali.1` | The tribe of Hilal packed their tents and rode west… | بنو هلال لمّوا خيامهم ومشيوا عالغرب… |  |  |  |
| 130 | `afk.line.hilali.2` | Abu Zayd, dark as night and brave as noon, went ahead as a spy. | أبو زيد، أسمر متل الليل وشجاع متل الضهر، سبقهم جاسوس. |  |  |  |
| 131 | `afk.line.hilali.3` | A journey of a hundred years, and we are only at the first well! | رحلة مية سنة، ونحنا لسّا عند أوّل بير! |  |  |  |
| 132 | `afk.line.zir.1` | When Kulayb fell, his brother Salem swore an oath… | لما وقع كليب، حلف أخوه سالم يمين… |  |  |  |
| 133 | `afk.line.zir.2` | Forty years of war, my friends, for one she-camel! | أربعين سنة حرب يا جماعة، كرمال ناقة وحدة! |  |  |  |
| 134 | `afk.line.zir.3` | Revenge is a cup that never empties. Pour him more tea! | التار كاسة ما بتفضى. صبّولو شاي! |  |  |  |
| 135 | `afk.line.sayf.1` | King Sayf rode into the lands of the jinn… | الملك سيف دخل بلاد الجن… |  |  |  |
| 136 | `afk.line.sayf.2` | A sorceress, a magic tablet, and a river that flows uphill. | ساحرة، ولوح مسحور، ونهر بيمشي لفوق. |  |  |  |
| 137 | `afk.line.sayf.3` | Don't fall asleep! The best part is coming. | لا تنامو! الأحلى جاي. |  |  |  |
| 138 | `afk.line.lane.1` | One winter night the thieves came to our very gate… | بليلة شتوية وصلوا الحرامية لعند بابنا… |  |  |  |
| 139 | `afk.line.lane.2` | The watchman barred it, and the men of the lane stood shoulder to shoulder. | الناطور سكّره، ورجال الحارة وقفوا كتف بكتف. |  |  |  |
| 140 | `afk.line.lane.3` | Until dawn not one of them passed. And that is why we bar it still. | لحد الفجر ما مرق ولا واحد. وكرمال هيك لسّا منسكّره. |  |  |  |
| 141 | `event.title` | Event | المناسبة |  |  |  |
| 142 | `event.olive_harvest.name` | Olive Harvest Nights | ليالي موسم الزيتون |  |  |  |
| 143 | `event.olive_harvest.desc` | Bandits are raiding the olive harvest in the orchards. Hold the road and earn olives for the harvest shop. | الحرامية عم يغزوا موسم الزيتون بالبساتين. صمّد عالطريق واجمع زيتون لدكان الموسم. |  |  |  |
| 144 | `event.olive_harvest.currency` | {n} olives | {n} زيتونة |  |  |  |
| 145 | `event.olive_harvest.rewards` | olives every wave, +25 for a full harvest | زيتون كل موجة، و+٢٥ إذا صمّدت للآخر |  |  |  |
| 146 | `event.play` | Play the event | العب المناسبة |  |  |  |
| 147 | `event.left_dh` | {d}d {h}h left | باقي {d} يوم و{h} ساعة |  |  |  |
| 148 | `event.left_hm` | {h}h {m}m left | باقي {h} ساعة و{m} دقيقة |  |  |  |
| 149 | `event.stock` | {n}/{max} left | باقي {n}/{max} |  |  |  |
| 150 | `event.owned` | owned | عندك ياها |  |  |  |
| 151 | `event.sold_out` | Sold out | خلص |  |  |  |
| 152 | `event.bought` | Bought: {item} | اشتريت: {item} |  |  |  |
| 153 | `event.over` | This event has ended. | المناسبة خلصت. |  |  |  |
| 154 | `event.err.not_enough` | Not enough olives yet. | ما معك زيتون كفاية. |  |  |  |
| 155 | `event.err.sold_out` | Sold out for this event. | خلص بهالمناسبة. |  |  |  |
| 156 | `event.shop.qirsh_400` | 400 qirsh | ٤٠٠ قرش |  |  |  |
| 157 | `event.shop.lira_120` | 120 lira | ١٢٠ ليرة |  |  |  |
| 158 | `event.shop.stone_1` | 1 trait stone | حجر صفة واحد |  |  |  |
| 159 | `event.shop.shawl` | Embroidered shawl | شال مطرّز |  |  |  |
| 160 | `story.season.title` | Season Story 1 · The Night Guard | حكاية الموسم ١ · الحارس الليلي |  |  |  |
| 161 | `story.cart.name` | Pickle cart | عربية المخلّل |  |  |  |
| 162 | `story.cart.prompt` | Look | اتفرّج |  |  |  |
| 163 | `story.cart.1` | A pickle cart by the gate. Long ago the za'im lent a hard man the money to push it. | عربية مخلّل جنب الباب. من زمان الزعيم ديّن زلمة قاسي مصاري ليدفشها. |  |  |  |
| 164 | `story.cart.2` | By day he sold pickles from it. By night he walked the roofs. | بالنهار كان يبيع منها مخلّل، وبالليل يمشي عالسطوح. |  |  |  |
| 165 | `story.cart.3` | Its wheels still turn. Some say the man who owned it guards this gate now. | دواليبها لسّا بتدور. وفي ناس بتقول صاحبها صار يحرس هالباب. |  |  |  |
| 166 | `afk.tales` | Tales | حكايات |  |  |  |
| 167 | `afk.tales_title` | The Hakawati's tales | حكايات الحكواتي |  |  |  |
| 168 | `afk.tale_locked` | Clear Episode {n} to hear this tale. | اربح الحلقة {n} لتسمع هالحكاية. |  |  |  |
| 169 | `story.ep1.title` | Night of the Thieves | ليلة الحرامية |  |  |  |
| 170 | `story.ep1.intro.1` | Gather round. In the lane of jasmine, the cloth merchant's gold vanished in one night. | يا سادة يا كرام، بحارة الياسمين راح دهب تاجر القماش بليلة وحدة. |  |  |  |
| 171 | `story.ep1.intro.2` | The watchman saw a shadow at the gate, lifted his lantern… and was never seen again. | الناطور شاف خيال عند الباب، رفع فانوسه… وما حدا شافه بعدها. |  |  |  |
| 172 | `story.ep1.intro.3` | Tonight the thieves come back for more. Hold the gate until dawn. | الليلة الحرامية راجعين لياخدوا أكتر. امسكوا الباب للصبح. |  |  |  |
| 173 | `story.ep1.outro.1` | Dawn came, and the gate still stood. | طلع الضو، والباب بعدو واقف. |  |  |  |
| 174 | `story.ep1.outro.2` | The gold was gone, and so was the watchman. Only his lantern lay in the dust. | الدهب راح، والناطور كمان. بس فانوسه ضلّ مرمي بالتراب. |  |  |  |
| 175 | `story.ep1.outro.3` | And one man in the lane slept badly that night. Remember him. | وفي زلمة بالحارة ما غمّض عينه هديك الليلة. تذكّروه. |  |  |  |
| 176 | `story.ep2.title` | The Rival Lane | الحارة التانية |  |  |  |
| 177 | `story.ep2.intro.1` | A man with a heavy secret moved his family to the next lane. | زلمة شايل سرّ تقيل نقل عيلته عالحارة التانية. |  |  |  |
| 178 | `story.ep2.intro.2` | There he whispered in their 'akeed's ear: "Jasmine Lane thinks it is better than you." | وهونيك وشوش بإدن عكيدها: "حارة الياسمين شايفة حالها أحسن منكن." |  |  |  |
| 179 | `story.ep2.intro.3` | Now their thugs march on our gate, and their 'akeed walks behind them. | وهلّق زعرانهن جايين عبابنا، وعكيدهن ماشي وراهن. |  |  |  |
| 180 | `story.ep2.outro.1` | The rival lane's men limped home, and their 'akeed swore he would return. | رجال الحارة التانية رجعوا عرجانين، وعكيدهن حلف ليرجع. |  |  |  |
| 181 | `story.ep2.outro.2` | Nobody asked who had lit the fire between the two lanes. | وما حدا سأل مين ولّع النار بين الحارتين. |  |  |  |
| 182 | `story.ep2.outro.3` | Nobody, except the Hakawati. Come back tomorrow. | ما حدا… غير الحكواتي. ارجعوا بكرا. |  |  |  |
| 183 | `story.ep3.title` | The Siege | الحصار |  |  |  |
| 184 | `story.ep3.intro.1` | The noise of the feud reached the garrison on the hill. | صوت العركة وصل للثكنة اللي عالتلّة. |  |  |  |
| 185 | `story.ep3.intro.2` | The commandant said: "If the lanes cannot keep order, my soldiers will." | القومندان قال: "إذا الحارات ما بتعرف تضبط حالها، عساكري بيضبطوها." |  |  |  |
| 186 | `story.ep3.intro.3` | Sappers at the walls, riders at the gate. This is a siege. | لغّامة عالحيطان وخيّالة عالباب. هاد حصار. |  |  |  |
| 187 | `story.ep3.outro.1` | The commandant rode away, his boots heavy with our mud. | القومندان مشي، وجزمته تقيلة من طين حارتنا. |  |  |  |
| 188 | `story.ep3.outro.2` | The lane counted its doors, its jars and its children. All there. | الحارة عدّت بوابها وجرارها وولادها. كلّن موجودين. |  |  |  |
| 189 | `story.ep3.outro.3` | But the gold of the first night was still missing. Patience. | بس دهب أول ليلة بعدو ضايع. طوّلوا بالكن. |  |  |  |
| 190 | `story.ep4.title` | The Lost Shoe | الصرماية |  |  |  |
| 191 | `story.ep4.intro.1` | Pickpockets poured into the square like sparrows, and the drums came after them. | النشّالة فاضوا عالساحة متل العصافير، ووراهن الطبول. |  |  |  |
| 192 | `story.ep4.intro.2` | The gendarmes came too, searching every house for the stolen gold. | وإجوا الدرك كمان، يفتّشوا كل بيت عالدهب المسروق. |  |  |  |
| 193 | `story.ep4.intro.3` | Hold the square. Somewhere in this lane, a shoe is waiting to be found. | امسكوا الساحة. بمحل ما بهالحارة في صرماية ناطرة حدا يلاقيها. |  |  |  |
| 194 | `story.ep4.outro.1` | Under a chest in a dark room, they found one old shoe. | تحت صندوق بأوضة معتمة لقيوا صرماية عتيقة وحدة. |  |  |  |
| 195 | `story.ep4.outro.2` | Its twin had been lost at the gate on the night of the gold. | وأختها كانت ضايعة عند الباب ليلة الدهب. |  |  |  |
| 196 | `story.ep4.outro.3` | The sergeant shouted and threatened, but its owner said nothing at all. | الرقيب صرّخ وهدّد، بس صاحبها ما حكى ولا كلمة. |  |  |  |
| 197 | `story.ep5.title` | Fire at the Warehouse | حريق البوايكية |  |  |  |
| 198 | `story.ep5.intro.1` | The 'akeed needed a night guard for his warehouse, and he chose the man nobody trusted. | العكيد كان بدّه ناطور لبوايكيته، واختار الزلمة اللي ما حدا بيوثق فيه. |  |  |  |
| 199 | `story.ep5.intro.2` | That same night, torches moved through the orchards toward the door. | وبنفس الليلة، مشاعل مشيت بين البساتين لعند الباب. |  |  |  |
| 200 | `story.ep5.intro.3` | Keep water ready. If the door burns, the harvest burns with it. | جهّزوا المي. إذا احترق الباب، بيحترق الموسم معه. |  |  |  |
| 201 | `story.ep5.outro.1` | The cleaver man was caught with the oil jar still in his hand. | صاحب الساطور انمسك وجرّة الزيت بعدها بإيده. |  |  |  |
| 202 | `story.ep5.outro.2` | In the morning the 'akeed paid the night guard one gold lira. | الصبح العكيد عطى الناطور ليرة دهب وحدة. |  |  |  |
| 203 | `story.ep5.outro.3` | The first honest coin of his life. He held it and wept. | أول قرش حلال بحياته. مسكها وبكي. |  |  |  |
| 204 | `story.ep6.title` | The Blind Beggar | الشحّاد الأعمى |  |  |  |
| 205 | `story.ep6.intro.1` | Fog sat on the square, and a blind beggar sat by the courtyard wall. | الضباب قاعد عالساحة، وشحّاد أعمى قاعد جنب حيط الباحة. |  |  |  |
| 206 | `story.ep6.intro.2` | He heard everything. And he saw, the Hakawati says, a little too much. | كان يسمع كل شي. وبيقول الحكواتي: كان يشوف أكتر من اللازم. |  |  |  |
| 207 | `story.ep6.intro.3` | Tonight some neighbours in the lane are not neighbours at all. Lanterns up. | الليلة في جيران ماشيين بالحارة وهنّي مو جيران. ارفعوا الفوانيس. |  |  |  |
| 208 | `story.ep6.outro.1` | The beggar tore off his blindfold and ran, but the lanterns had seen his face. | الشحّاد شلح الطمّاشة وهرب، بس الفوانيس شافت وجهه. |  |  |  |
| 209 | `story.ep6.outro.2` | At the gate they found the purse he had taken, still full. | وعند الباب لقيوا الصرّة اللي سرقها، بعدها مليانة. |  |  |  |
| 210 | `story.ep6.outro.3` | The lane learned a hard lesson: not every quiet man is harmless. | الحارة تعلّمت درس صعب: مو كل واحد ساكت بيكون مسالم. |  |  |  |
| 211 | `story.ep7.title` | The Police Post | المخفر |  |  |  |
| 212 | `story.ep7.intro.1` | The sergeant lost his prisoner, and the corporal lost his rifle. | الرقيب ضيّع سجينه، والعريف ضيّع بارودته. |  |  |  |
| 213 | `story.ep7.intro.2` | Ashamed, the whole post marched on the lane to win back its pride. | ومن الخجل، المخفر كلّه زحف عالحارة ليرجّع هيبته. |  |  |  |
| 214 | `story.ep7.intro.3` | Riflemen will try to pin your defenders down. Spread them out. | البندقجية رح يحاولوا يشلّوا رجالك. فرّقوهن. |  |  |  |
| 215 | `story.ep7.outro.1` | The commandant counted his men and found fewer than he had brought. | القومندان عدّ عساكره ولقاهن أقل من اللي جابهن. |  |  |  |
| 216 | `story.ep7.outro.2` | The corporal's rifle turned up in a cooking pot. Nobody owned up. | بارودة العريف طلعت بطنجرة طبخ. وما حدا اعترف. |  |  |  |
| 217 | `story.ep7.outro.3` | The post went quiet. But the rival lane had been watching. | المخفر هدي. بس الحارة التانية كانت عم تتفرّج. |  |  |  |
| 218 | `story.ep8.title` | The Two Lanes | الحارتين |  |  |  |
| 219 | `story.ep8.intro.1` | Two roads, two gates, and every man of the rival lane on them. | طريقين، وبابين، وكل رجال الحارة التانية عليهن. |  |  |  |
| 220 | `story.ep8.intro.2` | Their 'akeed has stopped smiling. This time he comes himself. | عكيدهن بطّل يضحك. هالمرّة جاي بنفسه. |  |  |  |
| 221 | `story.ep8.intro.3` | And somewhere among them walks the thief who started it all. | وبيناتهن ماشي الحرامي اللي بلّش كل شي. |  |  |  |
| 222 | `story.ep8.outro.1` | At our gate the thief stopped, looked back at our lane, and turned his back on theirs. | عند بابنا الحرامي وقف، طلّع بحارتنا، وعطى ضهره لحارتهن. |  |  |  |
| 223 | `story.ep8.outro.2` | He fought beside us to the last wave. The lane called him a hero. | حارب معنا لآخر موجة. والحارة سمّته بطل. |  |  |  |
| 224 | `story.ep8.outro.3` | Only he knew how heavy that word was. One tale is left. | بس هو كان يعرف قدّيش هالكلمة تقيلة. ضلّت حكاية وحدة. |  |  |  |
| 225 | `story.ep9.title` | The Confession | الاعتراف |  |  |  |
| 226 | `story.ep9.intro.1` | His arm is gone and his nights are full of bad dreams. Still, he guards the gate. | إيده راحت ولياليه مليانة كوابيس. ومع هيك، واقف عالباب. |  |  |  |
| 227 | `story.ep9.intro.2` | Snakes crawl out of a grave that only he knows about. | حيّات طالعة من قبر ما حدا بيعرف فيه غيره. |  |  |  |
| 228 | `story.ep9.intro.3` | Stand with him until dawn. He has something to say before the end. | اوقفوا معه للصبح. عنده كلمة بدّه يقولها قبل النهاية. |  |  |  |
| 229 | `story.ep9.outro.1` | Before the elders he told the truth: the gold, the watchman, the night at the gate. | قدّام كبار الحارة قال الحقيقة: الدهب، والناطور، وليلة الباب. |  |  |  |
| 230 | `story.ep9.outro.2` | Half the gold went to the lane, and half to the watchman's family. | نصّ الدهب راح للحارة، والنصّ التاني لعيلة الناطور. |  |  |  |
| 231 | `story.ep9.outro.3` | And the lane forgave him. So ends the tale of the Night Guard. | والحارة سامحته. وهون بتخلص حكاية الحارس الليلي. |  |  |  |
| 232 | `story.boss.sergeant` | The sergeant swaggers in. He was never any good at catching thieves. | الرقيب داخل متمختر. عمره ما كان شاطر يمسك حرامية. |  |  |  |
| 233 | `story.boss.chief_thief` | Look who walks with the thieves tonight. Keep your eyes on his feet. | شوفوا مين ماشي مع الحرامية الليلة. عينكن على رجليه. |  |  |  |
| 234 | `story.boss.rival_zaim` | The rival lane's 'akeed comes to settle the score. | عكيد الحارة التانية جاي ياخد تاره. |  |  |  |
| 235 | `story.boss.colonel` | The commandant, at last. He has never lost a siege… until tonight? | القومندان أخيراً. عمره ما خسر حصار… لهلّق؟ |  |  |  |
| 236 | `story.boss.corporal` | Here comes the corporal, holding his rifle the wrong way round. | إجا العريف، ماسك بارودته بالمقلوب. |  |  |  |
| 237 | `story.boss.abu_jawdan` | The sergeant of four lanes. He wants a confession, any confession. | رقيب الأربع حارات. بدّه اعتراف، أي اعتراف. |  |  |  |
| 238 | `story.boss.abu_shatour` | The cleaver man and his torch. Mind the door! | صاحب الساطور ومشعله. دير بالك عالباب! |  |  |  |
| 239 | `story.boss.lateef` | The blind beggar opens his eyes. Watch him: he jumps. | الشحّاد الأعمى فتّح عيونه. انتبهوا: بينطّ. |  |  |  |
| 240 | `story.boss.spy` | Something moves in the shadows by the wall. Light it up. | في شي عم يتحرّك بالعتمة جنب الحيط. ضوّوا عليه. |  |  |  |
| 241 | `story.boss.fakhr` | One hand, one club, and a long grudge. | إيد وحدة، وعصاية وحدة، وحقد طويل. |  |  |  |
| 242 | `story.boss.abu_zira` | He reels like a ship in a storm, and hits like one too. | بيتمايل متل مركب بالعاصفة، وبيضرب متله كمان. |  |  |  |
| 243 | `story.boss.rival_zaim_enraged` | The rival 'akeed is furious now, and his men close in around him. | عكيد الحارة التانية معصّب هلّق، ورجاله ملمومين حواليه. |  |  |  |
| 244 | `story.moment.ally_turn` | The thief reaches our gate… and turns to face his own lane. | الحرامي وصل لبابنا… ولفّ وجهه لحارته. |  |  |  |
| 245 | `bead.range.name` | Bead of reach (+1 range) | خرزة المدى (+١ مدى) |  |  |  |
| 246 | `bead.cooldown.name` | Bead of haste (−4 % cooldown) | خرزة السرعة (−٤٪ وقت) |  |  |  |
| 247 | `bead.cash.name` | Bead of fortune (+8 % kill cash) | خرزة الرزق (+٨٪ مصاري) |  |  |  |
| 248 | `bead.heal.name` | Bead of mending (+2 gate repair) | خرزة التصليح (+٢ للباب) |  |  |  |
| 249 | `bead.buff.name` | Bead of spirit (+3 % boost) | خرزة الهمّة (+٣٪ تشجيع) |  |  |  |

## Sign-off

| Reviewer | Dialect / country | Date | Sections reviewed | Notes |
|----------|-------------------|------|-------------------|-------|
|  |  |  |  |  |

*After review: apply corrections in `src/shared/Config/Strings.luau` (the `ar` table), run `lune run tests/run` (checks every key exists in both languages), and set COPYRIGHT_REGISTER C-013 and RELEASE_CHECKLIST §C "Cultural review" accordingly.*

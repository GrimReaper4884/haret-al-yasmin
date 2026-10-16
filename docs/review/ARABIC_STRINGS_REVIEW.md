# Arabic strings: native-speaker review pack

*Generated 2026-10-16 from `src/shared/Config/Strings.luau` (branch `feat/vertical-slice`, commit 2b0b800). 385 keys in 17 screens; Claude flagged 62 of them. Regenerate with `python -I docs/review/build_arabic_review.py .` after edits rather than hand-editing the Arabic column.*

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

- [1. Main HUD and buttons](#1-main-hud-and-buttons) — 17 strings, 4 flagged
- [2. Lane neighbours and the first errand](#2-lane-neighbours-and-the-first-errand) — 28 strings, 5 flagged
- [3. Story: Season 1 · Episode 1 (Wedding Eve)](#3-story-season-1--episode-1-wedding-eve) — 27 strings, 6 flagged
- [4. Wardrobe and tailor shop](#4-wardrobe-and-tailor-shop) — 37 strings, 3 flagged
- [5. Store and Robux products](#5-store-and-robux-products) — 40 strings, 4 flagged
- [6. Notifications (toasts)](#6-notifications-toasts) — 18 strings, 1 flagged
- [7. Disconnect messages (shown by Roblox)](#7-disconnect-messages-shown-by-roblox) — 4 strings, 1 flagged
- [8. Tower defense: modes, arenas and party queue](#8-tower-defense-modes-arenas-and-party-queue) — 23 strings, 4 flagged
- [9. Tower defense: match HUD](#9-tower-defense-match-hud) — 49 strings, 10 flagged
- [10. Enemies](#10-enemies) — 11 strings, 2 flagged
- [11. Defender roster, rarities, roles and traits](#11-defender-roster-rarities-roles-and-traits) — 51 strings, 10 flagged
- [12. Units screen](#12-units-screen) — 11 strings, 1 flagged
- [13. Summon screen](#13-summon-screen) — 18 strings, 3 flagged
- [14. Lane Diary (season pass)](#14-lane-diary-season-pass) — 13 strings, 1 flagged
- [15. Codes, daily reward and reward labels](#15-codes-daily-reward-and-reward-labels) — 19 strings, 2 flagged
- [16. Lobby NPCs (tower-defense square)](#16-lobby-npcs-tower-defense-square) — 12 strings, 4 flagged
- [17. World signs (3D text in the lane)](#17-world-signs-3d-text-in-the-lane) — 7 strings, 1 flagged

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
| 17 | `hud.defend` | Defend the gate: step on a portal in the square. | دافع عن الباب: وقّف على بوابة بالساحة. | MEANING: the lane gate is «الباب» here but «البوابة» in the Episode 1 clues, and the queue portals are also «بوابة». Pick one word for the gate and another for the portal (e.g. portal «الدائرة»/«نقطة التجمّع»). |  |  |

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
| 25 | `product.pass_premium.desc` | Double lira on every level, trait stones, two cosmetics and the Great Za'im at level 50. | ضعف الليرات بكل مستوى، أحجار صفات، قطعتين لبس، والزعيم الأكبر بالمستوى ٥٠. |  |  |  |
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
| 8 | `mode.infinite.name` | Endless Night | ليل ما بيخلص |  |  |  |
| 9 | `mode.infinite.desc` | Hold the gate as long as you can. Rewards every 10 waves. | صمّد على الباب أطول ما فيك. جوائز كل ١٠ موجات. | STYLE: «صمّد» (causative, 'make hold') used as 'hold out'. Suggest «اصمد عالباب قدّ ما فيك». |  |  |
| 10 | `arena.orchard.name` | The Orchard Road | طريق البساتين |  |  |  |
| 11 | `arena.siege.name` | Under the Walls | تحت السور |  |  |  |
| 12 | `difficulty.normal` | Normal | عادي |  |  |  |
| 13 | `difficulty.hard` | Hard | صعب |  |  |  |
| 14 | `difficulty.nightmare` | Nightmare | كابوس |  |  |  |
| 15 | `mode.locked` | Locked: clear {mode} first | مقفول: خلّص {mode} أول |  |  |  |
| 16 | `mode.locked_difficulty` | Clear the easier difficulty first | خلّص المستوى الأسهل أول |  |  |  |
| 17 | `queue.title` | Party | الشلّة |  |  |  |
| 18 | `queue.players` | {n}/{max} players | {n}/{max} لاعبين | STYLE: plural agreement: «لاعبين» is right for 3–10 but the count is a placeholder (see general note 4). |  |  |
| 19 | `queue.starting` | Starting in {n}s | بنبلّش بعد {n} ث | DIALECT: «بنبلّش» is Lebanese/Palestinian 1st-person plural; Damascene «منبلّش». |  |  |
| 20 | `queue.leave` | Leave | اطلع |  |  |  |
| 21 | `queue.host` | Host picks the difficulty | صاحب الشلّة بيختار الصعوبة |  |  |  |
| 22 | `queue.joined` | {name} joined the party | {name} انضم للشلّة |  |  |  |
| 23 | `queue.left` | {name} left the party | {name} طلع من الشلّة |  |  |  |

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
| 13 | `match.sell` | Sell · ${n} | بيع · ${n} |  |  |  |
| 14 | `match.target` | Target: {mode} | الهدف: {mode} |  |  |  |
| 15 | `target.first` | First | الأول |  |  |  |
| 16 | `target.last` | Last | الأخير |  |  |  |
| 17 | `target.strong` | Strongest | الأقوى |  |  |  |
| 18 | `target.close` | Closest | الأقرب |  |  |  |
| 19 | `match.level` | Lv {n} | مستوى {n} |  |  |  |
| 20 | `match.stat_damage` | Damage {n} | ضرب {n} | STYLE: «ضرب» (hitting) for Damage; gamers expect «ضرر». |  |  |
| 21 | `match.stat_range` | Range {n} | مدى {n} |  |  |  |
| 22 | `match.stat_cooldown` | Speed {n}s | سرعة {n} ث |  |  |  |
| 23 | `match.stat_income` | Income ${n}/wave | دخل ${n}/موجة |  |  |  |
| 24 | `match.stat_buff` | Buff +{n}% | تقوية +{n}% |  |  |  |
| 25 | `match.stat_heal` | Repairs {n} HP/wave | ترميم {n} نقطة/موجة |  |  |  |
| 26 | `match.wave_start` | Wave {n} | موجة {n} |  |  |  |
| 27 | `match.boss_wave` | {boss} is coming! | {boss} جاي! |  |  |  |
| 28 | `match.gate_closing` | The watchman bars the gate. Hold the lane! | الناطور سكّر الباب. صمّدوا يا رجال الحارة! | STYLE: «صمّدوا» → «اصمدوا». |  |  |
| 29 | `match.gate_breached` | The gate took a hit! | الباب أكل ضربة! |  |  |  |
| 30 | `match.victory` | The lane is safe! | الحارة بأمان! |  |  |  |
| 31 | `match.defeat` | The gate has fallen… | وقع الباب… |  |  |  |
| 32 | `match.waves_held` | Waves held: {n} | موجات صمّدتوها: {n} | STYLE: «موجات صمّدتوها: {n}» is awkward. Suggest «صمدتوا {n} موجة». |  |  |
| 33 | `match.rewards` | Rewards | الجوائز |  |  |  |
| 34 | `match.first_clear` | First clear bonus ×2 | أول مرة بتخلّصها: ×٢ |  |  |  |
| 35 | `match.back` | Back to the lane | رجوع للحارة |  |  |  |
| 36 | `match.vote_skip` | {name} voted to skip | {name} صوّت للتخطّي |  |  |  |
| 37 | `match.shabriyeh` | Shabriyeh! | يا شبرية! | MEANING: «يا شبرية!» as a battle-cry reads oddly (vocative to a dagger). Reviewer: is there a natural shout, or just «شبرية!»? |  |  |
| 38 | `match.camera_overhead` | Watchtower view | منظر البرج |  |  |  |
| 39 | `match.camera_walk` | Walk | مشي |  |  |  |
| 40 | `match.err.on_path` | Not on the road. | مش على الطريق. | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «مو على الطريق». |  |  |
| 41 | `match.err.too_close` | Too close to another defender. | قريب كتير من واحد تاني. |  |  |  |
| 42 | `match.err.cannot_afford` | Not enough cash. | ما معك مصاري كفاية. |  |  |  |
| 43 | `match.err.unit_cap` | You placed the maximum of this unit. | حطّيت أكبر عدد من هالرجّال. | STYLE: «أكبر عدد من هالرجّال» → «الحدّ الأقصى من هالمدافع» (see hud.units). |  |  |
| 44 | `match.err.tower_cap` | You placed the maximum number of defenders. | حطّيت أكبر عدد من المدافعين. |  |  |  |
| 45 | `match.err.out_of_bounds` | Outside the arena. | برّا الساحة. |  |  |  |
| 46 | `match.err.not_in_loadout` | Not in your loadout. | مش بتشكيلتك. | DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «مو بتشكيلتك». |  |  |
| 47 | `match.err.max_level` | Already at max level. | وصل لأعلى مستوى. |  |  |  |
| 48 | `match.err.match_over` | The match is over. | خلصت الجولة. |  |  |  |
| 49 | `match.err.fast_pass` | 3x speed needs the Fast Mode pass. | سرعة 3x بدها بطاقة السرعة. | STYLE: Latin «3x» mixed into Arabic (see general note 3). |  |  |

## 10. Enemies

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `enemy.gendarme.name` | Gendarme | دركي |  |  |  |
| 2 | `enemy.thief.name` | Night thief | حرامي الليل |  |  |  |
| 3 | `enemy.bandit.name` | Orchard bandit | قاطع طريق |  |  |  |
| 4 | `enemy.thug.name` | Rival-lane thug | زعران الحارة التانية | MEANING: «زعران» is plural for a single enemy. Suggest «أزعر من الحارة التانية». |  |  |
| 5 | `enemy.rider.name` | Mounted officer | ضابط خيّال |  |  |  |
| 6 | `enemy.sapper.name` | Sapper | نقّاب | STYLE: «نقّاب» (digger) for Sapper; reviewer to confirm or suggest «لغّام». |  |  |
| 7 | `enemy.spy.name` | Spy | جاسوس |  |  |  |
| 8 | `enemy.sergeant.name` | The Sergeant | الشاويش |  |  |  |
| 9 | `enemy.chief_thief.name` | The Thief King | كبير الحرامية |  |  |  |
| 10 | `enemy.rival_zaim.name` | Za'im of the rival lane | زعيم الحارة التانية |  |  |  |
| 11 | `enemy.colonel.name` | The Commandant | القومندان |  |  |  |

## 11. Defender roster, rarities, roles and traits

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `unit.walad.name` | Lane Boy | ولد الحارة |  |  |  |
| 2 | `unit.walad.desc` | Quick with a sling and quicker with excuses. Cheap, plentiful, everywhere at once. | سريع بالمقلاع وأسرع بالأعذار. رخيص وكتير وبكل مكان. |  |  |  |
| 3 | `unit.natour.name` | Abu Fares the Watchman | أبو فارس الناطور | NAME: Abu Fares is also a minor name in the TV series (COPYRIGHT_REGISTER C-013). Reviewer: does it evoke that show? If yes, propose a swap. |  |  |
| 4 | `unit.natour.desc` | Bars the gate every night. His lantern reveals night thieves and slows anyone it shines on. | بيسكّر الباب كل ليلة. فانوسه بيكشف الحرامية وبيبطّئ كل مين بيوقع عليه الضو. |  |  |  |
| 5 | `unit.farran.name` | Abu Bashir the Baker | أبو بشير الفرّان |  |  |  |
| 6 | `unit.farran.desc` | Hurls loaves straight from the oven. Hits a whole group at once. | بيرمي الأرغفة من الفرن مباشرة. بيضرب مجموعة كاملة بضربة. | STYLE: MSA «الأرغفة … مباشرة». Colloquial «بيرمي الرغفان طازة من الفرن». |  |  |
| 7 | `unit.saqqa.name` | Abu Jamil the Water Carrier | أبو جميل السقّا |  |  |  |
| 8 | `unit.saqqa.desc` | Empties his water skin over the road. Soaks and slows everyone in the splash. | بيكبّ القربة على الطريق. بيبلّل وبيبطّئ كل مين بالرشّة. |  |  |  |
| 9 | `unit.hallaq.name` | Abu Nidal the Barber | أبو نضال الحلاق |  |  |  |
| 10 | `unit.hallaq.desc` | Fast hands, sharp razor, sharper tongue. Close range, relentless. | إيد سريعة وموس حاد ولسان أحدّ. مدى قصير وما بيوقف. |  |  |  |
| 11 | `unit.khayyat.name` | Abu Samir the Tailor | أبو سمير الخياط |  |  |  |
| 12 | `unit.khayyat.desc` | Threads a needle at thirty paces. Longest reach in the lane. | بيلضم الإبرة من تلاتين خطوة. أطول مدى بالحارة. | DIALECT: «بيلضم الإبرة» — reviewer to confirm Damascene verb (some say «بيشكّ الإبرة»). |  |  |
| 13 | `unit.qahwaji.name` | Abu Hamed the Coffee-house Keeper | أبو حامد القهوجي |  |  |  |
| 14 | `unit.qahwaji.desc` | Doesn't fight; he serves. Pays you cash at the end of every wave. | ما بيقاتل، بيقدّم. بيدفعلك مصاري بآخر كل موجة. | STYLE: «بيقدّم» (serves) is flat; «بيضيّف» is the natural word for a coffee-house keeper. |  |  |
| 15 | `unit.qabaday.name` | The 'Akeed | العكيد |  |  |  |
| 16 | `unit.qabaday.desc` | The za'im's right hand, first to draw. Every few seconds his shabriyeh strike deals massive damage. | إيد الزعيم اليمين وأول مين بيسحب. كل كم ثانية ضربة شبريته بتعمل ضرر هائل. | STYLE: MSA «ضرر هائل». Alt «ضربة شبريته بتهدّ». |  |  |
| 17 | `unit.haddad.name` | Abu Khater the Blacksmith | أبو خاطر الحدّاد | NAME: Abu Khater is also a minor name in the TV series (C-013). Same question as Abu Fares. |  |  |
| 18 | `unit.haddad.desc` | One hammer blow stuns and shakes the whole road. | ضربة مطرقة وحدة بتدوّخ وبتهزّ الطريق كله. |  |  |  |
| 19 | `unit.mukhtar.name` | The Mukhtar | المختار |  |  |  |
| 20 | `unit.mukhtar.desc` | The headman's word carries. Defenders near him hit harder. | كلمة المختار مسموعة. المدافعين حدّه بيضربوا أقوى. |  |  |  |
| 21 | `unit.zaim.name` | The Za'im | الزعيم |  |  |  |
| 22 | `unit.zaim.desc` | Leader of the lane. Rarely draws the shabriyeh, and when he does, it ends the matter. | زعيم الحارة. نادراً ما بيسحب الشبرية، وإذا سحبها خلصت القصة. |  |  |  |
| 23 | `unit.pahlawan.name` | The Strongman | البهلوان | MEANING (high): in modern Levantine «بهلوان» means acrobat/clown, not strongman. Historic Damascene 'pahlavan' wrestler sense may be lost on kids. Suggest «المصارع» or «أبو العضلات». Also banner.pahlawan.name. |  |  |
| 24 | `unit.pahlawan.desc` | Wrestler from the hammam. Sweeps the road clear with his bare arms. | مصارع الحمّام. بيكنّس الطريق بذراعيه. |  |  |  |
| 25 | `unit.umm_hara.name` | Umm Zaki, Mother of the Lane | أم زكي، أم الحارة |  |  |  |
| 26 | `unit.umm_hara.desc` | Patches the gate after every wave and keeps the men's spirits up. | بترمّم الباب بعد كل موجة وبترفع معنويات الرجال. |  |  |  |
| 27 | `unit.arada.name` | The 'Arada Troupe | فرقة العراضة |  |  |  |
| 28 | `unit.arada.desc` | Sword and shield dancers of the wedding procession. Their swing cuts a wide arc. | رقّاصين السيف والترس بالزفّة. ضربتهم بتقطع قوس واسع. | MEANING: «رقّاصين» (dancers) can sound belittling for 'arada performers; usual phrase «لعّيبة السيف والترس». |  |  |
| 29 | `unit.zaim_akbar.name` | The Great Za'im | الزعيم الأكبر |  |  |  |
| 30 | `unit.zaim_akbar.desc` | The legend every lane tells of. One drawn shabriyeh and the road is silent. | الأسطورة اللي كل حارة بتحكي عنها. شبرية وحدة والطريق بيسكت. |  |  |  |
| 31 | `unit.qitt.name` | Cat of the Lane | بسّة الحارة |  |  |  |
| 32 | `unit.qitt.desc` | Nobody owns the cat. The cat owns the lane. (Secret) | ما حدا بيملك البسّة. البسّة بتملك الحارة. (سرّي) |  |  |  |
| 33 | `rarity.rare` | Rare | نادر |  |  |  |
| 34 | `rarity.epic` | Epic | ملحمي |  |  |  |
| 35 | `rarity.legendary` | Legendary | أسطوري |  |  |  |
| 36 | `rarity.mythic` | Mythic | خرافي |  |  |  |
| 37 | `rarity.secret` | Secret | سرّي |  |  |  |
| 38 | `role.melee` | Melee | قريب |  |  |  |
| 39 | `role.ranged` | Ranged | بعيد |  |  |  |
| 40 | `role.splash` | Area | منطقة | STYLE: «منطقة» (area) alone is unclear; alt «ضرب جماعي». |  |  |
| 41 | `role.support` | Support | دعم |  |  |  |
| 42 | `role.farm` | Income | دخل |  |  |  |
| 43 | `role.healer` | Repair | ترميم |  |  |  |
| 44 | `trait.steady.name` | Steady | ثابت |  |  |  |
| 45 | `trait.swift.name` | Swift | سريع |  |  |  |
| 46 | `trait.keen.name` | Keen-eyed | عينه قوية | MEANING: «عينه قوية» in Levantine usually means bold/cheeky, not sharp-sighted. Suggest «نظره حاد». |  |  |
| 47 | `trait.sharp.name` | Sharp | حاد |  |  |  |
| 48 | `trait.golden.name` | Golden hands | إيده دهب |  |  |  |
| 49 | `trait.hawk.name` | Hawk | صقر |  |  |  |
| 50 | `trait.zaim.name` | Za'im's blood | دم الزعيم |  |  |  |
| 51 | `trait.legend.name` | Legend | أسطورة |  |  |  |

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

## 13. Summon screen

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `summon.title` | Summon | استدعاء |  |  |  |
| 2 | `summon.banner` | Banner: {name} | اللافتة: {name} | STYLE: «اللافتة» (street sign) for a gacha banner. Arab players usually say «البانر». Also summon.rotates. |  |  |
| 3 | `summon.featured` | Featured | مميّز | STYLE: «مميّز» is also used for Premium. Suggest «بالواجهة» or «النجم» for Featured. |  |  |
| 4 | `summon.rotates` | New banner in {n} | لافتة جديدة بعد {n} |  |  |  |
| 5 | `summon.one` | Summon ×1 · {n} lira | استدعاء ×١ · {n} ليرة |  |  |  |
| 6 | `summon.ten` | Summon ×10 · {n} lira | استدعاء ×١٠ · {n} ليرة |  |  |  |
| 7 | `summon.rates` | Rates | النسب |  |  |  |
| 8 | `summon.rates_title` | Drop rates (this pull) | نسب الظهور (هالسحبة) |  |  |  |
| 9 | `summon.pity` | Guaranteed Legendary within {l} pulls ({a} left) · Mythic within {m} pulls ({b} left) | أسطوري مضمون خلال {l} سحبة (باقي {a}) · خرافي خلال {m} سحبة (باقي {b}) |  |  |  |
| 10 | `summon.new` | NEW | جديد |  |  |  |
| 11 | `summon.copy` | Copy | نسخة |  |  |  |
| 12 | `summon.again` | Again | كمان |  |  |  |
| 13 | `summon.no_lira` | Not enough lira. | ما معك ليرات كفاية. |  |  |  |
| 14 | `summon.get_lira` | Get lira | جيب ليرات |  |  |  |
| 15 | `summon.restricted` | Lira can't be bought in your region. Earn it from matches, dailies and codes. | ما فيك تشتري ليرات بمنطقتك. اجمعها من الجولات واليومي والأكواد. |  |  |  |
| 16 | `banner.zaim.name` | The Za'im returns | رجع الزعيم |  |  |  |
| 17 | `banner.pahlawan.name` | Night of the Strongman | ليلة البهلوان | MEANING: see unit.pahlawan.name. |  |  |
| 18 | `banner.umm_hara.name` | Mother of the Lane | أم الحارة |  |  |  |

## 14. Lane Diary (season pass)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `pass.season.s1.name` | Lane Diary · Season 1 | دفتر الحارة · الموسم ١ |  |  |  |
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
| 9 | `daily.title` | Daily reward | جائزة اليوم |  |  |  |
| 10 | `daily.day` | Day {n} | يوم {n} |  |  |  |
| 11 | `daily.claim` | Claim | استلم |  |  |  |
| 12 | `daily.claimed` | Come back tomorrow | ارجع بكرا | STYLE: spelled «بكرا» here, «بكرة» in dlg.hajj_rashid.busy. Pick one. |  |  |
| 13 | `daily.streak` | Streak: {n} days | متتالية: {n} يوم | STYLE: «متتالية: {n} يوم» is stiff. Suggest «صرلك {n} يوم ورا بعض». |  |  |
| 14 | `reward.lira` | +{n} lira | +{n} ليرة |  |  |  |
| 15 | `reward.qirsh` | +{n} qirsh | +{n} قرش |  |  |  |
| 16 | `reward.xp` | +{n} XP | +{n} خبرة |  |  |  |
| 17 | `reward.stones` | +{n} trait stone(s) | +{n} حجر صفات |  |  |  |
| 18 | `reward.item` | {item} | {item} |  |  |  |
| 19 | `reward.unit` | {unit} | {unit} |  |  |  |

## 16. Lobby NPCs (tower-defense square)

| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |
|---|-----|---------|------------------|-------------|------------|-----|
| 1 | `npc.barber.name` | Abu Nidal | أبو نضال |  |  |  |
| 2 | `npc.barber.role` | Barber | حلاق | STYLE: no article («حلاق», «قهوجي») while older roles use one («الفرّان», «الخيّاط»). Make consistent. |  |  |
| 3 | `npc.qahwaji.name` | Abu Hamed | أبو حامد |  |  |  |
| 4 | `npc.qahwaji.role` | Coffee-house keeper | قهوجي |  |  |  |
| 5 | `npc.natour.name` | Abu Fares | أبو فارس | NAME: see unit.natour.name. |  |  |
| 6 | `npc.natour.role` | Night watchman | ناطور الحارة |  |  |  |
| 7 | `dlg.barber.greet` | Sit, sit! A shave, a trim, and all the news of the lane for free. They say thieves are testing the gate at night… | اقعد اقعد! حلاقة وتزيين وأخبار الحارة كلها ببلاش. بيقولوا في حرامية عم يجرّبوا الباب بالليل… |  |  |  |
| 8 | `dlg.barber.greet.ok` | Then I'd better go defend it. | لكان أحسن روح دافع عنه. | STYLE: «لكان أحسن روح دافع عنه» is a bit clipped; alt «لكان لازم روح دافع عنه». |  |  |
| 9 | `dlg.qahwaji.greet` | Tea or coffee? Sit by the fountain. The men gather here before the gate closes. | شاي ولا قهوة؟ اقعد جنب البحرة. الرجال بيتجمّعوا هون قبل ما يتسكّر الباب. |  |  |  |
| 10 | `dlg.qahwaji.greet.ok` | Later, Abu Hamed. | بعدين يا أبو حامد. |  |  |  |
| 11 | `dlg.natour.greet` | After the evening prayer I bar this gate, and nobody enters without a name. Want to help hold it? The portals are in the square. | بعد صلاة العشا بسكّر هالباب وما حدا بيفوت بلا اسم. بدك تساعد تصمّده؟ البوابات بالساحة. | STYLE: «بدك تساعد تصمّده؟» awkward (see «صمّد» note); «البوابات» = portals collides with the gate word. Alt «بدك تساعدنا نحميه؟ نقاط التجمّع بالساحة». |  |  |
| 12 | `dlg.natour.greet.ok` | I'll be there. | جاي. |  |  |  |

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

## Sign-off

| Reviewer | Dialect / country | Date | Sections reviewed | Notes |
|----------|-------------------|------|-------------------|-------|
|  |  |  |  |  |

*After review: apply corrections in `src/shared/Config/Strings.luau` (the `ar` table), run `lune run tests/run` (checks every key exists in both languages), and set COPYRIGHT_REGISTER C-013 and RELEASE_CHECKLIST §C "Cultural review" accordingly.*

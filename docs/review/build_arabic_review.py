"""Builds docs/review/ARABIC_STRINGS_REVIEW.md from src/shared/Config/Strings.luau (overwrites it:
copy reviewer answers out first).
Usage: python -I docs/review/build_arabic_review.py .
Claude's pre-review flags live in `flags` below; drop a flag once the reviewer has answered it."""
import re
import sys
import pathlib

root = pathlib.Path(sys.argv[1])
src = (root / "src/shared/Config/Strings.luau").read_text(encoding="utf-8")

def table(name):
    m = re.search(r"local " + name + r": \{ \[string\]: string \} = \{\n(.*?)\n\}\n", src, re.S)
    out = {}
    order = []
    for k, v in re.findall(r'\["([^"]+)"\] = "((?:[^"\\]|\\.)*)"', m.group(1)):
        out[k] = v
        order.append(k)
    return out, order

en, en_order = table("en")
ar, _ = table("ar")
assert set(en) == set(ar), set(en) ^ set(ar)

# Claude's own pre-review. Tags: MEANING = may say the wrong thing, DIALECT = not Damascene / reads
# Lebanese or MSA, STYLE = awkward or inconsistent. Suggestions are proposals, not fixes.
D_MO = "DIALECT: «مش» reads Lebanese/Palestinian; a Damascene would say «مو». Suggest «{s}»."
flags = {
    "hud.close": "STYLE: MSA «إغلاق» in an otherwise colloquial UI. Fine for a button; colloquial alt «سكّر».",
    "hud.units": "MEANING: «الرجال» (the men) labels a roster that includes Umm Zaki and the cat. Suggest «المدافعين» or «رجال الحارة» if the male framing is intended. Same issue in units.title, units.empty, pass.reward.unit, notify.unit_new, pass.extra_slot.desc, match.err.unit_cap.",
    "hud.daily": "STYLE: bare «يومي» (daily, adj.) as a button. Suggest «جائزة اليوم» or «اليومية».",
    "hud.defend": "MEANING: the lane gate is «الباب» here but «البوابة» in the Episode 1 clues, and the queue portals are also «بوابة». Pick one word for the gate and another for the portal (e.g. portal «الدائرة»/«نقطة التجمّع»).",
    "prompt.portal": "STYLE: MSA «انضم». Colloquial alt «فوت».",
    "dlg.common.not_now": D_MO.format(s="مو هلّق"),
    "dlg.abu_nadim.thanks": "STYLE: MSA «قريباً». Colloquial alt «لا تطوّل علينا» / «ارجع عن قريب».",
    "dlg.sitt_wardeh.greet": "MEANING: «يا ابني» and all imperatives address a boy. The player may be a girl. Decide: keep masculine as the generic, or rephrase neutrally (e.g. «يا عيني»). Applies to every dialogue line.",
    "dlg.sitt_wardeh.delivery": "DIALECT: «هيدي» is Lebanese; Damascene «هاي». Suggest «هاي ريحة كعك أبو نديم؟».",
    "quest.delivery_kaak.obj_completed": "STYLE: MSA «تمّ التوصيل» next to colloquial text. Alt «وصلت السلّة».",
    "quest.s1e1.obj_active": "DIALECT: «حوالي» → Damascene «حوالين البحرة». Also see hud.defend on gate = «البوابة» vs «الباب».",
    "clue.slipper.text": "STYLE + " + D_MO.format(s="مو جزمة") + " «شحّاطة طرية» (soft slipper) sounds odd; alt «أثر شحّاطة خفيفة».",
    "dlg.hajj_rashid.busy": D_MO.format(s="مو هلّق يا ابني، مو هلّق"),
    "dlg.hajj_rashid.plea2.decline": D_MO.format(s="هاد مو شغلي"),
    "dlg.hajj_rashid.accepted": "DIALECT: «حوالي» → «حوالين».",
    "dlg.hajj_rashid.reported": "STYLE: «خود هدول عتعبك» — «هدول» has no referent on screen (coins?). Alt «خود هالقروش على تعبك».",
    "item.tarboosh_gold.name": "MEANING: «زنّار» is a waist sash (and is the name of item.zunnar_sash). For a hat band suggest «طربوش بشريط دهبي».",
    "item.tarboosh_gold.desc": "MEANING: same «زنّار» issue; suggest «بشريط وشرّابة دهب».",
    "item.sherwal_indigo.desc": "STYLE: «بأحواض خليل» (in Khalil's basins) for dye vats; reviewer to confirm the natural word.",
    "store.passes": "MEANING: «البطاقات» (cards) for Roblox game passes. Check the term Roblox's own Arabic UI uses for Game Pass and match it.",
    "store.packs": "STYLE: «صُرر» is a bookish plural. Alt «أكياس القروش».",
    "notify.coming_soon": D_MO.format(s="هاد لسا مو متوفّر"),
    "notify.lira_added": "STYLE: spelled «يسلمو» here but «يسلموا» in notify.qirsh_added. Pick one.",
    "kick.session_lost": "STYLE: «فتت من سيرفر تاني، فانسكّرت هالجلسة» is understandable but stiff; reviewer to smooth.",
    "mode.infinite.desc": "STYLE: «صمّد» (causative, 'make hold') used as 'hold out'. Suggest «اصمد عالباب قدّ ما فيك».",
    "queue.starting": "DIALECT: «بنبلّش» is Lebanese/Palestinian 1st-person plural; Damascene «منبلّش».",
    "queue.players": "STYLE: plural agreement: «لاعبين» is right for 3–10 but the count is a placeholder (see general note 4).",
    "match.skip": "STYLE: noun «تخطّي» here, imperative spelled «تخطّى» in pass.skip / product.pass_skip. Make consistent.",
    "match.place": "DIALECT: «كبس» is past tense; imperative is «اكبس». Suggest «اكبس عالأرض لتحطّ {unit}».",
    "match.stat_damage": "STYLE: «ضرب» (hitting) for Damage; gamers expect «ضرر».",
    "match.gate_closing": "STYLE: «صمّدوا» → «اصمدوا».",
    "match.waves_held": "STYLE: «موجات صمّدتوها: {n}» is awkward. Suggest «صمدتوا {n} موجة».",
    "match.shabriyeh": "MEANING: «يا شبرية!» as a battle-cry reads oddly (vocative to a dagger). Reviewer: is there a natural shout, or just «شبرية!»?",
    "match.err.on_path": D_MO.format(s="مو على الطريق"),
    "match.err.unit_cap": "STYLE: «أكبر عدد من هالرجّال» → «الحدّ الأقصى من هالمدافع» (see hud.units).",
    "match.err.not_in_loadout": D_MO.format(s="مو بتشكيلتك"),
    "match.err.fast_pass": "STYLE: Latin «3x» mixed into Arabic (see general note 3).",
    "enemy.thug.name": "MEANING: «زعران» is plural for a single enemy. Suggest «أزعر من الحارة التانية».",
    "enemy.sapper.name": "STYLE: «نقّاب» (digger) for Sapper; reviewer to confirm or suggest «لغّام».",
    "unit.farran.desc": "STYLE: MSA «الأرغفة … مباشرة». Colloquial «بيرمي الرغفان طازة من الفرن».",
    "unit.qahwaji.desc": "STYLE: «بيقدّم» (serves) is flat; «بيضيّف» is the natural word for a coffee-house keeper.",
    "unit.khayyat.desc": "DIALECT: «بيلضم الإبرة» — reviewer to confirm Damascene verb (some say «بيشكّ الإبرة»).",
    "unit.qabaday.desc": "STYLE: MSA «ضرر هائل». Alt «ضربة شبريته بتهدّ».",
    "unit.pahlawan.name": "MEANING (high): in modern Levantine «بهلوان» means acrobat/clown, not strongman. Historic Damascene 'pahlavan' wrestler sense may be lost on kids. Suggest «المصارع» or «أبو العضلات». Also banner.pahlawan.name.",
    "unit.arada.desc": "MEANING: «رقّاصين» (dancers) can sound belittling for 'arada performers; usual phrase «لعّيبة السيف والترس».",
    "role.splash": "STYLE: «منطقة» (area) alone is unclear; alt «ضرب جماعي».",
    "trait.keen.name": "MEANING: «عينه قوية» in Levantine usually means bold/cheeky, not sharp-sighted. Suggest «نظره حاد».",
    "units.empty": "STYLE: see hud.units («رجال»).",
    "summon.banner": "STYLE: «اللافتة» (street sign) for a gacha banner. Arab players usually say «البانر». Also summon.rotates.",
    "summon.featured": "STYLE: «مميّز» is also used for Premium. Suggest «بالواجهة» or «النجم» for Featured.",
    "banner.pahlawan.name": "MEANING: see unit.pahlawan.name.",
    "pass.ends": "STYLE: plural agreement: «{n} يوم» is right for 11+ only (3–10 needs «أيام»). See general note 4.",
    "daily.claimed": "STYLE: spelled «بكرا» here, «بكرة» in dlg.hajj_rashid.busy. Pick one.",
    "daily.streak": "STYLE: «متتالية: {n} يوم» is stiff. Suggest «صرلك {n} يوم ورا بعض».",
    "notify.leaderboard": "MEANING: «أحسن جولة ليل» does not clearly name the Endless mode. Suggest «أحسن رقم بليل ما بيخلص: موجة {n}».",
    "sign.tailor": "STYLE: «خياطة خليل» = 'Khalil's sewing'. Shop sign alt «خيّاط خليل» or «محل خليل الخيّاط». Same text in shop.khalil_tailor.title.",
    "npc.barber.role": "STYLE: no article («حلاق», «قهوجي») while older roles use one («الفرّان», «الخيّاط»). Make consistent.",
    "dlg.barber.greet.ok": "STYLE: «لكان أحسن روح دافع عنه» is a bit clipped; alt «لكان لازم روح دافع عنه».",
    "dlg.natour.greet": "STYLE: «بدك تساعد تصمّده؟» awkward (see «صمّد» note); «البوابات» = portals collides with the gate word. Alt «بدك تساعدنا نحميه؟ نقاط التجمّع بالساحة».",
    "unit.natour.name": "NAME: Abu Fares is also a minor name in the TV series (COPYRIGHT_REGISTER C-013). Reviewer: does it evoke that show? If yes, propose a swap.",
    "unit.haddad.name": "NAME: Abu Khater is also a minor name in the TV series (C-013). Same question as Abu Fares.",
    "npc.natour.name": "NAME: see unit.natour.name.",
}
for k in flags:
    assert k in en, k

sections = [
    ("hud", "1. Main HUD and buttons", ["hud.", "prompt.talk", "prompt.inspect"]),
    ("npc", "2. Lane neighbours and the first errand", ["npc.abu_nadim", "npc.sitt_wardeh", "npc.khalil_tailor", "dlg.common", "dlg.abu_nadim", "dlg.sitt_wardeh", "dlg.khalil_tailor", "quest.delivery_kaak"]),
    ("ep1", "3. Story: Season 1 · Episode 1 (Wedding Eve)", ["npc.hajj_rashid", "dlg.hajj_rashid", "quest.s1e1", "clue.", "notify.clue_found"]),
    ("wardrobe", "4. Wardrobe and tailor shop", ["item.", "wardrobe.", "shop."]),
    ("store", "5. Store and Robux products", ["store.", "product.", "pass.vip", "pass.fast_mode", "pass.extra_slot", "pass.lane_patron", "notify.qirsh_added", "notify.pass_unlocked", "notify.coming_soon", "notify.lira_added", "notify.stones_added", "notify.premium_unlocked", "notify.levels_added", "notify.bundle_granted", "notify.restricted"]),
    ("notify", "6. Notifications (toasts)", ["notify."]),
    ("kick", "7. Disconnect messages (shown by Roblox)", ["kick."]),
    ("modes", "8. Tower defense: modes, arenas and party queue", ["mode.", "arena.", "difficulty.", "queue.", "prompt.portal"]),
    ("match", "9. Tower defense: match HUD", ["match.", "target."]),
    ("enemies", "10. Enemies", ["enemy."]),
    ("roster", "11. Defender roster, rarities, roles and traits", ["unit.", "rarity.", "role.", "trait."]),
    ("units", "12. Units screen", ["units."]),
    ("summon", "13. Summon screen", ["summon.", "banner."]),
    ("diary", "14. Lane Diary (season pass)", ["pass."]),
    ("codes", "15. Codes, daily reward and reward labels", ["codes.", "daily.", "reward."]),
    ("lobby", "16. Lobby NPCs (tower-defense square)", ["npc.barber", "npc.qahwaji", "npc.natour", "dlg.barber", "dlg.qahwaji", "dlg.natour"]),
    ("signs", "17. World signs (3D text in the lane)", ["sign."]),
    # Everything newer than the sections above (AFK room, settings, Play, story, events, touch HUD, ...).
    ("other", "18. Other screens (AFK room, settings, Play, story, events, touch HUD)", [""]),
]
# Most specific prefix wins, so "notify.lira_added" goes to Store, not Notifications.
def section_of(key):
    best, best_len = None, -1
    for sid, _, prefixes in sections:
        for p in prefixes:
            if key.startswith(p) and len(p) > best_len:
                best, best_len = sid, len(p)
    assert best, key
    return best

by = {sid: [] for sid, _, _ in sections}
for k in en_order:
    by[section_of(k)].append(k)

def cell(s):
    return s.replace("\\\"", "\"").replace("|", "\\|").replace("\n", " ")

def bidi(s):
    # No invisible bidi marks: reviewers copy this text back into Strings.luau.
    return cell(s)

n_flag = sum(1 for k in en if k in flags)
lines = []
w = lines.append
w("# Arabic strings: native-speaker review pack")
w("")
w("*Generated 2026-10-16 from `src/shared/Config/Strings.luau` (branch `feat/vertical-slice`, commit 2b0b800). "
  f"{len(en)} keys in {len(sections)} screens; Claude flagged {n_flag} of them. Regenerate with `python -I docs/review/build_arabic_review.py .` after edits rather than "
  "hand-editing the Arabic column.*")
w("")
w("## For the reviewer")
w("")
w("The game is set in a 1930s Damascus lane (*hara*). Every Arabic line was drafted by an AI (Claude) and **no native "
  "speaker has read it yet**. We want natural **Damascene / Shami** colloquial for dialogue and short, clear "
  "colloquial for buttons. Players are mostly children and teenagers across the Arab world, so it should also be "
  "easy for a Gulf or Egyptian kid to read.")
w("")
w("How to review:")
w("")
w("1. Read each row. The **Claude flag** column is our own guess at a problem; it may be wrong. Agree, disagree or ignore it.")
w("2. If the Arabic is fine, put `OK` in the last column. If not, write your version in **Correction** (keep `{n}`, `{name}` and other `{…}` placeholders exactly as they are; they are replaced by numbers or names in the game).")
w("3. Tell us about anything that sounds Lebanese, Egyptian, Gulf or too formal (فصحى) where a Damascene would speak differently.")
w("4. Tell us if anything is rude, religiously insensitive, embarrassing for kids, or sounds like it was copied from the TV series *Bab al-Hara* (names, catch-phrases).")
w("5. Return this file (or a copy with the last two columns filled). Name and date at the bottom, please.")
w("")
w("Tag legend in the flag column: **MEANING** may say the wrong thing · **DIALECT** not Damascene · "
  "**STYLE** awkward or inconsistent · **NAME** character-name check.")
w("")
w("## Questions that cut across many rows")
w("")
w("1. **Gender of address.** Dialogue says «يا ابني», «إنت», masculine imperatives (روح، خود، اكبس). The player can be a girl. Keep masculine as the generic, or rephrase lines to be neutral? (The game has no gender setting today.)")
w("2. **«الرجال» for units.** The defenders include a woman (Umm Zaki) and a cat, but the UI calls them «الرجال / رجّال». Keep it as period flavour, or use «المدافعين»?")
w("3. **Digits.** Hard-coded numbers use Arabic-Indic digits (١٠٠، ٢٠ موجة), but every `{n}` placeholder is filled with Western digits (1, 2, 3) and some strings use «3x», «R$», «$». So players will see «الموسم ١ · الحلقة 1». Which do you prefer for kids in Syria, the Gulf and Egypt: all Western digits, or all Arabic-Indic? (Code change; just tell us which.)")
w("4. **Number agreement.** Strings like «{n} يوم», «{n} حجر صفات», «{n}/{max} لاعبين» are right for some numbers and wrong for others (3–10 take the plural). Tell us which rows matter most; we can add proper plural forms.")
w("5. **«مش» vs «مو».** We used «مش» in several places; we believe Damascene speech uses «مو». Rows are flagged; confirm.")
w("6. **Gate vs portal.** The lane gate is «الباب» in the tower-defense screens but «البوابة» in the Episode 1 story, and the portals in the square are also «بوابة». Suggest one word for each.")
w("7. **Character names (copyright register C-013).** Abu Fares (watchman) and Abu Khater (blacksmith) also appear as minor names in *Bab al-Hara*. Do they make you think of the show? If yes, suggest replacements. Same question for any other name in section 11.")
w("8. **Not in this file:** `src/server/World/Arena.luau` line 113 hard-codes the sign «حارة الياسمين» (same as `sign.lane`).")
w("")
w("## Contents")
w("")
for sid, title, _ in sections:
    flagged = sum(1 for k in by[sid] if k in flags)
    anchor = re.sub(r"[^a-z0-9 -]", "", title.lower()).replace(" ", "-")
    w(f"- [{title}](#{anchor}) — {len(by[sid])} strings, {flagged} flagged")
w("")
for sid, title, _ in sections:
    w(f"## {title}")
    w("")
    w("| # | Key | English | Arabic (current) | Claude flag | Correction | OK? |")
    w("|---|-----|---------|------------------|-------------|------------|-----|")
    for i, k in enumerate(by[sid], 1):
        w(f"| {i} | `{k}` | {cell(en[k])} | {bidi(ar[k])} | {cell(flags.get(k, ''))} |  |  |")
    w("")
w("## Sign-off")
w("")
w("| Reviewer | Dialect / country | Date | Sections reviewed | Notes |")
w("|----------|-------------------|------|-------------------|-------|")
w("|  |  |  |  |  |")
w("")
w("*After review: apply corrections in `src/shared/Config/Strings.luau` (the `ar` table), run `lune run tests/run` "
  "(checks every key exists in both languages), and set COPYRIGHT_REGISTER C-013 and RELEASE_CHECKLIST §C "
  "\"Cultural review\" accordingly.*")

out = root / "docs/review/ARABIC_STRINGS_REVIEW.md"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(len(en), "keys,", n_flag, "flagged ->", out)
for sid, title, _ in sections:
    print(f"  {title}: {len(by[sid])}")

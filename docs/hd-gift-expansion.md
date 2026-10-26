# HD gift expansion

Adds 50 distinct gifts (IDs 055–104) without changing existing IDs or prices.
20 gifts cost 1–100 coins, 20 cost 160–1000, and 10 cost 1200–5000.
The original 150-coin tier boundary remains compatible.

Individual transparent 1280px assets replace atlas cropping for the additions and
legacy gifts 002 (Crimson Velocity) and 026 (Golden Bouquet). Other legacy gifts
still use their original 192px atlas cells; this release does not claim to upgrade them.
WebP quality 92 preserves alpha and reduces package size; decoding follows the
physical display size, capped at 1280px, rather than decoding every full image in the grid.

## Art direction

Built-in image generation, one call per asset. Base prompt:
“Individual premium WorldVoice virtual gift sprite. Exquisite crisp studio 3D CGI,
detailed materials, distinctive silhouette and colors. Entire object centered,
10% padding, square 1280x1280, transparent background. No floor, backdrop, text,
logo or watermark. Single gift, never a sheet.”

Existing car and bouquet were regenerated using the legacy atlas as a visual
reference with instructions to preserve their silhouette, colors and viewpoint.

## Catalog

| ID | Gift | Coins |
|---|---|---:|
| wv_gift_055 | Red Panda Hug / حضن الباندا الأحمر | 1 |
| wv_gift_056 | Matcha Cloud / سحابة الماتشا | 3 |
| wv_gift_057 | Strawberry Mochi / موتشي الفراولة | 5 |
| wv_gift_058 | Sunshine Duck / بطة الشمس | 8 |
| wv_gift_059 | Mint Scooter / دراجة النعناع | 10 |
| wv_gift_060 | Lunar Bunny / أرنب القمر | 15 |
| wv_gift_061 | Coral Seahorse / فرس البحر المرجاني | 20 |
| wv_gift_062 | Pixel Robot / روبوت الصداقة | 25 |
| wv_gift_063 | Cherry Skate / لوح الكرز | 30 |
| wv_gift_064 | Peach Axolotl / أكسولوتل الخوخ | 35 |
| wv_gift_065 | Cobalt Teapot / إبريق الكوبالت | 40 |
| wv_gift_066 | Origami Crane / كركي الأوريغامي | 45 |
| wv_gift_067 | Tulip Rainboots / توليب المطر | 50 |
| wv_gift_068 | Amber Vinyl / أسطوانة العنبر | 55 |
| wv_gift_069 | Candy Donut / دونات الحلوى | 60 |
| wv_gift_070 | Sushi Cat / قطة السوشي | 65 |
| wv_gift_071 | Aurora Kite / طائرة الشفق | 70 |
| wv_gift_072 | Desert Lantern / فانوس الصحراء | 80 |
| wv_gift_073 | Lucky Acorn / بلوطة الحظ | 90 |
| wv_gift_074 | Rainbow Pinwheel / دوارة قوس قزح | 100 |
| wv_gift_075 | Amethyst Geode / كهف الجمشت | 160 |
| wv_gift_076 | Copper Rocket / صاروخ النحاس | 180 |
| wv_gift_077 | Moon Rover / عربة القمر | 220 |
| wv_gift_078 | Sunset Sailboat / شراع الغروب | 260 |
| wv_gift_079 | Nebula Jellyfish / قنديل السديم | 300 |
| wv_gift_080 | Silver Cello / تشيلو الفضة | 340 |
| wv_gift_081 | Glacier Wolf / ذئب الجليد | 380 |
| wv_gift_082 | Amber Observatory / مرصد العنبر | 420 |
| wv_gift_083 | Espresso Atelier / آلة الإسبريسو | 460 |
| wv_gift_084 | Pearl Submarine / غواصة اللؤلؤ | 500 |
| wv_gift_085 | Rainbow Toucan / طوقان الألوان | 550 |
| wv_gift_086 | Cherry Blossom Train / قطار الساكورا | 600 |
| wv_gift_087 | Solar Satellite / قمر الطاقة الشمسي | 650 |
| wv_gift_088 | Opal Carousel / دوامة الأوبال | 700 |
| wv_gift_089 | Storm Surfboard / ركوب العاصفة | 750 |
| wv_gift_090 | Glass Octopus / أخطبوط الزجاج | 800 |
| wv_gift_091 | Snow Leopard / نمر الثلج | 850 |
| wv_gift_092 | Enchanted Storybook / كتاب الحكايات | 900 |
| wv_gift_093 | Royal Peacock / طاووس الألوان | 950 |
| wv_gift_094 | Dream Ferris Wheel / عجلة الأحلام | 1000 |
| wv_gift_095 | Interstellar Cruiser / طراد النجوم | 1200 |
| wv_gift_096 | Clockwork Scorpion / عقرب الساعة | 1500 |
| wv_gift_097 | Lunar Kingdom / مملكة القمر | 1800 |
| wv_gift_098 | Abyss Diving Helmet / خوذة الأعماق | 2200 |
| wv_gift_099 | Obsidian Volcano / بركان الأوبسيديان | 2600 |
| wv_gift_100 | Frost Mammoth / ماموث الجليد | 3000 |
| wv_gift_101 | Coral Mermaid / حورية المرجان | 3500 |
| wv_gift_102 | Prismatic Atom / الذرة المنشورية | 4000 |
| wv_gift_103 | Galaxy Gateway / بوابة المجرات | 4500 |
| wv_gift_104 | Worlds in Bloom / عوالم مزهرة | 5000 |

## Individual subject prompts

- 061: coral orange seahorse curled around turquoise seaweed.
- 062: sky blue and cream friendly robot with orange heart.
- 063: cherry red skateboard with aqua wheels and white lightning bolt.
- 064: peach pink axolotl with lilac feathery gills.
- 065: cobalt porcelain teapot with white botanical relief.
- 066: vermilion and ivory folded silk origami crane.
- 067: yellow rainboots holding pink and violet tulips.
- 068: amber vinyl record on a small teal record player.
- 069: A chunky lavender glazed donut with colorful sprinkles and a small bite, charming premium toy render.
- 070: white kitten sitting on salmon sushi cushion.
- 071: magenta turquoise violet silk kite with flowing tail.
- 072: terracotta and cobalt pierced ceramic lantern with warm inner glow.
- 073: chestnut acorn copper cap and fresh green sprout.
- 074: rainbow stained glass pinwheel on short ivory stem.
- 075: A split purple amethyst geode revealing crisp violet crystals inside rough charcoal rock, rich mineral collectible.
- 076: copper cream retro rocket with blue window and short orange exhaust.
- 077: ivory orange six wheel moon rover with camera mast.
- 078: wooden sailboat coral sail on sculptural turquoise wave.
- 079: opal blue translucent jellyfish purple flowing tentacles.
- 080: silver and burgundy cello with elegant bow.
- 081: white arctic wolf on tiny blue ice pedestal.
- 082: miniature copper dome observatory teal telescope.
- 083: A compact cream and copper espresso machine with one tiny cup of coffee, exquisite polished appliance.
- 084: pearl white orange submarine with clear bubble cockpit.
- 085: realistic black toucan with rainbow orange green beak on short branch.
- 086: white pink miniature steam locomotive with cherry blossom details.
- 087: silver orbital satellite with cobalt solar panels.
- 088: opal ivory lavender miniature carousel with three tiny horses.
- 089: orange black surfboard cutting a sculptural cobalt wave.
- 090: turquoise art glass octopus with gracefully curled eight arms.
- 091: natural spotted snow leopard standing on small slate rock.
- 092: An open teal leather magic storybook with luminous miniature paper mountains rising from the pages.
- 093: realistic emerald teal peacock with fully open magnificent tail fan.
- 094: pastel mint pink miniature ferris wheel with opal gondolas.
- 095: sleek silver interstellar spaceship cobalt engines intricate original design.
- 096: A magnificent articulated mechanical scorpion of black titanium and bright copper gears, curled segmented tail, bold luxury sculpture.
- 097: intricate ivory palace on a silver crescent moon floating island.
- 098: An antique brass deep sea diving helmet with round glowing cyan glass portholes and intricate bolts, coral pink accent light.
- 099: A dramatic black obsidian volcano miniature with molten orange lava rivers and a compact crimson eruption, self contained collectible.
- 100: A magnificent ivory tusked woolly mammoth in frosty silver fur with blue crystal armor, full body, majestic stance.
- 101: A graceful fully clothed fantasy mermaid with flowing coral orange tail and turquoise bodice sitting on a small pearl shell, luxurious sculpture.
- 102: An elaborate luminous atomic sculpture with three elliptical chrome electron orbits surrounding a faceted multicolor crystalline nucleus, jewel-like scientific collectible.
- 103: intricate silver violet circular stargate with cosmic center.
- 104: miniature floating planet jade forests pink flowers waterfalls and opal orbital ring.

## Distinct-subject review

Ten overlapping concepts were replaced before app publication. The existing red car and gold bouquet retain their IDs, with replacement HD art, not duplicate store records.

- 069 Candy Donut: A chunky lavender glazed donut with colorful sprinkles and a small bite, charming premium toy render. Transparent standalone 3D collectible, no text or backdrop.

- 075 Amethyst Geode: A split purple amethyst geode revealing crisp violet crystals inside rough charcoal rock, rich mineral collectible. Transparent standalone 3D collectible, no text or backdrop.

- 083 Espresso Atelier: A compact cream and copper espresso machine with one tiny cup of coffee, exquisite polished appliance. Transparent standalone 3D collectible, no text or backdrop.

- 092 Enchanted Storybook: An open teal leather magic storybook with luminous miniature paper mountains rising from the pages. Transparent standalone 3D collectible, no text or backdrop.

- 096 Clockwork Scorpion: A magnificent articulated mechanical scorpion of black titanium and bright copper gears, curled segmented tail, bold luxury sculpture. Transparent standalone 3D collectible, no text or backdrop.

- 098 Abyss Diving Helmet: An antique brass deep sea diving helmet with round glowing cyan glass portholes and intricate bolts, coral pink accent light. Transparent standalone 3D collectible, no text or backdrop.

- 099 Obsidian Volcano: A dramatic black obsidian volcano miniature with molten orange lava rivers and a compact crimson eruption, self contained collectible. Transparent standalone 3D collectible, no text or backdrop.

- 100 Frost Mammoth: A magnificent ivory tusked woolly mammoth in frosty silver fur with blue crystal armor, full body, majestic stance. Transparent standalone 3D collectible, no text or backdrop.

- 101 Coral Mermaid: A graceful fully clothed fantasy mermaid with flowing coral orange tail and turquoise bodice sitting on a small pearl shell, luxurious sculpture. Transparent standalone 3D collectible, no text or backdrop.

- 102 Prismatic Atom: An elaborate luminous atomic sculpture with three elliptical chrome electron orbits surrounding a faceted multicolor crystalline nucleus, jewel-like scientific collectible. Transparent standalone 3D collectible, no text or backdrop.

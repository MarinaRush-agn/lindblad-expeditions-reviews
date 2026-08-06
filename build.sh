#!/bin/bash
# build.sh — assembles all 17 pages from components/ + content/ into static index.html files.
# Reads header/footer/content, injects per-page <head> metadata and JSON-LD, converts
# absolute "/..." paths to relative per page depth, and replaces {{UPDATED}}/{{DATE}} tokens.
# Run: bash build.sh
set -e

echo "== Verifying computed scores against _source/ranking.json =="
node _source/verify-scores.mjs

UPDATED=$(date +"%B %Y")
BUILD_DATE_ISO=$(date +"%Y-%m-%d")

# BUILD-SPEC v2 §1.2 — SITE_URL must always equal the domain the site is actually served from.
# Canonical, Open Graph url, sitemap.xml and every JSON-LD url derive from this single variable.
SITE_URL="https://marinarush-agn.github.io/lindblad-expeditions-reviews"   # staging (GitHub Pages)
# SITE_URL="https://lindblad-expeditions-reviews.com"                      # production — flip when the domain is live, rebuild, confirm canonical matches, confirm no noindex survives anywhere.
BASE_URL="$SITE_URL"

ROBOTS_META="noindex, nofollow"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# assemble OUTFILE DEPTH TITLE DESC CONTENT_FILE CSS_PATH SCHEMA_FILE OG_TYPE CANONICAL
# OUTFILE is the full output path, e.g. "./index.html", "operators/poseidon-expeditions/index.html", "404.html"
assemble() {
  local OUTFILE="$1" DEPTH="$2" TITLE="$3" DESC="$4" CONTENT="$5" CSS="$6" SCHEMA="$7" OGTYPE="$8" CANON="$9"
  local OUTDIR
  OUTDIR="$(dirname "$OUTFILE")"
  local BASE=""
  local ROOT_HREF="./"
  if [ "$DEPTH" = "1" ]; then
    BASE="../"
    ROOT_HREF="../"
  elif [ "$DEPTH" = "2" ]; then
    BASE="../../"
    ROOT_HREF="../../"
  fi

  sed -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
      -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
      -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
      -e "s|{{UPDATED}}|${UPDATED}|g" \
      components/header.html > "$TMPDIR/header.html"

  sed -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
      -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
      -e "s|{{UPDATED}}|${UPDATED}|g" \
      components/footer.html > "$TMPDIR/footer.html"

  sed -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
      -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
      -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
      -e "s|{{UPDATED}}|${UPDATED}|g" \
      "$CONTENT" > "$TMPDIR/content.html"

  mkdir -p "$OUTDIR"
  {
    echo '<!DOCTYPE html>'
    echo '<html lang="en">'
    echo '<head>'
    echo '<meta charset="UTF-8">'
    echo '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
    echo "<meta name=\"robots\" content=\"${ROBOTS_META}\">"
    echo "<title>${TITLE}</title>"
    echo "<meta name=\"description\" content=\"${DESC}\">"
    echo "<link rel=\"canonical\" href=\"${CANON}\">"
    echo "<meta property=\"og:title\" content=\"${TITLE}\">"
    echo "<meta property=\"og:description\" content=\"${DESC}\">"
    echo "<meta property=\"og:type\" content=\"${OGTYPE}\">"
    echo "<meta property=\"og:url\" content=\"${CANON}\">"
    echo "<link rel=\"icon\" href=\"${BASE}images/favicon.svg\" type=\"image/svg+xml\">"
    echo "<link rel=\"icon\" href=\"${BASE}images/favicon-32.png\" sizes=\"32x32\">"
    echo "<link rel=\"apple-touch-icon\" href=\"${BASE}images/apple-touch-icon.png\">"
    echo "<link rel=\"stylesheet\" href=\"${BASE}css/global.css\">"
    echo "<link rel=\"stylesheet\" href=\"${BASE}${CSS}\">"
    if [ -n "$SCHEMA" ] && [ -f "$SCHEMA" ]; then
      sed "s|{{DATE}}|${BUILD_DATE_ISO}|g" "$SCHEMA"
    fi
    echo '</head>'
    echo '<body>'
    cat "$TMPDIR/header.html"
    echo '<main>'
    cat "$TMPDIR/content.html"
    echo '</main>'
    cat "$TMPDIR/footer.html"
    echo "<script src=\"${BASE}js/nav.js\"></script>"
    echo '</body>'
    echo '</html>'
  } > "$OUTFILE"

  echo "Built: $OUTFILE"
}

ORG_SCRIPT="<script type=\"application/ld+json\">{\"@context\":\"https://schema.org\",\"@type\":\"Organization\",\"name\":\"Expedition Review Desk\",\"url\":\"${BASE_URL}/\"}</script>"

# ---------------------------------------------------------------------------
# HOMEPAGE — Lindblad Expeditions brand-review hub (BUILD-SPEC v2 §5.1 / §8)
# ---------------------------------------------------------------------------
cat > "$TMPDIR/schema-home.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"Lindblad Expeditions Reviews 2026: Ratings, Ships and Complaints Across Every Destination","description":"Lindblad Expeditions scores on Cruise Critic, Travelstride and Trustpilot, plus which ships, destinations and complaints the reviews actually cover.","url":"${BASE_URL}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[
{"@type":"Question","name":"Why are Lindblad Expeditions so expensive?","acceptedAnswer":{"@type":"Answer","text":"The fare includes full-time National Geographic naturalists, a certified photo instructor on every ship, and on the polar vessels undersea specialists and ROV operations, none of which cheaper operators in this space include as standard. Lindblad still scores only 60 out of 100 on price-to-value in this site's comparison model."}},
{"@type":"Question","name":"Does Lindblad Expeditions have a childcare program?","acceptedAnswer":{"@type":"Answer","text":"No. Lindblad has no kids' club, no supervised drop-off care, and no children's menu fleet-wide. It runs National Geographic Explorers-in-Training, an educational activity programme for under-18s, which is activity programming, not childcare."}},
{"@type":"Question","name":"Are there family-friendly Lindblad Expeditions departures?","acceptedAnswer":{"@type":"Answer","text":"Yes. National Geographic Explorers-in-Training runs on every Alaska, Baja California and Galapagos departure and select Antarctica and Iceland sailings, with a minimum age of six on most family departures."}},
{"@type":"Question","name":"Which is the best expedition cruise line?","acceptedAnswer":{"@type":"Answer","text":"It depends what you're optimising for. This site's ten-operator Antarctic comparison ranks by a published formula weighting shore time, ratings, price and expedition depth; Lindblad ranks fourth of ten there specifically."}},
{"@type":"Question","name":"What do negative Lindblad Expeditions reviews mention?","acceptedAnswer":{"@type":"Answer","text":"Overwhelmingly, pre-departure administration, booking handling, misrepresented flight class, marketing promises that didn't match delivery, rather than the voyage itself, which is rated highly in the same review sample."}}
]}
</script>
EOF

assemble "index.html" "0" \
  "Lindblad Expeditions Reviews 2026: 3 Verified Ratings" \
  "Lindblad Expeditions scores on Cruise Critic, Travelstride and Trustpilot, plus which ships, destinations and complaints the reviews actually cover." \
  "content/main-lindblad.html" "css/ranking.css" "$TMPDIR/schema-home.html" "website" "${BASE_URL}/"

# ---------------------------------------------------------------------------
# ANTARCTICA CRUISE COMPARISON HUB (moved from "/" — BUILD-SPEC v2 §5.2)
# ---------------------------------------------------------------------------
cat > "$TMPDIR/schema-comparison.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"Antarctica Cruise Reviews 2026: Ten Expedition Operators, Scored","description":"A scored comparison of ten Antarctic cruise operators on shore time, ratings, price and expedition depth.","url":"${BASE_URL}/antarctica-cruise-comparison/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Expedition Review Desk","item":"${BASE_URL}/"},{"@type":"ListItem","position":2,"name":"Antarctica Cruise Comparison","item":"${BASE_URL}/antarctica-cruise-comparison/"}]}</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"ItemList","itemListElement":[
{"@type":"ListItem","position":1,"name":"Poseidon Expeditions","url":"${BASE_URL}/operators/poseidon-expeditions/"},
{"@type":"ListItem","position":2,"name":"Aurora Expeditions","url":"${BASE_URL}/operators/aurora-expeditions/"},
{"@type":"ListItem","position":3,"name":"Oceanwide Expeditions","url":"${BASE_URL}/operators/oceanwide-expeditions/"},
{"@type":"ListItem","position":4,"name":"Lindblad Expeditions","url":"${BASE_URL}/"},
{"@type":"ListItem","position":5,"name":"Quark Expeditions","url":"${BASE_URL}/operators/quark-expeditions/"},
{"@type":"ListItem","position":6,"name":"Scenic Luxury Cruises & Tours","url":"${BASE_URL}/operators/scenic/"},
{"@type":"ListItem","position":7,"name":"Ponant","url":"${BASE_URL}/operators/ponant/"},
{"@type":"ListItem","position":8,"name":"Silversea Cruises","url":"${BASE_URL}/operators/silversea/"},
{"@type":"ListItem","position":9,"name":"HX (Hurtigruten Expeditions)","url":"${BASE_URL}/operators/hurtigruten-hx/"},
{"@type":"ListItem","position":10,"name":"Holland America Line","url":"${BASE_URL}/operators/holland-america-line/"}
]}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[
{"@type":"Question","name":"Are Antarctica cruise reviews reliable?","acceptedAnswer":{"@type":"Answer","text":"Only as reliable as the sample behind them. Cruise Critic and Travelstride can disagree by four-tenths of a point on the same operator because their sample sizes differ by a factor of six. This site states which sample it used for every rating and why, rather than picking whichever number looks better."}},
{"@type":"Question","name":"What do most negative Lindblad Expeditions reviews mention?","acceptedAnswer":{"@type":"Answer","text":"Pre-departure administration, booking handling, misrepresented flight class, and marketing promises that did not match delivery, not the voyage itself. Onboard experience and naturalist quality are consistently rated highly in the same reviews that criticise the office that booked the trip."}},
{"@type":"Question","name":"Which operators have the best reviews for small groups?","acceptedAnswer":{"@type":"Answer","text":"Four operators post shore-time scores above 70 in this ranking: Poseidon Expeditions (114 passengers), Lindblad Expeditions (137.3 effective capacity), Oceanwide Expeditions (137.7 effective across its three ice-classed ships), and Aurora Expeditions (139 effective capacity). See the full ranking table for a direct comparison."}},
{"@type":"Question","name":"How much does an Antarctica cruise cost?","acceptedAnswer":{"@type":"Answer","text":"Published berth prices in this ranking run from $2,000 (Holland America, no landings) to $50,000 (Silversea's top suites), excluding flights to Ushuaia or Punta Arenas and excluding single supplement for solo travellers, which this site does not have a figure for on any operator."}},
{"@type":"Question","name":"Does ship size really change how much time you spend ashore?","acceptedAnswer":{"@type":"Answer","text":"Yes, arithmetically. IAATO caps a shore party at 100 people, so above that threshold guests split into groups and take turns. At equal voyage length, a 100-passenger ship and a 200-passenger ship differ by roughly double the actual time spent ashore."}}
]}
</script>
EOF

assemble "antarctica-cruise-comparison/index.html" "1" \
  "Antarctica Cruise Reviews 2026: 10 Operators Compared" \
  "A scored comparison of ten Antarctic cruise operators on shore time, ratings, price and expedition depth. Updated ${UPDATED}." \
  "content/main-ranking.html" "css/ranking.css" "$TMPDIR/schema-comparison.html" "website" "${BASE_URL}/antarctica-cruise-comparison/"

# ---------------------------------------------------------------------------
# OPERATOR PAGES — helper to cut down repetition
# ---------------------------------------------------------------------------
# operator_faq SLUG Q1 A1 Q2 A2 Q3 A3  ->  writes schema file to $TMPDIR/schema-op-SLUG.html
operator_schema() {
  local SLUG="$1" TITLE="$2" DESC="$3" Q1="$4" A1="$5" Q2="$6" A2="$7" Q3="$8" A3="$9"
  cat > "$TMPDIR/schema-op-${SLUG}.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"${TITLE}","description":"${DESC}","url":"${BASE_URL}/operators/${SLUG}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Expedition Review Desk","item":"${BASE_URL}/"},{"@type":"ListItem","position":2,"name":"${TITLE}","item":"${BASE_URL}/operators/${SLUG}/"}]}</script>
<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"${Q1}","acceptedAnswer":{"@type":"Answer","text":"${A1}"}},{"@type":"Question","name":"${Q2}","acceptedAnswer":{"@type":"Answer","text":"${A2}"}},{"@type":"Question","name":"${Q3}","acceptedAnswer":{"@type":"Answer","text":"${A3}"}}]}</script>
EOF
}

operator_schema "poseidon-expeditions" \
  "Poseidon Expeditions Reviews 2026 | Antarctic Score" \
  "Poseidon Expeditions ranks 1st of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "Is Poseidon Expeditions a good choice for solo travellers?" "Gratuities are explicitly excluded from the published fare, and this site has no verified single-supplement figure for Poseidon. Ask directly before booking." \
  "Does the Sea Spirit's age affect the experience?" "Some reviewers note the ship shows its age in cabin fittings despite annual refurbishment, though the expedition-team and landing experience are rated highly regardless." \
  "How does Poseidon's one-ship fleet compare to larger operators?" "One ship means no helicopters, no submersible, and a single route family, scoring 80 on expedition depth against Lindblad's 92 and Ponant's 95, the trade-off for the ranking's highest shore-time score."
assemble "operators/poseidon-expeditions/index.html" "2" \
  "Poseidon Expeditions Reviews 2026 | Antarctic Score" \
  "Poseidon Expeditions ranks 1st of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "content/operator-poseidon-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-poseidon-expeditions.html" "article" "${BASE_URL}/operators/poseidon-expeditions/"

operator_schema "oceanwide-expeditions" \
  "Oceanwide Expeditions Reviews 2026 | Antarctic Score" \
  "Oceanwide Expeditions ranks 3rd of 10 Antarctic operators in 2026 on shore time, ratings, price and expedition depth." \
  "Which Oceanwide Expeditions ship has the shortest landing wait?" "The 33-berth Rembrandt van Rijn sailing vessel is under the IAATO 100-guest limit, so every landing goes ashore together with no rotation at all, the shortest possible wait of any ship in this ranking." \
  "Are Oceanwide Expeditions Antarctica reviews consistent across ships?" "Not entirely. Hondius reviews describe a more polished experience than the smaller, plainer ships; food-service complaints recur more on the larger vessels than on Plancius or the sailing vessel." \
  "Is a parka included with Oceanwide Expeditions?" "No, unlike most operators in this ranking, Oceanwide does not include a parka loan, one reason its price/value score of 90 sits above operators that do include one."
assemble "operators/oceanwide-expeditions/index.html" "2" \
  "Oceanwide Expeditions Reviews 2026 | Antarctic Score" \
  "Oceanwide Expeditions ranks 3rd of 10 Antarctic operators in 2026 on shore time, ratings, price and expedition depth." \
  "content/operator-oceanwide-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-oceanwide-expeditions.html" "article" "${BASE_URL}/operators/oceanwide-expeditions/"

operator_schema "aurora-expeditions" \
  "Aurora Expeditions Reviews 2026 | Antarctic Score" \
  "Aurora Expeditions ranks 2nd of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "Is the Aurora Expeditions X-Bow hull unique to Aurora?" "No. The inverted bow shape cuts through waves instead of slamming over them, and reviewers credit it with a smoother Drake Passage crossing, but Lindblad's National Geographic Endurance and National Geographic Resolution use the same X-Bow design, so it is not an Aurora exclusive." \
  "Are Aurora Expeditions Svalbard cruise reviews different from Antarctica reviews?" "The same fleet and expedition-team praise recur in both regions; this page and the ranking focus on the Antarctic sailings specifically, where the 100-passenger-plus capacity drives the short-rotation landing style." \
  "Does Aurora Expeditions have helicopters?" "No. Unlike Quark's Ultramarine, no ship in Aurora's fleet carries a helicopter; its expedition-depth score of 78 reflects the X-Bow hull and activity roster rather than aircraft-supported landings."
assemble "operators/aurora-expeditions/index.html" "2" \
  "Aurora Expeditions Reviews 2026 | Antarctic Score" \
  "Aurora Expeditions ranks 2nd of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "content/operator-aurora-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-aurora-expeditions.html" "article" "${BASE_URL}/operators/aurora-expeditions/"

operator_schema "quark-expeditions" \
  "Quark Expeditions Reviews 2026 | Antarctic Score" \
  "Quark Expeditions ranks 5th of 10 Antarctic operators in 2026, with helicopter-equipped Ultramarine scored on shore time and expedition depth." \
  "Do Quark Expeditions Antarctica reviews mention the helicopters?" "Yes, repeatedly and positively. Ultramarine's two onboard helicopters are consistently cited as a standout differentiator for reaching sites Zodiacs cannot." \
  "What do Quark Expeditions cruise reviews say about communication?" "A recurring complaint involves thin updates during weather delays and at least one unannounced cabin reassignment; Quark has publicly acknowledged this feedback and said it would strengthen pre-voyage communication." \
  "Are Quark Expeditions Svalbard reviews relevant to its Antarctica score?" "No. This ranking scores Quark's Antarctic fleet and operations specifically; its Svalbard programme uses different ships and itineraries not covered by this scoring model."
assemble "operators/quark-expeditions/index.html" "2" \
  "Quark Expeditions Reviews 2026 | Antarctic Score" \
  "Quark Expeditions ranks 5th of 10 Antarctic operators in 2026, with helicopter-equipped Ultramarine scored on shore time and expedition depth." \
  "content/operator-quark-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-quark-expeditions.html" "article" "${BASE_URL}/operators/quark-expeditions/"

operator_schema "scenic" \
  "Scenic Antarctica Cruise Reviews 2026 | Score" \
  "Scenic Luxury Cruises & Tours ranks 6th of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "Does Scenic Eclipse actually use its helicopters and submersible in Antarctica?" "Reviewers note the hardware is present and impressive, but some report the shore-excursion programme does not always make full use of it. Ask an agent how frequently these are deployed on the specific itinerary you are booking." \
  "How does Scenic's price compare to the rest of this ranking?" "At $20,000 and up, Scenic has the second-highest entry price in this ranking, offset by an editorial price/value score of 45 that reflects extensive inclusions such as drinks, gratuities and butler service." \
  "What do Scenic Antarctica cruise reviews complain about most?" "A gap between the marketed premium positioning and delivered service responsiveness on some voyages, plus isolated operational issues such as charter-flight delays."
assemble "operators/scenic/index.html" "2" \
  "Scenic Antarctica Cruise Reviews 2026 | Score" \
  "Scenic Luxury Cruises & Tours ranks 6th of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "content/operator-scenic.html" "css/operator.css" "$TMPDIR/schema-op-scenic.html" "article" "${BASE_URL}/operators/scenic/"

operator_schema "ponant" \
  "Ponant Antarctica Reviews 2026 | PC2 Icebreaker" \
  "Ponant ranks 7th of 10 Antarctic operators in 2026. Le Commandant Charcot is the only PC2 icebreaker in this ranking, reaching the Weddell Sea." \
  "What makes Le Commandant Charcot different from other Antarctic ships?" "It is the only Polar Class 2 icebreaker in the world's tourism fleet, a classification that lets it reach the Weddell Sea, waters no other operator in this ranking's fleet can access." \
  "Is the onboard experience in English on Ponant?" "Not entirely. Non-French-speaking guests report some in-cabin content is only in French despite English translation elsewhere. Ask directly what language onboard programming runs in before booking." \
  "Does Ponant guarantee landing at the Weddell Sea's Emperor penguin colonies?" "No. At least one reviewer reported a missed colony landing due to weather and ice conditions, access depends on conditions even on the icebreaker-class Charcot."
assemble "operators/ponant/index.html" "2" \
  "Ponant Antarctica Reviews 2026 | PC2 Icebreaker" \
  "Ponant ranks 7th of 10 Antarctic operators in 2026. Le Commandant Charcot is the only PC2 icebreaker in this ranking, reaching the Weddell Sea." \
  "content/operator-ponant.html" "css/operator.css" "$TMPDIR/schema-op-ponant.html" "article" "${BASE_URL}/operators/ponant/"

operator_schema "silversea" \
  "Silversea Expeditions Reviews 2026 | Antarctic" \
  "Silversea Cruises ranks 8th of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "Do Silversea cruises expeditions reviews mention missed Antarctica landings?" "Yes, in a recurring and well-corroborated pattern across multiple sailings, including at least one voyage where guests never reached Antarctica due to weather and logistics." \
  "What is included in the Silversea Antarctica price?" "Premium drinks, gratuities, butler service and charter flights are included on Silversea's Antarctic sailings, among the most generous inclusion lists in this ranking, offsetting its high headline price." \
  "Which Silversea ship has the shortest landing wait?" "Silver Endeavour, capped at 200 in Antarctic waters, against 240 for Silver Cloud and Silver Wind. The smaller cap means fewer rotation shifts per landing."
assemble "operators/silversea/index.html" "2" \
  "Silversea Expeditions Reviews 2026 | Antarctic" \
  "Silversea Cruises ranks 8th of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "content/operator-silversea.html" "css/operator.css" "$TMPDIR/schema-op-silversea.html" "article" "${BASE_URL}/operators/silversea/"

operator_schema "hurtigruten-hx" \
  "HX Expeditions Reviews 2026 | Antarctic Score" \
  "HX (Hurtigruten Expeditions) ranks 9th of 10 in 2026, with the longest landing rotation of any operator that still lands passengers." \
  "What do HX expeditions antarctica reviews say about landing time?" "At 500 passengers, HX runs the longest multi-stage rotation in this ranking and posts the lowest shore-time score, 20.0, of any operator that still lands passengers at all." \
  "Are Hurtigruten expeditions reviews consistent on value?" "No, reviewers split sharply, with some calling it the best value in the category and others disputing the premium label after charter-flight logistics failures on specific voyages." \
  "Does HX have a science centre onboard?" "Yes, both Roald Amundsen and Fridtjof Nansen carry an onboard science centre, part of the hybrid-powered fleet's expedition-depth score of 65."
assemble "operators/hurtigruten-hx/index.html" "2" \
  "HX Expeditions Reviews 2026 | Antarctic Score" \
  "HX (Hurtigruten Expeditions) ranks 9th of 10 in 2026, with the longest landing rotation of any operator that still lands passengers." \
  "content/operator-hurtigruten-hx.html" "css/operator.css" "$TMPDIR/schema-op-hurtigruten-hx.html" "article" "${BASE_URL}/operators/hurtigruten-hx/"

operator_schema "holland-america-line" \
  "Holland America Antarctica Review 2026" \
  "Holland America ranks 10th of 10 in this 2026 ranking. Its ships make no landings in Antarctica at all. Here is what that means for travellers." \
  "Does Holland America land passengers in Antarctica?" "No. Under the Antarctic Treaty System, vessels carrying more than 500 passengers cannot land passengers in Antarctica at all; Holland America's Antarctic product is scenic cruising along the coast only." \
  "Why does Holland America rank last if the price/value score is the highest?" "Because price/value is only 20% of the total score. Shore time is 35% and Holland America scores zero there, since it makes no landings, a low overall score reflecting a different product category, not a poor cruise." \
  "Is a Holland America Antarctica cruise a real Antarctica trip?" "It is a real trip to Antarctic waters and coastline, viewed from the ship, without ever going ashore. Whether that satisfies seeing Antarctica is a personal call this page leaves to the reader."
assemble "operators/holland-america-line/index.html" "2" \
  "Holland America Antarctica Review 2026" \
  "Holland America ranks 10th of 10 in this 2026 ranking. Its ships make no landings in Antarctica at all. Here is what that means for travellers." \
  "content/operator-holland-america-line.html" "css/operator.css" "$TMPDIR/schema-op-holland-america-line.html" "article" "${BASE_URL}/operators/holland-america-line/"

# ---------------------------------------------------------------------------
# DESTINATION PAGES (BUILD-SPEC v2 §5 — /destinations/{slug}/)
# ---------------------------------------------------------------------------
destination_schema() {
  local SLUG="$1" TITLE="$2" DESC="$3"
  cat > "$TMPDIR/schema-dest-${SLUG}.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"${TITLE}","description":"${DESC}","url":"${BASE_URL}/destinations/${SLUG}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Expedition Review Desk","item":"${BASE_URL}/"},{"@type":"ListItem","position":2,"name":"${TITLE}","item":"${BASE_URL}/destinations/${SLUG}/"}]}</script>
EOF
}

destination_schema "antarctica" \
  "Lindblad Expeditions in Antarctica: Reviews 2026" \
  "What reviewers say about Lindblad's three Antarctic ships, how the destination compares to the rest of the operator field, and what the complaints concentrate on."
assemble "destinations/antarctica/index.html" "2" \
  "Lindblad Expeditions in Antarctica: Reviews 2026" \
  "What reviewers say about Lindblad's three Antarctic ships, how the destination compares to the rest of the operator field, and what the complaints concentrate on." \
  "content/destination-antarctica.html" "css/operator.css" "$TMPDIR/schema-dest-antarctica.html" "article" "${BASE_URL}/destinations/antarctica/"

destination_schema "galapagos" \
  "Lindblad Expeditions in the Galapagos: Reviews 2026" \
  "Why the Galapagos is Lindblad's most positively reviewed destination, which ships sail there, and what reviewers say."
assemble "destinations/galapagos/index.html" "2" \
  "Lindblad Expeditions in the Galapagos: Reviews 2026" \
  "Why the Galapagos is Lindblad's most positively reviewed destination, which ships sail there, and what reviewers say." \
  "content/destination-galapagos.html" "css/operator.css" "$TMPDIR/schema-dest-galapagos.html" "article" "${BASE_URL}/destinations/galapagos/"

destination_schema "alaska" \
  "Lindblad Expeditions in Alaska: Reviews 2026" \
  "What reviewers say about Lindblad's Alaska sailings on National Geographic Venture and Quest, and what the complaints concentrate on."
assemble "destinations/alaska/index.html" "2" \
  "Lindblad Expeditions in Alaska: Reviews 2026" \
  "What reviewers say about Lindblad's Alaska sailings on National Geographic Venture and Quest, and what the complaints concentrate on." \
  "content/destination-alaska.html" "css/operator.css" "$TMPDIR/schema-dest-alaska.html" "article" "${BASE_URL}/destinations/alaska/"

destination_schema "arctic-svalbard" \
  "Lindblad Expeditions in the Arctic & Svalbard: Reviews 2026" \
  "The Svalbard review titled 'VERY Disappointed' that ranks for this search, examined directly, alongside the wider Arctic review pattern."
assemble "destinations/arctic-svalbard/index.html" "2" \
  "Lindblad Expeditions in the Arctic & Svalbard: Reviews 2026" \
  "The Svalbard review titled 'VERY Disappointed' that ranks for this search, examined directly, alongside the wider Arctic review pattern." \
  "content/destination-arctic-svalbard.html" "css/operator.css" "$TMPDIR/schema-dest-arctic-svalbard.html" "article" "${BASE_URL}/destinations/arctic-svalbard/"

destination_schema "baja-california" \
  "Lindblad Expeditions in Baja California: Reviews 2026" \
  "What reviewers say about Lindblad's winter whale-watching season in Baja California and the Sea of Cortez."
assemble "destinations/baja-california/index.html" "2" \
  "Lindblad Expeditions in Baja California: Reviews 2026" \
  "What reviewers say about Lindblad's winter whale-watching season in Baja California and the Sea of Cortez." \
  "content/destination-baja-california.html" "css/operator.css" "$TMPDIR/schema-dest-baja-california.html" "article" "${BASE_URL}/destinations/baja-california/"

# ---------------------------------------------------------------------------
# SHIP PAGES (BUILD-SPEC v2 §5 — /ships/{slug}/)
# ---------------------------------------------------------------------------
ship_schema() {
  local SLUG="$1" TITLE="$2" DESC="$3"
  cat > "$TMPDIR/schema-ship-${SLUG}.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"${TITLE}","description":"${DESC}","url":"${BASE_URL}/ships/${SLUG}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Expedition Review Desk","item":"${BASE_URL}/"},{"@type":"ListItem","position":2,"name":"${TITLE}","item":"${BASE_URL}/ships/${SLUG}/"}]}</script>
EOF
}

ship_schema "national-geographic-explorer" \
  "National Geographic Explorer Review 2026" \
  "148-guest Lindblad polar ship: history, equipment, and what Cruise Critic reviewers say."
assemble "ships/national-geographic-explorer/index.html" "2" \
  "National Geographic Explorer Review 2026" \
  "148-guest Lindblad polar ship: history, equipment, and what Cruise Critic reviewers say." \
  "content/ship-national-geographic-explorer.html" "css/operator.css" "$TMPDIR/schema-ship-national-geographic-explorer.html" "article" "${BASE_URL}/ships/national-geographic-explorer/"

ship_schema "national-geographic-resolution" \
  "National Geographic Resolution Review 2026" \
  "138-guest Lindblad X-Bow polar ship: history, equipment, and what Cruise Critic reviewers say."
assemble "ships/national-geographic-resolution/index.html" "2" \
  "National Geographic Resolution Review 2026" \
  "138-guest Lindblad X-Bow polar ship: history, equipment, and what Cruise Critic reviewers say." \
  "content/ship-national-geographic-resolution.html" "css/operator.css" "$TMPDIR/schema-ship-national-geographic-resolution.html" "article" "${BASE_URL}/ships/national-geographic-resolution/"

ship_schema "national-geographic-endurance" \
  "National Geographic Endurance Review 2026" \
  "126-guest Lindblad X-Bow polar ship: history, equipment, and what Cruise Critic reviewers say."
assemble "ships/national-geographic-endurance/index.html" "2" \
  "National Geographic Endurance Review 2026" \
  "126-guest Lindblad X-Bow polar ship: history, equipment, and what Cruise Critic reviewers say." \
  "content/ship-national-geographic-endurance.html" "css/operator.css" "$TMPDIR/schema-ship-national-geographic-endurance.html" "article" "${BASE_URL}/ships/national-geographic-endurance/"

ship_schema "national-geographic-orion" \
  "National Geographic Orion Review 2026" \
  "Lindblad's most well-travelled ship: history, equipment, capacity discrepancy, and what Cruise Critic reviewers say."
assemble "ships/national-geographic-orion/index.html" "2" \
  "National Geographic Orion Review 2026" \
  "Lindblad's most well-travelled ship: history, equipment, capacity discrepancy, and what Cruise Critic reviewers say." \
  "content/ship-national-geographic-orion.html" "css/operator.css" "$TMPDIR/schema-ship-national-geographic-orion.html" "article" "${BASE_URL}/ships/national-geographic-orion/"

ship_schema "national-geographic-venture" \
  "National Geographic Venture Review 2026" \
  "100-guest Lindblad coastal ship sailing Alaska and Baja California: equipment and what Cruise Critic reviewers say."
assemble "ships/national-geographic-venture/index.html" "2" \
  "National Geographic Venture Review 2026" \
  "100-guest Lindblad coastal ship sailing Alaska and Baja California: equipment and what Cruise Critic reviewers say." \
  "content/ship-national-geographic-venture.html" "css/operator.css" "$TMPDIR/schema-ship-national-geographic-venture.html" "article" "${BASE_URL}/ships/national-geographic-venture/"

ship_schema "national-geographic-quest" \
  "National Geographic Quest Review 2026" \
  "100-guest Lindblad coastal ship sailing Alaska and Central America: history, equipment, and what Cruise Critic reviewers say."
assemble "ships/national-geographic-quest/index.html" "2" \
  "National Geographic Quest Review 2026" \
  "100-guest Lindblad coastal ship sailing Alaska and Central America: history, equipment, and what Cruise Critic reviewers say." \
  "content/ship-national-geographic-quest.html" "css/operator.css" "$TMPDIR/schema-ship-national-geographic-quest.html" "article" "${BASE_URL}/ships/national-geographic-quest/"

# ---------------------------------------------------------------------------
# E-E-A-T PAGES (no FAQPage schema — none of these pages have visible FAQ content)
# ---------------------------------------------------------------------------
eeat_schema() {
  local SLUG="$1" TITLE="$2" DESC="$3"
  cat > "$TMPDIR/schema-eeat-${SLUG}.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"${TITLE}","description":"${DESC}","url":"${BASE_URL}/${SLUG}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Expedition Review Desk","item":"${BASE_URL}/"},{"@type":"ListItem","position":2,"name":"${TITLE}","item":"${BASE_URL}/${SLUG}/"}]}</script>
EOF
}

eeat_schema "methodology" "How We Score Antarctic Operators | Methodology" "The published formula behind our Antarctic operator ranking: four weighted factors, worked examples, and what is measured versus editorial."
assemble "methodology/index.html" "1" "How We Score Antarctic Operators | Methodology" "The published formula behind our Antarctic operator ranking: four weighted factors, worked examples, and what is measured versus editorial." "content/methodology.html" "css/page.css" "$TMPDIR/schema-eeat-methodology.html" "article" "${BASE_URL}/methodology/"

eeat_schema "how-we-read-reviews" "How We Read Reviews | Expedition Review Desk" "The exact verification rule behind every rating figure and quote on this site, and why several sources are missing from the Lindblad Expeditions review page."
assemble "how-we-read-reviews/index.html" "1" "How We Read Reviews | Expedition Review Desk" "The exact verification rule behind every rating figure and quote on this site, and why several sources are missing from the Lindblad Expeditions review page." "content/how-we-read-reviews.html" "css/page.css" "$TMPDIR/schema-eeat-how-we-read-reviews.html" "article" "${BASE_URL}/how-we-read-reviews/"

eeat_schema "editorial-policy" "Editorial Policy | Expedition Review Desk" "How this site is funded, how it handles reviews, and how operators enter or leave the Antarctic operator ranking."
assemble "editorial-policy/index.html" "1" "Editorial Policy | Expedition Review Desk" "How this site is funded, how it handles reviews, and how operators enter or leave the Antarctic operator ranking." "content/editorial-policy.html" "css/page.css" "$TMPDIR/schema-eeat-editorial-policy.html" "article" "${BASE_URL}/editorial-policy/"

eeat_schema "about" "About | Expedition Review Desk" "What Expedition Review Desk covers, what it does not, and how the operator dataset is kept current each season."
assemble "about/index.html" "1" "About | Expedition Review Desk" "What Expedition Review Desk covers, what it does not, and how the operator dataset is kept current each season." "content/about.html" "css/page.css" "$TMPDIR/schema-eeat-about.html" "article" "${BASE_URL}/about/"

eeat_schema "submit-operator" "Submit an Operator | Expedition Review Desk" "Inclusion criteria and submission process for Antarctic expedition operators seeking to be added to this ranking."
assemble "submit-operator/index.html" "1" "Submit an Operator | Expedition Review Desk" "Inclusion criteria and submission process for Antarctic expedition operators seeking to be added to this ranking." "content/submit-operator.html" "css/page.css" "$TMPDIR/schema-eeat-submit-operator.html" "article" "${BASE_URL}/submit-operator/"

eeat_schema "contact" "Contact | Expedition Review Desk" "How to reach Expedition Review Desk for corrections, data updates, or operator submissions."
assemble "contact/index.html" "1" "Contact | Expedition Review Desk" "How to reach Expedition Review Desk for corrections, data updates, or operator submissions." "content/contact.html" "css/page.css" "$TMPDIR/schema-eeat-contact.html" "article" "${BASE_URL}/contact/"

eeat_schema "privacy-and-cookies" "Privacy & Cookies | Expedition Review Desk" "What Expedition Review Desk collects, what analytics run, and how cookies are handled on this site."
assemble "privacy-and-cookies/index.html" "1" "Privacy & Cookies | Expedition Review Desk" "What Expedition Review Desk collects, what analytics run, and how cookies are handled on this site." "content/privacy-and-cookies.html" "css/page.css" "$TMPDIR/schema-eeat-privacy-and-cookies.html" "article" "${BASE_URL}/privacy-and-cookies/"

# ---------------------------------------------------------------------------
# 404
# ---------------------------------------------------------------------------
cat > "$TMPDIR/content-404.html" <<'EOF'
<section class="section container" style="text-align:center">
  <h1>Page not found</h1>
  <p>The page you're looking for doesn't exist. Start from the <a href="/">full ranking of ten Antarctic operators</a>.</p>
</section>
EOF
assemble "404.html" "0" \
  "Page Not Found | Expedition Review Desk" \
  "The page you're looking for doesn't exist on Expedition Review Desk." \
  "$TMPDIR/content-404.html" "css/page.css" "" "website" "${BASE_URL}/404.html"

echo ""
echo "== Build complete =="

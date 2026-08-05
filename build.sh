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
BASE_URL="https://lindblad-expeditions-reviews.com"

# Set to "false" once the site is ready to be indexed (also flip robots.txt back to Allow: /).
NOINDEX="true"
ROBOTS_META="index, follow"
if [ "$NOINDEX" = "true" ]; then
  ROBOTS_META="noindex, nofollow"
fi

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

ORG_SCRIPT='<script type="application/ld+json">{"@context":"https://schema.org","@type":"Organization","name":"Antarctic Review Hub","url":"https://lindblad-expeditions-reviews.com/"}</script>'

# ---------------------------------------------------------------------------
# HOMEPAGE
# ---------------------------------------------------------------------------
cat > "$TMPDIR/schema-home.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"Lindblad Expeditions Reviews 2026: Compared to 9 Operators","description":"A scored comparison of ten Antarctic cruise operators on shore time, ratings, price and expedition depth.","url":"${BASE_URL}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"ItemList","itemListElement":[
{"@type":"ListItem","position":1,"name":"Poseidon Expeditions","url":"${BASE_URL}/operators/poseidon-expeditions/"},
{"@type":"ListItem","position":2,"name":"Oceanwide Expeditions","url":"${BASE_URL}/operators/oceanwide-expeditions/"},
{"@type":"ListItem","position":3,"name":"Aurora Expeditions","url":"${BASE_URL}/operators/aurora-expeditions/"},
{"@type":"ListItem","position":4,"name":"Lindblad Expeditions","url":"${BASE_URL}/operators/lindblad-expeditions/"},
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
{"@type":"Question","name":"Which operators have the best reviews for small groups?","acceptedAnswer":{"@type":"Answer","text":"Three operators sit in the small-ship band in this ranking: Poseidon Expeditions (114 passengers), Oceanwide Expeditions (111 effective capacity across a varied fleet), and Aurora Expeditions (139 effective capacity). All three post shore-time scores above 70; see the full ranking table for a direct comparison."}},
{"@type":"Question","name":"How much does an Antarctica cruise cost?","acceptedAnswer":{"@type":"Answer","text":"Published berth prices in this ranking run from $2,000 (Holland America, no landings) to $50,000 (Silversea's top suites), excluding flights to Ushuaia or Punta Arenas and excluding single supplement for solo travellers, which this site does not have a figure for on any operator."}},
{"@type":"Question","name":"Does ship size really change how much time you spend ashore?","acceptedAnswer":{"@type":"Answer","text":"Yes, arithmetically. IAATO caps a shore party at 100 people, so above that threshold guests split into groups and take turns. At equal voyage length, a 100-passenger ship and a 200-passenger ship differ by roughly double the actual time spent ashore."}}
]}
</script>
EOF

assemble "./index.html" "0" \
  "Lindblad Expeditions Reviews 2026: Compared to 9 Operators" \
  "A scored comparison of ten Antarctic cruise operators on shore time, ratings, price and expedition depth. Updated ${UPDATED}." \
  "content/main-ranking.html" "css/ranking.css" "$TMPDIR/schema-home.html" "website" "${BASE_URL}/"

# ---------------------------------------------------------------------------
# OPERATOR PAGES — helper to cut down repetition
# ---------------------------------------------------------------------------
# operator_faq SLUG Q1 A1 Q2 A2 Q3 A3  ->  writes schema file to $TMPDIR/schema-op-SLUG.html
operator_schema() {
  local SLUG="$1" TITLE="$2" DESC="$3" Q1="$4" A1="$5" Q2="$6" A2="$7" Q3="$8" A3="$9"
  cat > "$TMPDIR/schema-op-${SLUG}.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"${TITLE}","description":"${DESC}","url":"${BASE_URL}/operators/${SLUG}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Antarctic Review Hub","item":"${BASE_URL}/"},{"@type":"ListItem","position":2,"name":"${TITLE}","item":"${BASE_URL}/operators/${SLUG}/"}]}</script>
<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"${Q1}","acceptedAnswer":{"@type":"Answer","text":"${A1}"}},{"@type":"Question","name":"${Q2}","acceptedAnswer":{"@type":"Answer","text":"${A2}"}},{"@type":"Question","name":"${Q3}","acceptedAnswer":{"@type":"Answer","text":"${A3}"}}]}</script>
EOF
}

operator_schema "poseidon-expeditions" \
  "Poseidon Expeditions Reviews 2026 | Antarctic Score" \
  "Poseidon Expeditions ranks 1st of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "Is Poseidon Expeditions a good choice for solo travellers?" "Gratuities are explicitly excluded from the published fare, and this site has no verified single-supplement figure for Poseidon. Ask directly before booking." \
  "Does the Sea Spirit's age affect the experience?" "Some reviewers note the ship shows its age in cabin fittings despite annual refurbishment, though the expedition-team and landing experience are rated highly regardless." \
  "How does Poseidon's one-ship fleet compare to larger operators?" "One ship means no helicopters, no submersible, and a single route family, scoring 80 on expedition depth against Lindblad's 92 and Ponant's 95, the trade-off for the ranking's second-highest shore-time score."
assemble "operators/poseidon-expeditions/index.html" "2" \
  "Poseidon Expeditions Reviews 2026 | Antarctic Score" \
  "Poseidon Expeditions ranks 1st of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "content/operator-poseidon-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-poseidon-expeditions.html" "article" "${BASE_URL}/operators/poseidon-expeditions/"

operator_schema "oceanwide-expeditions" \
  "Oceanwide Expeditions Reviews 2026 | Antarctic Score" \
  "Oceanwide Expeditions ranks 2nd of 10 Antarctic operators in 2026 on shore time, ratings, price and expedition depth." \
  "Which Oceanwide Expeditions ship has the shortest landing wait?" "The 33-berth Rembrandt van Rijn sailing vessel is under the IAATO 100-guest limit, so every landing goes ashore together with no rotation at all, the shortest possible wait of any ship in this ranking." \
  "Are Oceanwide Expeditions Antarctica reviews consistent across ships?" "Not entirely. Hondius reviews describe a more polished experience than the smaller, plainer ships; food-service complaints recur more on the larger vessels than on Plancius or the sailing vessel." \
  "Is a parka included with Oceanwide Expeditions?" "No, unlike most operators in this ranking, Oceanwide does not include a parka loan, one reason its price/value score of 90 sits above operators that do include one."
assemble "operators/oceanwide-expeditions/index.html" "2" \
  "Oceanwide Expeditions Reviews 2026 | Antarctic Score" \
  "Oceanwide Expeditions ranks 2nd of 10 Antarctic operators in 2026 on shore time, ratings, price and expedition depth." \
  "content/operator-oceanwide-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-oceanwide-expeditions.html" "article" "${BASE_URL}/operators/oceanwide-expeditions/"

operator_schema "aurora-expeditions" \
  "Aurora Expeditions Reviews 2026 | Antarctic Score" \
  "Aurora Expeditions ranks 3rd of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "What makes the Aurora Expeditions X-Bow hull different?" "The inverted bow shape cuts through waves instead of slamming over them, which reviewers on all three ships credit with a noticeably smoother Drake Passage crossing than conventional expedition-ship hulls." \
  "Are Aurora Expeditions Svalbard cruise reviews different from Antarctica reviews?" "The same fleet and expedition-team praise recur in both regions; this page and the ranking focus on the Antarctic sailings specifically, where the 100-passenger-plus capacity drives the short-rotation landing style." \
  "Does Aurora Expeditions have helicopters?" "No. Unlike Quark's Ultramarine, no ship in Aurora's fleet carries a helicopter; its expedition-depth score of 78 reflects the X-Bow hull and activity roster rather than aircraft-supported landings."
assemble "operators/aurora-expeditions/index.html" "2" \
  "Aurora Expeditions Reviews 2026 | Antarctic Score" \
  "Aurora Expeditions ranks 3rd of 10 Antarctic operators in 2026, scored on shore time, ratings, price and expedition depth." \
  "content/operator-aurora-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-aurora-expeditions.html" "article" "${BASE_URL}/operators/aurora-expeditions/"

operator_schema "lindblad-expeditions" \
  "Lindblad Expeditions Fleet & Complaints 2026" \
  "Lindblad Expeditions' Antarctic fleet, ice class, and review-complaint pattern, examined alongside its 4th-place score of 10 operators." \
  "What do Lindblad Expeditions reviews complaints mention most?" "Pre-departure administration, booking handling, misrepresented flight class, and marketing promises that did not match delivery, not the voyage itself, which is rated highly in the same reviews." \
  "Do Lindblad Expeditions Galapagos reviews reflect the same score as Antarctica?" "No. This ranking's score is scoped to the three Antarctic ships specifically; Lindblad's wider fleet serving the Galapagos, Alaska and other regions is not covered by this scoring model." \
  "Which Lindblad Antarctic ship has the most review coverage?" "National Geographic Explorer, with 53 Cruise Critic reviews, against 15 for Resolution and 5 for Endurance. Treat conclusions about the smaller two ships as provisional."
assemble "operators/lindblad-expeditions/index.html" "2" \
  "Lindblad Expeditions Fleet & Complaints 2026" \
  "Lindblad Expeditions' Antarctic fleet, ice class, and review-complaint pattern, examined alongside its 4th-place score of 10 operators." \
  "content/operator-lindblad-expeditions.html" "css/operator.css" "$TMPDIR/schema-op-lindblad-expeditions.html" "article" "${BASE_URL}/operators/lindblad-expeditions/"

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
# E-E-A-T PAGES (no FAQPage schema — none of these pages have visible FAQ content)
# ---------------------------------------------------------------------------
eeat_schema() {
  local SLUG="$1" TITLE="$2" DESC="$3"
  cat > "$TMPDIR/schema-eeat-${SLUG}.html" <<EOF
<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebPage","name":"${TITLE}","description":"${DESC}","url":"${BASE_URL}/${SLUG}/","dateModified":"{{DATE}}"}</script>
${ORG_SCRIPT}
<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Antarctic Review Hub","item":"${BASE_URL}/"},{"@type":"ListItem","position":2,"name":"${TITLE}","item":"${BASE_URL}/${SLUG}/"}]}</script>
EOF
}

eeat_schema "methodology" "How We Score Antarctic Operators | Methodology" "The published formula behind our Antarctic operator ranking: four weighted factors, worked examples, and what is measured versus editorial."
assemble "methodology/index.html" "1" "How We Score Antarctic Operators | Methodology" "The published formula behind our Antarctic operator ranking: four weighted factors, worked examples, and what is measured versus editorial." "content/methodology.html" "css/page.css" "$TMPDIR/schema-eeat-methodology.html" "article" "${BASE_URL}/methodology/"

eeat_schema "editorial-policy" "Editorial Policy | Antarctic Review Hub" "How this site is funded, how it handles reviews, and how operators enter or leave the Antarctic operator ranking."
assemble "editorial-policy/index.html" "1" "Editorial Policy | Antarctic Review Hub" "How this site is funded, how it handles reviews, and how operators enter or leave the Antarctic operator ranking." "content/editorial-policy.html" "css/page.css" "$TMPDIR/schema-eeat-editorial-policy.html" "article" "${BASE_URL}/editorial-policy/"

eeat_schema "about" "About | Antarctic Review Hub" "What Antarctic Review Hub covers, what it does not, and how the operator dataset is kept current each season."
assemble "about/index.html" "1" "About | Antarctic Review Hub" "What Antarctic Review Hub covers, what it does not, and how the operator dataset is kept current each season." "content/about.html" "css/page.css" "$TMPDIR/schema-eeat-about.html" "article" "${BASE_URL}/about/"

eeat_schema "submit-operator" "Submit an Operator | Antarctic Review Hub" "Inclusion criteria and submission process for Antarctic expedition operators seeking to be added to this ranking."
assemble "submit-operator/index.html" "1" "Submit an Operator | Antarctic Review Hub" "Inclusion criteria and submission process for Antarctic expedition operators seeking to be added to this ranking." "content/submit-operator.html" "css/page.css" "$TMPDIR/schema-eeat-submit-operator.html" "article" "${BASE_URL}/submit-operator/"

eeat_schema "contact" "Contact | Antarctic Review Hub" "How to reach Antarctic Review Hub for corrections, data updates, or operator submissions."
assemble "contact/index.html" "1" "Contact | Antarctic Review Hub" "How to reach Antarctic Review Hub for corrections, data updates, or operator submissions." "content/contact.html" "css/page.css" "$TMPDIR/schema-eeat-contact.html" "article" "${BASE_URL}/contact/"

eeat_schema "privacy-and-cookies" "Privacy & Cookies | Antarctic Review Hub" "What Antarctic Review Hub collects, what analytics run, and how cookies are handled on this site."
assemble "privacy-and-cookies/index.html" "1" "Privacy & Cookies | Antarctic Review Hub" "What Antarctic Review Hub collects, what analytics run, and how cookies are handled on this site." "content/privacy-and-cookies.html" "css/page.css" "$TMPDIR/schema-eeat-privacy-and-cookies.html" "article" "${BASE_URL}/privacy-and-cookies/"

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
  "Page Not Found | Antarctic Review Hub" \
  "The page you're looking for doesn't exist on Antarctic Review Hub." \
  "$TMPDIR/content-404.html" "css/page.css" "" "website" "${BASE_URL}/404.html"

echo ""
echo "== Build complete =="

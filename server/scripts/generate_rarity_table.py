#!/usr/bin/env python3
"""
Generate rarity_table.dart from IUCN Red List bird data package.

Expects the folder downloaded from iucnredlist.org (e.g. "iucn_aves")
containing at minimum assessments.csv with columns:
  - scientificName  (binomial)
  - redlistCategory (LC, NT, VU, EN, CR, DD, EX, EW)
  - realm           (pipe-separated biogeographic realms for encounter proxy)

Usage:
    python generate_rarity_table.py path/to/iucn_aves
    python generate_rarity_table.py path/to/iucn_aves --show-histogram
    python generate_rarity_table.py path/to/iucn_aves --output ../../lib/data/rarity_table.dart
    python generate_rarity_table.py path/to/iucn_aves --output ../../lib/data/rarity_table.dart --thresholds 20,45,70
"""

import csv
import os
import sys
import math
from collections import Counter, defaultdict

# ── IUCN category → numeric conservation score (0–100) ─────────────────────
IUCN_SCORE = {
    "CR": 90,
    "EN": 75,
    "VU": 60,
    "NT": 30,
    "LC": 0,
}
DD_SCORE = None


# ── Normalise IUCN category strings ───────────────────────────────────────
_IUCN_LOOKUP = {
    "LC": "LC", "LEAST_CONCERN": "LC",
    "NT": "NT", "NEAR_THREATENED": "NT",
    "VU": "VU", "VULNERABLE": "VU",
    "EN": "EN", "ENDANGERED": "EN",
    "CR": "CR", "CRITICALLY_ENDANGERED": "CR",
    "CR(PE)": "CR", "CR(PEW)": "CR",
    "DD": "DD", "DATA_DEFICIENT": "DD",
    "EW": None, "EXTINCT_IN_THE_WILD": None,
    "EX": None, "EXTINCT": None,
    "REGIONALLY_EXTINCT": None,
}


def conservation_score(raw_category: str) -> float | None:
    # Normalise: uppercase, collapse whitespace, replace spaces with _
    normalised = "_".join(raw_category.strip().upper().split())
    mapped = _IUCN_LOOKUP.get(normalised)
    if mapped is None:
        return None
    return IUCN_SCORE.get(mapped, DD_SCORE)


# ── Encounter rarity from realm count ─────────────────────────────────────
def encounter_score(num_realms: int) -> float:
    # 1 realm  → ~95 (single-region endemic, hard to encounter)
    # 2 realms → ~75
    # 4 realms → ~45 (widespread)
    # 7+ realms → ~5 (cosmopolitan)
    if num_realms <= 0:
        return 50.0
    return max(0.0, min(100.0, 100 - 30 * math.log(num_realms + 2)))


# ── Blend ─────────────────────────────────────────────────────────────────
def blend(cons_score: float, enc_score: float) -> float:
    if cons_score >= 60:          # VU / EN / CR
        return cons_score * 0.8 + enc_score * 0.2
    elif cons_score >= 20:        # NT
        return cons_score * 0.5 + enc_score * 0.5
    else:                         # LC
        return enc_score * 0.8 + cons_score * 0.2


# ── Bucket into tiers ─────────────────────────────────────────────────────
DEFAULT_THRESHOLDS = [25, 50, 72]


def bucket(score: float, thresholds: list[float]) -> str:
    if score <= thresholds[0]:
        return "Rarity.common"
    elif score <= thresholds[1]:
        return "Rarity.uncommon"
    elif score <= thresholds[2]:
        return "Rarity.rare"
    else:
        return "Rarity.legendary"


# ── Main ───────────────────────────────────────────────────────────────────
def main():
    args = sys.argv[1:]
    folder_path = None
    output_path = None
    show_histogram = False
    thresholds = list(DEFAULT_THRESHOLDS)

    i = 0
    while i < len(args):
        if args[i] == "--show-histogram":
            show_histogram = True
        elif args[i] == "--output" and i + 1 < len(args):
            output_path = args[i + 1]
            i += 1
        elif args[i] == "--thresholds" and i + 1 < len(args):
            thresholds = [float(x) for x in args[i + 1].split(",")]
            i += 1
        elif args[i].startswith("--"):
            print(f"Unknown flag: {args[i]}", file=sys.stderr)
            sys.exit(1)
        else:
            folder_path = args[i]
        i += 1

    if not folder_path:
        print(__doc__)
        sys.exit(1)

    if not os.path.isdir(folder_path):
        print(f"Folder not found: {folder_path}", file=sys.stderr)
        sys.exit(1)

    assessments_path = os.path.join(folder_path, "assessments.csv")
    common_path = os.path.join(folder_path, "common_names.csv")

    for required in [assessments_path]:
        if not os.path.isfile(required):
            print(f"Required file not found: {required}", file=sys.stderr)
            sys.exit(1)

    # ── Read assessments ──────────────────────────────────────────────────
    with open(assessments_path, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        all_rows = list(reader)

    headers = list(all_rows[0].keys()) if all_rows else []
    print(f"Assessments columns: {headers}", file=sys.stderr)

    # Verify required columns exist
    if "scientificName" not in headers:
        print("ERROR: assessments.csv must have a 'scientificName' column",
              file=sys.stderr)
        sys.exit(1)
    if "redlistCategory" not in headers:
        print("ERROR: assessments.csv must have a 'redlistCategory' column",
              file=sys.stderr)
        sys.exit(1)

    has_realm = "realm" in headers
    print(f"  → Realm column: {'FOUND' if has_realm else 'MISSING — using IUCN-only scoring'}", file=sys.stderr)

    # ── Aggregate per species ─────────────────────────────────────────────
    species: dict[str, dict] = {}

    for row in all_rows:
        sci = row.get("scientificName", "").strip()
        if not sci:
            continue
        sci_lower = sci.lower()

        cs = conservation_score(row.get("redlistCategory", ""))
        if cs is None:
            continue

        if sci_lower not in species:
            species[sci_lower] = {
                "scientific": sci,
                "cs": cs,
                "realms": set(),
            }
        else:
            existing = species[sci_lower]
            if cs > existing["cs"]:
                existing["cs"] = cs

        if has_realm:
            realms = row.get("realm", "")
            if realms:
                for r in realms.split("|"):
                    r = r.strip()
                    if r:
                        species[sci_lower]["realms"].add(r)

    print(f"\nLoaded {len(species)} unique species from assessments.csv",
          file=sys.stderr)

    # ── Compute scores ────────────────────────────────────────────────────
    results: list[tuple[str, str, float, str, int]] = []
    scores = []

    for sci_lower, data in species.items():
        cs = data["cs"]
        num_realms = len(data["realms"]) if has_realm else 0
        es = encounter_score(num_realms)
        s = blend(cs, es)
        scores.append(s)
        results.append((sci_lower, data["scientific"], s, "", num_realms))

    # ── Statistics & histogram ────────────────────────────────────────────
    sorted_scores = sorted(scores)
    n = len(sorted_scores)

    print(f"\nScore distribution:", file=sys.stderr)
    print(f"  Species      : {n}", file=sys.stderr)
    print(f"  Min          : {sorted_scores[0]:.1f}", file=sys.stderr)
    print(f"  25th %ile    : {sorted_scores[int(n * 0.25)]:.1f}", file=sys.stderr)
    print(f"  Median       : {sorted_scores[int(n * 0.50)]:.1f}", file=sys.stderr)
    print(f"  75th %ile    : {sorted_scores[int(n * 0.75)]:.1f}", file=sys.stderr)
    print(f"  Max          : {sorted_scores[-1]:.1f}", file=sys.stderr)
    print(f"  Mean         : {sum(sorted_scores) / n:.1f}", file=sys.stderr)

    if show_histogram:
        _show_histogram(scores)

    # ── Tier distribution ─────────────────────────────────────────────────
    tier_counts = Counter()
    realm_values = []
    for _, _, s, _, nr in results:
        tier_counts[bucket(s, thresholds)] += 1
        realm_values.append(nr)

    print(f"\nTier distribution with thresholds {thresholds}:",
          file=sys.stderr)
    t_order = ["Rarity.common", "Rarity.uncommon", "Rarity.rare",
               "Rarity.legendary"]
    for t in t_order:
        print(f"  {t}: {tier_counts[t]} ({tier_counts[t]/n*100:.1f}%)",
              file=sys.stderr)

    if has_realm:
        realm_sorted = sorted(realm_values)
        print(f"\nRealm count distribution:", file=sys.stderr)
        print(f"  Min realms   : {realm_sorted[0]}", file=sys.stderr)
        print(f"  Median realms: {realm_sorted[n // 2]}", file=sys.stderr)
        print(f"  Max realms   : {realm_sorted[-1]}", file=sys.stderr)

    # ── Read common names for _byCommon map ───────────────────────────────
    common_map: dict[str, str] = {}  # lowercase common → scientific
    if os.path.isfile(common_path):
        with open(common_path, encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            for row in reader:
                sci = row.get("scientificName", "").strip()
                name = row.get("name", "").strip()
                is_main = row.get("main", "").strip().upper() == "TRUE"
                if sci and name and is_main:
                    sci_lower = sci.lower()
                    common_map[name.lower()] = sci_lower
        print(f"\nLoaded {len(common_map)} main common names",
              file=sys.stderr)
    else:
        print(f"\n{common_path} not found — _byCommon map will be empty",
              file=sys.stderr)

    # ── Generate Dart code ────────────────────────────────────────────────
    dart = _generate_dart(results, common_map, thresholds)

    if output_path:
        out_dir = os.path.dirname(output_path)
        if out_dir:
            os.makedirs(out_dir, exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(dart)
        print(f"\nWrote {len(results)} entries to {output_path}", file=sys.stderr)
    else:
        print(dart)


# ── Helpers ────────────────────────────────────────────────────────────────
def _show_histogram(scores: list[float], bins: int = 25):
    min_s, max_s = 0, 100
    bucket_size = (max_s - min_s) / bins
    hist = [0] * bins
    for s in scores:
        idx = min(int((s - min_s) / bucket_size), bins - 1)
        hist[idx] += 1

    max_count = max(hist) if max(hist) > 0 else 1
    scale = 50 / max_count

    print(f"\nScore histogram (0–100, {bins} buckets):", file=sys.stderr)
    print(f"  (bar = count, max bar = {max_count})", file=sys.stderr)
    for i in range(bins):
        low = min_s + i * bucket_size
        high = low + bucket_size
        count = hist[i]
        bar = "█" * int(count * scale)
        label = f"  {low:3.0f}–{high:3.0f}"
        if i == bins // 2:
            label = f"  {low:3.0f}–{high:3.0f}  ← thresholds: {low:.0f}"
        print(f"{label}: {bar} {count}", file=sys.stderr)


def _escape(s: str) -> str:
    """Escape a string for use inside a single-quoted Dart string literal."""
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")


def _generate_dart(
    results: list[tuple[str, str, float, str, int]],
    common_map: dict[str, str],
    thresholds: list[float],
) -> str:
    results.sort(key=lambda r: r[1].lower())

    lines: list[str] = []
    lines.append("// Auto-generated by server/scripts/generate_rarity_table.py")
    lines.append(f"// Thresholds: {thresholds}")
    from datetime import date
    lines.append(f"// Generated: {date.today()}")
    lines.append("")
    lines.append("import '../models/rarity.dart';")
    lines.append("")
    lines.append("class RarityTable {")
    lines.append("  RarityTable._();")
    lines.append("")
    lines.append("  /// Keyed by lowercase scientific name (binomial).")
    lines.append("  /// Auto-generated from IUCN Red List bird data.")
    lines.append(f"  /// Contains {len(results)} species.")
    lines.append("  static const Map<String, Rarity> _byScientific = {");

    for sci_lower, sci_proper, score, _, num_realms in results:
        tier = bucket(score, thresholds)
        lines.append(f"    '{_escape(sci_lower)}': {tier}, // {num_realms}r realm{'' if num_realms == 1 else 's'} score={score:.0f}")

    lines.append("  };")
    lines.append("")
    lines.append("  /// Fallback map keyed by lowercase common name.")
    lines.append("  /// Populated from the IUCN common_names.csv.")
    lines.append(f"  /// Contains {len(common_map)} entries.")
    lines.append("  static const Map<String, Rarity> _byCommon = {");

    # Sort common names alphabetically
    for common_lower, sci_lower in sorted(common_map.items(), key=lambda x: x[0]):
        # Find the tier for this species from results
        tier = "Rarity.common"
        for s_lower, _, s_score, _, _ in results:
            if s_lower == sci_lower:
                tier = bucket(s_score, thresholds)
                break
        lines.append(f"    '{_escape(common_lower)}': {tier},")

    lines.append("  };")
    lines.append("")
    lines.append("  static Rarity rarityFor(String? scientificName, String? commonName) {")
    lines.append("    if (scientificName != null && scientificName.isNotEmpty) {")
    lines.append("      final result = _byScientific[scientificName.trim().toLowerCase()];")
    lines.append("      if (result != null) return result;")
    lines.append("    }")
    lines.append("    if (commonName != null && commonName.isNotEmpty) {")
    lines.append("      final result = _byCommon[commonName.trim().toLowerCase()];")
    lines.append("      if (result != null) return result;")
    lines.append("    }")
    lines.append("    return Rarity.common;")
    lines.append("  }")
    lines.append("")
    lines.append("  static bool isKnown(String? scientificName, String? commonName) {")
    lines.append("    if (scientificName != null && scientificName.isNotEmpty) {")
    lines.append("      if (_byScientific.containsKey(scientificName.trim().toLowerCase())) return true;")
    lines.append("    }")
    lines.append("    if (commonName != null && commonName.isNotEmpty) {")
    lines.append("      if (_byCommon.containsKey(commonName.trim().toLowerCase())) return true;")
    lines.append("    }")
    lines.append("    return false;")
    lines.append("  }")
    lines.append("}")

    return "\n".join(lines)


if __name__ == "__main__":
    main()

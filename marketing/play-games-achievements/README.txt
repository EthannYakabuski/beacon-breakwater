Beacon Breakwater: Google Play Games achievement import
Prepared 2026-11-12 from game/catalog.json and marketing/achievements.
The owner confirmed this exact ZIP imported successfully on 2026-11-12.

Upload ONLY beacon-breakwater-achievements-google-play.zip.
The ZIP contains two CSV files and 26 existing PNG icons directly at its root.
The companion README, validation report and ID worksheet are not in the ZIP.

PACKAGED CHOICES
- All 26 achievements use the standard type (Incremental Value False).
  This matches the current game's unlock_achievement implementation.
- Initial state: Revealed for all 26.
- Point values: 10 to 100, totaling 1,115. All are multiples of 5 and
  leave 885 points below Google's 2,000-point total allowance.
  These points and states were selected for this package, not found in the catalog.
- Order, titles, descriptions and icon bytes match the current catalog exactly.
  The 12 coast descriptions are identical in the source and are preserved.
  Google's quality guidance recommends unique descriptions; consider naming the
  particular coast in each description before publishing.

DEFAULT LANGUAGE
The metadata Name and Description columns supply the game's default locale.
They contain the catalog's English text. Confirm the game's default locale is
the intended English locale before importing.
No AchievementsLocalizations.csv is needed for the default locale. Google marks
it optional and says the default locale cannot be included in that file.
No additional translations were created.

IMPORT
1. Open Beacon Breakwater in Google Play Console.
2. Go to Play Games Services > Setup and management > Achievements.
3. Choose Import achievements, then upload the ZIP.
4. Review all 26 rows, point values, states and icons; save as draft.
5. Copy the generated Play Games achievement IDs into the companion worksheet
   and then map them by CatalogKey in platform/config.json.
The ZIP creates achievement definitions, not the game's ID bindings.
The owner performed the successful Console import. This package does not publish
achievements or change the game code and configuration.
If achievements already exist, check for duplicates before importing;
this package was not reconciled with current Console contents.
Published achievement types and initial states cannot be changed.

VALIDATION
The archive was read back and checked locally against Google's documented
schema, names, row/column counts, flat layout, unique mappings, icon dimensions,
original icon hashes and byte limits. The owner subsequently confirmed the
import worked. The validation report preserves the original local checks.
Do not add the companion files or any subdirectories to the ZIP.

OFFICIAL SOURCES (checked 2026-11-12; pages updated 2026-10-06)
https://developer.android.com/games/pgs/integrate-achievements#zip-file-guidelines
https://developer.android.com/games/pgs/achievements#points_and_experience_points
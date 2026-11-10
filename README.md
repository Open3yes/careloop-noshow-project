# CareLoop Clinics — No-Show Guard
Repository: https://github.com/Open3yes/careloop-noshow-project

## Summary
- **Part 1 (Ingest & clean):** 1,020 raw appointment rows were cleaned down to **990**: 20 exact duplicates and 10 rows with an invalid date (e.g. `TBD`, `2025-02-30`) or a missing status were removed, and 16 spellings of `booking_channel` were collapsed to 3. Across the clean data, **218 of 990 appointments (22.0%) were no-shows**.
- **Part 2 (SQL):** Booking further ahead strongly predicts a no-show: the rate climbs from **16.2%** for appointments booked 1–7 days ahead to **30.0%** at 15–30 days and **60.5%** at 31+ days. By clinic, rates range from **13.8%** (Vaishali Nagar, Jaipur) to **33.3%** (Gomti Nagar, Lucknow).
- **Part 3 (Model):** Reminders matter most among the things CareLoop controls: **30.8%** of patients without a reminder missed their visit versus **15.3%** with one, and the logistic regression estimates a reminder cuts the odds of a no-show by about **69%** (odds ratio 0.31) with other factors held fixed. The final model reaches a **test ROC-AUC of 0.789**.
- **Part 4 (GenAI):** Gemini classified the first 10 follow-up notes, and all 9 non-blank replies passed Pydantic and allowed-list validation (the blank note was skipped without an API call). The causes were spread out: forgot/no reminder, distance/transport and work/schedule (**2 each**), cost and illness (1 each), and 1 "other" (the patient was unreachable). The structured CRAFT prompt returned an allowed label for **2 of 2** test notes; a one-line prompt returned **0 of 2**.

## Recommendation
The riskiest appointments are those booked **31+ days ahead (60.5% no-show)**, patients with **two or more prior no-shows (43.6–47.2%)**, and patients living **more than 15 km away (31.4%)**. The clearest reason patients miss, and the one CareLoop can fix, is the absence of a reminder: **429 of 990 appointments (43%) got none**, and those had a **30.8%** no-show rate against **15.3%** for reminded patients. The follow-up notes back this up, with forgetting or no reminder among the most common stated causes. CareLoop should first **send a reminder for every appointment**, prioritising long-lead bookings, where reminders matter most (15–30 days: 41.4% without vs 20.4% with). Next, use the model at the 0.35 threshold to pick patients for a personal call. On the test set it flagged **49 of 198 appointments (25%)** and caught **57%** of the actual no-shows. Distance and cost appear in the notes too, so transport or fee support is worth piloting at the highest-rate clinics, Gomti Nagar (33.3%) and Hadapsar (27.3%).

## Model choice
**Logistic regression** (scaled, inside a pipeline) was chosen because it had the highest **5-fold cross-validated ROC-AUC on the training data: 0.774**. The other candidates were the tuned random forest (0.767), the default random forest (0.747) and the depth-3 decision tree (0.678). It is also the easiest model to explain, since each coefficient maps to an odds ratio. On the held-out test set, which was used once, it scored a **test ROC-AUC of 0.789**. The flagging **threshold is 0.35** rather than the default 0.5, chosen on out-of-fold training predictions. At 0.5 the model caught only 25% of no-shows (recall 0.25, F1 0.35). At 0.35, recall rises to 0.47 and F1 to 0.49, while precision drops only from 0.58 to 0.51. Missing a no-show wastes a clinic slot, while an unnecessary reminder call costs little, so a lower threshold that catches more no-shows is worth a few extra calls. On the test set this gives precision 0.57 and recall 0.57.

## Limitations
- **Small, short sample:** the data covers 990 appointments at 8 clinics over six months (Jan–Jun 2025), and the test set holds only 49 no-shows, so the metrics and clinic rankings could shift with more data.
- **Correlation, not causation:** reminders were not randomly assigned, so part of the 30.8% vs 15.3% gap may come from who receives reminders rather than the reminder itself; an A/B test would confirm the effect.
- **Only 10 notes analysed:** the free-tier API limit restricted the GenAI step to the first 10 of 30 follow-up notes (15 API calls in total), so the root-cause split is indicative, not representative.

## Project files
| File | What it does |
|---|---|
| `data/` | Raw inputs: `appointments.csv`, `clinics.csv`, `followup_notes.csv` |
| `01_ingest_clean.ipynb` | Cleans the appointments, adds `lead_days` / `no_show`, fetches clinic weather, and writes `appointments_clean.csv`, `clinics_enriched.csv`, `load_data.sql` |
| `noshowguard.sql` | Creates the MySQL database and tables |
| `02_queries.sql` | Analysis queries: clinic rates, lead-time bands, monthly trend, clinic ranking |
| `03_model.ipynb` | Logistic regression, decision tree and random forest; model and threshold choice; writes `test_risk_scores.csv` |
| `04_genai.ipynb` | Gemini note classification with Pydantic validation and a prompt comparison; writes `notes_analysed.csv` |

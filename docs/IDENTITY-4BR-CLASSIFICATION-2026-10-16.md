# 4BRd2E8vBic — bounded source-identity classification

Baseline: `a87ab6f88646fd02c8f78844cbfa6ef9fdc00d0d`. This investigation
does not accept or reject the physical dance demonstrated by this source.

| Candidate explanation | Finding |
|---|---|
| Wrong source mapping | Not established. Manifest `video_id`, archived info `id`, fixture `recordingMeta.source_video`/`provenance.sourceUrl`, and the bundled reference all identify `4BRd2E8vBic`/JoeyTheJAM. The archived title explicitly covers both Bounce and Rock. |
| Counter defect | Not found for the declared whole-lesson rule. The 32 own-term hits are 28 `bounc` roots + 4 `hip hop`; the 50 opposing hits are 38 `rock` + 10 `rocking` + 2 `rocks`. They are not substring matches to unrelated words. Whole-lesson frequency cannot establish a selected segment's movement identity. |
| Software reporting defect | Confirmed and fixed: the gate carried the known red 32/50 record but ended by saying no accepted source contradicted its assignment. The final line now reports the number of carried open contradictions and explicitly withholds source/segment/physical approval. |
| Missing source/provenance | The original MP4 named by the manifest is absent from the available archive; only its info JSON remains in `raw/`. The historical extraction rig SHA/observed SHA are null. Existing landmarks/transcripts are available, but full visual/extractor lineage cannot be reconstructed from that alone. |
| Physical correctness | Unresolved. No new footage or competent physical assessment was produced. Retained 2D landmarks and transcript counts cannot approve the selected movement or settle bounce-versus-rock mechanics. |

Current `prepare_take.py --video 4BRd2E8vBic --step hh_bounce` reproduces
the archived selection: frames `[15072,15576)`, 24 fps, **628–649 seconds**,
period 0.625 seconds and 32 cycles. The sole overlapping transcript record
runs 612.55–657.5 seconds and contains four words, with zero bounce/rock
terms. This is absence of step-name evidence, not evidence of acoustic silence
or of a correct/incorrect physical movement. Preparation reproducibility also
does not establish the missing original MP4's lineage.

The existing R17/C-255 record reports that the available torso/hip comparison
was limited by the 6-degree tolerance floor. That historical result remains
historical; it was not rerun or promoted into new physical acceptance here.
The exact 32/50 adjudicated record, term sets, verdict labels, thresholds,
reference/course content and exit policy are unchanged.

`tools/test_identity_read.py` exercises real gate output/exit behavior with
temporary transcripts: exact carried record, changed counts in both directions,
wrong-step reuse, a fresh contradiction alongside the carried one, clean input,
and absent transcript pool. Expected exits remain 0/1/2. The test is connected
to `tool/gates.sh`; no app, shared Core, camera, music or store behavior changes.

Local source hashes, preparation output, transcript timing/lexical audit and
RED/GREEN evidence are retained under
`../data/night-acceptance-2026-10-16/`. New publication/CI evidence must name its
own source SHA; the successful baseline main CI is not the new patch's CI.

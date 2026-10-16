"""Exercise the gate's real exit and summary against isolated transcripts."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import identity_read


class IdentityGateOutputTest(unittest.TestCase):
    def run_gate(self, sources, *, step='hh_bounce', missing_pool=False):
        with tempfile.TemporaryDirectory(prefix='choreia-identity-output-') as tmp:
            root = Path(tmp)
            reference = root / f'{step}.json'
            reference.write_text(json.dumps({'sources': [
                {'videoId': video} for video, _, _ in sources
            ]}))
            words = root / 'words'
            words.write_text('bounce\nrock\ndancehall\nhip\nhop\nroger\nrunning\nman\n')
            own_term = identity_read.TERMS[step]['own'][0]
            confusable_term = identity_read.TERMS[step]['confusable'][0]
            for video, own, confusable in sources:
                (root / f'{video}.transcript.json').write_text(json.dumps([
                    {'text': f'{own_term} ' * own + f'{confusable_term} ' * confusable}
                ]))
            output = io.StringIO()
            transcripts = root / 'absent' if missing_pool else root
            with patch.object(identity_read, 'TRANSCRIPTS', transcripts), \
                    patch.object(identity_read, 'WORDLIST', words), \
                    patch.object(identity_read, 'shipped_references',
                                 return_value=[reference]), \
                    patch('sys.argv', ['identity_read.py']), \
                    redirect_stdout(output):
                code = identity_read.main()
            return code, output.getvalue()

    def test_carried_contradiction_is_not_summarized_as_absent(self):
        code, output = self.run_gate([('4BRd2E8vBic', 32, 50)])
        self.assertEqual(code, 0)
        self.assertIn('KIRMIZI=1', output)
        self.assertIn('kendi=32 karışt=50', output)
        self.assertIn('TAŞINIYOR', output)
        summary = output.splitlines()[-1]
        self.assertIn('1 açık çürütme', summary)
        self.assertNotIn('hiçbir kabul edilmiş', summary)

    def test_changed_carried_counts_still_fail(self):
        for confusable in (49, 51):
            with self.subTest(confusable=confusable):
                code, output = self.run_gate([('4BRd2E8vBic', 32, confusable)])
                self.assertEqual(code, 1)
                self.assertIn('SAYILARI DEĞİŞTİ', output)
                self.assertNotIn('OK —', output)

    def test_same_video_assigned_to_another_step_cannot_use_the_baseline(self):
        code, output = self.run_gate([('4BRd2E8vBic', 32, 50)],
                                     step='hh_roger_rabbit')
        self.assertEqual(code, 1)
        self.assertNotIn('TAŞINIYOR', output)

    def test_missing_transcript_pool_stays_environment_unavailable(self):
        code, output = self.run_gate([], missing_pool=True)
        self.assertEqual(code, 2)
        self.assertIn('ORTAM YOK', output)
        self.assertNotIn('OK —', output)

    def test_new_contradiction_still_fails_alongside_carried_one(self):
        code, output = self.run_gate([
            ('4BRd2E8vBic', 32, 50), ('synthetic-unseen-source', 1, 2)
        ])
        self.assertEqual(code, 1)
        self.assertIn('TAŞINIYOR', output)
        self.assertIn('synthetic-unseen-source', output)
        self.assertIn('karıştırılabilir terim BASKIN', output)
        self.assertNotIn('OK —', output)

    def test_no_contradiction_retains_clean_summary(self):
        code, output = self.run_gate([('synthetic-clean-source', 2, 0)])
        self.assertEqual(code, 0)
        self.assertIn('hiçbir kabul edilmiş', output.splitlines()[-1])
        self.assertNotIn('TAŞINIYOR', output)


if __name__ == '__main__':
    unittest.main()

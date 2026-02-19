import { Router, Request, Response } from 'express';

const router = Router();

// Placeholder for Speechmatics integration
router.post('/transcribe', async (req: Request, res: Response) => {
  try {
    // For now, accept text input as mock transcription
    const { audio_text } = req.body;

    if (!audio_text) {
      return res.status(400).json({ error: 'audio_text is required for mock transcription' });
    }

    res.json({ transcript: audio_text, confidence: 0.98 });
  } catch (error) {
    res.status(500).json({ error: 'Voice transcription failed' });
  }
});

router.post('/confirm', async (req: Request, res: Response) => {
  try {
    const { message } = req.body;
    res.json({
      confirmation: `I heard: ${message}. Do you want to proceed?`,
      haptic_feedback: true
    });
  } catch (error) {
    res.status(500).json({ error: 'Voice confirmation failed' });
  }
});

export default router;

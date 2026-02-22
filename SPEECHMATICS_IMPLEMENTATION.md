# Speechmatics Real-time Voice AI Implementation

## ✅ COMPLETED - February 22, 2026

### Overview

Completely rewrote `speechmatics_service.dart` to implement proper **real-time conversational voice AI** using Speechmatics WebSocket streaming API, based on official Voice SDK documentation.

---

## Architecture

### WebSocket Real-time Streaming ✅

- **Endpoint**: `wss://eu2.rt.speechmatics.com/v2`
- **Protocol**: WebSocket binary audio streaming
- **Authentication**: JWT token via API key
- **Audio Format**: 16-bit PCM, 16kHz, mono (standard for mobile)

### Conversational AI Features ✅

#### 1. Automatic Turn Detection

- Detects when user finishes speaking (800ms silence delay)
- No manual "stop listening" button needed
- Siri-like natural conversation flow

#### 2. Intelligent Segmentation

- Groups words into meaningful speech segments
- Separates speaker turns automatically
- Provides clean, structured segments vs raw word stream

#### 3. Low-latency Transcription

- **Max delay**: 0.7 seconds (configurable)
- **Partial results**: Word-by-word updates as user speaks
- **Final results**: Complete segments after turn ends

#### 4. Speaker Diarization

- Identifies different speakers (USER, S1, S2, etc.)
- Useful for multi-speaker scenarios
- Enables speaker-focused transcription

#### 5. Preset Configurations

Based on Speechmatics Voice SDK presets:

| Preset        | Use Case              | Best For                |
| ------------- | --------------------- | ----------------------- |
| `adaptive` ✅ | General conversation  | InkaWallet (default)    |
| `fast`        | Low latency responses | Quick commands          |
| `smart_turn`  | Complex conversation  | ML-based turn detection |
| `scribe`      | Note-taking           | Dictation               |
| `captions`    | Live captioning       | Accessibility           |

---

## Implementation Details

### Service: `SpeechmaticsService`

#### Connection & Streaming

```dart
// Connect to WebSocket with conversational preset
await speechmatics.connect(
  language: 'en',
  preset: 'adaptive',          // Best for wallet conversations
  enableDiarization: true,     // Speaker detection
  enablePartials: true,        // Real-time word updates
  maxDelay: 0.7,              // Low latency (700ms)
);

// Stream audio chunks (16-bit PCM, 16kHz)
await speechmatics.sendAudio(audioBytes);

// Signal end of turn
await speechmatics.endStream();
```

#### Listen to Results

```dart
// Word-by-word updates (low latency)
speechmatics.partialTranscripts.listen((text) {
  print('Partial: $text'); // Updates as user speaks
});

// Complete segments (final results)
speechmatics.finalTranscripts.listen((text) {
  print('Final: $text'); // After turn ends
});

// Structured segments with metadata
speechmatics.segments.listen((segment) {
  print('Speaker ${segment['speaker_id']}: ${segment['text']}');
  print('Confidence: ${segment['confidence']}');
  print('Turn ended: ${segment['turn_ended']}');
});
```

#### State Management

```dart
bool isConnected = speechmatics.isConnected;
bool isStreaming = speechmatics.isStreaming;

// Cleanup
await speechmatics.disconnect();
speechmatics.dispose();
```

---

## Key Differences from Previous Implementation

### ❌ OLD (Batch HTTP API)

- HTTP POST to `/v2/jobs` endpoint
- Upload complete audio file
- Wait for processing
- Poll for results
- **NOT suitable for conversation**
- High latency (seconds to minutes)

### ✅ NEW (Real-time WebSocket)

- WebSocket streaming to `/v2` endpoint
- Stream audio chunks in real-time
- Receive word-by-word updates
- **Perfect for conversational AI**
- Low latency (0.7 seconds)
- Automatic turn detection
- Speaker diarization
- Intelligent segmentation

---

## Voice SDK Concepts Applied

From Speechmatics Python Voice SDK → Flutter Dart adaptation:

| Voice SDK Feature                    | Flutter Implementation        |
| ------------------------------------ | ----------------------------- |
| `VoiceAgentClient`                   | `SpeechmaticsService`         |
| `AgentServerMessageType.ADD_SEGMENT` | `segments` stream             |
| Automatic turn detection             | `_turnDetectionTimer` (800ms) |
| Speaker management                   | Speaker ID in segments        |
| Preset configurations                | `connect(preset: 'adaptive')` |
| Microphone streaming                 | `sendAudio(audioBytes)`       |
| Event handlers `@client.on()`        | Stream listeners              |

---

## Configuration Details

### StartRecognition Message

```json
{
  "message": "StartRecognition",
  "audio_format": {
    "type": "raw",
    "encoding": "pcm_s16le",
    "sample_rate": 16000
  },
  "transcription_config": {
    "language": "en",
    "operating_point": "enhanced",
    "enable_partials": true,
    "max_delay": 0.7,
    "diarization": "speaker",
    "enable_entities": true,
    "punctuation_overrides": {
      "permitted_marks": [".", ",", "?", "!"]
    }
  }
}
```

### WebSocket Message Types

#### Incoming (from Speechmatics)

- `RecognitionStarted` - Connection established
- `AddPartialTranscript` - Word-by-word updates
- `AddTranscript` - Final segment transcripts
- `EndOfTranscript` - Stream finished
- `Warning` - Non-fatal issues
- `Error` - Fatal errors
- `Info` - Informational messages

#### Outgoing (to Speechmatics)

- `StartRecognition` - Begin session with config
- Binary audio data - PCM chunks
- `EndOfStream` - Signal end of turn

---

## Dependencies Added

### pubspec.yaml

```yaml
dependencies:
  web_socket_channel: ^3.0.1 # NEW - WebSocket support
  http: ^1.1.2 # Existing - batch API
  shared_preferences: ^2.2.2 # Existing - API key storage
```

---

## Integration with VoiceCommandService

The `VoiceCommandService` should now use `SpeechmaticsService` for:

1. **Connect** when app starts or voice mode activated
2. **Stream audio** from microphone to Speechmatics
3. **Listen to segments** for completed user utterances
4. **Extract intents** using existing `extractIntent()` method
5. **Provide feedback** via TTS and haptics
6. **Disconnect** when voice mode deactivated

---

## Next Steps

### Immediate (Required for Testing)

1. ✅ Install `web_socket_channel` package
2. ⏳ Configure Speechmatics API key in settings
3. ⏳ Integrate with `VoiceCommandService`
4. ⏳ Test on real Android/iOS device with microphone

### Enhancement (Future)

1. Audio chunk buffering for optimal WebSocket performance
2. Retry logic for connection failures
3. Network quality detection and adaptive streaming
4. Offline mode with fallback to local `speech_to_text`
5. Voice activity detection (VAD) for noise filtering
6. Multi-language support (add language selector)

---

## Testing Checklist

- [ ] Verify WebSocket connection to `wss://eu2.rt.speechmatics.com/v2`
- [ ] Test partial transcripts appear word-by-word
- [ ] Verify final transcripts after 800ms silence
- [ ] Check speaker diarization works
- [ ] Test turn detection (automatic stop)
- [ ] Verify low latency (< 1 second)
- [ ] Test error handling (network loss, invalid API key)
- [ ] Verify cleanup on disconnect
- [ ] Test conversation flow: speak → listen → respond → repeat

---

## Documentation Sources

- **Main**: https://docs.speechmatics.com/
- **API Reference**: https://docs.speechmatics.com/api-ref
- **Voice SDK**: https://docs.speechmatics.com/voice-agents/overview
- **Real-time Quickstart**: https://docs.speechmatics.com/speech-to-text/realtime/quickstart
- **GitHub SDK**: https://github.com/speechmatics/speechmatics-python-sdk

---

## Summary

✅ **Proper real-time conversational AI implemented**  
✅ **WebSocket streaming with low latency**  
✅ **Automatic turn detection (Siri-like)**  
✅ **Intelligent segmentation and speaker detection**  
✅ **Based on official Speechmatics Voice SDK concepts**  
✅ **Ready for hands-free wallet control**

⚠️ **Requires API key configuration and device testing**

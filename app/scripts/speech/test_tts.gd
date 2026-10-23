class_name TestTTS
extends TTSProvider
## Offline development synthesizer (labelled fallback, NOT a finished voice). Produces a
## robotic formant-like tone per word with a deterministic amplitude envelope, plus a viseme
## plan ("A" during each syllable, "sil" between words). Deterministic per word (seeded by
## word hash) so tests are reproducible. This drives real audio and real mouth motion offline,
## but it is explicitly a development fixture, not speech quality.

const SR := 24000
const SYLLABLE_MS := 140
const GAP_MS := 70
const _TAU := 6.28318530718


func synthesize(text: String, is_cancelled: Callable = Callable()) -> Array:
	var words := _words(text)
	var segments: Array = []
	var seq := 0
	for word in words:
		if is_cancelled.is_valid() and is_cancelled.call():
			break
		var seg := SpeechSegment.new()
		seg.id = SpeechSegment.new_id()
		seg.seq = seq
		seg.text = word
		seg.sample_rate = SR
		seg.pcm = _synthesize_word(word)
		seg.duration_samples = seg.pcm.size()
		seg.visemes = _visemes_for(seg.duration_samples)
		segments.append(seg)
		seq += 1
	return segments


func _words(text: String) -> Array:
	var words: Array = []
	for token in Store.tokenize(text):
		words.append(token)
	return words


## Deterministic per-word pitch so different words sound distinct.
func _word_pitch(word: String) -> float:
	var h := 0
	for i in word.length():
		h = (h * 31 + word.unicode_at(i)) & 0x7fffffff
	return 180.0 + float(h % 160)


func _synthesize_word(word: String) -> PackedFloat32Array:
	var syllable := int(float(SYLLABLE_MS) * SR / 1000.0)
	var gap := int(float(GAP_MS) * SR / 1000.0)
	var total := syllable + gap
	var pcm := PackedFloat32Array()
	pcm.resize(total)
	var f0 := _word_pitch(word)
	for i in syllable:
		var t := float(i) / SR
		var env := pow(sin(PI * float(i) / float(syllable)), 2.0)
		var sample := 0.0
		sample += sin(_TAU * f0 * t)
		sample += 0.4 * sin(_TAU * f0 * 2.0 * t)
		sample += 0.2 * sin(_TAU * f0 * 3.0 * t)
		pcm[i] = 0.25 * env * sample
	# Remaining gap samples are already zero.
	return pcm


func _visemes_for(duration_samples: int) -> Array:
	var syllable := int(float(SYLLABLE_MS) * SR / 1000.0)
	var out: Array = []
	out.append({"time_ms": 0, "viseme": "A", "weight": 1.0})
	out.append({"time_ms": SYLLABLE_MS, "viseme": "sil", "weight": 1.0})
	return out

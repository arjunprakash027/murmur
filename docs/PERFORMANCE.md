# Performance

murmur is fast on low-end hardware. We measured it on a base MacBook Air M1 with 8 GB of RAM.

## Test machine

| Item | Value |
|---|---|
| Model | MacBook Air (M1, 2020), `MacBookAir10,1` |
| Chip | Apple M1 |
| Memory | 8 GB |
| macOS | 26.7.2 |
| Power | Mains power |
| App | murmur 0.1, whisper.cpp 1.7.5, `base.en` model, Metal GPU |
| Date | 2026-10-11 |

## Speed

We ran each clip 5 times. The time is the time to turn speech into text.

| Clip length | Words | Time (median) | Range | Faster than real time |
|---|---|---|---|---|
| 2.5 s | 9 | **205 ms** | 198 to 213 ms | 12 times |
| 7.3 s | 26 | **307 ms** | 304 to 312 ms | 24 times |
| 20.9 s | 78 | **616 ms** | 573 to 657 ms | 34 times |

You wait about 0.2 s after a short sentence. You wait about 0.6 s after 20 s of speech.

## Memory, CPU and size

| Item | Value |
|---|---|
| Memory while idle | about 210 MB |
| Memory peak while transcribing | 238 to 250 MB |
| CPU while idle | 0.0 % |
| Model load at launch | 130 to 230 ms (one time) |
| App size | 146 MB (zip: 129 MB) |

murmur does not record and does not run the model when you are idle. The CPU stays at 0 %.

## What the numbers mean

- All 3 test clips came back with the same word count as the script (9, 26 and 78 words).
- The test clips use a synthetic macOS voice. Real speech, background noise and accents can change the accuracy.
- The numbers cover the model only. We did not measure microphone launch or paste time.
- We tested one machine on mains power. We did not test battery use.

## Run the test yourself

```
./build.sh
scripts/benchmark.sh
```

The script needs `say` and `ffmpeg`. It prints the machine, the times and the peak memory.

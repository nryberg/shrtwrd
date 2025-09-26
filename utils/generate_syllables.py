#!/usr/bin/env python3
"""
Generate syllable counts for words using the syllables library.
Creates a syllables.txt file with word:count format.
"""

import sys
import os

try:
    import syllables
except ImportError:
    print("Installing syllables library...")
    import subprocess

    subprocess.check_call([sys.executable, "-m", "pip", "install", "syllables"])
    import syllables


def count_syllables_accurate(word):
    """Count syllables using the syllables library with fallbacks"""
    try:
        count = syllables.estimate(word)
        return max(1, count)  # Every word has at least 1 syllable
    except:
        # Fallback to simple vowel counting if library fails
        word = word.lower()
        vowels = "aeiouy"
        count = 0
        prev_was_vowel = False

        for char in word:
            is_vowel = char in vowels
            if is_vowel and not prev_was_vowel:
                count += 1
            prev_was_vowel = is_vowel

        # Handle silent e
        if word.endswith("e") and count > 1:
            count -= 1

        return max(1, count)


def main():
    # Read words from words.txt
    words_file = "../words.txt"
    if not os.path.exists(words_file):
        words_file = "words.txt"

    if not os.path.exists(words_file):
        print("Error: words.txt not found")
        return 1

    print("Reading words...")
    with open(words_file, "r") as f:
        words = [line.strip() for line in f if line.strip()]

    print(f"Processing {len(words)} words...")

    # Generate syllable counts
    syllable_data = []
    errors = []

    for i, word in enumerate(words):
        if i % 100 == 0:
            print(f"Processed {i}/{len(words)} words...")

        try:
            count = count_syllables_accurate(word)
            syllable_data.append((word, count))
        except Exception as e:
            errors.append((word, str(e)))

    # Write syllables.txt
    output_file = "syllables.txt"
    with open(output_file, "w") as f:
        for word, count in syllable_data:
            f.write(f"{word}:{count}\n")

    print(f"Generated {output_file} with {len(syllable_data)} entries")

    if errors:
        print(f"Errors processing {len(errors)} words:")
        for word, error in errors[:5]:  # Show first 5 errors
            print(f"  {word}: {error}")

    # Show some examples
    print("\nSample syllable counts:")
    for word, count in syllable_data[:10]:
        print(f"  {word}: {count}")

    # Test some tricky words
    test_words = ["spasm", "rhythm", "sixth", "through", "squirrel", "fire", "hour"]
    print("\nTest words:")
    word_dict = dict(syllable_data)
    for word in test_words:
        if word in word_dict:
            print(f"  {word}: {word_dict[word]}")
        else:
            count = count_syllables_accurate(word)
            print(f"  {word}: {count} (not in word list)")


if __name__ == "__main__":
    main()

"""
train_skin_model.py
Trains a word-count DictVectorizer + Logistic Regression classifier on labelled
skin-concern sentences, then exports a local CoreML .mlmodel bundled with the
Glowza Xcode project. Input at inference time: a {word: count} dictionary.
Coremltools officially supports DictVectorizer -> LogisticRegression pipelines.
"""

import sys
# Ensure sklearn 1.5.x from /tmp/sklearn151 is used (coremltools ≤ 1.5.1 compat)
sys.path.insert(0, "/tmp/sklearn151")

import coremltools as ct
from sklearn.feature_extraction import DictVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import Normalizer
from sklearn.pipeline import Pipeline

# ─────────────────────────────────────────────────────────────
# 1. Training data — labelled skin-concern sentences
# ─────────────────────────────────────────────────────────────
# These are the categories our model will learn to predict!
LABELS = [
    "Acne & Breakouts",
    "Dark Circles",
    "Hyperpigmentation",
    "Wrinkles & Aging",
    "Unwanted Hair",
    "Dull & Uneven Tone",
    "Dryness & Dehydration",
    "Acne Scars",
]

# This is the training data. We provide examples of what a user might say
# and label them with the correct concern category.
training_examples = [
    # ── Acne & Breakouts ──────────────────────────────────────
    ("I have pimples on my face",                              LABELS[0]),
    ("my skin breaks out every month",                         LABELS[0]),
    ("acne keeps coming back on my cheeks",                    LABELS[0]),
    ("oily skin with blackheads and whiteheads",               LABELS[0]),
    ("clogged pores and blemishes all over",                   LABELS[0]),
    ("I get zits around my chin and forehead",                 LABELS[0]),
    ("breakout keeps happening",                               LABELS[0]),
    ("sebum excess causing acne",                              LABELS[0]),
    ("fungal acne on forehead",                                LABELS[0]),
    ("hormonal breakouts on jaw",                              LABELS[0]),
    ("painful cystic pimples under skin",                      LABELS[0]),
    ("persistent acne and oily T-zone",                        LABELS[0]),
    ("blemishes and spots on face",                            LABELS[0]),
    ("I have very oily skin and I break out frequently",       LABELS[0]),
    ("whiteheads and blackheads on nose",                      LABELS[0]),

    # ── Dark Circles ────────────────────────────────────────
    ("I have dark circles under my eyes",                      LABELS[1]),
    ("puffy eyes with dark shadows",                           LABELS[1]),
    ("under eye bags look terrible",                           LABELS[1]),
    ("I look tired because of dark under eyes",                LABELS[1]),
    ("hollow eyes making me look old",                         LABELS[1]),
    ("periorbital darkening is bothering me",                  LABELS[1]),
    ("swollen puffy lower eyelids",                            LABELS[1]),
    ("undereye discoloration",                                 LABELS[1]),
    ("dark pigment around eye area",                           LABELS[1]),
    ("shadows under eyes make me look exhausted",              LABELS[1]),
    ("eye bags and dark circles",                              LABELS[1]),
    ("I need treatment for puffy tired looking eyes",          LABELS[1]),
    ("my eyes look dark and sunken",                           LABELS[1]),
    ("blue tinge under my eyes always",                        LABELS[1]),
    ("dark circles not going away with sleep",                 LABELS[1]),

    # ── Hyperpigmentation ────────────────────────────────────
    ("I have dark spots on my face from sun",                  LABELS[2]),
    ("melasma patches on cheeks and forehead",                 LABELS[2]),
    ("uneven skin tone and discoloration",                     LABELS[2]),
    ("freckles and age spots appearing",                       LABELS[2]),
    ("sun tan is not going away",                              LABELS[2]),
    ("uneven patches on skin from sun damage",                 LABELS[2]),
    ("brown spots on face and neck",                           LABELS[2]),
    ("pigmentation from old acne spots",                       LABELS[2]),
    ("my skin looks blotchy and uneven",                       LABELS[2]),
    ("post inflammatory hyperpigmentation",                    LABELS[2]),
    ("dark patches after waxing",                              LABELS[2]),
    ("tan lines from outdoor activities",                      LABELS[2]),
    ("skin discoloration due to hormones",                     LABELS[2]),
    ("uneven skin color on different parts of face",           LABELS[2]),
    ("stubborn dark spots not fading",                         LABELS[2]),

    # ── Wrinkles & Aging ────────────────────────────────────
    ("I have wrinkles on my forehead",                         LABELS[3]),
    ("fine lines appearing under eyes",                        LABELS[3]),
    ("sagging skin around jawline",                            LABELS[3]),
    ("deep nasolabial folds",                                  LABELS[3]),
    ("crow feet around eyes",                                  LABELS[3]),
    ("loss of facial volume and hollow cheeks",                LABELS[3]),
    ("my skin is losing elasticity",                           LABELS[3]),
    ("aging and loose skin on neck",                           LABELS[3]),
    ("expression lines on forehead",                           LABELS[3]),
    ("skin does not bounce back anymore",                      LABELS[3]),
    ("deep laugh lines beside mouth",                          LABELS[3]),
    ("forehead lines and frown marks",                         LABELS[3]),
    ("anti aging treatment needed for fine lines",             LABELS[3]),
    ("signs of aging showing on face",                         LABELS[3]),
    ("volume loss making face look hollow",                    LABELS[3]),

    # ── Unwanted Hair ────────────────────────────────────────
    ("I have unwanted hair on my upper lip",                   LABELS[4]),
    ("body hair growing too fast after shaving",               LABELS[4]),
    ("facial hair on chin and cheeks",                         LABELS[4]),
    ("hair on legs and arms that I want removed",              LABELS[4]),
    ("want permanent hair removal solution",                   LABELS[4]),
    ("waxing every month is not working",                      LABELS[4]),
    ("dark hair on my back",                                   LABELS[4]),
    ("bikini area hair removal",                               LABELS[4]),
    ("underarm hair growing back quickly",                     LABELS[4]),
    ("excessive hair growth all over body",                    LABELS[4]),
    ("hirsutism on face and chin",                             LABELS[4]),
    ("unwanted facial and body hair bothers me",               LABELS[4]),
    ("hair follicles on arms and legs",                        LABELS[4]),
    ("hair removal above eyebrows",                            LABELS[4]),
    ("shaving rashes from frequent hair removal",              LABELS[4]),

    # ── Dull & Uneven Tone ──────────────────────────────────
    ("my skin looks dull and lifeless",                        LABELS[5]),
    ("I want a brighter more glowing skin",                    LABELS[5]),
    ("skin tone is uneven and dark",                           LABELS[5]),
    ("fairness injections for skin brightening",               LABELS[5]),
    ("skin whitening and radiance",                            LABELS[5]),
    ("lack of glow on face",                                   LABELS[5]),
    ("skin looks tired and grey",                              LABELS[5]),
    ("glutathione for skin lightening",                        LABELS[5]),
    ("uneven skin tone after pregnancy",                       LABELS[5]),
    ("want bright and radiant skin",                           LABELS[5]),
    ("vitamin C glow treatment",                               LABELS[5]),
    ("dull complexion and no radiance",                        LABELS[5]),
    ("skin whitening without harsh chemicals",                 LABELS[5]),
    ("skin brightening treatment needed",                      LABELS[5]),
    ("improving skin tone to look more even",                  LABELS[5]),

    # ── Dryness & Dehydration ────────────────────────────────
    ("my skin is extremely dry and flaky",                     LABELS[6]),
    ("dehydrated skin that feels tight",                       LABELS[6]),
    ("dry patches on cheeks and forehead",                     LABELS[6]),
    ("rough and itchy dry skin",                               LABELS[6]),
    ("skin moisture barrier is broken",                        LABELS[6]),
    ("I need hydration for my skin",                           LABELS[6]),
    ("parched skin that drinks up moisturizer instantly",      LABELS[6]),
    ("dry skin in winter months",                              LABELS[6]),
    ("flaky and peeling skin around nose",                     LABELS[6]),
    ("lack of moisture in skin",                               LABELS[6]),
    ("dehydrated skin causing premature wrinkles",             LABELS[6]),
    ("skin feels dry and uncomfortable",                       LABELS[6]),
    ("ceramide depleted dry skin",                             LABELS[6]),
    ("very dry skin that cracks",                              LABELS[6]),
    ("over cleansed dehydrated skin",                          LABELS[6]),

    # ── Acne Scars ───────────────────────────────────────────
    ("I have acne scars from old pimples",                     LABELS[7]),
    ("crater like marks left from acne",                       LABELS[7]),
    ("pockmarks and indented scars on cheeks",                 LABELS[7]),
    ("rolling scars and icepick scars",                        LABELS[7]),
    ("post acne marks not healing",                            LABELS[7]),
    ("boxcar scars on cheeks from old acne",                   LABELS[7]),
    ("acne left deep holes in my skin",                        LABELS[7]),
    ("textured skin from old breakouts",                       LABELS[7]),
    ("scarring from severe cystic acne",                       LABELS[7]),
    ("red marks from recent pimples",                          LABELS[7]),
    ("indented skin texture from acne",                        LABELS[7]),
    ("microneedling for old acne scars",                       LABELS[7]),
    ("post inflammatory scarring",                             LABELS[7]),
    ("skin pitting from teenage acne",                         LABELS[7]),
    ("old acne scars treatment",                               LABELS[7]),
]

texts, labels = zip(*training_examples)

# ─────────────────────────────────────────────────────────────
# 2. Convert text → word-count dicts  (Bag of Words)
# ─────────────────────────────────────────────────────────────
# This function splits a sentence into words and counts how many times
# each word appears. This is a simple way to represent text for ML!
def text_to_word_counts(text: str) -> dict:
    words = text.lower().split()
    counts = {}
    for w in words:
        counts[w] = counts.get(w, 0) + 1
    return counts

# Convert all our training texts into these word-count dictionaries!
text_dicts = [text_to_word_counts(t) for t in texts]

# ─────────────────────────────────────────────────────────────
# 3. Build sklearn pipeline
# ─────────────────────────────────────────────────────────────
# We use a pipeline to chain together the vectorizer, normalizer, and classifier.
pipeline = Pipeline([
    # DictVectorizer converts the {word: count} dicts into numerical vectors!
    ("vect",    DictVectorizer()),
    # Normalizer scales the vectors so they have unit norm (length of 1).
    ("norm",    Normalizer(norm="l2")),
    # LogisticRegression is the actual classifier that learns patterns!
    ("clf",     LogisticRegression(C=1.5, max_iter=500, multi_class="ovr", solver="liblinear")),
])

# Train the model!
pipeline.fit(text_dicts, labels)

# Quick self-check to see if the model learned the training data well!
test_cases = [
    ("pimples and oily skin",          LABELS[0]),
    ("dark circles under eyes",        LABELS[1]),
    ("sun tan and pigmentation",       LABELS[2]),
    ("wrinkles on forehead",           LABELS[3]),
    ("unwanted body hair",             LABELS[4]),
    ("dull skin wants glow",           LABELS[5]),
    ("dry flaky dehydrated skin",      LABELS[6]),
    ("acne scars pockmarks",           LABELS[7]),
]
all_pass = True
for text, expected in test_cases:
    pred = pipeline.predict([text_to_word_counts(text)])[0]
    status = "✓" if pred == expected else "✗"
    if pred != expected:
        all_pass = False
    print(f"{status}  [{expected}]  '{text}' → '{pred}'")

# ─────────────────────────────────────────────────────────────
# 4. Export to CoreML
# ─────────────────────────────────────────────────────────────
# Now we convert the trained scikit-learn pipeline into Apple's CoreML format!
coreml_model = ct.converters.sklearn.convert(
    pipeline,
    input_features="wordCounts",        # The name of the input feature in iOS.
    output_feature_names="skinConcernLabel", # The name of the output prediction.
)

# Add some metadata so we know what this model is!
coreml_model.short_description = "Skin concern text classifier for Glowza app"
coreml_model.author             = "Glowza AI"
coreml_model.version            = "1.0"
coreml_model.input_description["wordCounts"]        = "Word-count dictionary of the skin concern input"
coreml_model.output_description["skinConcernLabel"] = "Predicted skin concern category"

# Save the model to the Xcode project directory!
OUTPUT = "/Users/COBSCCOMP242P-024/AsiniDev/GLOWZA/GLOWZA/Views/AIBeauty/SkinConcernClassifier.mlmodel"
coreml_model.save(OUTPUT)
print(f"\n{'' if all_pass else ' '}  Model saved → {OUTPUT}")
print(f"   Classes: {list(pipeline.classes_)}")

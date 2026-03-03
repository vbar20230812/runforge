# RunForge — Running Personal Trainer

## Design & Architecture Document

**Version:** 1.0  
**Date:** February 26, 2026  
**Status:** Ready for Implementation  

---

## 1. Product Vision

RunForge is a web-based personal training application purpose-built for runners targeting a 10K PR. It combines AI-generated superset strength workouts with structured running plans, visualized on a training calendar with Garmin Forerunner device synchronization. The app generates unique workouts each session, tracks muscle impact over time, and adapts training load across the week.

### 1.1 Target User Profile

- Intermediate runners (able to complete 10K, aiming to improve time)
- Age range: 30–55, health-conscious, possibly managing conditions (e.g., controlled blood pressure)
- Has a Garmin Forerunner series watch
- Wants efficient gym sessions (20–35 min) using supersets
- Runs 2–3 times per week, strength trains 3–5 times per week

### 1.2 Core Goals

| # | Goal | Metric |
|---|------|--------|
| G1 | Improve 10K time | Pace progression tracked from Garmin data |
| G2 | Prevent injury | Balanced muscle loading across week |
| G3 | Maximize gym efficiency | Superset-based workouts under 35 min |
| G4 | Workout variety | No repeated workout in a 4-week cycle |
| G5 | Seamless device sync | Garmin Forerunner push/pull |
| G6 | Increase bone density | Prioritize high-impact + heavy-load exercises that stimulate osteogenesis |

---

## 2. Feature Specification

### 2.1 Workout Generation Engine

#### 2.1.1 Strength Workouts (3–5 per week)

Each strength session is built from **superset pairs** — two exercises performed back-to-back with minimal rest, targeting either opposing muscle groups or upper/lower body alternation.

**Workout Structure:**
```
Warm-up: 5 min dynamic stretching
Superset Block 1: Exercise A + Exercise B — 3 sets × 10–12 reps
Superset Block 2: Exercise C + Exercise D — 3 sets × 10–12 reps
Superset Block 3: Exercise E + Exercise F — 3 sets × 10–12 reps
(Optional) Superset Block 4: Exercise G + Exercise H — 2–3 sets × 12–15 reps
Cool-down: 5 min static stretching
```

**Superset Pairing Strategies (rotated per session):**

| Strategy | Description | Example |
|----------|-------------|---------|
| Antagonist | Opposing muscle groups | Hamstring curl + Leg extension |
| Upper/Lower | Alternating body regions | Push-ups + Bulgarian split squats |
| Push/Pull | Opposing movement patterns | Overhead press + Rows |
| Compound/Isolation | Heavy compound + targeted isolation | Deadlift + Calf raises |
| Strength/Core | Power move + core stability | Squats + Pallof press |

**Bone Density Loading Principles:**

Bone adapts to mechanical stress through a process called mechanotransduction — osteocytes (bone cells) sense strain and signal osteoblasts to deposit new bone matrix. Research shows that exercises producing ground-reaction forces exceeding 4× bodyweight or muscle-pull forces at major tendon attachment sites are the most effective stimulators of bone mineral density (BMD). This is especially critical for runners over 40, where natural bone loss accelerates.

The workout generator enforces **bone density loading rules** in every session:

| Bone-Loading Category | Mechanism | Minimum Per Week | Key Exercises |
|----------------------|-----------|-----------------|---------------|
| **Heavy axial loading** | Compressive force through spine + femur from heavy weight | 2 sessions | Barbell squat, Deadlift, Hip thrust, Goblet squat |
| **High-impact plyometrics** | Ground-reaction forces of 4–6× bodyweight stimulate hip/tibia/femur | 1–2 sessions | Jump squat, Box jump, Jump lunge |
| **Unilateral loaded stance** | Concentrated force through single femur + hip | 2 sessions | Bulgarian split squat, Single-leg RDL, Step-ups, Walking lunge |
| **Upper body pulling/pressing** | Muscle-pull forces at wrist, humerus, spine | 1–2 sessions | Pull-ups, Overhead press, Push-ups, Rows |
| **Impact running** | Repetitive ground-reaction forces at tibia + calcaneus | 2–3 sessions (running days) | All running workouts contribute |

**Exercise Bone Density Scores:**

Each exercise in the catalog carries a `boneDensityScore` (0–100) indicating its effectiveness at stimulating bone formation. The generator uses this score alongside `runnerScore` to ensure every week includes adequate bone-loading stimulus:

```typescript
const BONE_DENSITY_SCORES: Record<string, number> = {
  // Highest impact — heavy axial loading + ground reaction forces
  "barbell_squat":         95,   // Heavy spinal + femoral loading
  "conventional_deadlift": 95,   // Peak hip/spine compressive force
  "jump_squat":            92,   // 5-6× BW ground reaction
  "box_jumps":             90,   // High-impact landing forces
  "jump_lunge":            88,   // Plyometric + unilateral loading
  "hip_thrust":            85,   // Heavy hip extension, femur loading
  "goblet_squat":          83,   // Moderate axial loading

  // High impact — unilateral heavy loading
  "bulgarian_split_squat": 82,   // Single-leg femoral loading
  "walking_lunge":         80,   // Dynamic loading per leg
  "step_ups":              78,   // Single-leg weight bearing
  "single_leg_rdl":        77,   // Hip hinge, single-leg stance
  "forward_lunge":         76,
  "reverse_lunge":         75,
  "lateral_lunge":         72,
  "curtsy_lunge":          70,

  // Moderate impact — muscle-pull forces on bone
  "romanian_deadlift":     74,   // Hamstring pull on ischium
  "overhead_press":        70,   // Humerus + spine compression
  "pull_ups":              68,   // Humerus traction, spine decompression
  "pushups":               55,   // Wrist + humerus loading
  "dumbbell_row":          52,   // Humerus, scapula loading
  "calf_raises":           65,   // Tibia + calcaneus loading
  "glute_bridge":          50,   // Moderate hip loading

  // Lower impact — stability/isolation (still valuable but less bone stimulus)
  "hamstring_curl":        35,
  "reverse_fly":           30,
  "front_plank":           25,   // Isometric, minimal bone impact
  "side_plank":            25,
  "dead_bug":              15,
  "bird_dog":              15,
  "v_ups":                 10,
  "pallof_press":          20,
  "mountain_climbers":     40,   // Dynamic loading
  "russian_twist":         15,
  "superman":              20,
  "clam_shells":           10,
  "banded_side_steps":     12,
  "sumo_squat":            78,
};
```

#### 2.1.2 Running Workouts (2–3 per week)

Structured running sessions targeting 10K improvement:

| Type | Frequency | Description |
|------|-----------|-------------|
| Easy Run | 1/week | Zone 2, conversational pace, 30–45 min |
| Tempo Run | 1/week | 10 min warm-up → 20 min at threshold → 10 min cool-down |
| Interval/Speed | 0–1/week | 400m–1K repeats at 5K pace with recovery jogs |
| Long Run | 1 every 2 weeks | 60–80 min at easy pace |

**Periodization Model:**  
4-week mesocycles — 3 weeks progressive load → 1 week deload. Running volume increases ~10% per build week, drops 40% on deload week.

#### 2.1.3 Weekly Schedule Template

```
Monday:    Strength (Lower-body focus) + Optional easy run
Tuesday:   Tempo Run
Wednesday: Strength (Upper-body + core focus)
Thursday:  Easy Run or Rest
Friday:    Strength (Full-body power focus)
Saturday:  Long Run or Intervals
Sunday:    Rest or Active Recovery
```

The scheduler adapts based on user-selected frequency (3–5 strength + 2–3 running) and distributes hard days to avoid consecutive overload.

### 2.2 Exercise Database

#### 2.2.1 Complete Exercise Catalog

Each exercise stores: `id`, `name`, `primaryMuscles[]`, `secondaryMuscles[]`, `equipment`, `movement`, `difficulty`, `isUnilateral`, `instructions`, `animationUrl`.

**Lower Body — Runner Priority Exercises:**

| Exercise | Primary Muscles | Secondary | Equipment | Movement | Bone Score |
|----------|----------------|-----------|-----------|----------|------------|
| Barbell Back Squat | Quads, Glutes | Core, Hamstrings | Barbell | Compound | 95 |
| Goblet Squat | Quads, Glutes | Core | Dumbbell | Compound | 83 |
| Bulgarian Split Squat | Quads, Glutes | Hamstrings, Core | Dumbbell | Unilateral | 82 |
| Pistol Squat | Quads, Glutes | Core, Calves | Bodyweight | Unilateral | 75 |
| Jump Squat | Quads, Glutes | Calves | Bodyweight | Plyometric | 92 |
| Romanian Deadlift | Hamstrings, Glutes | Lower Back | Barbell/DB | Compound | 74 |
| Single-Leg RDL | Hamstrings, Glutes | Core, Lower Back | Dumbbell | Unilateral | 77 |
| Conventional Deadlift | Hamstrings, Glutes, Back | Core, Quads | Barbell | Compound | 95 |
| Forward Lunge | Quads, Glutes | Hamstrings | Dumbbell | Unilateral | 76 |
| Reverse Lunge | Quads, Glutes | Hamstrings | Dumbbell | Unilateral | 75 |
| Walking Lunge | Quads, Glutes | Hamstrings, Core | Dumbbell | Unilateral | 80 |
| Lateral Lunge | Adductors, Quads | Glutes | Dumbbell | Unilateral | 72 |
| Curtsy Lunge | Glutes, Quads | Adductors | Dumbbell | Unilateral | 70 |
| Jump Lunge | Quads, Glutes | Calves | Bodyweight | Plyometric | 88 |
| Step-Ups | Quads, Glutes | Hamstrings | Dumbbell/Box | Unilateral | 78 |
| Glute Bridge | Glutes | Hamstrings, Core | Bodyweight/Barbell | Isolation | 50 |
| Hip Thrust | Glutes | Hamstrings, Core | Barbell/Bench | Compound | 85 |
| Hamstring Curl | Hamstrings | Calves | Machine/Band | Isolation | 35 |
| Calf Raises | Calves (Gastrocnemius) | Soleus | Dumbbell/BW | Isolation | 65 |
| Clam Shells | Glute Med | Hip Rotators | Band | Isolation | 10 |
| Banded Side Steps | Glute Med, Glute Min | TFL | Band | Isolation | 12 |
| Box Jumps | Quads, Glutes | Calves, Core | Box | Plyometric | 90 |
| Sumo Squat | Quads, Adductors | Glutes | Dumbbell | Compound | 78 |

**Upper Body & Core — Supporting Exercises:**

| Exercise | Primary Muscles | Secondary | Equipment | Movement | Bone Score |
|----------|----------------|-----------|-----------|----------|------------|
| Push-ups | Chest, Triceps | Shoulders, Core | Bodyweight | Compound | 55 |
| Rows (Dumbbell) | Lats, Rhomboids | Biceps, Rear Delts | Dumbbell | Compound | 52 |
| Pull-ups | Lats, Biceps | Rear Delts, Core | Bar | Compound | 68 |
| Reverse Fly | Rear Delts, Rhomboids | Traps | Dumbbell | Isolation | 30 |
| Plank (Front) | Core (Transverse Abd) | Shoulders, Glutes | Bodyweight | Isometric | 25 |
| Side Plank | Obliques | Glute Med, Shoulders | Bodyweight | Isometric | 25 |
| Dead Bug | Core (Deep Stabilizers) | Hip Flexors | Bodyweight | Stability | 15 |
| Bird Dog | Core, Erectors | Glutes, Shoulders | Bodyweight | Stability | 15 |
| V-Ups | Rectus Abdominis | Hip Flexors | Bodyweight | Isolation | 10 |
| Pallof Press | Obliques, Transverse Abd | Shoulders | Cable/Band | Anti-rotation | 20 |
| Overhead Press | Shoulders, Triceps | Core | Dumbbell | Compound | 70 |
| Superman | Erectors, Glutes | Hamstrings | Bodyweight | Isolation | 20 |
| Mountain Climbers | Core | Hip Flexors, Shoulders | Bodyweight | Dynamic | 40 |
| Russian Twist | Obliques | Rectus Abdominis | Dumbbell/BW | Rotation | 15 |

#### 2.2.2 Exercise Images Strategy

Every exercise in the catalog must have a visual reference — either an animated GIF showing the movement or a pair of static images (start/end position). This is critical for correct form and injury prevention.

**Primary Source: free-exercise-db (Open Source, Public Domain)**

The `yuhonas/free-exercise-db` GitHub repository provides 800+ exercises with paired start/end position images, structured JSON data, and public domain licensing. Images are hosted directly on GitHub and can be referenced via CDN URLs.

Image URL pattern:
```
https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{exercise_folder}/{0|1}.jpg
```

Example for "Barbell Deadlift":
```
Start position: .../exercises/Barbell_Deadlift/0.jpg
End position:   .../exercises/Barbell_Deadlift/1.jpg
```

**Mapping Strategy:**

Each exercise in our catalog maps to its free-exercise-db counterpart via a `sourceId` field. Since naming may differ, we maintain an explicit mapping table:

```typescript
const IMAGE_MAPPING: Record<string, { sourceId: string; hasGif: boolean }> = {
  "barbell_squat":       { sourceId: "Barbell_Full_Squat", hasGif: false },
  "goblet_squat":        { sourceId: "Dumbbell_Goblet_Squat", hasGif: false },
  "bulgarian_split_squat": { sourceId: "Dumbbell_Single_Leg_Split_Squat", hasGif: false },
  "romanian_deadlift":   { sourceId: "Barbell_Romanian_Deadlift", hasGif: false },
  "single_leg_rdl":      { sourceId: "Dumbbell_Single_Leg_Deadlift", hasGif: false },
  "conventional_deadlift": { sourceId: "Barbell_Deadlift", hasGif: false },
  "forward_lunge":       { sourceId: "Dumbbell_Lunges", hasGif: false },
  "reverse_lunge":       { sourceId: "Barbell_Rear_Lunge", hasGif: false },
  "walking_lunge":       { sourceId: "Dumbbell_Walking_Lunges", hasGif: false },
  "lateral_lunge":       { sourceId: "Dumbbell_Lateral_Lunges", hasGif: false },
  "step_ups":            { sourceId: "Dumbbell_Step_Ups", hasGif: false },
  "glute_bridge":        { sourceId: "Glute_Bridge", hasGif: false },
  "hip_thrust":          { sourceId: "Barbell_Hip_Thrust", hasGif: false },
  "hamstring_curl":      { sourceId: "Lying_Leg_Curls", hasGif: false },
  "calf_raises":         { sourceId: "Standing_Calf_Raises", hasGif: false },
  "pushups":             { sourceId: "Push_Ups", hasGif: false },
  "dumbbell_row":        { sourceId: "Dumbbell_Bent_Over_Row", hasGif: false },
  "pull_ups":            { sourceId: "Pullups", hasGif: false },
  "reverse_fly":         { sourceId: "Dumbbell_Reverse_Fly", hasGif: false },
  "front_plank":         { sourceId: "Front_Plank", hasGif: false },
  "side_plank":          { sourceId: "Side_Plank", hasGif: false },
  "dead_bug":            { sourceId: "Dead_Bug", hasGif: false },
  "bird_dog":            { sourceId: "Bird_Dog", hasGif: false },
  "v_ups":               { sourceId: "V_Up", hasGif: false },
  "overhead_press":      { sourceId: "Dumbbell_Shoulder_Press", hasGif: false },
  "mountain_climbers":   { sourceId: "Mountain_Climber", hasGif: false },
  "russian_twist":       { sourceId: "Russian_Twist", hasGif: false },
  // ... complete mapping for all 37 exercises
};
```

**Fallback Layers (when free-exercise-db doesn't cover an exercise):**

| Priority | Source | Type | Cost | Coverage |
|----------|--------|------|------|----------|
| 1 | free-exercise-db (GitHub) | Static JPG pairs (start/end) | Free (Public Domain) | ~70% of our catalog |
| 2 | Custom SVG illustrations | Vector line art | One-time design cost | For missing exercises |
| 3 | AI-generated illustrations | Stylized instruction art | Minimal (API cost) | Emergency fallback |

**Image Delivery Architecture:**

Rather than linking directly to GitHub raw URLs in production (which has rate limits), we implement a CDN-backed image pipeline:

```
1. BUILD STEP: Download all mapped images from free-exercise-db
2. PROCESS: Resize to 3 variants (thumb: 150px, card: 400px, full: 800px)
3. CONVERT: WebP format with JPEG fallback
4. UPLOAD: Store in S3-compatible bucket (e.g., Cloudflare R2 — free egress)
5. SERVE: Via CDN with cache headers (images never change)
```

**Image URL structure in production:**
```
https://cdn.runforge.app/exercises/{exerciseId}/thumb.webp    (150×150, ~8KB)
https://cdn.runforge.app/exercises/{exerciseId}/card.webp     (400×400, ~25KB)
https://cdn.runforge.app/exercises/{exerciseId}/full.webp     (800×800, ~50KB)
https://cdn.runforge.app/exercises/{exerciseId}/start.webp    (400×400, position 0)
https://cdn.runforge.app/exercises/{exerciseId}/end.webp      (400×400, position 1)
```

**Where images appear in the UI:**

| Context | Image variant | Behavior |
|---------|--------------|----------|
| Exercise card in workout view | `card` (400px) | Shows start position, tap to toggle end position |
| Superset block compact view | `thumb` (150px) | Circular crop, side-by-side A + B |
| Exercise detail modal | `full` (800px) | Animated toggle between start/end with crossfade |
| Workout player (active) | `full` (800px) | Large hero image, auto-flips start↔end every 2s |
| Calendar day preview | `thumb` (150px) | First exercise of first superset as preview icon |

**Updated Exercise Data Model with Images:**

```typescript
interface Exercise {
  id: string;
  name: string;
  primaryMuscles: MuscleGroup[];
  secondaryMuscles: MuscleGroup[];
  equipment: Equipment;
  movementType: MovementType;
  difficulty: 1 | 2 | 3 | 4 | 5;
  isUnilateral: boolean;
  instructions: string[];
  boneDensityScore: number;         // 0–100 osteogenic potential (see §2.1.1)
  images: {
    sourceId: string;           // free-exercise-db folder name
    thumbUrl: string;           // CDN: 150px thumbnail
    cardUrl: string;            // CDN: 400px card image
    fullUrl: string;            // CDN: 800px full image
    startUrl: string;           // CDN: start position
    endUrl: string;             // CDN: end position
    hasAnimation: boolean;      // true if GIF/animation available
    animationUrl?: string;      // CDN: animated GIF (if available)
    attribution: string;        // "Public Domain via free-exercise-db" or custom
  };
}
```

**Note:** These image columns are included in the main `exercises` table schema (see §3.3). The seed script populates both exercise data and image references in a single pass.

#### 2.2.3 Muscle-Group Taxonomy

```
MUSCLE_GROUPS = {
  "quads":          { region: "legs", subRegion: "anterior", svgId: "quads" },
  "hamstrings":     { region: "legs", subRegion: "posterior", svgId: "hamstrings" },
  "glutes":         { region: "legs", subRegion: "posterior", svgId: "glutes" },
  "calves":         { region: "legs", subRegion: "lower", svgId: "calves" },
  "adductors":      { region: "legs", subRegion: "medial", svgId: "adductors" },
  "gluteMed":       { region: "hips", subRegion: "lateral", svgId: "glute-med" },
  "hipFlexors":     { region: "hips", subRegion: "anterior", svgId: "hip-flexors" },
  "core":           { region: "torso", subRegion: "anterior", svgId: "core" },
  "obliques":       { region: "torso", subRegion: "lateral", svgId: "obliques" },
  "lowerBack":      { region: "torso", subRegion: "posterior", svgId: "lower-back" },
  "chest":          { region: "upper", subRegion: "anterior", svgId: "chest" },
  "lats":           { region: "upper", subRegion: "posterior", svgId: "lats" },
  "shoulders":      { region: "upper", subRegion: "lateral", svgId: "shoulders" },
  "rearDelts":      { region: "upper", subRegion: "posterior", svgId: "rear-delts" },
  "triceps":        { region: "arms", subRegion: "posterior", svgId: "triceps" },
  "biceps":         { region: "arms", subRegion: "anterior", svgId: "biceps" },
  "traps":          { region: "upper", subRegion: "posterior", svgId: "traps" },
  "erectors":       { region: "torso", subRegion: "posterior", svgId: "erectors" },
}
```

#### 2.2.4 Pre-defined Superset Pair Pool

The engine selects from a curated pool of proven superset combinations, categorized by strategy. Each pair has a `compatibilityScore` for runners (higher = more relevant) and a `boneScore` reflecting combined osteogenic potential:

```json
{
  "supersetPairs": [
    {
      "id": "SS001",
      "strategy": "antagonist",
      "exerciseA": "hip_thrust",
      "exerciseB": "calf_raises",
      "focus": "lower",
      "runnerScore": 95,
      "boneScore": 75,
      "note": "Stride power + push-off strength"
    },
    {
      "id": "SS002",
      "strategy": "upper_lower",
      "exerciseA": "bulgarian_split_squat",
      "exerciseB": "side_plank",
      "focus": "mixed",
      "runnerScore": 92,
      "boneScore": 54,
      "note": "Single-leg strength + lateral stability"
    },
    {
      "id": "SS003",
      "strategy": "compound_isolation",
      "exerciseA": "deadlift",
      "exerciseB": "pushups",
      "focus": "full_body",
      "runnerScore": 90,
      "boneScore": 75,
      "note": "Posterior chain + upper body push — HIGH BONE LOADING"
    },
    {
      "id": "SS004",
      "strategy": "strength_core",
      "exerciseA": "forward_lunge",
      "exerciseB": "front_plank",
      "focus": "mixed",
      "runnerScore": 88,
      "boneScore": 51,
      "note": "Quad/glute drive + running posture"
    },
    {
      "id": "SS005",
      "strategy": "antagonist",
      "exerciseA": "hamstring_curl",
      "exerciseB": "goblet_squat",
      "focus": "lower",
      "runnerScore": 87,
      "boneScore": 59,
      "note": "Knee flexion/extension balance"
    },
    {
      "id": "SS006",
      "strategy": "push_pull",
      "exerciseA": "overhead_press",
      "exerciseB": "dumbbell_row",
      "focus": "upper",
      "runnerScore": 75,
      "boneScore": 61,
      "note": "Arm swing mechanics + humerus/spine loading"
    },
    {
      "id": "SS007",
      "strategy": "compound_isolation",
      "exerciseA": "single_leg_rdl",
      "exerciseB": "clam_shells",
      "focus": "lower",
      "runnerScore": 93,
      "boneScore": 44,
      "note": "Hip stability + glute activation"
    },
    {
      "id": "SS008",
      "strategy": "strength_core",
      "exerciseA": "barbell_squat",
      "exerciseB": "pallof_press",
      "focus": "mixed",
      "runnerScore": 91,
      "boneScore": 58,
      "note": "Leg drive + anti-rotation — HEAVY AXIAL BONE LOADING"
    },
    {
      "id": "SS009",
      "strategy": "upper_lower",
      "exerciseA": "step_ups",
      "exerciseB": "reverse_fly",
      "focus": "mixed",
      "runnerScore": 82,
      "boneScore": 54,
      "note": "Hill climbing power + posture"
    },
    {
      "id": "SS010",
      "strategy": "antagonist",
      "exerciseA": "walking_lunge",
      "exerciseB": "dead_bug",
      "focus": "mixed",
      "runnerScore": 89,
      "boneScore": 48,
      "note": "Dynamic legs + deep core stability"
    },
    {
      "id": "SS011",
      "strategy": "upper_lower",
      "exerciseA": "jump_squat",
      "exerciseB": "mountain_climbers",
      "focus": "full_body",
      "runnerScore": 85,
      "boneScore": 66,
      "note": "Explosive power + cardio — PLYOMETRIC BONE IMPACT"
    },
    {
      "id": "SS012",
      "strategy": "compound_isolation",
      "exerciseA": "romanian_deadlift",
      "exerciseB": "banded_side_steps",
      "focus": "lower",
      "runnerScore": 94,
      "boneScore": 43,
      "note": "Hamstring length + hip abductor activation"
    },
    {
      "id": "SS013",
      "strategy": "push_pull",
      "exerciseA": "pushups",
      "exerciseB": "pull_ups",
      "focus": "upper",
      "runnerScore": 78,
      "boneScore": 62,
      "note": "Upper body balance — humerus traction/compression"
    },
    {
      "id": "SS014",
      "strategy": "strength_core",
      "exerciseA": "curtsy_lunge",
      "exerciseB": "bird_dog",
      "focus": "mixed",
      "runnerScore": 86,
      "boneScore": 43,
      "note": "Multi-plane hip + contralateral stability"
    },
    {
      "id": "SS015",
      "strategy": "antagonist",
      "exerciseA": "glute_bridge",
      "exerciseB": "v_ups",
      "focus": "core",
      "runnerScore": 84,
      "boneScore": 30,
      "note": "Posterior/anterior trunk balance"
    },
    {
      "id": "SS016",
      "strategy": "compound_isolation",
      "exerciseA": "sumo_squat",
      "exerciseB": "russian_twist",
      "focus": "mixed",
      "runnerScore": 80,
      "boneScore": 47,
      "note": "Adductor strength + rotational core"
    },
    {
      "id": "SS017",
      "strategy": "upper_lower",
      "exerciseA": "lateral_lunge",
      "exerciseB": "superman",
      "focus": "mixed",
      "runnerScore": 83,
      "boneScore": 46,
      "note": "Lateral movement + back endurance"
    },
    {
      "id": "SS018",
      "strategy": "strength_core",
      "exerciseA": "box_jumps",
      "exerciseB": "front_plank",
      "focus": "mixed",
      "runnerScore": 87,
      "boneScore": 58,
      "note": "Explosive power + core — HIGH IMPACT BONE LOADING"
    },
    {
      "id": "SS019",
      "strategy": "antagonist",
      "exerciseA": "reverse_lunge",
      "exerciseB": "calf_raises",
      "focus": "lower",
      "runnerScore": 90,
      "boneScore": 70,
      "note": "Deceleration + push-off — tibia + calcaneus loading"
    },
    {
      "id": "SS020",
      "strategy": "compound_isolation",
      "exerciseA": "hip_thrust",
      "exerciseB": "hamstring_curl",
      "focus": "lower",
      "runnerScore": 91,
      "boneScore": 60,
      "note": "Glute max + hamstring endurance — femoral head loading"
    }
  ]
}
```

### 2.3 Workout Generation Algorithm

```
FUNCTION generateWeeklyPlan(userProfile, weekNumber, previousWeeks):

  1. DETERMINE PHASE
     - week % 4 == 0 → DELOAD
     - else → BUILD (intensity = week % 4 level)

  2. DETERMINE FREQUENCIES
     - strengthDays = user.strengthFrequency (3–5)
     - runDays = user.runFrequency (2–3)
     - totalDays = min(strengthDays + runDays, 6) // at least 1 rest

  3. SCHEDULE DISTRIBUTION
     - Place hardest run (tempo/interval) on Tue or Thu
     - Place strength sessions on Mon/Wed/Fri (+ Sat if 4–5x)
     - Place easy run on non-strength days or stacked with strength
     - Ensure no 3+ consecutive training days without rest

  4. FOR EACH STRENGTH SESSION:
     a. Assign session FOCUS based on rotation:
        - Session 1: Lower-body dominant
        - Session 2: Upper-body + core dominant
        - Session 3: Full-body power
        - Session 4+: Supplementary (unilateral focus)

     b. Select 3–4 superset pairs:
        - Filter supersetPairs by focus compatibility
        - Remove pairs used in last 2 weeks (recentHistory)
        - Score remaining: (runnerScore × 0.6 + boneDensityScore × 0.4) × (1 + recencyBonus)
        - Select top 3–4, ensuring muscle group coverage:
          • Lower: at least 2 quad + 2 hamstring/glute exercises
          • Upper: at least 1 push + 1 pull
          • Core: at least 1 anti-rotation or stability exercise

     c. ENFORCE BONE DENSITY MINIMUM (critical constraint):
        - Each session MUST include at least 1 exercise with boneDensityScore ≥ 75
        - Each week MUST include:
          • ≥ 1 heavy axial loading exercise (squat/deadlift variant, score ≥ 90)
          • ≥ 1 plyometric/impact exercise (jump squat/box jump/jump lunge, score ≥ 85)
          • ≥ 2 unilateral loaded stance exercises (split squat/lunge/step-up, score ≥ 70)
        - If selected pairs don't meet bone minimums, swap lowest-scored pair
          for highest available bone-density pair that satisfies the gap
        - DELOAD WEEKS: reduce load (lighter weight, fewer sets) but KEEP
          impact exercises — bone adaptation requires consistent stimulus;
          reducing frequency more than 2 weeks causes bone loss reversal

     d. Assign sets/reps based on phase:
        - BUILD week 1: 3×12 @ moderate weight
        - BUILD week 2: 3×10 @ moderate-heavy
        - BUILD week 3: 4×8 @ heavy (peak bone stimulus — heaviest loads)
        - DELOAD: 2×12 @ light (maintain impact exercises, reduce volume not variety)

        BONE DENSITY REP OVERRIDES (applied per-exercise on top of phase):
        - Heavy axial exercises (squat, deadlift): cap at 8 reps max in
          build weeks 2–3 → heavier load = greater bone strain signal
        - Plyometric exercises (jumps): always 3×5–8 reps with full recovery
          (60–90s rest) → max force production per rep matters more than volume
        - Research basis: bone responds to PEAK strain magnitude, not cumulative
          volume; fewer reps at higher intensity is more osteogenic than many
          reps at low intensity (Frost's Mechanostat Theory: strain must exceed
          ~1500–3000 microstrain to trigger modeling/formation response)

  5. FOR EACH RUNNING SESSION:
     a. Select type from weekly running template
     b. Calculate paces from user's current 10K time/goal:
        - Easy pace: 10K pace + 60–90 sec/km
        - Tempo pace: 10K pace + 10–20 sec/km
        - Interval pace: 10K pace - 10–20 sec/km
     c. Structure workout with warm-up, main set, cool-down
     d. Format for Garmin Training API compatibility

  6. VALIDATE WEEKLY LOAD
     - Sum muscle group volume (sets × intensity)
     - Flag if any group > 150% of target weekly volume
     - Flag if any group < 50% of target weekly volume
     - Auto-adjust by swapping superset pairs if imbalanced

  6b. VALIDATE BONE DENSITY STIMULUS
     - Calculate weekly bone load score:
       boneScore = SUM(exercise.boneDensityScore × sets × intensityMultiplier)
                   for all exercises in week
     - MINIMUM weekly bone score threshold: 800 (empirically tuned)
     - If below threshold: swap lowest bone-score superset pair for
       highest-scoring available pair from the pool
     - Count high-impact exercises (score ≥ 85): must be ≥ 2 per week
     - Count heavy compound exercises (score ≥ 90): must be ≥ 1 per week
     - Running workouts contribute approximately:
       boneRunBonus = distance_km × 15 (impact loading from foot strikes)
     - Log weekly bone stimulus score to enable long-term tracking

  7. RETURN weeklyPlan
```

### 2.4 Calendar System

#### 2.4.1 Calendar Views

| View | Description |
|------|-------------|
| Month View | Grid showing workout type icons per day, color-coded by completion status |
| Week View | Expanded cards per day showing workout summary, estimated duration |
| Day View | Full workout detail with exercise list, sets/reps, notes |

#### 2.4.2 Workout States

```
PLANNED    → Gray outline, future date, shows workout preview
TODAY      → Highlighted border (pulse animation), "Start Workout" CTA
COMPLETED  → Solid green fill, shows actual stats from Garmin or manual log
SKIPPED    → Strikethrough, muted color
MODIFIED   → Orange indicator (user changed exercises)
```

#### 2.4.3 Calendar Data Model

```typescript
interface CalendarEntry {
  id: string;
  date: string;                    // ISO date
  workoutId: string;               // ref to generated workout
  status: "planned" | "completed" | "skipped" | "modified";
  scheduledType: "strength" | "run_easy" | "run_tempo" | "run_interval" | "run_long" | "rest";
  estimatedDuration: number;       // minutes
  actualDuration?: number;         // from Garmin or manual
  garminActivityId?: string;       // linked Garmin activity
  completedAt?: string;            // ISO datetime
  userNotes?: string;
  muscleImpact?: MuscleImpactMap;  // computed post-workout
}
```

### 2.5 Muscle Impact Visualization

After completing a workout, the app displays an anatomical body map showing which muscles were targeted and their estimated load intensity.

#### 2.5.1 Impact Calculation

**Muscle Load:**

```
FOR EACH exercise in completedWorkout:
  FOR EACH muscle in exercise.primaryMuscles:
    muscleLoad[muscle] += sets × reps × intensityMultiplier × 1.0
  FOR EACH muscle in exercise.secondaryMuscles:
    muscleLoad[muscle] += sets × reps × intensityMultiplier × 0.4

intensityMultiplier:
  - Compound exercises: 1.2
  - Isolation exercises: 1.0
  - Plyometric exercises: 1.4
  - Isometric exercises: 0.8

FOR EACH muscle in running workout (if run was done):
  calves += distance_km × 8
  quads += distance_km × 6
  hamstrings += distance_km × 5
  glutes += distance_km × 5
  hipFlexors += distance_km × 4
  core += distance_km × 3
```

**Bone Density Stimulus Score (per workout):**

```
boneStimulus = 0

FOR EACH exercise in completedWorkout:
  IF exercise.boneDensityScore >= 85:
    // High-impact: score heavily, emphasize low reps at high load
    boneStimulus += exercise.boneDensityScore × sets × min(reps, 8) × 0.15
  ELIF exercise.boneDensityScore >= 50:
    // Moderate impact: standard contribution
    boneStimulus += exercise.boneDensityScore × sets × reps × 0.08
  ELSE:
    // Low impact: minimal contribution
    boneStimulus += exercise.boneDensityScore × sets × reps × 0.03

IF workoutType is RUNNING:
  // Impact forces from foot strikes (~1500 strikes/km, each 2-3× BW)
  boneStimulus += distance_km × 15

boneLevel:
  0–20:   "Minimal bone stimulus"     (light isolation/stability day)
  21–50:  "Moderate bone stimulus"    (mixed workout)
  51–80:  "Strong bone stimulus"      (includes heavy compounds)
  81+:    "Peak bone stimulus"        (heavy loading + plyometrics)
```

This score is displayed on the post-workout muscle impact screen alongside the muscle heat map, and tracked over time in the progress charts.

#### 2.5.2 Heat Map Intensity Levels

| Level | Color | Threshold | Label |
|-------|-------|-----------|-------|
| 0 | `#E8E8E8` (gray) | 0 | Not targeted |
| 1 | `#FEF3C7` (light yellow) | 1–20% | Lightly activated |
| 2 | `#FDE68A` (yellow) | 21–40% | Warm-up level |
| 3 | `#F59E0B` (amber) | 41–60% | Moderate load |
| 4 | `#EA580C` (orange) | 61–80% | Heavy load |
| 5 | `#DC2626` (red) | 81–100% | Peak load |

#### 2.5.3 SVG Body Map Structure

Two views: **anterior** (front) and **posterior** (back), each with selectable muscle regions. Each region is an SVG `<path>` with `id` matching `svgId` from the muscle taxonomy. Colors applied dynamically via `fill` attribute.

Interaction: Tapping a muscle region shows a tooltip with the exercise(s) that targeted it, set/rep count, and estimated recovery time.

### 2.6 Garmin Integration

#### 2.6.1 API Architecture

Garmin Connect Developer Program provides server-to-server APIs. Our backend mediates all communication.

```
┌──────────┐    OAuth 1.0a    ┌──────────────┐   REST API   ┌─────────────────┐
│ RunForge  │ ───────────────→│  RunForge     │ ────────────→│ Garmin Connect  │
│ Frontend  │                 │  Backend      │              │ Developer API   │
└──────────┘                  └──────────────┘              └─────────────────┘
                                     │                             │
                                     │   Webhook (PUSH)            │
                                     │←────────────────────────────│
                                     │   (Activity data when       │
                                     │    user syncs device)       │
```

#### 2.6.2 Integration Points

| Direction | API | Purpose |
|-----------|-----|---------|
| **PUSH** (to Garmin) | Training API | Send structured running workouts to Garmin Connect calendar → auto-syncs to Forerunner |
| **PULL** (from Garmin) | Activity API | Receive completed activity data (pace, HR, distance, duration) via webhook |
| **PULL** (from Garmin) | Health API | Daily summaries: resting HR, sleep quality, stress, steps |

#### 2.6.3 Workout Push Format (Training API)

Running workouts are structured as Garmin workout steps:

```json
{
  "workoutName": "Tempo Run - Week 3",
  "sport": "RUNNING",
  "steps": [
    {
      "type": "WorkoutStep",
      "stepOrder": 1,
      "intensity": "WARMUP",
      "durationType": "TIME",
      "durationValue": 600000,
      "description": "Easy jog warm-up"
    },
    {
      "type": "WorkoutStep",
      "stepOrder": 2,
      "intensity": "ACTIVE",
      "durationType": "TIME",
      "durationValue": 1200000,
      "targetType": "PACE",
      "targetValueLow": 300,
      "targetValueHigh": 315,
      "description": "Tempo pace 5:00-5:15/km"
    },
    {
      "type": "WorkoutStep",
      "stepOrder": 3,
      "intensity": "COOLDOWN",
      "durationType": "TIME",
      "durationValue": 600000,
      "description": "Easy jog cool-down"
    }
  ]
}
```

#### 2.6.4 Activity Data Webhook (Activity API)

When the user syncs their Forerunner after a run, Garmin POSTs activity data to our webhook:

```json
{
  "activities": [{
    "userId": "garmin_user_id",
    "activityId": 12345678,
    "activityType": "RUNNING",
    "startTimeInSeconds": 1709000000,
    "durationInSeconds": 2820,
    "distanceInMeters": 8200,
    "averagePaceInMinutesPerKilometer": 5.15,
    "averageHeartRateInBeatsPerMinute": 158,
    "maxHeartRateInBeatsPerMinute": 175,
    "activeKilocalories": 520,
    "laps": [...]
  }]
}
```

#### 2.6.5 OAuth Flow

1. User clicks "Connect Garmin" in settings
2. Backend initiates OAuth 1.0a → redirects to Garmin consent page
3. User authorizes → callback with access token
4. Backend stores encrypted token, subscribes to activity webhooks
5. Frontend shows connected status with last sync timestamp

#### 2.6.6 Forerunner Compatibility

Strength workouts are NOT pushed to Garmin (Forerunner doesn't support superset display well). Instead, strength workouts are displayed in-app only. Running workouts ARE pushed as structured workouts that the Forerunner can guide the user through (pace targets, intervals, etc.).

---

## 3. System Architecture

### 3.1 Technology Stack

| Layer | Technology | Justification |
|-------|-----------|---------------|
| Frontend | React 18 + TypeScript | Component model fits calendar/workout UIs |
| Styling | Tailwind CSS | Rapid prototyping, consistent design tokens |
| State | Zustand | Lightweight, no boilerplate |
| Calendar | Custom (react-day-picker base) | Full control over workout rendering |
| Body Map | Custom SVG + React | Interactive muscle visualization |
| Charts | Recharts | Training load progression graphs |
| Backend | Node.js + Express | JS ecosystem, Garmin SDK compatibility |
| Database | PostgreSQL | Relational data (users, plans, history) |
| Cache | Redis | Session store, rate limiting, workout cache |
| Auth | JWT + OAuth 1.0a (Garmin) | Standard web auth + Garmin flow |
| Hosting | Vercel (frontend) + Railway (backend) | Cost-effective, auto-scaling |

### 3.2 High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (React SPA)                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │Dashboard │ │ Calendar │ │ Workout  │ │ Muscle Impact    │   │
│  │  Page    │ │  Views   │ │ Player   │ │ Visualization    │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │ Settings │ │ Profile  │ │ Progress │ │ Garmin Sync      │   │
│  │  Page    │ │  Setup   │ │ Charts   │ │ Status Widget    │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │ REST API (HTTPS)
┌──────────────────────────┴──────────────────────────────────────┐
│                      BACKEND (Node.js/Express)                  │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────────┐  │
│  │ Auth Service  │  │ Workout       │  │ Garmin Integration  │  │
│  │ (JWT + OAuth) │  │ Generator     │  │ Service             │  │
│  └──────────────┘  │ Engine        │  │ - Training API      │  │
│  ┌──────────────┐  │               │  │ - Activity Webhook  │  │
│  │ Calendar      │  │ - Superset    │  │ - Health API        │  │
│  │ Service       │  │   Selector    │  └─────────────────────┘  │
│  └──────────────┘  │ - Periodizer  │  ┌─────────────────────┐  │
│  ┌──────────────┐  │ - Validator   │  │ Muscle Impact       │  │
│  │ Progress      │  └───────────────┘  │ Calculator          │  │
│  │ Tracker       │                     └─────────────────────┘  │
│  └──────────────┘                                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────┴──────┐  ┌────────┴───────┐  ┌───────┴──────┐
│  PostgreSQL  │  │     Redis      │  │    Garmin    │
│  - Users     │  │  - Sessions    │  │   Connect    │
│  - Workouts  │  │  - Cache       │  │   API        │
│  - History   │  │  - Rate Limit  │  │              │
│  - Exercises │  │                │  │              │
└──────────────┘  └────────────────┘  └──────────────┘
```

### 3.3 Database Schema

```sql
-- Users
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name          VARCHAR(100),
  created_at    TIMESTAMPTZ DEFAULT NOW(),

  -- Profile
  age           INT,
  weight_kg     DECIMAL(5,1),
  height_cm     INT,
  current_10k_time_sec INT,       -- current 10K time in seconds
  goal_10k_time_sec    INT,       -- target 10K time

  -- Preferences
  strength_frequency   INT DEFAULT 3 CHECK (strength_frequency BETWEEN 3 AND 5),
  run_frequency        INT DEFAULT 2 CHECK (run_frequency BETWEEN 2 AND 3),
  available_equipment  TEXT[],     -- ['dumbbell','barbell','band','bodyweight','machine']
  preferred_run_days   TEXT[],     -- ['tuesday','saturday']

  -- Garmin
  garmin_user_id       VARCHAR(100),
  garmin_access_token  TEXT,       -- encrypted
  garmin_token_secret  TEXT,       -- encrypted
  garmin_connected_at  TIMESTAMPTZ,
  garmin_last_sync     TIMESTAMPTZ
);

-- Exercises (reference data)
CREATE TABLE exercises (
  id               VARCHAR(50) PRIMARY KEY,
  name             VARCHAR(100) NOT NULL,
  primary_muscles  TEXT[] NOT NULL,
  secondary_muscles TEXT[],
  equipment        VARCHAR(50) NOT NULL,
  movement_type    VARCHAR(50) NOT NULL,    -- compound, isolation, plyometric, isometric
  difficulty       INT CHECK (difficulty BETWEEN 1 AND 5),
  is_unilateral    BOOLEAN DEFAULT FALSE,
  instructions     TEXT,
  -- Image fields
  image_source_id  VARCHAR(200),            -- free-exercise-db folder name (e.g. "Barbell_Deadlift")
  image_cdn_base   VARCHAR(500),            -- CDN base URL (e.g. "https://cdn.runforge.app/exercises/deadlift")
  has_animation    BOOLEAN DEFAULT FALSE,   -- true if animated GIF available
  image_attribution VARCHAR(200) DEFAULT 'Public Domain via free-exercise-db',
  -- Bone density
  bone_density_score INT CHECK (bone_density_score BETWEEN 0 AND 100)  -- osteogenic potential score
);

-- Superset Pairs (reference data)
CREATE TABLE superset_pairs (
  id             VARCHAR(10) PRIMARY KEY,
  strategy       VARCHAR(30) NOT NULL,      -- antagonist, upper_lower, push_pull, etc.
  exercise_a_id  VARCHAR(50) REFERENCES exercises(id),
  exercise_b_id  VARCHAR(50) REFERENCES exercises(id),
  focus          VARCHAR(20) NOT NULL,      -- lower, upper, full_body, core, mixed
  runner_score   INT CHECK (runner_score BETWEEN 0 AND 100),
  bone_score     INT CHECK (bone_score BETWEEN 0 AND 100),  -- combined osteogenic potential
  note           TEXT
);

-- Weekly Plans
CREATE TABLE weekly_plans (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  week_number   INT NOT NULL,
  year          INT NOT NULL,
  phase         VARCHAR(20) NOT NULL,       -- build_1, build_2, build_3, deload
  mesocycle     INT NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_number, year)
);

-- Individual Workouts
CREATE TABLE workouts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  weekly_plan_id    UUID REFERENCES weekly_plans(id) ON DELETE CASCADE,
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
  scheduled_date    DATE NOT NULL,
  workout_type      VARCHAR(30) NOT NULL,   -- strength_lower, strength_upper, strength_full,
                                            -- run_easy, run_tempo, run_interval, run_long, rest
  status            VARCHAR(20) DEFAULT 'planned',
  estimated_duration_min INT,
  actual_duration_min    INT,
  garmin_activity_id     VARCHAR(100),
  completed_at           TIMESTAMPTZ,
  user_notes             TEXT,
  created_at             TIMESTAMPTZ DEFAULT NOW()
);

-- Workout Superset Blocks (for strength workouts)
CREATE TABLE workout_supersets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_id      UUID REFERENCES workouts(id) ON DELETE CASCADE,
  block_order     INT NOT NULL,
  superset_pair_id VARCHAR(10) REFERENCES superset_pairs(id),
  sets            INT NOT NULL,
  reps_a          INT NOT NULL,
  reps_b          INT NOT NULL,
  rest_between_sec INT DEFAULT 60,
  rest_after_sec   INT DEFAULT 90,
  notes           TEXT
);

-- Running Workout Details
CREATE TABLE running_workout_details (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_id      UUID REFERENCES workouts(id) ON DELETE CASCADE,
  warmup_duration_sec   INT,
  warmup_pace_sec_km    INT,
  main_set_type         VARCHAR(30),      -- steady, tempo, intervals
  main_set_duration_sec INT,
  main_set_pace_low     INT,              -- seconds per km
  main_set_pace_high    INT,
  interval_count        INT,
  interval_duration_sec INT,
  recovery_duration_sec INT,
  cooldown_duration_sec INT,
  total_distance_km     DECIMAL(4,1),
  garmin_workout_id     VARCHAR(100),     -- Garmin Training API workout ID
  pushed_to_garmin      BOOLEAN DEFAULT FALSE
);

-- Completed Workout Muscle Impact
CREATE TABLE muscle_impact_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_id      UUID REFERENCES workouts(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  muscle_group    VARCHAR(30) NOT NULL,
  load_score      DECIMAL(6,1) NOT NULL,
  intensity_level INT CHECK (intensity_level BETWEEN 0 AND 5),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Bone Density Stimulus Tracking (per workout + weekly aggregation)
CREATE TABLE bone_stimulus_logs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_id        UUID REFERENCES workouts(id) ON DELETE CASCADE,
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
  stimulus_score    DECIMAL(6,1) NOT NULL,      -- calculated bone stimulus score
  stimulus_level    VARCHAR(20) NOT NULL,        -- minimal, moderate, strong, peak
  heavy_compound_count INT DEFAULT 0,            -- exercises with bone_score >= 90
  plyometric_count     INT DEFAULT 0,            -- exercises with plyometric movement type
  impact_exercise_count INT DEFAULT 0,           -- exercises with bone_score >= 70
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- Weekly Bone Stimulus Summary (materialized for progress charts)
CREATE TABLE weekly_bone_summary (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
  week_number       INT NOT NULL,
  year              INT NOT NULL,
  total_bone_score  DECIMAL(8,1) NOT NULL,       -- sum of all workout bone scores that week
  workout_count     INT NOT NULL,                -- how many workouts contributed
  avg_bone_score    DECIMAL(6,1) NOT NULL,       -- average per workout
  meets_minimum     BOOLEAN NOT NULL,            -- did week meet 800 threshold?
  heavy_sessions    INT DEFAULT 0,               -- sessions with heavy axial loading
  impact_sessions   INT DEFAULT 0,               -- sessions with plyometric exercises
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_number, year)
);

-- Garmin Activity Cache
CREATE TABLE garmin_activities (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES users(id) ON DELETE CASCADE,
  garmin_activity_id    VARCHAR(100) UNIQUE NOT NULL,
  activity_type         VARCHAR(50),
  start_time            TIMESTAMPTZ,
  duration_sec          INT,
  distance_meters       INT,
  avg_pace_sec_km       DECIMAL(5,1),
  avg_hr                INT,
  max_hr                INT,
  calories              INT,
  raw_data              JSONB,            -- full Garmin payload
  received_at           TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_workouts_user_date ON workouts(user_id, scheduled_date);
CREATE INDEX idx_workouts_status ON workouts(status);
CREATE INDEX idx_weekly_plans_user ON weekly_plans(user_id, year, week_number);
CREATE INDEX idx_muscle_impact_user ON muscle_impact_logs(user_id, created_at);
CREATE INDEX idx_bone_stimulus_user ON bone_stimulus_logs(user_id, created_at);
CREATE INDEX idx_weekly_bone_user ON weekly_bone_summary(user_id, year, week_number);
CREATE INDEX idx_garmin_activities_user ON garmin_activities(user_id, start_time);
```

### 3.4 API Endpoints

#### Auth
```
POST   /api/auth/register          Register new user
POST   /api/auth/login             Login → JWT
POST   /api/auth/refresh           Refresh token
GET    /api/auth/garmin             Initiate Garmin OAuth
GET    /api/auth/garmin/callback    Garmin OAuth callback
DELETE /api/auth/garmin             Disconnect Garmin
```

#### User Profile
```
GET    /api/profile                 Get user profile + preferences
PUT    /api/profile                 Update profile
PUT    /api/profile/goals           Update 10K goal time
PUT    /api/profile/preferences     Update training preferences
```

#### Workout Generation
```
POST   /api/plans/generate          Generate next week's plan
GET    /api/plans/current           Get current week plan
GET    /api/plans/:weekNumber/:year Get specific week plan
```

#### Calendar
```
GET    /api/calendar?from=&to=      Get calendar entries for date range
GET    /api/calendar/:date          Get specific date's workout
PUT    /api/calendar/:workoutId     Update workout (skip, modify, add notes)
POST   /api/calendar/:workoutId/complete   Mark workout complete (manual)
```

#### Workouts
```
GET    /api/workouts/:id            Full workout detail
GET    /api/workouts/:id/impact     Muscle impact for completed workout
```

#### Progress
```
GET    /api/progress/running        Running pace progression over time
GET    /api/progress/volume         Weekly training volume chart data
GET    /api/progress/muscles?weeks= Muscle group heatmap over N weeks
GET    /api/progress/bone?weeks=    Bone density stimulus trend over N weeks
```

#### Garmin Webhook
```
POST   /api/webhooks/garmin/activity    Receive activity data
POST   /api/webhooks/garmin/health      Receive daily health summaries
```

---

## 4. Frontend Component Architecture

### 4.1 Page Hierarchy

```
App
├── AuthPages/
│   ├── LoginPage
│   ├── RegisterPage
│   └── OnboardingWizard          # 10K time, goals, equipment, schedule
│
├── MainLayout (authenticated)
│   ├── Sidebar / Bottom Nav
│   │
│   ├── DashboardPage
│   │   ├── TodayWorkoutCard      # Today's workout preview + Start CTA
│   │   ├── WeekOverviewStrip     # 7-day mini calendar
│   │   ├── GarminSyncStatus      # Last sync, connected device
│   │   └── ProgressSnapshot      # 10K pace trend mini chart
│   │
│   ├── CalendarPage
│   │   ├── CalendarHeader        # Month/Week/Day toggle + navigation
│   │   ├── MonthView             # Grid with workout type icons
│   │   ├── WeekView              # Expanded daily cards
│   │   └── DayView               # Full workout detail
│   │       ├── StrengthWorkoutView
│   │       │   ├── SupersetBlock (×3–4)
│   │       │   │   ├── ExerciseCard (A)
│   │       │   │   └── ExerciseCard (B)
│   │       │   └── WorkoutTimer
│   │       └── RunningWorkoutView
│   │           ├── RunStructureDiagram
│   │           └── PaceTargetDisplay
│   │
│   ├── WorkoutPlayerPage         # Active workout tracking
│   │   ├── CurrentExerciseDisplay
│   │   ├── SetCounter
│   │   ├── RestTimer
│   │   └── SupersetProgressBar
│   │
│   ├── MuscleImpactPage
│   │   ├── BodyMapSVG (anterior + posterior toggle)
│   │   ├── MuscleDetailTooltip
│   │   ├── BoneStimulusGauge          # Circular gauge: today's bone density score
│   │   ├── BoneStimulusWeeklyBar      # Weekly bar showing bone score trend
│   │   ├── WeeklyLoadSummary
│   │   └── RecoveryEstimate
│   │
│   ├── ProgressPage
│   │   ├── PaceTrendChart        # 10K pace over time
│   │   ├── VolumeChart           # Weekly sets/distance
│   │   ├── BoneStimulusChart     # Weekly bone density score trend over months
│   │   ├── MuscleBalanceRadar    # Radar chart of muscle group volume
│   │   └── ConsistencyHeatmap    # GitHub-style activity map
│   │
│   └── SettingsPage
│       ├── ProfileForm
│       ├── TrainingPreferences
│       ├── GarminConnectionPanel
│       └── NotificationSettings
```

### 4.2 Key Component Specifications

#### 4.2.1 BodyMapSVG Component

```typescript
interface BodyMapProps {
  muscleData: Record<string, {
    loadScore: number;
    intensityLevel: 0 | 1 | 2 | 3 | 4 | 5;
    exercises: string[];
    sets: number;
  }>;
  view: "anterior" | "posterior";
  onMuscleClick: (muscleId: string) => void;
  interactive: boolean;
}
```

The SVG contains ~18 path regions per view. Each path's `fill` is dynamically set based on `intensityLevel` using the color scale from §2.5.2. On hover/tap, a floating tooltip shows muscle name, exercises that targeted it, and recovery status.

**SVG Structure (simplified):**
```svg
<svg viewBox="0 0 400 800" id="body-anterior">
  <g id="body-outline"><!-- body silhouette --></g>
  <path id="quads-left" d="..." class="muscle-region" />
  <path id="quads-right" d="..." class="muscle-region" />
  <path id="core" d="..." class="muscle-region" />
  <path id="chest" d="..." class="muscle-region" />
  <path id="shoulders-left" d="..." class="muscle-region" />
  <path id="shoulders-right" d="..." class="muscle-region" />
  <!-- ... all anterior muscle groups -->
</svg>
```

#### 4.2.2 CalendarMonthView Component

```typescript
interface CalendarMonthProps {
  year: number;
  month: number;   // 0-indexed
  entries: CalendarEntry[];
  onDateClick: (date: string) => void;
  onWorkoutAction: (workoutId: string, action: WorkoutAction) => void;
}
```

Each day cell renders:
- Workout type icon (dumbbell for strength, shoe for running, couch for rest)
- Status indicator (color dot: green=done, gray=planned, red=skipped)
- If completed: tiny duration label ("32m")
- Today's cell: highlighted border with pulse animation

#### 4.2.3 SupersetBlock Component

```typescript
interface SupersetBlockProps {
  blockNumber: number;
  exerciseA: Exercise;
  exerciseB: Exercise;
  sets: number;
  repsA: number;
  repsB: number;
  restBetween: number;  // seconds
  restAfter: number;
  strategy: SupersetStrategy;
  isActive: boolean;    // in workout player mode
  completedSets: number;
}
```

Renders as two exercise cards side-by-side (desktop) or stacked (mobile) with a "lightning bolt" connector icon indicating they're a superset pair. Shows the superset strategy label (e.g., "Antagonist Pair" or "Upper/Lower").

---

## 5. UI/UX Design Direction

### 5.1 Aesthetic

**Design Language:** "Athletic Precision" — clean, data-rich, with purposeful pops of kinetic energy. Think Strava meets a personal training whiteboard.

**Color Palette:**
```
--bg-primary:     #0F1117    (deep charcoal)
--bg-card:        #1A1D27    (elevated surface)
--bg-elevated:    #242836    (modal/dropdown)
--text-primary:   #F0F0F5    (off-white)
--text-secondary: #8B8FA3    (muted)
--accent-run:     #22D3EE    (cyan — running workouts)
--accent-strength:#F97316    (orange — strength workouts)
--accent-success: #10B981    (green — completed)
--accent-rest:    #6366F1    (indigo — rest days)
--accent-warning: #FBBF24    (amber — deload/caution)
--accent-danger:  #EF4444    (red — skipped/overload)
```

**Typography:**
```
--font-display:  'DM Sans', sans-serif    (headings, numbers)
--font-body:     'IBM Plex Sans', sans-serif  (body text)
--font-mono:     'JetBrains Mono', monospace  (pace/time data)
```

### 5.2 Key Screen Wireframes (Description)

**Dashboard (Home):**
- Top: Greeting + today's date
- Hero card: Today's workout with type icon, duration estimate, and "Start Workout" button (glowing accent border)
- Below: 7-day strip calendar (scrollable horizontal) showing workout type icons
- Bottom section: Two cards side by side — Garmin sync status (last sync time, device icon) and 10K pace trend (sparkline chart)

**Calendar Month View:**
- Header with month/year + prev/next arrows + view toggle (Month/Week)
- 7-column grid, each cell shows: day number, workout icon, status dot
- Color coding: strength days have orange left-border, running days have cyan left-border
- Tapping a day opens a slide-up panel with workout details

**Workout Player (Strength):**
- Full-screen mode with dark background
- Current superset block displayed prominently with Exercise A and B
- Large set counter (e.g., "Set 2 of 3")
- Circular rest timer between exercises (animates down)
- Swipe/tap to advance to next set or block
- Bottom bar: overall progress (e.g., "Block 2/4 · Set 1/3")

**Muscle Impact (Post-Workout):**
- Full body SVG centered on screen
- Anterior/Posterior toggle at top
- Muscles colored by heat map scale
- Tapping a muscle shows floating card with: muscle name, exercises, total volume, estimated recovery (24h/48h/72h)
- **Bone Density Stimulus Gauge** (right side or below body): circular gauge showing today's bone stimulus score with level label (Minimal/Moderate/Strong/Peak) and color-coded ring (gray→yellow→orange→red). Below the gauge: "This week: X/800 target" progress bar showing weekly cumulative bone score
- Below body: weekly summary — bar chart of muscle group total volume
- If bone stimulus is below "Moderate" for the session: subtle coaching note — "Add a heavy squat or deadlift day this week for optimal bone health"

---

## 6. File Structure (Implementation Guide)

```
runforge/
├── client/                          # React frontend
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── main.tsx                 # Entry point
│   │   ├── App.tsx                  # Router + layout
│   │   │
│   │   ├── pages/
│   │   │   ├── DashboardPage.tsx
│   │   │   ├── CalendarPage.tsx
│   │   │   ├── WorkoutPlayerPage.tsx
│   │   │   ├── MuscleImpactPage.tsx
│   │   │   ├── ProgressPage.tsx
│   │   │   ├── SettingsPage.tsx
│   │   │   ├── LoginPage.tsx
│   │   │   ├── RegisterPage.tsx
│   │   │   └── OnboardingPage.tsx
│   │   │
│   │   ├── components/
│   │   │   ├── calendar/
│   │   │   │   ├── CalendarHeader.tsx
│   │   │   │   ├── MonthView.tsx
│   │   │   │   ├── WeekView.tsx
│   │   │   │   ├── DayCell.tsx
│   │   │   │   └── DayDetailPanel.tsx
│   │   │   │
│   │   │   ├── workout/
│   │   │   │   ├── SupersetBlock.tsx
│   │   │   │   ├── ExerciseCard.tsx
│   │   │   │   ├── WorkoutTimer.tsx
│   │   │   │   ├── SetCounter.tsx
│   │   │   │   ├── StrengthWorkoutView.tsx
│   │   │   │   └── RunningWorkoutView.tsx
│   │   │   │
│   │   │   ├── body-map/
│   │   │   │   ├── BodyMapSVG.tsx
│   │   │   │   ├── AnteriorPaths.tsx
│   │   │   │   ├── PosteriorPaths.tsx
│   │   │   │   ├── MuscleTooltip.tsx
│   │   │   │   └── HeatMapLegend.tsx
│   │   │   │
│   │   │   ├── charts/
│   │   │   │   ├── PaceTrendChart.tsx
│   │   │   │   ├── VolumeChart.tsx
│   │   │   │   ├── MuscleRadarChart.tsx
│   │   │   │   └── ConsistencyHeatmap.tsx
│   │   │   │
│   │   │   ├── garmin/
│   │   │   │   ├── GarminConnectButton.tsx
│   │   │   │   ├── GarminSyncStatus.tsx
│   │   │   │   └── GarminDeviceInfo.tsx
│   │   │   │
│   │   │   └── shared/
│   │   │       ├── Layout.tsx
│   │   │       ├── Sidebar.tsx
│   │   │       ├── BottomNav.tsx
│   │   │       ├── LoadingSpinner.tsx
│   │   │       └── Modal.tsx
│   │   │
│   │   ├── stores/
│   │   │   ├── authStore.ts
│   │   │   ├── workoutStore.ts
│   │   │   ├── calendarStore.ts
│   │   │   ├── garminStore.ts
│   │   │   └── progressStore.ts
│   │   │
│   │   ├── hooks/
│   │   │   ├── useWorkoutGenerator.ts
│   │   │   ├── useCalendar.ts
│   │   │   ├── useMuscleImpact.ts
│   │   │   ├── useGarminSync.ts
│   │   │   └── useTimer.ts
│   │   │
│   │   ├── services/
│   │   │   ├── api.ts               # Axios instance + interceptors
│   │   │   ├── authService.ts
│   │   │   ├── workoutService.ts
│   │   │   ├── calendarService.ts
│   │   │   ├── garminService.ts
│   │   │   └── progressService.ts
│   │   │
│   │   ├── data/
│   │   │   ├── exercises.ts          # Exercise catalog (static)
│   │   │   ├── exerciseImages.ts     # Image URL mapping per exercise
│   │   │   ├── supersetPairs.ts      # Superset pair pool (static)
│   │   │   ├── muscleGroups.ts       # Muscle taxonomy
│   │   │   └── colorScales.ts        # Heat map colors
│   │   │
│   │   ├── utils/
│   │   │   ├── workoutGenerator.ts   # Core generation algorithm
│   │   │   ├── muscleCalculator.ts   # Impact calculation
│   │   │   ├── paceUtils.ts          # Pace conversion helpers
│   │   │   ├── dateUtils.ts
│   │   │   └── formatters.ts
│   │   │
│   │   └── types/
│   │       ├── exercise.ts
│   │       ├── workout.ts
│   │       ├── calendar.ts
│   │       ├── garmin.ts
│   │       ├── muscle.ts
│   │       └── user.ts
│   │
│   ├── package.json
│   ├── tsconfig.json
│   ├── tailwind.config.js
│   └── vite.config.ts
│
├── server/                          # Node.js backend
│   ├── src/
│   │   ├── index.ts                 # Express app entry
│   │   ├── config/
│   │   │   ├── database.ts
│   │   │   ├── redis.ts
│   │   │   └── garmin.ts
│   │   │
│   │   ├── routes/
│   │   │   ├── auth.ts
│   │   │   ├── profile.ts
│   │   │   ├── plans.ts
│   │   │   ├── calendar.ts
│   │   │   ├── workouts.ts
│   │   │   ├── progress.ts
│   │   │   └── webhooks.ts
│   │   │
│   │   ├── services/
│   │   │   ├── authService.ts
│   │   │   ├── workoutGeneratorService.ts
│   │   │   ├── calendarService.ts
│   │   │   ├── garminService.ts
│   │   │   ├── muscleImpactService.ts
│   │   │   └── progressService.ts
│   │   │
│   │   ├── middleware/
│   │   │   ├── auth.ts
│   │   │   ├── validation.ts
│   │   │   └── rateLimiter.ts
│   │   │
│   │   ├── models/
│   │   │   ├── User.ts
│   │   │   ├── Workout.ts
│   │   │   ├── WeeklyPlan.ts
│   │   │   └── GarminActivity.ts
│   │   │
│   │   ├── seeds/
│   │   │   ├── run-seeds.ts          # Seed runner script
│   │   │   ├── exercises.seed.ts     # INSERT all exercises + images
│   │   │   └── superset-pairs.seed.ts # INSERT all superset pairs
│   │   │
│   │   ├── migrations/
│   │   │   ├── 001_initial_schema.sql
│   │   │   ├── 002_seed_exercises.sql
│   │   │   ├── 003_add_image_columns.sql
│   │   │   └── 004_add_garmin_indexes.sql
│   │   │
│   │   └── utils/
│   │       ├── garminAuth.ts        # OAuth 1.0a helpers
│   │       ├── garminWorkoutFormat.ts # Format workouts for Training API
│   │       └── encryption.ts        # Token encryption
│   │
│   ├── package.json
│   └── tsconfig.json
│
├── scripts/                         # Build & CI scripts
│   ├── build-exercise-images.ts     # Download from free-exercise-db → resize → upload to R2
│   ├── validate-image-mapping.ts    # Check all exercises have valid image mappings
│   └── generate-image-manifest.ts   # Create manifest of all CDN URLs for frontend
│
├── shared/                          # Shared types between client/server
│   └── types/
│       ├── api.ts
│       └── models.ts
│
└── docs/
    ├── DESIGN.md                    # This document
    ├── API.md                       # API documentation
    └── GARMIN_INTEGRATION.md        # Garmin setup guide
```

---

## 7. Implementation Priority & Phases

### Phase 1 — Core MVP (Weeks 1–3)
- User auth (register, login, JWT)
- Onboarding wizard (10K time, frequency, equipment)
- Exercise database + superset pair pool (static data)
- Workout generation engine (strength only)
- Basic calendar (month view, planned workouts)
- Workout detail view (view generated workout)

### Phase 2 — Running + Muscle Map (Weeks 4–5)
- Running workout generation (easy, tempo, intervals)
- Weekly schedule distribution algorithm
- Periodization (4-week mesocycles)
- Muscle impact calculator
- Body map SVG visualization (anterior + posterior)
- Calendar status updates (complete/skip)

### Phase 3 — Workout Player + Polish (Weeks 5–6)
- Active workout player (strength: set tracking, rest timer)
- Running workout view with pace targets
- Calendar week view
- Post-workout muscle impact display

### Phase 4 — Garmin Integration (Weeks 7–8)
- Garmin OAuth flow
- Training API: push running workouts to Garmin Connect
- Activity API: webhook to receive completed runs
- Auto-match Garmin activities to planned workouts
- Garmin sync status UI

### Phase 5 — Progress & Optimization (Weeks 9–10)
- Pace trend chart (from Garmin data + manual logs)
- Weekly volume chart
- Muscle balance radar chart
- Consistency heatmap
- Workout history with filtering
- Generation algorithm refinement based on completion data

---

## 8. Key Technical Decisions & Rationale

| Decision | Rationale |
|----------|-----------|
| PostgreSQL over Firebase/Firestore | Relational data (workout→supersets→exercises) maps poorly to document DBs; complex queries for progress tracking need SQL joins |
| Superset pairs as curated pool vs. pure algorithm | Curated pairs ensure exercise safety and biomechanical compatibility; algorithm selects from pool for variety |
| Workout generation server-side | Prevents manipulation, enables consistent periodization, and allows batch generation |
| SVG body map vs. image overlay | SVG enables interactive regions, dynamic coloring, accessibility, and scales perfectly on any screen |
| Garmin Training API for runs only | Forerunner devices display running workouts well but have no UI for superset guidance; pushing strength workouts would create poor UX on the watch |
| 4-week mesocycle periodization | Industry-standard model balancing progressive overload with recovery; simple enough for automated generation |
| Bone density scoring system | Per-exercise osteogenic scores (0–100) based on ground-reaction force and axial loading research; enables algorithm to guarantee minimum weekly bone stimulus without over-complicating workout selection |
| Plyometric rep cap at 8 | Research shows bone responds to peak strain magnitude, not volume; fewer heavy/explosive reps produce greater osteogenic stimulus than high-rep sets at lower intensity |
| OAuth 1.0a for Garmin (not 2.0) | Garmin Connect API requires OAuth 1.0a specifically; this is a Garmin requirement, not a choice |
| Redis for workout cache | Generated weekly plans can be cached to avoid regeneration; also handles rate limiting for Garmin webhook |

---

## 9. Database Hosting & Data Management

### 9.1 Recommended Hosting: Supabase (Primary) or Neon (Alternative)

Given that RunForge is a consumer-facing app with moderate traffic, the database needs managed hosting with minimal DevOps overhead. After evaluating options, here is the recommended stack:

**Primary Recommendation: Supabase**

| Attribute | Detail |
|-----------|--------|
| Why Supabase | Full BaaS — gives us PostgreSQL + built-in Auth (JWT/Row-Level Security) + auto-generated REST API + Realtime subscriptions + file storage (for exercise images if not using R2) |
| Postgres version | Standard vanilla PostgreSQL 15+ (no proprietary fork) |
| Free tier | 500 MB database, 1 GB file storage, 50K monthly active users |
| Paid tier | Pro at $25/month — 8 GB database, 100 GB storage, unlimited API requests |
| Auth integration | GoTrue-based JWT auth replaces our custom auth service, saving significant backend code |
| Realtime | Websocket subscriptions for live workout player sync (future feature) |
| Region | Choose `eu-central-1` (Frankfurt) for low latency from Israel (~30ms) |
| Connection pooling | Built-in PgBouncer (transaction mode), handles serverless connection patterns |
| Backups | Daily automated backups, point-in-time recovery on Pro plan |
| Dashboard | Web UI for running queries, viewing data, managing RLS policies |

**Alternative: Neon (if pure database needed without BaaS features)**

| Attribute | Detail |
|-----------|--------|
| Why Neon | Serverless Postgres with scale-to-zero — costs nothing when idle; great for early-stage when usage is low |
| Free tier | 512 MB storage, 100 pooled connections, auto-suspend after 5 min idle |
| Paid tier | Launch at $19/month — 10 GB storage, branching, 300 compute hours |
| Best for | If building custom auth anyway, or if the app is hosted on Vercel (native integration) |
| Branching | Instant copy-on-write database clones for testing and preview deployments |
| Cold starts | ~0.4–0.75s on first query after idle; acceptable for non-real-time fitness app |

**Decision Matrix:**

| Factor | Supabase | Neon | Winner |
|--------|----------|------|--------|
| Saves backend code (auth, API) | Yes — built-in auth + REST API | No — pure database | Supabase |
| Cost at low usage | $0/month (free tier) | $0/month (free tier) | Tie |
| Cost at moderate usage | $25/month (Pro) | $19/month (Launch) | Neon |
| Scale-to-zero (saves money when idle) | No (always-on) | Yes | Neon |
| Image/file storage included | Yes (S3-compatible) | No | Supabase |
| Latency from Israel | ~30ms (EU region) | ~40ms (EU region) | Supabase |
| Production maturity | Very mature, wide adoption | Mature (acquired by Databricks) | Tie |
| Garmin webhook handling | Works via Edge Functions | Needs separate backend | Supabase |

**Verdict:** Supabase is recommended because it eliminates the need for a separate auth service, provides file storage for exercise images, and offers Edge Functions that can handle Garmin webhooks — reducing overall infrastructure complexity.

### 9.2 Full Infrastructure Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         HOSTING OVERVIEW                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  FRONTEND                           BACKEND                            │
│  ┌─────────────────────┐           ┌──────────────────────────────┐    │
│  │  Vercel              │           │  Option A: Supabase BaaS     │    │
│  │  - React SPA         │  REST     │  - PostgreSQL database       │    │
│  │  - Static assets     │──────────→│  - GoTrue Auth (JWT + RLS)  │    │
│  │  - Edge caching      │           │  - PostgREST (auto REST API)│    │
│  │  - Free tier: 100GB  │           │  - Edge Functions (webhooks)│    │
│  │    bandwidth/month   │           │  - Realtime (websockets)    │    │
│  └─────────────────────┘           │  - Storage (exercise images)│    │
│                                     └──────────────┬───────────────┘    │
│  IMAGE CDN                                         │                    │
│  ┌─────────────────────┐                          │                    │
│  │  Cloudflare R2       │   ┌──────────────────────┘                    │
│  │  - Exercise images   │   │                                           │
│  │  - Free egress       │   │  Option B: Custom Backend                 │
│  │  - WebP optimized    │   │  ┌──────────────────────────────┐        │
│  │  - Global CDN        │   │  │  Railway / Render             │        │
│  └─────────────────────┘   │  │  - Node.js/Express API       │        │
│                              │  │  - Custom auth (JWT)         │        │
│  REDIS (if needed)           │  │  - Workout generator logic   │        │
│  ┌─────────────────────┐   │  │  - Garmin webhook endpoint   │        │
│  │  Upstash Redis       │   │  └──────────────┬───────────────┘        │
│  │  - Serverless Redis  │   │                  │                        │
│  │  - Rate limiting     │   │  ┌───────────────┘                        │
│  │  - Session cache     │   │  │  Database                              │
│  │  - Free: 10K cmds/day│   │  │  ┌──────────────────────────────┐     │
│  └─────────────────────┘   │  │  │  Supabase / Neon PostgreSQL   │     │
│                              │  │  │  - All application tables    │     │
│  EXTERNAL SERVICES           │  │  │  - Exercise reference data   │     │
│  ┌─────────────────────┐   │  │  │  - User workout history      │     │
│  │  Garmin Connect API  │←──┘  │  │  - Garmin activity cache     │     │
│  │  - Training API      │      │  └──────────────────────────────┘     │
│  │  - Activity API      │      │                                        │
│  │  - Health API        │      │                                        │
│  └─────────────────────┘      │                                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 9.3 Data Categories & Update Strategies

The database contains four distinct categories of data, each with its own lifecycle and update strategy:

#### Category 1: Static Reference Data (Exercises, Superset Pairs, Muscles)

This data changes rarely — only when we add new exercises or refine superset combinations.

**What it includes:**
- `exercises` table (37 rows — our exercise catalog)
- `superset_pairs` table (20+ rows — curated superset combinations)
- Muscle group taxonomy (embedded in code as constants)

**How it gets into the database:**

```
1. SEED SCRIPT (initial deployment):
   A Node.js/TypeScript seed script runs during first deployment.
   It reads static JSON files from the codebase and INSERTs all
   exercises and superset pairs.

   File: server/src/seeds/exercises.seed.ts
   Run:  npx tsx server/src/seeds/run-seeds.ts

2. MIGRATION (when adding/changing exercises):
   Standard SQL migration files. Each change is a numbered migration.

   File: server/src/migrations/003_add_box_jumps_exercise.sql
   Run:  npx supabase db push  (or custom migration runner)
```

**Seed script example:**

```typescript
// server/src/seeds/exercises.seed.ts
import { exercises } from '../data/exercises.json';
import { supersetPairs } from '../data/superset-pairs.json';

async function seedExercises(db: PoolClient) {
  for (const exercise of exercises) {
    await db.query(`
      INSERT INTO exercises (id, name, primary_muscles, secondary_muscles,
        equipment, movement_type, difficulty, is_unilateral, instructions,
        image_source_id, image_cdn_base, has_animation, image_attribution)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        primary_muscles = EXCLUDED.primary_muscles,
        image_cdn_base = EXCLUDED.image_cdn_base
    `, [
      exercise.id,
      exercise.name,
      exercise.primaryMuscles,
      exercise.secondaryMuscles,
      exercise.equipment,
      exercise.movementType,
      exercise.difficulty,
      exercise.isUnilateral,
      exercise.instructions,
      exercise.images.sourceId,
      `https://cdn.runforge.app/exercises/${exercise.id}`,
      exercise.images.hasAnimation,
      exercise.images.attribution
    ]);
  }

  for (const pair of supersetPairs) {
    await db.query(`
      INSERT INTO superset_pairs (id, strategy, exercise_a_id, exercise_b_id,
        focus, runner_score, note)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (id) DO UPDATE SET
        runner_score = EXCLUDED.runner_score,
        note = EXCLUDED.note
    `, [pair.id, pair.strategy, pair.exerciseA, pair.exerciseB,
        pair.focus, pair.runnerScore, pair.note]);
  }
}
```

**Update frequency:** Quarterly or when expanding the exercise library.

#### Category 2: User-Generated Data (Profiles, Preferences)

Created when users register and updated through profile settings.

**How it gets created:**

```
User registers → POST /api/auth/register
  → Creates row in `users` table with defaults
  → Onboarding wizard → PUT /api/profile fills in:
      age, weight, height, current_10k_time, goal_10k_time,
      strength_frequency, run_frequency, available_equipment
```

**How it gets updated:**

```
User changes settings → PUT /api/profile
  → Updates user row
  → If training preferences changed:
      → Triggers regeneration of next week's plan
      → Invalidates cached weekly plan in Redis
```

**Data flow diagram:**

```
[User action in UI]
     │
     ▼
[React component] ──→ authStore / workoutStore (Zustand)
     │
     ▼
[Service layer] ──→ POST/PUT to Supabase REST API (or Express API)
     │
     ▼
[Supabase PostgreSQL] ──→ Row-Level Security ensures user
                            can only read/write their own data
```

#### Category 3: Generated Data (Weekly Plans, Workouts, Superset Assignments)

The workout generation engine creates this data automatically.

**When generation happens:**

```
TRIGGER 1: User completes onboarding
  → Generate first 2 weeks of plans immediately
  → Push running workouts to Garmin (if connected)

TRIGGER 2: Weekly cron job (Sunday night)
  → For each active user: generate next week's plan
  → Runs as: Supabase Edge Function (cron) or Railway cron job

TRIGGER 3: User manually requests regeneration
  → "Regenerate this week" button in settings
  → Replaces only PLANNED (not COMPLETED) workouts

TRIGGER 4: User changes training preferences
  → Regenerates remaining planned workouts for current week
  → Generates fresh plan for next week
```

**Generation data flow:**

```
[Cron trigger or API call]
     │
     ▼
[workoutGeneratorService.generateWeeklyPlan()]
     │
     ├──→ READ: user preferences (frequency, equipment, goals)
     ├──→ READ: previous 4 weeks of plans (for variety tracking)
     ├──→ READ: exercise catalog + superset pairs
     │
     ▼
[Algorithm: select superset pairs, assign to days, set reps/sets]
     │
     ├──→ WRITE: weekly_plans table (1 row)
     ├──→ WRITE: workouts table (5-8 rows, one per training day)
     ├──→ WRITE: workout_supersets table (12-20 rows, 3-4 per strength workout)
     ├──→ WRITE: running_workout_details table (2-3 rows, one per run)
     │
     ▼
[If Garmin connected: push running workouts via Training API]
     │
     ├──→ WRITE: running_workout_details.garmin_workout_id (store Garmin's ID)
     └──→ WRITE: running_workout_details.pushed_to_garmin = true
```

**Data retention:** All generated plans are kept permanently for progress tracking. No auto-deletion.

#### Category 4: Activity & Tracking Data (Completions, Garmin Sync, Muscle Impact)

This is the most dynamic data — created through user actions and Garmin webhooks.

**How workout completions work:**

```
PATH A: Manual completion (strength workouts)
  1. User opens workout player → taps through sets
  2. On final set → "Complete Workout" button
  3. Frontend sends: POST /api/calendar/{workoutId}/complete
     Body: { actualDurationMin: 28, notes: "Felt strong" }
  4. Backend:
     a. UPDATE workouts SET status='completed', actual_duration_min=28, completed_at=NOW()
     b. RUN muscleImpactService.calculate(workoutId) → INSERT muscle_impact_logs
     c. RETURN muscle impact data for visualization

PATH B: Automatic completion (running workouts via Garmin)
  1. User completes run on Forerunner → syncs to Garmin Connect
  2. Garmin POSTs to our webhook: POST /api/webhooks/garmin/activity
  3. Backend:
     a. INSERT INTO garmin_activities (raw webhook data)
     b. MATCH activity to planned workout:
        - Find workout with same date + type=run_* + status=planned
        - Match by: date proximity (±1 day), activity_type=RUNNING
     c. UPDATE workouts SET status='completed',
          garmin_activity_id = garmin_activity.id,
          actual_duration_min = activity.duration / 60
     d. RUN muscleImpactService.calculate(workoutId)
```

**Garmin webhook data handling:**

```
[Garmin Connect Server]
     │
     │  POST /api/webhooks/garmin/activity
     │  Headers: { Authorization: Bearer <garmin_token> }
     │  Body: { activities: [...] }
     │
     ▼
[Webhook handler (Edge Function or Express route)]
     │
     ├──→ VERIFY: Garmin signature (prevent spoofing)
     ├──→ DEDUPLICATE: Check garmin_activity_id doesn't already exist
     ├──→ STORE: INSERT into garmin_activities (full raw payload as JSONB)
     ├──→ MATCH: Find corresponding planned workout
     ├──→ UPDATE: Mark workout as completed with Garmin data
     └──→ CALCULATE: Muscle impact from running data
```

### 9.4 Migration Strategy & Schema Versioning

**Tool: Supabase Migrations (or node-pg-migrate for custom backend)**

```
server/src/migrations/
├── 001_initial_schema.sql          # All CREATE TABLE statements
├── 002_seed_exercises.sql          # INSERT exercises + superset pairs
├── 003_add_image_columns.sql       # Exercise image fields
├── 004_add_garmin_indexes.sql      # Performance indexes
├── 005_add_weekly_load_cache.sql   # Future optimization
└── ...
```

**Migration workflow:**

```bash
# Create a new migration
npx supabase migration new add_recovery_tracking

# Apply migrations to local dev
npx supabase db push

# Apply to production (via CI/CD)
npx supabase db push --linked

# Rollback (manual — write reverse migration)
npx supabase migration new rollback_recovery_tracking
```

**Schema change rules for implementers:**
- Never modify existing migrations; always create new ones
- Every migration must be reversible (include rollback SQL in comments)
- Test migrations on Neon branch or Supabase preview before production
- Reference data changes (new exercises) go through seed scripts, not migrations

### 9.5 Backup & Disaster Recovery

| Layer | Strategy | Frequency | Retention |
|-------|----------|-----------|-----------|
| Database (Supabase Pro) | Automated daily backups + PITR | Daily + continuous WAL | 7 days PITR |
| Database (Neon) | Continuous WAL with branching | Continuous | 30 days |
| Exercise images (R2) | Versioned bucket, source in Git repo | On deploy | Indefinite (Git history) |
| Garmin tokens | Encrypted at rest (AES-256), stored in Supabase Vault | N/A | Until user disconnects |
| User data export | On-demand CSV export via API | User-triggered | N/A |

### 9.6 Data Flow Summary Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     DATA LIFECYCLE OVERVIEW                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ① STATIC DATA (deployed once, updated quarterly)               │
│  ┌──────────┐     seed script      ┌──────────────┐            │
│  │ JSON files│ ──────────────────→  │ exercises    │            │
│  │ in repo   │                      │ superset_prs │            │
│  └──────────┘                      └──────────────┘            │
│                                                                  │
│  ② USER DATA (created at signup, updated via settings)          │
│  ┌──────────┐     REST API          ┌──────────────┐           │
│  │ React UI  │ ──────────────────→  │ users        │           │
│  └──────────┘                       └──────────────┘           │
│                                                                  │
│  ③ GENERATED DATA (created by engine on schedule/demand)        │
│  ┌──────────┐     cron/API          ┌──────────────┐           │
│  │ Workout   │ ──────────────────→  │ weekly_plans │           │
│  │ Generator │                      │ workouts     │           │
│  │ Engine    │                      │ wkt_supersets│           │
│  └──────────┘                      │ run_details  │           │
│       │                             └──────────────┘           │
│       │  push runs to Garmin                                    │
│       └──────────────────────→ [Garmin Training API]            │
│                                                                  │
│  ④ ACTIVITY DATA (from user actions + Garmin webhooks)          │
│  ┌──────────┐     POST              ┌──────────────┐           │
│  │ Garmin    │ ──────────────────→  │ garmin_actvts│           │
│  │ Webhook   │                      └──────┬───────┘           │
│  └──────────┘                             │ match              │
│  ┌──────────┐     POST              ┌─────▼────────┐           │
│  │ Workout   │ ──────────────────→  │ workouts     │           │
│  │ Player UI │                      │ (status →    │           │
│  └──────────┘                      │  completed)  │           │
│                                     └──────┬───────┘           │
│                                            │ calculate          │
│                                     ┌──────▼────────┐           │
│                                     │ muscle_impact │           │
│                                     │ _logs         │           │
│                                     └───────────────┘           │
│                                                                  │
│  ⑤ EXERCISE IMAGES (built at deploy, served via CDN)            │
│  ┌──────────┐     build script      ┌──────────────┐           │
│  │ free-     │ ──→ resize/webp ──→  │ Cloudflare   │           │
│  │ exercise  │                      │ R2 bucket    │           │
│  │ -db repo  │                      └──────┬───────┘           │
│  └──────────┘                             │ CDN               │
│                                     ┌──────▼────────┐           │
│                                     │ cdn.runforge  │           │
│                                     │ .app/exercises│           │
│                                     └───────────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 9.7 Cost Estimate (Monthly)

| Service | Free Tier | Growth ($) | Notes |
|---------|-----------|------------|-------|
| Supabase (DB + Auth + API) | $0 (up to 500MB, 50K MAU) | $25/mo Pro | Includes auth, REST API, storage |
| Vercel (frontend hosting) | $0 (100GB bandwidth) | $20/mo Pro | React SPA + edge caching |
| Cloudflare R2 (images) | $0 (10GB storage, 10M reads) | ~$1/mo | 37 exercises × 5 variants = <50MB total |
| Upstash Redis (caching) | $0 (10K commands/day) | $10/mo | Rate limiting + session cache |
| Domain (runforge.app) | — | $12/year | .app domain |
| **Total at launch** | **$0/month** | | Free tier covers MVP easily |
| **Total at growth** | | **~$57/month** | ~500 active users |

---

## 10. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| User has only bodyweight equipment | Filter exercise catalog to bodyweight-only; reduce superset pool accordingly |
| User skips 2+ weeks | Reset mesocycle to build_1; add "return to training" deload week |
| Garmin webhook delivers duplicate activity | Deduplicate by `garmin_activity_id` UNIQUE constraint |
| Garmin token expires | Background refresh; if fails, surface "Reconnect Garmin" prompt |
| No superset pairs available after filtering | Fallback: construct ad-hoc pairs from compatible exercises by muscle group |
| User modifies scheduled workout | Store modification, exclude modified pair from "recently used" tracking |
| Two workouts same day (strength + run) | Calendar shows both with time-of-day ordering; muscle impact aggregates both |

---

## 11. Testing Strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Unit | Jest | Workout generation algorithm, muscle calculator, pace utilities |
| Component | React Testing Library | Calendar views, superset block, body map interaction |
| Integration | Supertest | API endpoints, auth flow, webhook handling |
| E2E | Playwright | Full user flows: onboarding → generate plan → complete workout → view impact |
| Visual | Storybook | Body map states, calendar states, exercise cards |

---

## 12. Performance Targets

| Metric | Target |
|--------|--------|
| Initial page load (LCP) | < 2.0s |
| Workout generation API | < 500ms |
| Calendar render (month with 30 entries) | < 100ms |
| Body map SVG interaction (hover/tap) | < 16ms (60fps) |
| Garmin webhook processing | < 200ms |
| Bundle size (gzipped) | < 250KB |

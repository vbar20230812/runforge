# RunForge — Running Personal Trainer
## Design & Architecture Document v2.0

**Version:** 2.0
**Date:** March 2, 2026
**Status:** Enhanced with Progress Tracking, Google Fit & Injury Prevention

---

## What's New in v2.0

This version adds major new capabilities:

| Feature | Description |
|---------|-------------|
| **Goal-Driven Training** | All workouts generated toward a specific goal; default goal is maintaining 10K under 1 hour |
| **Progress Tracking** | Comprehensive tracking of fitness progress, PRs, and trends over time |
| **Google Fit Integration** | Sync weight, heart rate, sleep, and other health metrics |
| **Smart Workout Recommendations** | AI-powered workout suggestions based on historical data and missed workouts |
| **Missed Workout Analysis** | Track patterns in missed workouts and adjust accordingly |
| **Injury Prevention System** | Monitor training load, fatigue, and injury risk factors |
| **Dynamic Recalculation** | When goal changes, all future workouts are recalculated to match the new target |

---

## 1. Product Vision

RunForge is a web-based personal training application purpose-built for runners targeting a 10K PR. It combines AI-generated superset strength workouts with structured running plans, visualized on a training calendar with Garmin Forerunner device synchronization. The app generates unique workouts each session, tracks muscle impact over time, adapts training load across the week, and actively works to prevent injuries through intelligent load management and recovery tracking.

### 1.1 Target User Profile

- Intermediate runners (able to complete 10K, aiming to improve time)
- Age range: 30–55, health-conscious, possibly managing conditions (e.g., controlled blood pressure)
- Has a Garmin Forerunner series watch
- Wants efficient gym sessions (20–35 min) using supersets
- Runs 2–3 times per week, strength trains 3–5 times per week
- **New:** Wants to track progress over time and avoid injuries

### 1.2 Core Goals

| # | Goal | Metric |
|---|------|--------|
| G1 | **Goal-oriented training** | All workouts drive toward user's specific goal |
| G2 | Improve 10K time | Pace progression tracked from Garmin data |
| G3 | Prevent injury | Balanced muscle loading + injury risk monitoring |
| G4 | Maximize gym efficiency | Superset-based workouts under 35 min |
| G5 | Workout variety | No repeated workout in a 4-week cycle |
| G6 | Seamless device sync | Garmin Forerunner + Google Fit sync |
| G7 | Increase bone density | Prioritize high-impact + heavy-load exercises |
| G8 | **Track progress** | Visual progress charts, PR tracking, trend analysis |
| G9 | **Smart recommendations** | AI-adapted workouts based on history and recovery |
| G10 | **Reduce injuries** | Early warning system for overtraining and muscle imbalances |

### 1.3 Default Goal

**Every user starts with a default goal: Maintain 10K under 1 hour (60 minutes)**

This goal ensures:
- Workout intensity is calibrated to maintain sub-60min fitness
- Running paces are calculated relative to 6:00/km baseline
- Strength workouts focus on endurance and injury prevention
- If no custom goal is set, the system always works toward this baseline

When a user sets a different goal, **all workouts are recalculated** to align with the new target.

---

## 2. New Feature Specification

### 2.1 Progress Tracking System

#### 2.1.1 Progress Metrics Dashboard

The progress tracking system monitors multiple dimensions of fitness:

**Running Progress:**

| Metric | Description | Data Source |
|--------|-------------|-------------|
| 10K Pace Trend | Pace progression over weeks/months | Garmin activities |
| Weekly Distance | Total km per week | Garmin + manual |
| Average Heart Rate | Trend in running HR | Garmin |
| Heart Rate Zones | Time in each zone | Garmin |
| VO2 Max Estimate | Calculated from pace/HR | Garmin |
| Cadence | Steps per minute trend | Garmin |

**Strength Progress:**

| Metric | Description | Data Source |
|--------|-------------|-------------|
| Total Volume | Sets × Reps × Weight per exercise | Manual entry |
| Exercise PRs | Personal records for key lifts | Manual entry |
| Workout Frequency | Strength sessions per week | App tracking |
| Muscle Load Balance | Even distribution across muscle groups | Calculated |
| Bone Density Score | Weekly bone stimulus accumulation | Calculated |

**Health Metrics (from Google Fit):**

| Metric | Description | Data Source |
|--------|-------------|-------------|
| Weight Trend | Weight changes over time | Google Fit |
| Resting Heart Rate | Recovery indicator | Google Fit |
| Sleep Quality | Hours and sleep stages | Google Fit |
| Daily Steps | Activity outside training | Google Fit |
| Body Fat % | If available from connected devices | Google Fit |

#### 2.1.2 Progress Data Model

```sql
-- Progress Snapshots (daily aggregation)
CREATE TABLE progress_snapshots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  snapshot_date   DATE NOT NULL,

  -- Running metrics
  weekly_distance_km     DECIMAL(6,2),
  avg_pace_sec_km        INT,
  avg_hr                 INT,
  run_sessions_week      INT,

  -- Strength metrics
  strength_sessions_week INT,
  total_volume_load      DECIMAL(10,2),  -- sum of sets×reps×weight
  bone_density_weekly    DECIMAL(8,2),

  -- Health metrics (from Google Fit)
  weight_kg              DECIMAL(5,2),
  resting_hr             INT,
  sleep_hours            DECIMAL(4,2),
  daily_steps            INT,
  body_fat_percent       DECIMAL(4,1),

  -- Calculated scores
  recovery_score         INT CHECK (recovery_score BETWEEN 0 AND 100),
  injury_risk_score      INT CHECK (injury_risk_score BETWEEN 0 AND 100),
  progress_score         INT CHECK (progress_score BETWEEN 0 AND 100),

  created_at             TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, snapshot_date)
);

-- Personal Records
CREATE TABLE personal_records (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  record_type     VARCHAR(50) NOT NULL,    -- '10k_time', 'squat_weight', 'deadlift_weight', etc.
  record_value    DECIMAL(10,2) NOT NULL,
  unit            VARCHAR(20) NOT NULL,    -- 'seconds', 'kg', 'reps', etc.
  achieved_date   DATE NOT NULL,
  workout_id      UUID REFERENCES workouts(id),
  garmin_activity_id VARCHAR(100),
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Progress Goals
CREATE TABLE progress_goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  goal_type       VARCHAR(50) NOT NULL,    -- '10k_time', 'weight', 'strength_session_freq', etc.
  target_value    DECIMAL(10,2) NOT NULL,
  unit            VARCHAR(20) NOT NULL,
  start_value     DECIMAL(10,2),
  start_date      DATE NOT NULL,
  target_date     DATE,
  status          VARCHAR(20) DEFAULT 'active',  -- 'active', 'achieved', 'abandoned'
  achieved_date   DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

#### 2.1.3 Progress Charts & Visualizations

**Chart Types:**

1. **Pace Trend Chart** - Line chart showing 10K pace over time with trend line
2. **Volume Chart** - Stacked area chart showing weekly running + strength volume
3. **Weight Trend Chart** - Line chart with goal line overlay
4. **Muscle Balance Radar** - Radar chart showing volume per muscle group
5. **Recovery Score Trend** - Line chart showing recovery over time
6. **Consistency Heatmap** - GitHub-style activity grid
7. **PR Timeline** - Timeline of personal records achieved
8. **Injury Risk Gauge** - Circular gauge showing current risk level

---

### 2.2 Google Fit Integration

#### 2.2.1 Integration Architecture

```
┌──────────────┐    OAuth 2.0    ┌──────────────┐   REST API   ┌─────────────┐
│  RunForge    │ ───────────────→│  RunForge    │ ────────────→│ Google Fit  │
│  Frontend    │                 │  Backend     │              │ API         │
└──────────────┘                 └──────────────┘              └─────────────┘
                                       │
                                       │   Webhook/Polling
                                       │←────────────────────
                                       │   (Health data updates)
```

#### 2.2.2 Data Points Synced from Google Fit

| Data Type | Google Fit API | Sync Frequency | Usage |
|-----------|---------------|----------------|-------|
| Weight | `com.google.weight` | On change + daily | Progress tracking, load calculations |
| Height | `com.google.height` | Once | BMI calculations |
| Body Fat % | `com.google.body.fat.percentage` | On change | Body composition tracking |
| Resting HR | `com.google.heart_rate.resting` | Daily | Recovery indicator |
| Sleep | `com.google.sleep.segment` | Daily morning | Recovery score calculation |
| Steps | `com.google.step_count` | Daily | Activity level tracking |
| Distance | `com.google.distance.delta` | Daily | Cross-check with running |
| Calories | `com.google.calories.expended` | Daily | Training load context |
| Heart Rate Variability | `com.google.heart_rate.variability` | If available | Advanced recovery metric |

#### 2.2.3 Google Fit Data Model

```sql
-- Google Fit Connection
ALTER TABLE users ADD COLUMN google_fit_connected BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN google_fit_access_token TEXT;
ALTER TABLE users ADD COLUMN google_fit_refresh_token TEXT;
ALTER TABLE users ADD COLUMN google_fit_token_expires TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN google_fit_last_sync TIMESTAMPTZ;

-- Google Fit Health Data
CREATE TABLE google_fit_data (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  data_type       VARCHAR(50) NOT NULL,    -- 'weight', 'resting_hr', 'sleep', etc.
  value           DECIMAL(10,2) NOT NULL,
  unit            VARCHAR(20) NOT NULL,
  recorded_at     TIMESTAMPTZ NOT NULL,
  source          VARCHAR(100),            -- Which app/device provided the data
  raw_data        JSONB,                   -- Full Google Fit data point
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for efficient queries
CREATE INDEX idx_google_fit_user_type_date ON google_fit_data(user_id, data_type, recorded_at DESC);
```

#### 2.2.4 Google Fit Sync Logic

```typescript
// Sync service runs daily and on-demand
async function syncGoogleFitData(userId: string): Promise<SyncResult> {
  const user = await getUser(userId);
  if (!user.google_fit_connected) return { synced: false, reason: 'not_connected' };

  // Refresh token if expired
  const tokens = await refreshGoogleFitTokenIfNeeded(user);

  // Fetch data for each type
  const dataTypes = [
    'com.google.weight',
    'com.google.heart_rate.resting',
    'com.google.sleep.segment',
    'com.google.step_count',
  ];

  const results = await Promise.all(
    dataTypes.map(type => fetchAndStoreGoogleFitData(userId, type, tokens))
  );

  // Update progress snapshot with new data
  await updateProgressSnapshot(userId);

  // Recalculate recovery and injury risk scores
  await recalculateRiskScores(userId);

  return { synced: true, dataPoints: results.flat().length };
}
```

---

### 2.3 Smart Workout Recommendations

#### 2.3.1 Recommendation Engine

At the start of each workout, the system analyzes historical data and current state to recommend the optimal workout:

**Input Factors:**

| Factor | Weight | Data Source |
|--------|--------|-------------|
| Planned workout for today | 40% | Generated schedule |
| Recent workout completion | 15% | Workout history |
| Missed workouts (last 7 days) | 15% | Workout history |
| Muscle recovery status | 10% | Muscle impact logs + time since last workout |
| Current fatigue level | 10% | Recovery score from health data |
| Injury risk score | 5% | Calculated risk |
| User preference/energy | 5% | User input (optional) |

**Recommendation Logic:**

```
FUNCTION getRecommendedWorkout(userId, date):
  plannedWorkout = getPlannedWorkout(userId, date)
  recentHistory = getRecentWorkouts(userId, days=14)
  missedWorkouts = getMissedWorkouts(userId, days=7)
  recoveryStatus = getRecoveryScore(userId)
  injuryRisk = getInjuryRiskScore(userId)
  muscleRecovery = getMuscleRecoveryStatus(userId)
  healthData = getLatestGoogleFitData(userId)

  // Adjust recommendation based on conditions

  IF injuryRisk > 70:
    RETURN recommendRecoveryWorkout(userId, plannedWorkout)

  IF recoveryStatus < 40:
    RETURN recommendLightWorkout(userId, plannedWorkout)

  IF hasMissedLowerBodyWorkouts(missedWorkouts) AND !hasRecentLowerBodySession(recentHistory):
    // Prioritize missed muscle groups
    RETURN recommendLowerBodyFocus(userId, plannedWorkout)

  IF muscleRecovery.quads < 50 OR muscleRecovery.hamstrings < 50:
    // Muscles still recovering, shift focus
    RETURN recommendUpperBodyFocus(userId, plannedWorkout)

  IF healthData.sleep_hours < 6 AND recoveryStatus < 60:
    // Poor recovery indicators
    RETURN recommendReducedIntensity(userId, plannedWorkout)

  // All good - proceed with planned workout
  RETURN plannedWorkout
```

#### 2.3.2 Workout Adjustment Types

| Adjustment Type | When Applied | What Changes |
|-----------------|--------------|--------------|
| **Recovery Workout** | Injury risk > 70% or recovery < 40% | Replace with light mobility/stretching |
| **Light Workout** | Recovery < 60% or poor sleep | Reduce sets by 1, reduce weight suggestion |
| **Focus Shift** | Missed muscle group sessions | Swap superset pairs to target neglected muscles |
| **Intensity Reduction** | Signs of fatigue | Lower rep count, longer rest periods |
| **Full Replacement** | User hasn't trained in 5+ days | Deload-style full-body reintroduction |
| **No Change** | All metrics good | Proceed with planned workout |

#### 2.3.3 Recommendation UI

When starting a workout, users see:

```
┌─────────────────────────────────────────────────────────────┐
│  TODAY'S RECOMMENDATION                                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Based on your recent training and recovery:                │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ We recommend: LIGHT WORKOUT                       │    │
│  │                                                      │    │
│  │ Why: Your sleep was 5.2 hours last night            │    │
│  │      and recovery score is at 55%                    │    │
│  │                                                      │    │
│  │ Changes from planned:                                │    │
│  | - 2 sets instead of 3 for heavy compounds            │    │
│  | - 90s rest instead of 60s                            │    │
│  | - Skip plyometric exercises today                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  [Start Recommended]  [Start Full Planned]  [View Details]  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

### 2.4 Missed Workout Tracking & Analysis

#### 2.4.1 Missed Workout Detection

A workout is considered "missed" when:
- Status is `planned` and the scheduled date has passed by > 24 hours
- User explicitly marks it as "skipped"

#### 2.4.2 Pattern Analysis

The system tracks patterns in missed workouts:

```sql
-- Missed Workout Analysis View
CREATE VIEW missed_workout_analysis AS
SELECT
  user_id,
  DATE_TRUNC('week', scheduled_date) as week,
  COUNT(*) FILTER (WHERE status = 'skipped' OR
    (status = 'planned' AND scheduled_date < CURRENT_DATE - 1)) as missed_count,
  COUNT(*) FILTER (WHERE workout_type LIKE 'strength%') as missed_strength,
  COUNT(*) FILTER (WHERE workout_type LIKE 'run_%') as missed_running,
  EXTRACT(DOW FROM scheduled_date) as day_of_week,
  workout_type
FROM workouts
GROUP BY user_id, DATE_TRUNC('week', scheduled_date), workout_type;
```

**Pattern Detection:**

| Pattern | Detection Logic | Action |
|---------|-----------------|--------|
| **Day-of-week skip** | Same weekday missed 3+ times in a row | Suggest schedule adjustment |
| **Type avoidance** | Same workout type missed > 50% | Suggest alternative or discuss in settings |
| **Post-long-run skip** | Skip after long run 2+ times | Reduce intensity after long runs |
| **Consecutive skips** | 3+ days in a row | Trigger check-in notification |
| **Monday skips** | Monday consistently missed | Suggest Sunday prep or different day |

#### 2.4.3 Missed Workout Data Model

```sql
-- Missed Workout Patterns
CREATE TABLE missed_workout_patterns (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  pattern_type    VARCHAR(50) NOT NULL,    -- 'day_of_week', 'workout_type', 'post_long_run', etc.
  pattern_data    JSONB NOT NULL,          -- Pattern-specific data
  occurrence_count INT DEFAULT 1,
  first_detected  TIMESTAMPTZ DEFAULT NOW(),
  last_occurrence TIMESTAMPTZ DEFAULT NOW(),
  action_suggested BOOLEAN DEFAULT FALSE,
  action_taken    BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Workout Adherence Stats
CREATE TABLE workout_adherence_stats (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  planned_workouts INT NOT NULL,
  completed_workouts INT NOT NULL,
  skipped_workouts INT NOT NULL,
  adherence_rate DECIMAL(5,2),  -- percentage
  strength_adherence DECIMAL(5,2),
  running_adherence DECIMAL(5,2),
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_start_date)
);
```

---

### 2.5 Injury Prevention System

#### 2.5.1 Injury Risk Factors

The system monitors multiple risk factors:

| Risk Factor | Weight | Threshold | Data Source |
|-------------|--------|-----------|-------------|
| **Training Load Spike** | 25% | > 20% increase in 1 week | Workout volume |
| **Muscle Imbalance** | 20% | > 30% difference between opposing muscles | Muscle impact logs |
| **Inadequate Recovery** | 20% | Recovery score < 50 for 3+ days | Health data |
| **Poor Sleep** | 15% | < 6 hours for 3+ nights | Google Fit |
| **High Resting HR** | 10% | > 10% above baseline | Google Fit |
| **Missed Rest Days** | 10% | No rest day in 10+ days | Calendar data |

#### 2.5.2 Injury Risk Score Calculation

```typescript
function calculateInjuryRiskScore(userId: string): InjuryRiskResult {
  const factors: RiskFactor[] = [];

  // 1. Training Load Spike (ACWR - Acute:Chronic Workload Ratio)
  const acuteLoad = getWeeklyLoad(userId, weeksAgo: 0);  // This week
  const chronicLoad = getAverageWeeklyLoad(userId, weeks: 4);  // 4-week average
  const acwr = acuteLoad / chronicLoad;

  if (acwr > 1.5) {
    factors.push({
      factor: 'training_load_spike',
      severity: 'high',
      value: acwr,
      message: `Training load increased ${(acwr - 1) * 100}% from your average`
    });
  } else if (acwr > 1.3) {
    factors.push({
      factor: 'training_load_spike',
      severity: 'medium',
      value: acwr,
      message: 'Training load is increasing quickly'
    });
  }

  // 2. Muscle Imbalance
  const muscleBalance = getMuscleBalance(userId, days: 30);
  const imbalances = findMuscleImbalances(muscleBalance, threshold: 0.30);

  if (imbalances.length > 0) {
    factors.push({
      factor: 'muscle_imbalance',
      severity: imbalances.length > 2 ? 'high' : 'medium',
      value: imbalances,
      message: `Imbalances detected: ${imbalances.map(i => i.name).join(', ')}`
    });
  }

  // 3. Recovery Score
  const recoveryScore = getRecoveryScore(userId);
  if (recoveryScore < 40) {
    factors.push({
      factor: 'inadequate_recovery',
      severity: 'high',
      value: recoveryScore,
      message: 'Recovery score is critically low'
    });
  } else if (recoveryScore < 60) {
    factors.push({
      factor: 'inadequate_recovery',
      severity: 'medium',
      value: recoveryScore,
      message: 'Recovery could be better'
    });
  }

  // 4. Sleep Quality
  const recentSleep = getRecentSleepData(userId, days: 3);
  const avgSleep = average(recentSleep.map(s => s.hours));

  if (avgSleep < 6) {
    factors.push({
      factor: 'poor_sleep',
      severity: 'high',
      value: avgSleep,
      message: `Averaging only ${avgSleep.toFixed(1)} hours of sleep`
    });
  }

  // 5. Rest Days
  const daysSinceRest = getDaysSinceLastRestDay(userId);
  if (daysSinceRest > 10) {
    factors.push({
      factor: 'no_rest_day',
      severity: 'high',
      value: daysSinceRest,
      message: `No rest day in ${daysSinceRest} days`
    });
  } else if (daysSinceRest > 7) {
    factors.push({
      factor: 'no_rest_day',
      severity: 'medium',
      value: daysSinceRest,
      message: 'Consider taking a rest day'
    });
  }

  // Calculate overall risk score (0-100)
  const weights = {
    training_load_spike: 0.25,
    muscle_imbalance: 0.20,
    inadequate_recovery: 0.20,
    poor_sleep: 0.15,
    high_resting_hr: 0.10,
    no_rest_day: 0.10,
  };

  let riskScore = 0;
  for (const factor of factors) {
    const weight = weights[factor.factor] || 0.10;
    const severityScore = factor.severity === 'high' ? 100 : factor.severity === 'medium' ? 60 : 30;
    riskScore += weight * severityScore;
  }

  riskScore = Math.min(100, riskScore);

  return {
    score: riskScore,
    level: riskScore > 70 ? 'high' : riskScore > 40 ? 'medium' : 'low',
    factors,
    recommendations: generateRecommendations(factors),
  };
}
```

#### 2.5.3 Recovery Score Calculation

```typescript
function calculateRecoveryScore(userId: string): number {
  let score = 100;

  // Sleep quality (max -30 points)
  const lastNightSleep = getLastNightSleep(userId);
  if (lastNightSleep < 5) score -= 30;
  else if (lastNightSleep < 6) score -= 20;
  else if (lastNightSleep < 7) score -= 10;

  // Resting HR vs baseline (max -20 points)
  const restingHR = getLatestRestingHR(userId);
  const baselineHR = getBaselineRestingHR(userId);
  const hrIncrease = ((restingHR - baselineHR) / baselineHR) * 100;
  if (hrIncrease > 15) score -= 20;
  else if (hrIncrease > 10) score -= 15;
  else if (hrIncrease > 5) score -= 10;

  // Recent training load (max -25 points)
  const yesterdayLoad = getYesterdayLoad(userId);
  const avgLoad = getAverageDailyLoad(userId, days: 14);
  if (yesterdayLoad > avgLoad * 1.5) score -= 25;
  else if (yesterdayLoad > avgLoad * 1.2) score -= 15;

  // Muscle recovery (max -25 points)
  const muscleRecovery = getMuscleRecoveryStatus(userId);
  const avgRecovery = average(Object.values(muscleRecovery));
  score -= (100 - avgRecovery) * 0.25;

  return Math.max(0, Math.min(100, score));
}
```

#### 2.5.4 Injury Risk Data Model

```sql
-- Injury Risk Assessments
CREATE TABLE injury_risk_assessments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  assessment_date DATE NOT NULL,
  risk_score      INT CHECK (risk_score BETWEEN 0 AND 100),
  risk_level      VARCHAR(20) NOT NULL,    -- 'low', 'medium', 'high'

  -- Individual factor scores
  load_spike_score        INT,
  muscle_imbalance_score  INT,
  recovery_score          INT,
  sleep_score             INT,
  resting_hr_score        INT,
  rest_day_score          INT,

  -- Detailed factors
  risk_factors    JSONB,                   -- Array of detected risk factors
  recommendations JSONB,                   -- Array of recommendations

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, assessment_date)
);

-- Injury History (user-reported)
CREATE TABLE injury_history (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  injury_type     VARCHAR(100) NOT NULL,   -- 'shin_splints', 'runner_knee', 'hamstring_strain', etc.
  body_part       VARCHAR(50) NOT NULL,    -- 'knee', 'ankle', 'hamstring', etc.
  severity        VARCHAR(20) NOT NULL,    -- 'minor', 'moderate', 'severe'
  start_date      DATE NOT NULL,
  end_date        DATE,
  recovery_weeks  INT,
  cause_notes     TEXT,                    -- What caused it
  treatment_notes TEXT,
  exercises_avoided TEXT[],                -- Exercises to avoid during recovery
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Muscle Recovery Status
CREATE TABLE muscle_recovery_status (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  muscle_group    VARCHAR(30) NOT NULL,
  last_trained_date DATE,
  recovery_percentage INT DEFAULT 100,     -- 0-100, increases over time
  estimated_full_recovery TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, muscle_group)
);
```

#### 2.5.5 Injury Risk Dashboard UI

```
┌─────────────────────────────────────────────────────────────────┐
│  INJURY PREVENTION                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                CURRENT RISK LEVEL                          │  │
│  │                                                             │  │
│  │      +-----------------------------------------+           │  │
│  |      |                                         |           │  │
│  |      |           LOW RISK                      |           │  │
│  |      |           Score: 28/100                 |           │  │
│  |      |                                         |           │  │
│  |      +-----------------------------------------+           │  │
│  │                                                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  RISK FACTORS:                                                   │
│  +-----------------------------------------------------------+  │
│  |  Muscle Imbalance (Medium)                                 |  │
│  |     Your quads are 35% stronger than hamstrings            |  │
│  |     Add more hamstring exercises this week                 |  │
│  |                                                            |  │
│  |  Training Load (Good)                                      |  │
│  |     Load increase is within safe limits                    |  │
│  |                                                            |  │
│  |  Recovery (Good)                                           |  │
│  |     Recovery score: 72/100                                 |  │
│  |                                                            |  │
│  |  Sleep (Good)                                              |  │
│  |     Last night: 7.5 hours                                  |  │
│  +-----------------------------------------------------------+  │
│                                                                  │
│  MUSCLE RECOVERY STATUS:                                         │
│  +-----------------------------------------------------------+  │
│  |  Quads      ##########  85%  (last: 2 days ago)            |  │
│  |  Hamstrings ########    72%  (last: 2 days ago)            |  │
│  |  Glutes     ############ 100% (last: 4 days ago)           |  │
│  |  Calves     ############ 100% (last: 3 days ago)           |  │
│  |  Core       #######       65%  (last: yesterday)           |  │
│  +-----------------------------------------------------------+  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

### 2.6 Goal-Driven Training System

#### 2.6.1 Overview

Every workout in RunForge is generated with a specific goal in mind. The goal drives:
- **Running pace targets** - calculated from goal 10K time
- **Strength workout intensity** - calibrated to support the running goal
- **Training volume** - adjusted based on goal difficulty
- **Recovery requirements** - more aggressive goals need better recovery

#### 2.6.2 Default Goal

**If no custom goal is set, the default goal is:**

```
MAINTAIN 10K UNDER 60 MINUTES (6:00/km pace)
```

This default goal:
- Is automatically assigned on account creation
- Ensures all users have meaningful, targeted workouts from day one
- Represents a healthy baseline fitness level for recreational runners
- Requires consistent but not excessive training (2-3 runs/week, 2-3 strength sessions/week)

#### 2.6.3 Goal Types

| Goal Type | Description | Example |
|-----------|-------------|---------|
| `maintain` | Maintain current fitness level | "Keep 10K under 60 min" |
| `improve_time` | Achieve a specific 10K time | "Run 10K in 55 min" |
| `improve_pace` | Achieve a specific pace | "Run at 5:30/km" |
| `complete_first` | Complete first 10K | "Finish my first 10K" |
| `race_prep` | Prepare for a specific race | "Race on June 15th, target 52 min" |

#### 2.6.4 Goal Data Model

```sql
-- Training Goals
CREATE TABLE training_goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,

  -- Goal definition
  goal_type       VARCHAR(30) NOT NULL,    -- 'maintain', 'improve_time', 'improve_pace', 'complete_first', 'race_prep'
  status          VARCHAR(20) DEFAULT 'active',  -- 'active', 'achieved', 'abandoned', 'replaced'

  -- Target metrics
  target_10k_time_sec    INT,              -- Target 10K time in seconds (e.g., 3300 = 55 min)
  target_pace_sec_km     INT,              -- Target pace in sec/km (e.g., 330 = 5:30/km)
  race_date              DATE,             -- For race_prep goals

  -- Current baseline
  baseline_10k_time_sec  INT,              -- Current 10K time when goal was set
  baseline_pace_sec_km   INT,              -- Current pace when goal was set

  -- Goal timeline
  target_date            DATE,             -- When to achieve this goal
  created_at             TIMESTAMPTZ DEFAULT NOW(),
  achieved_at            TIMESTAMPTZ,

  -- Calculation metadata
  last_recalculation     TIMESTAMPTZ,      -- When workouts were last recalculated for this goal
  recalculation_reason   VARCHAR(100),     -- 'goal_created', 'goal_changed', 'progress_update', 'manual'

  -- Is this the default goal?
  is_default             BOOLEAN DEFAULT FALSE,

  UNIQUE(user_id) WHERE (status = 'active')  -- Only one active goal per user
);

-- Goal Progress Tracking
CREATE TABLE goal_progress (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id         UUID REFERENCES training_goals(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  progress_date   DATE NOT NULL,

  -- Progress metrics
  current_estimate_10k_sec  INT,           -- Estimated current 10K capability
  progress_percentage       DECIMAL(5,2),  -- 0-100% progress toward goal
  pace_improvement_sec      INT,           -- How many seconds/km improved
  time_improvement_sec      INT,           -- How many seconds total improved

  -- Projection
  projected_achievement_date DATE,         -- When we'll hit the goal at current rate
  on_track                   BOOLEAN,

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(goal_id, progress_date)
);
```

#### 2.6.5 How Goals Drive Workout Generation

When generating workouts, the system uses the active goal to calculate:

**Running Workout Parameters:**

```
FUNCTION calculateRunningParams(goal):
  targetPace = goal.target_pace_sec_km OR deriveFrom10KTime(goal.target_10k_time_sec)

  // Easy runs: 60-90 sec slower than goal pace
  easyPaceLow = targetPace + 60
  easyPaceHigh = targetPace + 90

  // Tempo runs: 10-20 sec slower than goal pace
  tempoPaceLow = targetPace + 10
  tempoPaceHigh = targetPace + 20

  // Intervals: 10-20 sec FASTER than goal pace
  intervalPaceLow = targetPace - 20
  intervalPaceHigh = targetPace - 10

  // Volume based on goal difficulty
  IF goal.goal_type == 'maintain':
    weeklyVolume = 15-20 km/week
  ELIF goal.goal_type == 'improve_time':
    improvementDelta = goal.baseline_10k_time_sec - goal.target_10k_time_sec
    IF improvementDelta > 300:  // > 5 min improvement
      weeklyVolume = 25-35 km/week  // Higher volume
    ELSE:
      weeklyVolume = 20-25 km/week
  ELIF goal.goal_type == 'race_prep':
    // Periodized volume based on weeks until race
    weeksToRace = weeksBetween(NOW(), goal.race_date)
    weeklyVolume = calculatePeriodizedVolume(weeksToRace)

  RETURN {
    easyPaceRange: [easyPaceLow, easyPaceHigh],
    tempoPaceRange: [tempoPaceLow, tempoPaceHigh],
    intervalPaceRange: [intervalPaceLow, intervalPaceHigh],
    weeklyVolume: weeklyVolume
  }
```

**Strength Workout Parameters:**

```
FUNCTION calculateStrengthParams(goal):
  // Base intensity multiplier
  IF goal.goal_type == 'maintain':
    intensityMultiplier = 0.75  // Moderate intensity
    focusAreas = ['general_endurance', 'injury_prevention']
  ELIF goal.goal_type == 'improve_time':
    improvementDelta = goal.baseline_10k_time_sec - goal.target_10k_time_sec
    IF improvementDelta > 300:
      intensityMultiplier = 0.90  // Higher intensity
      focusAreas = ['power', 'running_economy', 'speed_endurance']
    ELSE:
      intensityMultiplier = 0.85
      focusAreas = ['running_economy', 'injury_prevention']
  ELIF goal.goal_type == 'complete_first':
    intensityMultiplier = 0.65  // Lower intensity for beginners
    focusAreas = ['general_strength', 'endurance_base', 'injury_prevention']

  // Strength session frequency
  IF goal.goal_type == 'maintain':
    strengthFrequency = 2-3 per week
  ELIF goal.goal_type == 'improve_time':
    strengthFrequency = 3-4 per week
  ELIF goal.goal_type == 'complete_first':
    strengthFrequency = 2 per week

  RETURN {
    intensityMultiplier,
    focusAreas,
    strengthFrequency
  }
```

#### 2.6.6 Goal Change → Workout Recalculation

**Triggering Events:**

| Event | Action |
|-------|--------|
| User creates first custom goal | Replace default goal, recalculate all future workouts |
| User modifies active goal | Recalculate all PLANNED workouts |
| User achieves goal | Prompt for new goal, maintain current workouts until set |
| System detects goal is unrealistic | Suggest adjustment, offer to recalculate |
| Significant progress update | Optionally adjust workout intensity |

**Recalculation Flow:**

```
FUNCTION recalculateWorkoutsForGoal(userId, newGoal):
  // 1. Archive old goal if exists
  oldGoal = getActiveGoal(userId)
  IF oldGoal:
    oldGoal.status = 'replaced'
    oldGoal.replaced_by = newGoal.id

  // 2. Set new goal as active
  newGoal.status = 'active'
  newGoal.last_recalculation = NOW()
  newGoal.recalculation_reason = 'goal_changed'

  // 3. Calculate new training parameters
  runningParams = calculateRunningParams(newGoal)
  strengthParams = calculateStrengthParams(newGoal)

  // 4. Delete all PLANNED workouts (keep COMPLETED)
  DELETE FROM workouts
  WHERE user_id = userId
    AND status = 'planned'
    AND scheduled_date >= CURRENT_DATE

  // 5. Regenerate weekly plans with new parameters
  FOR week IN getNext4Weeks():
    generateWeeklyPlan(userId, week, runningParams, strengthParams)

  // 6. Update Garmin if connected (push new running workouts)
  IF user.garmin_connected:
    syncRunningWorkoutsToGarmin(userId)

  // 7. Notify user
  sendNotification(userId, {
    type: 'workouts_recalculated',
    message: "Your workouts have been updated for your new goal: ${newGoal.description}"
  })

  RETURN { success: true, workoutsRegenerated: count }
```

#### 2.6.7 Goal Setting UI

**Goal Selection Screen:**

```
+---------------------------------------------------------------+
|  WHAT'S YOUR RUNNING GOAL?                                     |
+---------------------------------------------------------------+
|                                                                |
|  Select your primary goal and we'll customize your training:  |
|                                                                |
|  +-----------------------------------------------------------+ |
|  |  [MAINTAIN]  Keep 10K under 60 min                       | |
|  |                                                           | |
|  |  Default goal - maintain your fitness with               | |
|  |  balanced training (2-3 runs, 2-3 strength/week)         | |
|  +-----------------------------------------------------------+ |
|                                                                |
|  +-----------------------------------------------------------+ |
|  |  [IMPROVE TIME]  Run a faster 10K                        | |
|  |                                                           | |
|  |  Current 10K time: [55:00]                                | |
|  |  Target 10K time:  [50:00]                                | |
|  |                                                           | |
|  |  Estimated timeline: 8-12 weeks                           | |
|  +-----------------------------------------------------------+ |
|                                                                |
|  +-----------------------------------------------------------+ |
|  |  [RACE PREP]  Train for a specific race                  | |
|  |                                                           | |
|  |  Race date: [June 15, 2026]                               | |
|  |  Target time: [52:00]                                     | |
|  |                                                           | |
|  |  14-week training plan will be created                    | |
|  +-----------------------------------------------------------+ |
|                                                                |
|  +-----------------------------------------------------------+ |
|  |  [COMPLETE FIRST]  Finish my first 10K                   | |
|  |                                                           | |
|  |  Gradual build-up plan for beginners                      | |
|  |  12-week program                                          | |
|  +-----------------------------------------------------------+ |
|                                                                |
|  [Save Goal]                                                   |
|                                                                |
+---------------------------------------------------------------+
```

**Goal Progress Dashboard:**

```
+---------------------------------------------------------------+
|  YOUR GOAL: Run 10K in 50:00                                   |
+---------------------------------------------------------------+
|                                                                |
|  +-----------------------------------------------------------+ |
|  |                    PROGRESS                               | |
|  |                                                           | |
|  |  Current estimated:  52:30                                | |
|  |  Target:              50:00                               | |
|  |  Started at:          55:00                               | |
|  |                                                           | |
|  |  [===========================>>>>>---------] 72%          | |
|  |                                                           | |
|  |  You've improved 2:30! On track to hit goal by March 28. | |
|  +-----------------------------------------------------------+ |
|                                                                |
|  THIS WEEK'S TARGETS:                                          |
|  +-----------------------------------------------------------+ |
|  |  Pace targets for your 50:00 goal:                        | |
|  |                                                           | |
|  |  Easy runs:     5:40-6:10/km                              | |
|  |  Tempo runs:    4:50-5:00/km                              | |
|  |  Intervals:     4:30-4:40/km                              | |
|  |                                                           | |
|  |  Weekly volume: 25-30 km                                  | |
|  +-----------------------------------------------------------+ |
|                                                                |
|  [Adjust Goal]  [View Projected Timeline]                      |
|                                                                |
+---------------------------------------------------------------+
```

#### 2.6.8 Smart Goal Adjustments

The system monitors progress and suggests goal adjustments:

| Situation | Detection | Suggestion |
|-----------|-----------|------------|
| **Goal too easy** | On track to achieve > 3 weeks early | "You're ahead of schedule! Want to set a more ambitious target?" |
| **Goal too hard** | < 30% progress after 50% of timeline | "This goal might be aggressive. Consider adjusting to X?" |
| **Plateau detected** | No improvement for 3+ weeks | "You've plateaued. Try adjusting training or recovery." |
| **Overtraining signs** | Recovery score consistently low | "Your recovery is suffering. Consider a lighter goal temporarily." |
| **Goal achieved** | Current estimate >= target | "Congratulations! Set your next goal?" |

---

## 3. Enhanced API Endpoints

### 3.1 Progress Endpoints

```
GET    /api/progress/overview              Get overall progress summary
GET    /api/progress/running               Running progress metrics
GET    /api/progress/strength              Strength progress metrics
GET    /api/progress/health                Health metrics from Google Fit
GET    /api/progress/snapshots?range=      Get progress snapshots for date range
GET    /api/progress/personal-records      List all personal records
POST   /api/progress/personal-records      Log a new personal record
GET    /api/progress/goals                 List progress goals
POST   /api/progress/goals                 Create a progress goal
PUT    /api/progress/goals/:id             Update goal status
```

### 3.2 Google Fit Endpoints

```
GET    /api/integrations/google-fit/status      Check connection status
GET    /api/integrations/google-fit/connect     Get OAuth URL
GET    /api/integrations/google-fit/callback    OAuth callback
DELETE /api/integrations/google-fit             Disconnect
POST   /api/integrations/google-fit/sync        Trigger manual sync
GET    /api/integrations/google-fit/data/:type  Get specific data type
```

### 3.3 Recommendation Endpoints

```
GET    /api/recommendations/today               Get today's workout recommendation
GET    /api/recommendations/analysis            Get recommendation factors breakdown
POST   /api/recommendations/feedback            Submit feedback on recommendation
GET    /api/recommendations/schedule-adjustments  Get suggested schedule changes
```

### 3.4 Injury Prevention Endpoints

```
GET    /api/injury-risk/current                 Get current injury risk assessment
GET    /api/injury-risk/history?weeks=          Get historical risk assessments
GET    /api/injury-risk/factors                 Get detailed risk factor breakdown
GET    /api/injury-risk/recovery-status         Get muscle recovery status
POST   /api/injury-risk/injury                  Report an injury
GET    /api/injury-risk/injuries                Get injury history
PUT    /api/injury-risk/injuries/:id            Update injury status
```

### 3.5 Missed Workouts Endpoints

```
GET    /api/adherence/weekly                    Get weekly adherence stats
GET    /api/adherence/patterns                  Get detected missed workout patterns
POST   /api/adherence/patterns/:id/dismiss      Dismiss a pattern suggestion
GET    /api/adherence/trends                    Get adherence trends over time
```

### 3.6 Goal Endpoints

```
GET    /api/goals/active                        Get user's active training goal
POST   /api/goals                               Create a new training goal
PUT    /api/goals/:id                           Update goal details
DELETE /api/goals/:id                           Abandon a goal
GET    /api/goals/history                       Get past goals (achieved/abandoned)
GET    /api/goals/:id/progress                  Get progress toward specific goal
POST   /api/goals/:id/recalculate               Trigger workout recalculation for goal
GET    /api/goals/suggestions                   Get smart goal suggestions based on progress
```

---

## 4. Enhanced Frontend Components

### 4.1 New Pages

```
App
|-- ...existing pages...
|
|-- ProgressPage/                      # Enhanced progress page
|   |-- OverviewTab
|   |   |-- ProgressScoreCard
|   |   |-- WeeklySnapshot
|   |   +-- GoalProgressList
|   |-- RunningTab
|   |   |-- PaceTrendChart
|   |   |-- DistanceVolumeChart
|   |   +-- HeartRateZonesChart
|   |-- StrengthTab
|   |   |-- VolumeTrendChart
|   |   |-- PRTimeline
|   |   +-- MuscleBalanceRadar
|   +-- HealthTab
|       |-- WeightTrendChart
|       |-- SleepQualityChart
|       +-- RestingHRTrend
|
|-- InjuryPreventionPage/              # NEW: Injury prevention dashboard
|   |-- RiskScoreGauge
|   |-- RiskFactorsList
|   |-- MuscleRecoveryGrid
|   |-- RecommendationsList
|   +-- InjuryHistoryLog
|
+-- IntegrationsPage/                  # NEW: Integration settings
    |-- GarminConnectionPanel
    |-- GoogleFitConnectionPanel
    +-- SyncStatusWidget
```

### 4.2 New Components

```typescript
// components/progress/ProgressScoreCard.tsx
interface ProgressScoreCardProps {
  overallScore: number;
  changeFromLastWeek: number;
  breakdown: {
    running: number;
    strength: number;
    recovery: number;
    consistency: number;
  };
}

// components/injury-risk/RiskScoreGauge.tsx
interface RiskScoreGaugeProps {
  score: number;
  level: 'low' | 'medium' | 'high';
  trend: 'improving' | 'stable' | 'worsening';
}

// components/recommendations/WorkoutRecommendation.tsx
interface WorkoutRecommendationProps {
  recommendation: {
    type: 'planned' | 'light' | 'recovery' | 'focus_shift';
    reasoning: string[];
    adjustments: string[];
    workout: Workout;
  };
  onStartRecommended: () => void;
  onStartPlanned: () => void;
}

// components/integrations/GoogleFitSyncStatus.tsx
interface GoogleFitSyncStatusProps {
  connected: boolean;
  lastSync: Date | null;
  dataTypes: {
    type: string;
    lastUpdate: Date;
    value: number;
  }[];
  onSync: () => void;
}
```

---

## 5. Backend Services

### 5.1 Service Architecture

```
server/src/services/
|-- ...existing services...
|
|-- progressService.ts           # Progress tracking logic
|   |-- calculateProgressScore()
|   |-- getWeeklySnapshot()
|   |-- updatePersonalRecord()
|   +-- getGoalProgress()
|
|-- googleFitService.ts          # Google Fit integration
|   |-- getOAuthUrl()
|   |-- exchangeCodeForTokens()
|   |-- refreshAccessToken()
|   |-- fetchWeightData()
|   |-- fetchSleepData()
|   |-- fetchHeartRateData()
|   |-- fetchStepsData()
|   +-- syncAllData()
|
|-- recommendationService.ts     # Smart recommendations
|   |-- getTodayRecommendation()
|   |-- analyzeMissedWorkouts()
|   |-- calculateMusclePriority()
|   |-- adjustWorkoutIntensity()
|   +-- generateFocusShiftWorkout()
|
|-- injuryRiskService.ts         # Injury prevention
|   |-- calculateInjuryRiskScore()
|   |-- calculateRecoveryScore()
|   |-- detectMuscleImbalances()
|   |-- analyzeTrainingLoad()
|   |-- updateMuscleRecovery()
|   +-- generateRiskRecommendations()
|
+-- adherenceService.ts          # Missed workout tracking
    |-- calculateWeeklyAdherence()
    |-- detectMissedPatterns()
    |-- generateScheduleSuggestions()
    +-- updateAdherenceStats()
```

### 5.2 Background Jobs

```typescript
// Daily sync job (runs at 6 AM)
const dailySyncJob = {
  schedule: '0 6 * * *',
  tasks: [
    'syncGoogleFitData',
    'calculateRecoveryScores',
    'calculateInjuryRiskScores',
    'updateProgressSnapshots',
    'detectMissedWorkoutPatterns',
  ],
};

// Weekly summary job (runs Sunday night)
const weeklySummaryJob = {
  schedule: '0 22 * * 0',
  tasks: [
    'generateWeeklyAdherenceReport',
    'calculateWeeklyProgressScore',
    'analyzeTrainingPatterns',
    'generateWeeklyRecommendations',
  ],
};
```

---

## 6. Implementation Phases (Updated)

### Phase 1 - Core MVP (Weeks 1-3)
*Unchanged from v1.0*

### Phase 2 - Running + Muscle Map (Weeks 4-5)
*Unchanged from v1.0*

### Phase 3 - Workout Player + Polish (Weeks 5-6)
*Unchanged from v1.0*

### Phase 4 - Garmin Integration (Weeks 7-8)
*Unchanged from v1.0*

### Phase 5 - Progress & Optimization (Weeks 9-10)
*Unchanged from v1.0*

### Phase 6 - Google Fit Integration (Weeks 11-12)
- Google Fit OAuth flow
- Health data sync (weight, sleep, HR, steps)
- Google Fit connection UI
- Health metrics in progress dashboard

### Phase 7 - Smart Recommendations (Weeks 13-14)
- Recommendation engine implementation
- Missed workout pattern detection
- Workout adjustment logic
- Recommendation UI in workout start flow

### Phase 8 - Injury Prevention (Weeks 15-17)
- Injury risk score calculation
- Recovery score calculation
- Muscle recovery tracking
- Injury risk dashboard
- Alert/notification system for high risk

### Phase 9 - Polish & Analytics (Weeks 18-20)
- Enhanced progress charts
- Weekly/monthly reports
- Pattern insights
- Performance optimization
- User testing and refinement

---

## 7. Database Schema (Complete)

### 7.1 New Tables Summary

| Table | Purpose |
|-------|---------|
| `progress_snapshots` | Daily aggregated progress metrics |
| `personal_records` | Personal best achievements |
| `progress_goals` | User-defined progress goals |
| `google_fit_data` | Synced health data from Google Fit |
| `missed_workout_patterns` | Detected patterns in missed workouts |
| `workout_adherence_stats` | Weekly adherence statistics |
| `injury_risk_assessments` | Daily injury risk calculations |
| `injury_history` | User-reported injuries |
| `muscle_recovery_status` | Per-muscle recovery tracking |

### 7.2 Modified Tables

| Table | Changes |
|-------|---------|
| `users` | Added Google Fit connection columns |
| `workouts` | Added recommendation_type, recommendation_reason columns |

---

## 8. Configuration & Environment

### 8.1 New Environment Variables

```bash
# Google Fit API
GOOGLE_FIT_CLIENT_ID=your_client_id
GOOGLE_FIT_CLIENT_SECRET=your_client_secret
GOOGLE_FIT_REDIRECT_URI=https://runforge.app/api/integrations/google-fit/callback

# Feature Flags
ENABLE_GOOGLE_FIT=true
ENABLE_INJURY_PREVENTION=true
ENABLE_SMART_RECOMMENDATIONS=true
```

### 8.2 Google Fit API Setup

1. Create project in Google Cloud Console
2. Enable Fitness API
3. Configure OAuth consent screen
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs
6. Request scopes:
   - `https://www.googleapis.com/auth/fitness.body.read`
   - `https://www.googleapis.com/auth/fitness.sleep.read`
   - `https://www.googleapis.com/auth/fitness.heart_rate.read`
   - `https://www.googleapis.com/auth/fitness.activity.read`

---

## 9. Cost Estimate (Updated)

| Service | Free Tier | Growth ($) | Notes |
|---------|-----------|------------|-------|
| Supabase (DB + Auth) | $0 | $25/mo | Increased storage for health data |
| Vercel (frontend) | $0 | $20/mo | Unchanged |
| Cloudflare R2 (images) | $0 | ~$1/mo | Unchanged |
| Upstash Redis | $0 | $10/mo | Increased for caching health data |
| Background Jobs | $0 | $5/mo | Cron jobs for sync |
| Domain | - | $12/year | Unchanged |
| **Total at launch** | **$0/month** | | |
| **Total at growth** | | **~$61/month** | |

---

## 10. Key Technical Decisions (New)

| Decision | Rationale |
|----------|-----------|
| Daily snapshots vs real-time | Pre-aggregated data enables fast chart loading; health data doesn't change frequently enough to need real-time |
| Google Fit over Apple Health | Cross-platform (works on Android + Web); Apple Health requires iOS app |
| 4-week ACWR calculation | Industry standard for training load monitoring in sports science |
| Risk score 0-100 | Simple to understand; matches recovery score convention |
| Pattern detection threshold 3+ occurrences | Prevents false positives from occasional schedule changes |
| Muscle recovery 72-hour window | Based on research showing muscle protein synthesis elevated for 48-72h post-exercise |

---

## 11. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Weekly adherence rate | > 80% | Completed / Planned workouts |
| Injury risk score average | < 40 | Daily assessment |
| Google Fit sync success rate | > 95% | Sync attempts vs successes |
| Recommendation acceptance rate | > 70% | Followed / Suggested |
| User-reported injuries | < 5% of users | Injury reports / Total users |
| Progress score improvement | +10% in 12 weeks | New users average |

---

## 12. File Structure (Updated)

```
runforge/
|-- client/                          # React frontend
|   |-- src/
|   |   |-- pages/
|   |   |   |-- ...existing pages...
|   |   |   |-- ProgressPage.tsx         # Enhanced
|   |   |   |-- InjuryPreventionPage.tsx # NEW
|   |   |   +-- IntegrationsPage.tsx     # NEW
|   |   |
|   |   |-- components/
|   |   |   |-- ...existing components...
|   |   |   |-- progress/                # NEW directory
|   |   |   |   |-- ProgressScoreCard.tsx
|   |   |   |   |-- WeeklySnapshot.tsx
|   |   |   |   |-- PRTimeline.tsx
|   |   |   |   +-- GoalProgressList.tsx
|   |   |   |
|   |   |   |-- injury-risk/             # NEW directory
|   |   |   |   |-- RiskScoreGauge.tsx
|   |   |   |   |-- RiskFactorsList.tsx
|   |   |   |   |-- MuscleRecoveryGrid.tsx
|   |   |   |   +-- InjuryHistoryLog.tsx
|   |   |   |
|   |   |   |-- recommendations/         # NEW directory
|   |   |   |   |-- WorkoutRecommendation.tsx
|   |   |   |   +-- RecommendationFactors.tsx
|   |   |   |
|   |   |   +-- integrations/            # NEW directory
|   |   |       |-- GoogleFitConnection.tsx
|   |   |       +-- SyncStatusWidget.tsx
|   |   |
|   |   +-- stores/
|   |       |-- ...existing stores...
|   |       |-- progressStore.ts         # NEW
|   |       |-- injuryRiskStore.ts       # NEW
|   |       +-- integrationsStore.ts     # NEW
|
|-- server/                          # Node.js backend
|   |-- src/
|   |   |-- services/
|   |   |   |-- ...existing services...
|   |   |   |-- progressService.ts       # NEW
|   |   |   |-- googleFitService.ts      # NEW
|   |   |   |-- recommendationService.ts # NEW
|   |   |   |-- injuryRiskService.ts     # NEW
|   |   |   +-- adherenceService.ts      # NEW
|   |   |
|   |   |-- routes/
|   |   |   |-- ...existing routes...
|   |   |   |-- progress.ts              # NEW
|   |   |   |-- integrations.ts          # NEW
|   |   |   |-- recommendations.ts       # NEW
|   |   |   |-- injuryRisk.ts            # NEW
|   |   |   +-- adherence.ts             # NEW
|   |   |
|   |   +-- migrations/
|   |       |-- ...existing migrations...
|   |       |-- 005_add_google_fit_tables.sql
|   |       |-- 006_add_progress_tracking.sql
|   |       |-- 007_add_injury_prevention.sql
|   |       +-- 008_add_adherence_tracking.sql
|   |
|   +-- jobs/                        # NEW: Background jobs
|       |-- dailySyncJob.ts
|       +-- weeklySummaryJob.ts
|
+-- shared/
    +-- types/
        |-- ...existing types...
        |-- progress.ts               # NEW
        |-- googleFit.ts              # NEW
        |-- injuryRisk.ts             # NEW
        +-- recommendations.ts        # NEW
```

---

*End of Document v2.0*
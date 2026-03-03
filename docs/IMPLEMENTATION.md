# RunForge Implementation Guide

## Quick Start

### Prerequisites

- Node.js 18+ installed
- A Supabase account (free tier at https://supabase.com)
- Git

---

## Step 1: Initialize the Frontend (React + TypeScript + Vite)

```powershell
cd C:\Users\victo\Projects\RunForge\client

# Create Vite React TypeScript project
npm create vite@latest . -- --template react-ts

# Install dependencies
npm install

# Install additional dependencies
npm install react-router-dom zustand @tanstack/react-query axios
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Start dev server
npm run dev
```

**Frontend folder structure after setup:**
```
client/
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── pages/
│   ├── components/
│   ├── stores/
│   ├── services/
│   ├── hooks/
│   └── types/
├── public/
├── package.json
├── vite.config.ts
└── tailwind.config.js
```

---

## Step 2: Initialize the Backend (Node.js + Express + TypeScript)

```powershell
cd C:\Users\victo\Projects\RunForge\server

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express cors helmet morgan dotenv pg

# Install dev dependencies
npm install typescript ts-node nodemon @types/node @types/express @types/cors @types/morgan --save-dev

# Initialize TypeScript
npx tsc --init

# Create folder structure
mkdir src
mkdir src/routes
mkdir src/services
mkdir src/middleware
mkdir src/models
mkdir src/config
mkdir src/seeds
mkdir src/migrations
```

**Create server/src/index.ts:**
```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Add scripts to server/package.json:**
```json
{
  "scripts": {
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
```

---

## Step 3: Set Up Supabase (Database + Auth)

### 3.1 Create Supabase Project

1. Go to https://supabase.com
2. Click "New Project"
3. Name: `runforge-dev`
4. Set a strong database password (save it!)
5. Choose a region close to you (e.g., EU West)
6. Click "Create new project"
7. Wait ~2 minutes for project to be ready

### 3.2 Get API Keys

1. Go to Settings > API
2. Copy these values:
   - **Project URL** (e.g., `https://xyz.supabase.co`)
   - **anon public key**
   - **service_role key** (keep secret!)
3. Go to Settings > Database
4. Copy the **Connection string** (URI format)
   - Replace `[YOUR-PASSWORD]` with your database password

---

## Step 4: Create Environment Files

### client/.env
```
VITE_API_URL=http://localhost:3001/api
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key_here
```

### server/.env
```
PORT=3001
DATABASE_URL=postgresql://postgres:your_password@db.your-project.supabase.co:5432/postgres
JWT_SECRET=generate_a_random_32_char_string_here
```

**Generate JWT secret:**
```powershell
# PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

---

## Step 5: Create Initial Database Schema

Run this SQL in Supabase SQL Editor:

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
  weight_kg     DECIMAL(5,2),
  height_cm     INT,
  current_10k_time_sec INT,
  goal_10k_time_sec    INT,

  -- Preferences
  strength_frequency   INT DEFAULT 3 CHECK (strength_frequency BETWEEN 3 AND 5),
  run_frequency        INT DEFAULT 2 CHECK (run_frequency BETWEEN 2 AND 3),
  available_equipment  TEXT[],
  preferred_run_days   TEXT[],

  -- Garmin
  garmin_user_id       VARCHAR(100),
  garmin_access_token  TEXT,
  garmin_token_secret  TEXT,
  garmin_connected_at  TIMESTAMPTZ,
  garmin_last_sync     TIMESTAMPTZ,

  -- Google Fit
  google_fit_connected BOOLEAN DEFAULT FALSE,
  google_fit_access_token TEXT,
  google_fit_refresh_token TEXT,
  google_fit_token_expires TIMESTAMPTZ,
  google_fit_last_sync TIMESTAMPTZ
);

-- Training Goals
CREATE TABLE training_goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  goal_type       VARCHAR(30) NOT NULL,
  status          VARCHAR(20) DEFAULT 'active',
  target_10k_time_sec    INT,
  target_pace_sec_km     INT,
  race_date              DATE,
  baseline_10k_time_sec  INT,
  baseline_pace_sec_km   INT,
  target_date            DATE,
  created_at             TIMESTAMPTZ DEFAULT NOW(),
  achieved_at            TIMESTAMPTZ,
  last_recalculation     TIMESTAMPTZ,
  recalculation_reason   VARCHAR(100),
  is_default             BOOLEAN DEFAULT FALSE,
  UNIQUE(user_id) WHERE (status = 'active')
);

-- Exercises (reference data)
CREATE TABLE exercises (
  id               VARCHAR(50) PRIMARY KEY,
  name             VARCHAR(100) NOT NULL,
  primary_muscles  TEXT[] NOT NULL,
  secondary_muscles TEXT[],
  equipment        VARCHAR(50) NOT NULL,
  movement_type    VARCHAR(50) NOT NULL,
  difficulty       INT CHECK (difficulty BETWEEN 1 AND 5),
  is_unilateral    BOOLEAN DEFAULT FALSE,
  instructions     TEXT,
  bone_density_score INT CHECK (bone_density_score BETWEEN 0 AND 100),
  image_source_id  VARCHAR(200),
  image_cdn_base   VARCHAR(500),
  has_animation    BOOLEAN DEFAULT FALSE
);

-- Weekly Plans
CREATE TABLE weekly_plans (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  week_number   INT NOT NULL,
  year          INT NOT NULL,
  phase         VARCHAR(20) NOT NULL,
  mesocycle     INT NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_number, year)
);

-- Workouts
CREATE TABLE workouts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  weekly_plan_id    UUID REFERENCES weekly_plans(id) ON DELETE CASCADE,
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
  scheduled_date    DATE NOT NULL,
  workout_type      VARCHAR(30) NOT NULL,
  status            VARCHAR(20) DEFAULT 'planned',
  estimated_duration_min INT,
  actual_duration_min    INT,
  garmin_activity_id     VARCHAR(100),
  completed_at           TIMESTAMPTZ,
  user_notes             TEXT,
  recommendation_type    VARCHAR(30),
  recommendation_reason  TEXT,
  created_at             TIMESTAMPTZ DEFAULT NOW()
);

-- Progress Snapshots
CREATE TABLE progress_snapshots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  snapshot_date   DATE NOT NULL,
  weekly_distance_km     DECIMAL(6,2),
  avg_pace_sec_km        INT,
  avg_hr                 INT,
  run_sessions_week      INT,
  strength_sessions_week INT,
  total_volume_load      DECIMAL(10,2),
  bone_density_weekly    DECIMAL(8,2),
  weight_kg              DECIMAL(5,2),
  resting_hr             INT,
  sleep_hours            DECIMAL(4,2),
  daily_steps            INT,
  recovery_score         INT CHECK (recovery_score BETWEEN 0 AND 100),
  injury_risk_score      INT CHECK (injury_risk_score BETWEEN 0 AND 100),
  progress_score         INT CHECK (progress_score BETWEEN 0 AND 100),
  created_at             TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, snapshot_date)
);

-- Injury Risk Assessments
CREATE TABLE injury_risk_assessments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  assessment_date DATE NOT NULL,
  risk_score      INT CHECK (risk_score BETWEEN 0 AND 100),
  risk_level      VARCHAR(20) NOT NULL,
  load_spike_score        INT,
  muscle_imbalance_score  INT,
  recovery_score          INT,
  sleep_score             INT,
  resting_hr_score        INT,
  rest_day_score          INT,
  risk_factors    JSONB,
  recommendations JSONB,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, assessment_date)
);

-- Indexes
CREATE INDEX idx_workouts_user_date ON workouts(user_id, scheduled_date);
CREATE INDEX idx_workouts_status ON workouts(status);
CREATE INDEX idx_progress_user_date ON progress_snapshots(user_id, snapshot_date);
CREATE INDEX idx_injury_risk_user_date ON injury_risk_assessments(user_id, assessment_date);
```

---

## Step 6: Install and Run

### Terminal 1 - Backend:
```powershell
cd C:\Users\victo\Projects\RunForge\server
npm run dev
```

### Terminal 2 - Frontend:
```powershell
cd C:\Users\victo\Projects\RunForge\client
npm run dev
```

- Frontend: http://localhost:5173
- Backend: http://localhost:3001
- API Health: http://localhost:3001/api/health

---

## Implementation Phases

| Phase | What to Build | Time | Priority |
|-------|---------------|------|----------|
| **1A** | Project setup, database schema, basic auth | Week 1 | HIGH |
| **1B** | Exercise catalog (static data), workout generator | Week 2 | HIGH |
| **1C** | Calendar view, workout display | Week 3 | HIGH |
| **2** | Running workouts, muscle impact visualization | Weeks 4-5 | HIGH |
| **3** | Workout player, active tracking | Weeks 5-6 | MEDIUM |
| **4** | Garmin integration | Weeks 7-8 | MEDIUM |
| **5** | Progress tracking, charts | Weeks 9-10 | MEDIUM |
| **6** | Google Fit integration | Weeks 11-12 | LOW |
| **7** | Smart recommendations | Weeks 13-14 | LOW |
| **8** | Injury prevention system | Weeks 15-17 | LOW |

---

## Key Files to Create First

### Phase 1A Checklist:
- [ ] `server/src/index.ts` - Express app entry
- [ ] `server/src/config/database.ts` - PostgreSQL connection
- [ ] `server/src/routes/auth.ts` - Auth endpoints
- [ ] `server/src/services/authService.ts` - Auth logic
- [ ] `client/src/main.tsx` - React entry
- [ ] `client/src/App.tsx` - Router setup
- [ ] `client/src/stores/authStore.ts` - Auth state
- [ ] `client/src/services/api.ts` - Axios instance

### Phase 1B Checklist:
- [ ] `server/src/seeds/exercises.seed.ts` - Seed exercise data
- [ ] `server/src/services/workoutGeneratorService.ts` - Core algorithm
- [ ] `server/src/routes/plans.ts` - Plan generation endpoints
- [ ] `client/src/pages/DashboardPage.tsx`
- [ ] `client/src/pages/CalendarPage.tsx`
- [ ] `client/src/components/calendar/MonthView.tsx`

---

## Resources

- **Design Doc**: `docs/DESIGN.md`
- **Original Doc**: `docs/RunForge-Design-Document.md`
- **Supabase Dashboard**: https://supabase.com/dashboard
- **Vite Docs**: https://vitejs.dev
- **React Router**: https://reactrouter.com
- **Zustand**: https://zustand-demo.pmnd.rs

---

## Git Workflow

```powershell
# Create feature branch
git checkout -b feature/phase-1a-setup

# After completing work
git add .
git commit -m "feat: Set up project structure and basic auth"

# Push to GitHub
git push origin feature/phase-1a-setup

# Create PR on GitHub
```

---

*Last updated: March 3, 2026*

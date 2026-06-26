# RoadGuard Backend GCP Deployment

RoadGuard mobile itself is not deployed to Cloud Run. The GCP deployment target is the FastAPI backend under `roadguard_backend/`.

## Deployment Shape

- Cloud Run for the FastAPI backend
- Artifact Registry for container images
- Cloud Build for image build and deployment
- PostgreSQL for persistent hazard, device, and model registry data
- Secret Manager for production secrets

## Current Repo Files

- `roadguard_backend/Dockerfile`
- `roadguard_backend/cloudbuild.backend.yaml`
- `roadguard_backend/.env.example`

## Required GCP Resources

- one GCP project for RoadGuard
- one Artifact Registry repository, for example `roadguard`
- one Cloud Run service, for example `roadguard-backend`
- one PostgreSQL database
- one runtime service account, for example `roadguard-backend-runner`

## Required APIs

Enable:

- Cloud Run Admin API
- Cloud Build API
- Artifact Registry API
- Secret Manager API
- Cloud SQL Admin API if using Cloud SQL

## Required Runtime Configuration

The backend currently expects:

- `ROADGUARD_DATABASE_URL`
- `ROADGUARD_ALLOWED_ORIGINS`
- `ROADGUARD_ENVIRONMENT`
- `ROADGUARD_DEBUG`
- `ROADGUARD_API_PREFIX`

Recommended production values:

- `ROADGUARD_ENVIRONMENT=production`
- `ROADGUARD_DEBUG=false`
- `ROADGUARD_API_PREFIX=/api`

## Cloud SQL

If you use Cloud SQL PostgreSQL, the production database URL will usually look like:

```text
postgresql+psycopg2://USER:PASSWORD@localhost:5432/DATABASE?host=/cloudsql/PROJECT:REGION:INSTANCE
```

If you use Cloud Run with Cloud SQL attachment, set `ROADGUARD_DATABASE_URL` from Secret Manager and attach the Cloud SQL instance during deployment.

## Build and Deploy with Cloud Build

Example command:

```bash
gcloud builds submit \
  --config roadguard_backend/cloudbuild.backend.yaml \
  --substitutions=_REGION=asia-south1,_AR_REPOSITORY=roadguard,_SERVICE_NAME=roadguard-backend,_SERVICE_ACCOUNT=roadguard-backend-runner@PROJECT_ID.iam.gserviceaccount.com,_ALLOWED_ORIGINS=https://your-mobile-web-origin.example
```

## Recommended Extra Deploy Step

The current Cloud Build file intentionally does not inject a production database URL. For a real deployment you should either:

1. deploy with a later `gcloud run services update` step that adds:
   - `ROADGUARD_DATABASE_URL` from Secret Manager
2. or extend `cloudbuild.backend.yaml` to include:
   - `--update-secrets=ROADGUARD_DATABASE_URL=roadguard-database-url:latest`
3. and if using Cloud SQL, also add:
   - `--add-cloudsql-instances=PROJECT:REGION:INSTANCE`

## Suggested Secret Manager Secrets

- `roadguard-database-url`

## Suggested GitHub Actions Secrets

If you deploy from GitHub Actions later, you will likely want:

- `GCP_PROJECT_ID`
- `GCP_REGION`
- `GCP_ARTIFACT_REPOSITORY`
- `GCP_SERVICE_ACCOUNT_EMAIL`
- `WIF_PROVIDER`

If you prefer key-based auth instead of Workload Identity Federation:

- `GCP_SA_KEY`

## Local Notes

- `gcloud` is installed on this machine.
- This Codex session can read your active account/project, but the local gcloud config directory is not writable in this environment, so I did not run a live deployment from here.
- The repo is now structured so you can deploy the backend through Cloud Build or GitHub Actions with your own secrets and project values.

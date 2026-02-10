# OpenAI Setup

The try-on pipeline uses OpenAI Responses API with the `image_generation` tool.

## Option 1: direct dart-define

```bash
flutter run -d chrome \
  --dart-define=OPENAI_API_KEY=YOUR_OPENAI_API_KEY \
  --dart-define=OPENAI_MODEL=gpt-4.1
```

`OPENAI_MODEL` is optional. Default model is `gpt-4.1`.

## Option 2: env file (`--dart-define-from-file`)

1. Create local env file:

```bash
cp env/openai.example.json env/openai.local.json
```

2. Put your real key into `env/openai.local.json`.

3. Run app:

```bash
flutter run -d chrome --dart-define-from-file=env/openai.local.json
```

## Security note

Do not commit real API keys to repository files.

## GitHub Actions secrets

For `/Users/user/Documents/startup3/.github/workflows/deploy.yml`, configure:

- `OPENAI_API_KEY` (required)
- `OPENAI_MODEL` (optional, default `gpt-4.1`)

## Behavior without key

If `OPENAI_API_KEY` is missing, the app shows an in-app error and does not call OpenAI.

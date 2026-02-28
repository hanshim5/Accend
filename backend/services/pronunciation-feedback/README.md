# pronunciation-feedback

Minimal FastAPI template. Add your pronunciation logic here.

## Run locally

```bash
pip install -r requirements.txt
uvicorn main:app --reload
```

## Run with Docker

```bash
docker build -t pronunciation-feedback .
docker run -p 8000:8000 pronunciation-feedback
```

- Root: http://localhost:8000/
- Health: http://localhost:8000/health
- Docs: http://localhost:8000/docs

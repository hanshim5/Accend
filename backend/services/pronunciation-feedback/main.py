from fastapi import FastAPI

app = FastAPI(
    title="Pronunciation Feedback",
    description="Microservice for pronunciation assessment and feedback.",
    version="0.1.0",
)


@app.get("/")
def root():
    return {"service": "pronunciation-feedback", "status": "ok"}


@app.get("/health")
def health():
    return {"status": "healthy"}

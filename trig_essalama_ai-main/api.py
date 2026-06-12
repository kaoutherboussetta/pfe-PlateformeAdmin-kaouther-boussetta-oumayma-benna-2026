from fastapi import FastAPI
from pipeline import run_pipeline

app = FastAPI()


@app.get("/analyse/ping")
def analyse_ping():
    return {"status": "ok"}


@app.get("/analyse")
def analyse():
    return run_pipeline()

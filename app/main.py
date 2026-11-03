from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas
from .database import engine, get_db, Base
from prometheus_fastapi_instrumentator import Instrumentator

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Task API")


# Esto crea automáticamente el endpoint /metrics
Instrumentator().instrument(app).expose(app) # <-- NUEVO

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/tasks", response_model=list[schemas.TaskOut])
def list_tasks(db: Session = Depends(get_db)):
    return db.query(models.Task).all()

@app.post("/tasks", response_model=schemas.TaskOut, status_code=201)
def create_task(payload: schemas.TaskCreate, db: Session = Depends(get_db)):
    task = models.Task(title=payload.title)
    db.add(task)
    db.commit()
    db.refresh(task)
    return task

@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()


from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas
from app.db.session import get_db

router = APIRouter()

@router.get("/", response_model=List[schemas.EmergencyContactResponse])
async def get_emergency_contacts(db: Session = Depends(get_db)):
    contacts = db.query(models.EmergencyContact).all()
    return contacts

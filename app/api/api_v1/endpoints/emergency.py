from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import get_current_admin
from sqlalchemy.orm import Session
from typing import List, Optional

from app import models, schemas
from app.db.session import get_db

router = APIRouter()

@router.get("/", response_model=List[schemas.EmergencyContactResponse])
async def get_emergency_contacts(
    region: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(models.EmergencyContact)
    if region:
        query = query.filter(models.EmergencyContact.region.ilike(f"%{region}%"))
    contacts = query.all()
    return contacts
@router.post("/", response_model=schemas.EmergencyContactResponse, status_code=status.HTTP_201_CREATED)
async def create_emergency_contact(
    contact: schemas.EmergencyContactCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    new_contact = models.EmergencyContact(**contact.model_dump())
    db.add(new_contact)
    db.commit()
    db.refresh(new_contact)
    return new_contact

@router.put("/{contact_id}", response_model=schemas.EmergencyContactResponse)
async def update_emergency_contact(
    contact_id: int,
    contact_data: schemas.EmergencyContactUpdate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    contact = db.query(models.EmergencyContact).filter(models.EmergencyContact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Kontak tidak ditemukan")
    
    update_data = contact_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(contact, key, value)
    
    db.commit()
    db.refresh(contact)
    return contact

@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_emergency_contact(
    contact_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    contact = db.query(models.EmergencyContact).filter(models.EmergencyContact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Kontak tidak ditemukan")
    
    db.delete(contact)
    db.commit()
    return None

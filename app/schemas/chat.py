from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
import datetime

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None
    refraction_result: Optional[str] = None

class BotResponseDetail(BaseModel):
    id: int
    role: str = "bot"
    message: str
    created_at: datetime.datetime
    metadata: Optional[dict] = None

class ChatResponse(BaseModel):
    session_id: str
    bot_response: BotResponseDetail

class ChatMessageResponse(BaseModel):
    id: int
    role: str
    message: str
    created_at: datetime.datetime
    metadata: Optional[dict] = Field(None, alias="metadata_json")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class ChatUnreadCountResponse(BaseModel):
    unread_count: int

class ChatFeedbackRequest(BaseModel):
    message_id: int
    rating: int
    comment: Optional[str] = None

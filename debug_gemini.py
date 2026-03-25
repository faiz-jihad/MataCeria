import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("API Key not found in .env")
else:
    genai.configure(api_key=api_key)
    print(f"Checking models for key: {api_key[:10]}...")
    try:
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(f"Validated Model: {m.name}")
    except Exception as e:
        print(f"Error listing models: {e}")

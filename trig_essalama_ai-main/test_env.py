from dotenv import load_dotenv
import os

load_dotenv()
print("GEE_PROJECT =", os.getenv("GEE_PROJECT"))
print("GOOGLE_CLOUD_PROJECT =", os.getenv("GOOGLE_CLOUD_PROJECT"))

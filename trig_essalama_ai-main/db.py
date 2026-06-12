from pymongo import MongoClient

MONGO_URI = "mongodb+srv://oumaymabenna2_db_user:Test123456@trigessalama.sw3x05v.mongodb.net/trig_essalama?retryWrites=true&w=majority"
client = MongoClient(MONGO_URI)

# 👉 nom EXACT de ta base (MongoDB Atlas)
db = client["trig_essalama"]

# collection (table)
collection = db["risques"]

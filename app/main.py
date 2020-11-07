from fastapi.applications import FastAPI
from sqlalchemy.dialects.postgresql import JSONB
from starlette.config import Config
from typing import Any
from typing import Dict
import databases
import sqlalchemy


app = FastAPI()
config = Config(".env")

DATABASE_URL = config(
    "DATABASE_URL",
    cast=databases.DatabaseURL,
    default="postgresql://postgres:postgres@localhost:5432/postgres",
)
database = databases.Database(DATABASE_URL)
engine = sqlalchemy.create_engine(str(DATABASE_URL))
metadata = sqlalchemy.MetaData()
data = sqlalchemy.Table(
    "data",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, autoincrement=True, primary_key=True),
    sqlalchemy.Column("data", JSONB),
)


@app.on_event("startup")
async def startup():
    metadata.create_all(engine)
    await database.connect()


@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()


@app.post("/")
async def post(body: Dict[str, Any]):
    values = dict(data=body)
    query = data.insert(values)
    return await database.execute(query)


@app.get("/")
async def get():
    query = data.select()
    return await database.fetch_all(query)

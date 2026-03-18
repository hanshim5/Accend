from fastapi import HTTPException

def bad_request(msg: str):
    raise HTTPException(status_code=400, detail=msg)

def conflict(msg: str):
    raise HTTPException(status_code=409, detail=msg)

def not_found(msg: str):
    raise HTTPException(status_code=404, detail=msg)
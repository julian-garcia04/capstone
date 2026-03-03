from passlib.context import CryptContext

# takes the plain-text password the user typed and scrambles it into a random string like $2b$12$eImi
# saves scrambled string into the database.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(plain_password: str) -> str:
    # Scrambles a plain-text password into a bcrypt hash that is safe to store in the database.
    # Args: plain_password
    # Returns: a hash string (e.g. $2b$12$...)  to store in the database
    return pwd_context.hash(plain_password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    # Checks if a plain-text password typed at login matches the stored bcrypt hash
    # Args: plain_password, hashed password   
    # Returns: Boolean if password matches/ not 
    return pwd_context.verify(plain_password, hashed_password)

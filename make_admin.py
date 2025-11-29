#!/usr/bin/env python3
"""
Script to make a user an admin
or remove admin rights.
usage:
# Make user an admin
python make_admin.py someusername
# Remove admin rights
python make_admin.py --remove someusername
"""

import sys
from app import app
from models import db, User

def make_admin(username):
    with app.app_context():
        user = User.query.filter_by(username=username).first()
        
        if not user:
            print(f"Error: User '{username}' not found")
            return False
        
        if user.is_admin:
            print(f"User '{username}' is already an admin")
            return True
        
        user.is_admin = True
        db.session.commit()
        print(f"Success: '{username}' is now an admin")
        return True

def remove_admin(username):
    with app.app_context():
        user = User.query.filter_by(username=username).first()
        
        if not user:
            print(f"Error: User '{username}' not found")
            return False
        
        if not user.is_admin:
            print(f"User '{username}' is not an admin")
            return True
        
        user.is_admin = False
        db.session.commit()
        print(f"Success: Admin rights removed from '{username}'")
        return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python make_admin.py <username>")
        print("       python make_admin.py --remove <username>")
        sys.exit(1)
    
    if sys.argv[1] == '--remove' and len(sys.argv) == 3:
        remove_admin(sys.argv[2])
    else:
        make_admin(sys.argv[1])
genres = {
    "rock": {
        "name": "Rock",
        "connections": ["metal"]
    },
    "metal": {
        "name": "Metal", 
        "connections": ["rock", "death-metal", "thrash-metal", "groove-metal"]
    },
    "death-metal": {
        "name": "Death Metal",
        "connections": ["metal"]
    },
    "groove-metal": {
        "name": "Groove Metal",
        "connections": ["metal"]
    },
    "thrash-metal": {
        "name": "Thrash Metal",
        "connections": ["metal"]
    }
}

bands = {
    "pantera": {
        "name": "Pantera",
        "genres": ["groove-metal", "thrash-metal"]
    },
    "death": {
        "name": "Death",
        "genres": ["death-metal"]        
    },
    "cannibalcorpse": {
        "name": "Cannibal Corpse",
        "genres": ["death-metal"]        
    },
    "anthrax": {
        "name": "Anthrax",
        "genres": ["thrash-metal"]        
    }    
}
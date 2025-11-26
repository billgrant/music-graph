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
        "primary_genre": "groove-metal",
        "genres": ["groove-metal", "thrash-metal"]
    },
    "death": {
        "name": "Death",
        "primary_genre": "death-metal",
        "genres": ["death-metal"]        
    },
    "cannibalcorpse": {
        "name": "Cannibal Corpse",
        "primary_genre": "death-metal",
        "genres": ["death-metal"]        
    },
    "anthrax": {
        "name": "Anthrax",
        "primary_genre": "thrash-metal",
        "genres": ["thrash-metal"]        
    }    
}
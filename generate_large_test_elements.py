#!/usr/bin/env python3
import json
import random

# Berlin area bounds for randomization
LAT_MIN = 52.45
LAT_MAX = 52.60
LNG_MIN = 13.25
LNG_MAX = 13.55

# Marker types to cycle through
MARKER_TYPES = ["restaurant", "hospital", "school", "park", "bank"]

# Line styles to cycle through
LINE_STYLES = ["solid", "dashed", "dotted"]

def random_coordinate():
    """Generate a random coordinate within Berlin bounds"""
    lat = random.uniform(LAT_MIN, LAT_MAX)
    lng = random.uniform(LNG_MIN, LNG_MAX)
    return [lat, lng]

def generate_polygon():
    """Generate a random triangle polygon"""
    center = random_coordinate()
    # Create a small triangle around the center point
    offset = 0.002  # Small offset for triangle size
    return {
        "points": [
            [center[0] + offset, center[1] - offset],
            [center[0] - offset, center[1] + offset],
            [center[0] + offset, center[1] + offset]
        ]
    }

def generate_marker(marker_type):
    """Generate a random marker of given type"""
    return {
        "coordinates": random_coordinate(),
        "type": marker_type
    }

def generate_widget():
    """Generate a random pinned widget"""
    return {
        "coordinates": random_coordinate()
    }

def generate_line(style):
    """Generate a random line with given style"""
    return {
        "start": random_coordinate(),
        "end": random_coordinate(),
        "style": style
    }

def main():
    # Set seed for reproducible results
    random.seed(42)
    
    # Generate 100 of each element type
    data = {
        "polygons": [],
        "customMarkers": [],
        "pinnedWidgets": [],
        "lines": []
    }
    
    # Generate 100 polygons
    for i in range(100):
        data["polygons"].append(generate_polygon())
    
    # Generate 100 custom markers (20 of each type)
    for i in range(100):
        marker_type = MARKER_TYPES[i % len(MARKER_TYPES)]
        data["customMarkers"].append(generate_marker(marker_type))
    
    # Generate only 10 pinned widgets to avoid touch event interference
    for i in range(10):
        data["pinnedWidgets"].append(generate_widget())
    
    # Generate 100 lines (cycling through styles)
    for i in range(100):
        style = LINE_STYLES[i % len(LINE_STYLES)]
        data["lines"].append(generate_line(style))
    
    # Write to file
    with open("assets/test_elements_large.json", "w") as f:
        json.dump(data, f, indent=2)
    
    print("Generated test_elements_large.json with:")
    print(f"- {len(data['polygons'])} polygons")
    print(f"- {len(data['customMarkers'])} custom markers")
    print(f"- {len(data['pinnedWidgets'])} pinned widgets")
    print(f"- {len(data['lines'])} lines")

if __name__ == "__main__":
    main()

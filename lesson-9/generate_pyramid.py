#!/usr/bin/env python3
"""
Generate Sanity Checks Testing Pyramid as PNG
Run: python generate_pyramid.py
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import Polygon
import numpy as np

def create_sanity_checks_pyramid():
    # Create figure and axis
    fig, ax = plt.subplots(1, 1, figsize=(12, 10))
    
    # Define pyramid levels (from bottom to top)
    levels = [
        {"name": "Sanity Checks", "subtitle": "(Basic functionality)", "color": "#FF6B6B", "width": 10},
        {"name": "Unit Tests", "subtitle": "(Individual functions)", "color": "#4ECDC4", "width": 8},
        {"name": "Integration Tests", "subtitle": "(Component interactions)", "color": "#45B7D1", "width": 6},
        {"name": "E2E Tests", "subtitle": "(Complete workflows)", "color": "#96CEB4", "width": 4}
    ]
    
    # Starting position
    base_y = 0
    level_height = 1.5
    
    # Draw each level of the pyramid
    for i, level in enumerate(levels):
        y_bottom = base_y + (i * level_height)
        y_top = y_bottom + level_height
        width = level["width"]
        
        # Calculate trapezoid points
        left_bottom = -width/2
        right_bottom = width/2
        
        if i < len(levels) - 1:  # Not the top level
            next_width = levels[i + 1]["width"]
            left_top = -next_width/2
            right_top = next_width/2
        else:  # Top level (triangle)
            left_top = 0
            right_top = 0
        
        # Create trapezoid/triangle
        points = [
            [left_bottom, y_bottom],
            [right_bottom, y_bottom],
            [right_top, y_top],
            [left_top, y_top]
        ]
        
        # Draw the shape
        polygon = Polygon(points, facecolor=level["color"], edgecolor='black', linewidth=2, alpha=0.8)
        ax.add_patch(polygon)
        
        # Add text labels
        text_y = y_bottom + level_height/2
        ax.text(0, text_y + 0.2, level["name"], ha='center', va='center', 
                fontsize=14, fontweight='bold', color='white')
        ax.text(0, text_y - 0.2, level["subtitle"], ha='center', va='center', 
                fontsize=10, color='white', style='italic')
    
    # Add arrows and annotations on the sides
    arrow_props = dict(arrowstyle='->', lw=2, color='#333333')
    
    # Left side annotations
    ax.annotate('More tests\nFaster execution\nLower cost\nLower confidence', 
                xy=(-6, 1), xytext=(-8, 1),
                ha='center', va='center', fontsize=10, color='#333333',
                bbox=dict(boxstyle="round,pad=0.3", facecolor='lightgray', alpha=0.7))
    
    # Right side annotations  
    ax.annotate('Fewer tests\nSlower execution\nHigher cost\nHigher confidence', 
                xy=(6, 5), xytext=(8, 5),
                ha='center', va='center', fontsize=10, color='#333333',
                bbox=dict(boxstyle="round,pad=0.3", facecolor='lightgray', alpha=0.7))
    
    # Add arrows
    ax.annotate('', xy=(-5.5, 0.5), xytext=(-5.5, 2.5), arrowprops=arrow_props)
    ax.annotate('', xy=(5.5, 5.5), xytext=(5.5, 3.5), arrowprops=arrow_props)
    
    # Add title
    ax.text(0, 7.5, 'Testing Pyramid with Sanity Checks', ha='center', va='center', 
            fontsize=18, fontweight='bold', color='#333333')
    
    # Add subtitle explanation
    ax.text(0, -1, 'Sanity Checks: Foundation layer ensuring system is "sane" enough for further testing', 
            ha='center', va='center', fontsize=12, color='#666666', style='italic')
    
    # Set axis properties
    ax.set_xlim(-10, 10)
    ax.set_ylim(-1.5, 8)
    ax.set_aspect('equal')
    ax.axis('off')  # Hide axes
    
    # Adjust layout and save
    plt.tight_layout()
    plt.savefig('sanity_checks_pyramid.png', dpi=300, bbox_inches='tight', 
                facecolor='white', edgecolor='none')
    plt.show()
    
    print("✅ Sanity checks pyramid saved as 'sanity_checks_pyramid.png'")

if __name__ == "__main__":
    create_sanity_checks_pyramid()

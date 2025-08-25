#!/usr/bin/env python3
"""
Script to create a psycopg2 Lambda layer
"""
import os
import subprocess
import tempfile
import shutil
import zipfile

def create_psycopg2_layer():
    """Create a psycopg2 Lambda layer"""
    
    # Create temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        layer_dir = os.path.join(temp_dir, "python", "lib", "python3.11", "site-packages")
        os.makedirs(layer_dir, exist_ok=True)
        
        # Install psycopg2-binary
        subprocess.run([
            "pip", "install", "psycopg2-binary==2.9.9", 
            "-t", layer_dir, "--no-deps"
        ], check=True)
        
        # Clean up unnecessary files
        for root, dirs, files in os.walk(layer_dir):
            # Remove __pycache__ directories
            dirs[:] = [d for d in dirs if d != "__pycache__"]
            
            # Remove .pyc and .pyo files
            for file in files:
                if file.endswith(('.pyc', '.pyo')):
                    os.remove(os.path.join(root, file))
        
        # Create zip file
        zip_path = "psycopg2-layer-built.zip"
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            python_dir = os.path.join(temp_dir, "python")
            for root, dirs, files in os.walk(python_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, temp_dir)
                    zipf.write(file_path, arcname)
        
        print(f"psycopg2 layer created: {zip_path}")
        return zip_path

if __name__ == "__main__":
    create_psycopg2_layer()
